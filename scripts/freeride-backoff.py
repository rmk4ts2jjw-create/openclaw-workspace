#!/usr/bin/env python3
"""
FreeRide Exponential Backoff Wrapper

Wraps FreeRide/OpenRouter API calls with exponential backoff on 429 errors.
State: ~/.freeride/backoff-state.json

Usage:
  python3 freeride-backoff.py --check     → Check current backoff state
  python3 freeride-backoff.py --reset     → Reset all backoff state
  python3 freeride-backoff.py --call CMD  → Run a command with backoff awareness

Backoff strategy:
  - Base delay: 5 seconds
  - Multiplier: 2x per consecutive 429
  - Max delay: 300 seconds (5 minutes)
  - Cooldown resets after 60 seconds of successful calls
  - Per-model tracking (each model has its own backoff counter)
"""

import json
import os
import sys
import time
import subprocess
import shutil
import tempfile
from datetime import datetime, timezone

STATE_FILE = os.path.expanduser("~/.freeride/backoff-state.json")
LOG_FILE = os.path.expanduser("~/.freeride/backoff.log")
BASE_DELAY = 5       # seconds
MAX_DELAY = 300       # seconds (5 min)
MULTIPLIER = 2.0
RESET_AFTER = 60      # seconds of success before resetting backoff


def load_state():
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE) as f:
                return json.load(f)
        except:
            pass
    return {"models": {}, "global_429_count": 0, "last_429": None, "last_success": None}


def save_state(state):
    try:
        if os.path.exists(STATE_FILE):
            shutil.copy2(STATE_FILE, STATE_FILE + ".bak")
        fd, tmp = tempfile.mkstemp(dir=os.path.dirname(STATE_FILE), suffix='.tmp')
        with os.fdopen(fd, 'w') as f:
            json.dump(state, f, indent=2)
            f.flush()
            os.fsync(f.fileno())
        os.rename(tmp, STATE_FILE)
    except:
        pass


def log(msg):
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    with open(LOG_FILE, "a") as f:
        f.write(f"[{ts}] {msg}\n")
    print(msg)


def get_delay(model_id: str, state: dict) -> float:
    """Get the current delay for a model. Returns 0 if no backoff needed."""
    now = time.time()
    model_state = state.get("models", {}).get(model_id, {})
    
    consecutive_429s = model_state.get("consecutive_429s", 0)
    last_429 = model_state.get("last_429", 0)
    last_success = model_state.get("last_success", 0)
    
    # Reset if enough time has passed since last 429
    if last_429 and (now - last_429) > RESET_AFTER:
        if consecutive_429s > 0:
            log(f"  [backoff] {model_id}: reset after {RESET_AFTER}s cooldown")
        return 0
    
    # Reset if recent success
    if last_success and last_429 and last_success > last_429:
        return 0
    
    if consecutive_429s == 0:
        return 0
    
    delay = min(BASE_DELAY * (MULTIPLIER ** (consecutive_429s - 1)), MAX_DELAY)
    return delay


def record_429(model_id: str, state: dict):
    """Record a 429 error for a model."""
    now = time.time()
    if "models" not in state:
        state["models"] = {}
    if model_id not in state["models"]:
        state["models"][model_id] = {}
    
    model_state = state["models"][model_id]
    model_state["consecutive_429s"] = model_state.get("consecutive_429s", 0) + 1
    model_state["last_429"] = now
    state["global_429_count"] = state.get("global_429_count", 0) + 1
    state["last_429"] = datetime.now(timezone.utc).isoformat()
    
    delay = get_delay(model_id, state)
    log(f"  [backoff] {model_id}: 429 #{model_state['consecutive_429s']} → next delay {delay:.0f}s")


def record_success(model_id: str, state: dict):
    """Record a successful call for a model."""
    now = time.time()
    if "models" not in state:
        state["models"] = {}
    if model_id not in state["models"]:
        state["models"][model_id] = {}
    
    model_state = state["models"][model_id]
    prev_429s = model_state.get("consecutive_429s", 0)
    model_state["consecutive_429s"] = 0
    model_state["last_success"] = now
    state["last_success"] = datetime.now(timezone.utc).isoformat()
    
    if prev_429s > 0:
        log(f"  [backoff] {model_id}: success after {prev_429s} 429s → reset")


def check_status():
    """Print current backoff status."""
    state = load_state()
    print("FreeRide Backoff State")
    print(f"  Global 429 count: {state.get('global_429_count', 0)}")
    print(f"  Last 429: {state.get('last_429', 'never')}")
    print(f"  Last success: {state.get('last_success', 'never')}")
    print()
    
    models = state.get("models", {})
    if models:
        print("Per-model state:")
        for model_id, ms in models.items():
            consecutive = ms.get("consecutive_429s", 0)
            delay = get_delay(model_id, status)
            print(f"  {model_id}: {consecutive} consecutive 429s, next delay {delay:.0f}s")
    else:
        print("No per-model state tracked yet.")


def reset_state():
    """Reset all backoff state."""
    state = {"models": {}, "global_429_count": 0, "last_429": None, "last_success": None}
    save_state(state)
    log("Backoff state reset")


def main():
    args = sys.argv[1:]
    
    if not args or args[0] == "--check":
        check_status()
        return
    
    if args[0] == "--reset":
        reset_state()
        return
    
    if args[0] == "--call" and len(args) > 1:
        # Run a command with backoff awareness
        model_id = args[1] if len(args) > 2 else "default"
        cmd = args[2] if len(args) > 2 else args[1]
        
        state = load_state()
        delay = get_delay(model_id, state)
        
        if delay > 0:
            log(f"[backoff] {model_id}: waiting {delay:.0f}s before call...")
            time.sleep(delay)
        
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        
        # Check for 429 in output
        output = result.stdout + result.stderr
        if "429" in output or "rate limit" in output.lower() or result.returncode == 429:
            record_429(model_id, state)
            save_state(state)
            log(f"[backoff] {model_id}: 429 detected (rc={result.returncode})")
        else:
            record_success(model_id, state)
            save_state(state)
        
        print(result.stdout)
        if result.stderr:
            print(result.stderr, file=sys.stderr)
        sys.exit(result.returncode)
    
    print("Usage:")
    print("  freeride-backoff.py --check")
    print("  freeride-backoff.py --reset")
    print("  freeride-backoff.py --call [MODEL_ID] 'command'")


if __name__ == "__main__":
    main()
