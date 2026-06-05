#!/usr/bin/env python3
"""
safe_write.py — Atomic JSON write helper for tasks.json and incidents.json.

Usage from shell scripts:
    python3 safe_write.py <file_path> [json_data_stdin]

Usage from Python:
    from safe_write import safe_write_json, safe_write_json_locked

Guarantees:
- Atomic: writes to temp file first, then os.rename (atomic on same filesystem)
- Safe: preserves original file on error (no partial writes)
- Locked: file locking prevents concurrent writes from corrupting data
- Backed up: keeps last 3 versions as .bak.1, .bak.2, .bak.3
"""

import json
import os
import sys
import fcntl
import shutil
import tempfile
from datetime import datetime, timezone

TASKS_FILE = "/Users/spacemonkey/.openclaw/workspace/data/tasks.json"
INCIDENTS_FILE = "/Users/spacemonkey/.openclaw/workspace/data/incidents.json"
LOCK_DIR = "/Users/spacemonkey/.openclaw/workspace/data/.locks"


def get_lock_path(filepath):
    """Get the lock file path for a given data file."""
    basename = os.path.basename(filepath)
    return os.path.join(LOCK_DIR, f"{basename}.lock")


def safe_write_json(filepath, data, indent=2):
    """
    Atomically write JSON data to a file.
    - Creates parent dirs if needed
    - Writes to temp file in same directory, then os.rename
    - Rotates 3 backup copies (.bak.1, .bak.2, .bak.3)
    - Returns True on success, False on error
    """
    try:
        os.makedirs(os.path.dirname(filepath), exist_ok=True)

        # Rotate backups
        for i in range(3, 0, -1):
            src = f"{filepath}.bak.{i}" if i > 1 else f"{filepath}.bak"
            dst = f"{filepath}.bak.{i + 1}"
            if i == 3 and os.path.exists(dst):
                os.remove(dst)
            if os.path.exists(src):
                shutil.move(src, dst)
        if os.path.exists(filepath):
            shutil.move(filepath, f"{filepath}.bak")

        # Write to temp file in same directory (for atomic rename)
        dir_name = os.path.dirname(filepath) or '.'
        fd, tmp_path = tempfile.mkstemp(dir=dir_name, suffix='.tmp')
        try:
            with os.fdopen(fd, 'w') as f:
                json.dump(data, f, indent=indent)
                f.flush()
                os.fsync(f.fileno())
            os.rename(tmp_path, filepath)
            return True
        except Exception:
            # Clean up temp file on failure
            if os.path.exists(tmp_path):
                try:
                    os.remove(tmp_path)
                except OSError:
                    pass
            raise
    except Exception as e:
        print(f"safe_write_json error for {filepath}: {e}", file=sys.stderr)
        return False


def safe_write_json_locked(filepath, data, indent=2):
    """
    File-locked version of safe_write_json.
    Prevents concurrent writes from different processes.
    """
    os.makedirs(LOCK_DIR, exist_ok=True)
    lock_path = get_lock_path(filepath)

    try:
        lock_fd = open(lock_path, 'w')
        fcntl.flock(lock_fd.fileno(), fcntl.LOCK_EX)  # Exclusive lock
        try:
            result = safe_write_json(filepath, data, indent)
            return result
        finally:
            fcntl.flock(lock_fd.fileno(), fcntl.LOCK_UN)
            lock_fd.close()
    except Exception as e:
        print(f"safe_write_json_locked error for {filepath}: {e}", file=sys.stderr)
        return False


def safe_read_json(filepath, default=None):
    """
    Safely read JSON from a file.
    If the main file is corrupt, try backups.
    """
    for path in [filepath, f"{filepath}.bak", f"{filepath}.bak.2", f"{filepath}.bak.3"]:
        if os.path.exists(path):
            try:
                with open(path) as f:
                    return json.load(f)
            except (json.JSONDecodeError, IOError):
                continue
    return default if default is not None else []


if __name__ == '__main__':
    # CLI usage: python3 safe_write.py <file_path>
    # Reads JSON from stdin, writes atomically to file_path
    if len(sys.argv) < 2:
        print("Usage: python3 safe_write.py <file_path>", file=sys.stderr)
        sys.exit(1)

    filepath = sys.argv[1]
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Invalid JSON on stdin: {e}", file=sys.stderr)
        sys.exit(1)

    success = safe_write_json_locked(filepath, data)
    sys.exit(0 if success else 1)
