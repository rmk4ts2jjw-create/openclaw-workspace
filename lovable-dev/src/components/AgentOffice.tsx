import { useEffect, useRef } from "react";
import monkeyIdle from "@/assets/sprite-monkey-idle.png";
import monkeyWork from "@/assets/sprite-monkey-working.png";
import monkeyWalk from "@/assets/sprite-monkey-walking.png";
import lsIdle from "@/assets/sprite-lifesupport-idle.png";
import lsWork from "@/assets/sprite-lifesupport-working.png";
import lsWalk from "@/assets/sprite-lifesupport-walking.png";
import engIdle from "@/assets/sprite-engineer-idle.png";
import engWork from "@/assets/sprite-engineer-working.png";
import engWalk from "@/assets/sprite-engineer-walking.png";
import arcIdle from "@/assets/sprite-archivist-idle.png";
import arcWork from "@/assets/sprite-archivist-working.png";
import arcWalk from "@/assets/sprite-archivist-walking.png";

type AgentState = "idle" | "working" | "sleeping" | "walking";

interface AgentDef {
  id: string;
  name: string;
  accent: string; // hex
  accentSoft: string;
  home: 0 | 1 | 2 | 3; // room index
  state: AgentState;
  task: string;
  sprites: { idle: string; working: string; walking: string };
}

const ROOM_W = 380;
const ROOM_H = 275;
const W = ROOM_W * 2;
const H = ROOM_H * 2;

// Room top-left in canvas space: [col, row]
const ROOM_POS: [number, number][] = [
  [0, 0],            // 0 Command HQ
  [ROOM_W, 0],       // 1 Security Bay
  [0, ROOM_H],       // 2 Engineering
  [ROOM_W, ROOM_H],  // 3 Archive
];

const ROOM_META = [
  { label: "COMMAND HQ",   accent: "#a78bfa", tint: "rgba(139,92,246,0.10)" },
  { label: "SECURITY BAY", accent: "#ec4899", tint: "rgba(236,72,153,0.10)" },
  { label: "ENGINEERING",  accent: "#22d3ee", tint: "rgba(34,211,238,0.10)" },
  { label: "ARCHIVE",      accent: "#f59e0b", tint: "rgba(245,158,11,0.10)" },
];

const AGENTS: AgentDef[] = [
  {
    id: "monkey", name: "Space Monkey", accent: "#a78bfa", accentSoft: "rgba(167,139,250,0.35)",
    home: 0, state: "working", task: "Compiling Mission Control...",
    sprites: { idle: monkeyIdle, working: monkeyWork, walking: monkeyWalk },
  },
  {
    id: "lifesupport", name: "Life Support", accent: "#ec4899", accentSoft: "rgba(236,72,153,0.35)",
    home: 1, state: "idle", task: "Waiting for orders",
    sprites: { idle: lsIdle, working: lsWork, walking: lsWalk },
  },
  {
    id: "engineer", name: "Systems Engineer", accent: "#22d3ee", accentSoft: "rgba(34,211,238,0.35)",
    home: 2, state: "idle", task: "Standing by",
    sprites: { idle: engIdle, working: engWork, walking: engWalk },
  },
  {
    id: "archivist", name: "Station Archivist", accent: "#f59e0b", accentSoft: "rgba(245,158,11,0.35)",
    home: 3, state: "sleeping", task: "zzz",
    sprites: { idle: arcIdle, working: arcWork, walking: arcWalk },
  },
];

function loadImg(src: string): Promise<HTMLImageElement> {
  return new Promise((res) => {
    const i = new Image();
    i.onload = () => res(i);
    i.onerror = () => res(i);
    i.src = src;
  });
}

export function AgentOffice() {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx0 = canvas.getContext("2d");
    if (!ctx0) return;
    const ctx: CanvasRenderingContext2D = ctx0;

    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = W * dpr;
    canvas.height = H * dpr;
    canvas.style.width = "100%";
    canvas.style.aspectRatio = `${W} / ${H}`;
    ctx.scale(dpr, dpr);
    ctx.imageSmoothingEnabled = false;

    let raf = 0;
    let running = true;
    const start = performance.now();

    // Agent runtime state
    const SPRITE = 72;
    const HOME_OFFSET: [number, number][] = [
      [ROOM_W / 2 - SPRITE / 2, ROOM_H / 2 - SPRITE / 2 + 20],
      [ROOM_W / 2 - SPRITE / 2, ROOM_H / 2 - SPRITE / 2 + 20],
      [ROOM_W / 2 - SPRITE / 2, ROOM_H / 2 - SPRITE / 2 + 20],
      [ROOM_W / 2 - SPRITE / 2, ROOM_H / 2 - SPRITE / 2 + 20],
    ];
    const runtime = AGENTS.map((a) => {
      const [rx, ry] = ROOM_POS[a.home];
      const [ox, oy] = HOME_OFFSET[a.home];
      return {
        def: a,
        x: rx + ox,
        y: ry + oy,
        homeX: rx + ox,
        homeY: ry + oy,
        facing: 1 as 1 | -1,
        glanceAt: Math.random() * 12000,
        imgs: { idle: new Image(), working: new Image(), walking: new Image() } as Record<string, HTMLImageElement>,
        loaded: false,
      };
    });

    Promise.all(
      runtime.flatMap((r) => [
        loadImg(r.def.sprites.idle).then((i) => (r.imgs.idle = i)),
        loadImg(r.def.sprites.working).then((i) => (r.imgs.working = i)),
        loadImg(r.def.sprites.walking).then((i) => (r.imgs.walking = i)),
      ]),
    ).then(() => {
      runtime.forEach((r) => (r.loaded = true));
    });

    // ---- BACKGROUND (static-ish, redrawn each frame for simplicity) ----
    function drawRoom(idx: number, t: number) {
      const [x, y] = ROOM_POS[idx];
      const m = ROOM_META[idx];
      ctx.save();
      // floor base
      const grad = ctx.createLinearGradient(x, y, x, y + ROOM_H);
      grad.addColorStop(0, "#1a2138");
      grad.addColorStop(1, "#0e1426");
      ctx.fillStyle = grad;
      ctx.fillRect(x, y, ROOM_W, ROOM_H);
      // tint
      ctx.fillStyle = m.tint;
      ctx.fillRect(x, y, ROOM_W, ROOM_H);
      // tile grid (floor)
      ctx.strokeStyle = "rgba(255,255,255,0.03)";
      ctx.lineWidth = 1;
      for (let i = 1; i < 6; i++) {
        const gx = x + (i * ROOM_W) / 6;
        ctx.beginPath(); ctx.moveTo(gx, y + ROOM_H * 0.55); ctx.lineTo(gx, y + ROOM_H); ctx.stroke();
      }
      for (let i = 1; i < 4; i++) {
        const gy = y + ROOM_H * 0.55 + (i * ROOM_H * 0.45) / 4;
        ctx.beginPath(); ctx.moveTo(x, gy); ctx.lineTo(x + ROOM_W, gy); ctx.stroke();
      }
      // back wall accent strip
      ctx.fillStyle = "rgba(0,0,0,0.35)";
      ctx.fillRect(x, y, ROOM_W, ROOM_H * 0.55);

      // room label
      ctx.fillStyle = "rgba(0,0,0,0.5)";
      ctx.fillRect(x + 8, y + 8, 110, 16);
      ctx.fillStyle = m.accent;
      ctx.font = "9px ui-monospace, monospace";
      ctx.textBaseline = "middle";
      ctx.fillText(m.label, x + 14, y + 16);

      // per-room ambient
      if (idx === 0) drawCommand(x, y, t, m.accent);
      if (idx === 1) drawSecurity(x, y, t, m.accent);
      if (idx === 2) drawEngineering(x, y, t, m.accent);
      if (idx === 3) drawArchive(x, y, t, m.accent);
      ctx.restore();
    }

    function drawCommand(x: number, y: number, t: number, accent: string) {
      // 3 monitors
      for (let i = 0; i < 3; i++) {
        const mx = x + 60 + i * 90;
        const my = y + 70;
        const b = 0.35 + 0.5 * (0.5 + 0.5 * Math.sin(t / 600 + i * 1.7));
        ctx.fillStyle = "#0a0f1f";
        ctx.fillRect(mx, my, 70, 46);
        ctx.fillStyle = `rgba(167,139,250,${b * 0.55})`;
        ctx.fillRect(mx + 3, my + 3, 64, 40);
        ctx.strokeStyle = accent;
        ctx.lineWidth = 1;
        ctx.strokeRect(mx, my, 70, 46);
        // stand
        ctx.fillStyle = "#2a2f45";
        ctx.fillRect(mx + 30, my + 46, 10, 6);
      }
      // star map rotating
      ctx.save();
      const cx = x + ROOM_W - 50, cy = y + 50;
      ctx.translate(cx, cy);
      ctx.rotate((t / 60000) * Math.PI * 2);
      ctx.strokeStyle = "rgba(167,139,250,0.35)";
      ctx.beginPath(); ctx.arc(0, 0, 26, 0, Math.PI * 2); ctx.stroke();
      ctx.beginPath(); ctx.arc(0, 0, 16, 0, Math.PI * 2); ctx.stroke();
      for (let i = 0; i < 7; i++) {
        const a = (i / 7) * Math.PI * 2;
        ctx.fillStyle = "#e9d5ff";
        ctx.fillRect(Math.cos(a) * 22 - 1, Math.sin(a) * 22 - 1, 2, 2);
      }
      ctx.restore();
      // blink panel
      const blink = Math.floor(t / 1000) % 18 === 0;
      ctx.fillStyle = blink ? "#86efac" : "#16a34a";
      ctx.fillRect(x + 14, y + ROOM_H - 26, 8, 8);
    }

    function drawSecurity(x: number, y: number, t: number, accent: string) {
      // radar
      const cx = x + 70, cy = y + 95;
      ctx.fillStyle = "rgba(0,0,0,0.55)";
      ctx.beginPath(); ctx.arc(cx, cy, 40, 0, Math.PI * 2); ctx.fill();
      ctx.strokeStyle = "rgba(236,72,153,0.4)";
      for (let r = 10; r <= 40; r += 10) {
        ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke();
      }
      const sweep = (t / 4000) * Math.PI * 2;
      ctx.save();
      ctx.translate(cx, cy);
      ctx.rotate(sweep);
      const grd = ctx.createLinearGradient(0, 0, 40, 0);
      grd.addColorStop(0, "rgba(236,72,153,0.7)");
      grd.addColorStop(1, "rgba(236,72,153,0)");
      ctx.fillStyle = grd;
      ctx.beginPath(); ctx.moveTo(0, 0); ctx.arc(0, 0, 40, -0.35, 0.05); ctx.closePath(); ctx.fill();
      ctx.restore();
      // camera feeds (3)
      for (let i = 0; i < 3; i++) {
        const fx = x + 160 + (i % 3) * 60;
        const fy = y + 70;
        const hue = (t / 60 + i * 80) % 360;
        ctx.fillStyle = `hsl(${hue},40%,18%)`;
        ctx.fillRect(fx, fy, 50, 36);
        ctx.strokeStyle = accent;
        ctx.strokeRect(fx, fy, 50, 36);
        ctx.fillStyle = "rgba(255,255,255,0.06)";
        ctx.fillRect(fx, fy + 30, 50, 6);
      }
      // alert flash
      const flash = Math.sin(t / 350) > 0.97;
      if (flash) {
        ctx.fillStyle = "#f59e0b";
        ctx.fillRect(x + ROOM_W - 22, y + 30, 8, 8);
      }
    }

    function drawEngineering(x: number, y: number, t: number, accent: string) {
      // workbench
      ctx.fillStyle = "#3a2f1a";
      ctx.fillRect(x + 30, y + 110, ROOM_W - 60, 14);
      ctx.fillStyle = "#2a210f";
      ctx.fillRect(x + 30, y + 124, ROOM_W - 60, 4);
      // soldering spark
      const spark = (Math.sin(t / 120) + Math.sin(t / 73)) > 1.6;
      if (spark) {
        const sx = x + 70, sy = y + 108;
        ctx.fillStyle = "#fde047";
        ctx.fillRect(sx, sy, 3, 3);
        ctx.fillStyle = "rgba(253,224,71,0.45)";
        ctx.beginPath(); ctx.arc(sx + 1.5, sy + 1.5, 8, 0, Math.PI * 2); ctx.fill();
      }
      // holo blueprint
      ctx.save();
      const cx = x + ROOM_W - 75, cy = y + 80;
      ctx.translate(cx, cy);
      ctx.rotate((t / 20000) * Math.PI * 2);
      ctx.strokeStyle = "rgba(34,211,238,0.55)";
      ctx.lineWidth = 1;
      ctx.strokeRect(-22, -16, 44, 32);
      ctx.strokeRect(-14, -10, 12, 12);
      ctx.beginPath(); ctx.moveTo(2, -10); ctx.lineTo(18, -10); ctx.lineTo(18, 6); ctx.stroke();
      ctx.restore();
      // pulsing accent lights
      const pulse = 0.4 + 0.6 * (0.5 + 0.5 * Math.sin(t / 1000));
      ctx.fillStyle = `rgba(34,211,238,${pulse})`;
      ctx.fillRect(x + 6, y + 60, 4, 4);
      ctx.fillRect(x + 6, y + 100, 4, 4);
      ctx.fillRect(x + 6, y + 140, 4, 4);
      void accent;
    }

    function drawArchive(x: number, y: number, t: number, accent: string) {
      // bookshelves
      for (let i = 0; i < 3; i++) {
        const sx = x + 30 + i * 90;
        ctx.fillStyle = "#3a2a14";
        ctx.fillRect(sx, y + 50, 70, 90);
        for (let r = 0; r < 4; r++) {
          ctx.fillStyle = ["#7c2d12", "#9a3412", "#a16207", "#854d0e"][r];
          for (let b = 0; b < 6; b++) {
            ctx.fillRect(sx + 4 + b * 11, y + 56 + r * 22, 9, 18);
          }
        }
      }
      // lanterns (3, independent flicker)
      const lanternsY = y + 38;
      for (let i = 0; i < 3; i++) {
        const lx = x + 60 + i * 90;
        const seed = i * 1.7 + 0.4;
        const f = 0.55 + 0.45 * (0.5 + 0.5 * Math.sin(t / (1800 + i * 600) + seed) * Math.cos(t / (900 + i * 300)));
        ctx.fillStyle = `rgba(245,158,11,${f * 0.9})`;
        ctx.beginPath(); ctx.arc(lx, lanternsY, 7, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = `rgba(245,158,11,${f * 0.2})`;
        ctx.beginPath(); ctx.arc(lx, lanternsY, 16, 0, Math.PI * 2); ctx.fill();
        ctx.strokeStyle = "#1f1305"; ctx.beginPath(); ctx.moveTo(lx, y + 22); ctx.lineTo(lx, lanternsY - 6); ctx.stroke();
      }
      // dust motes
      for (let i = 0; i < 4; i++) {
        const seed = i * 97;
        const dx = x + ((seed * 13 + t * 0.01) % ROOM_W);
        const dy = y + ROOM_H - ((t * 0.015 + seed) % ROOM_H);
        const dxw = dx + Math.sin(t / 800 + i) * 6;
        ctx.fillStyle = "rgba(254,243,199,0.35)";
        ctx.fillRect(dxw, dy, 2, 2);
      }
      // crystal glow
      const glow = Math.sin(t / 1500 + 1.2) > 0.7;
      ctx.fillStyle = glow ? "rgba(245,158,11,0.9)" : "rgba(245,158,11,0.35)";
      ctx.fillRect(x + ROOM_W - 30, y + ROOM_H - 30, 6, 6);
      void accent;
    }

    function drawWalls() {
      // outer frame (subtle)
      ctx.strokeStyle = "rgba(255,255,255,0.06)";
      ctx.lineWidth = 1;
      ctx.strokeRect(0.5, 0.5, W - 1, H - 1);
      // vertical shared wall with doorway gap in the middle
      ctx.fillStyle = "rgba(255,255,255,0.08)";
      ctx.fillRect(ROOM_W - 1, 0, 2, H);
      ctx.fillStyle = "#12182A";
      ctx.fillRect(ROOM_W - 4, H / 2 - 22, 8, 44); // doorway
      // horizontal shared wall with doorway gap in the middle
      ctx.fillStyle = "rgba(255,255,255,0.08)";
      ctx.fillRect(0, ROOM_H - 1, W, 2);
      ctx.fillStyle = "#12182A";
      ctx.fillRect(W / 2 - 22, ROOM_H - 4, 44, 8);
    }

    function drawBubble(cx: number, topY: number, text: string, color: string) {
      ctx.font = "10px ui-monospace, monospace";
      const padX = 6, padY = 4;
      const w = Math.min(180, ctx.measureText(text).width + padX * 2);
      const h = 18;
      const x = cx - w / 2;
      const y = topY - h - 6;
      ctx.fillStyle = "rgba(26,26,46,0.95)";
      ctx.strokeStyle = color;
      ctx.lineWidth = 1;
      ctx.beginPath();
      const r = 4;
      ctx.moveTo(x + r, y);
      ctx.lineTo(x + w - r, y);
      ctx.quadraticCurveTo(x + w, y, x + w, y + r);
      ctx.lineTo(x + w, y + h - r);
      ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
      ctx.lineTo(cx + 4, y + h);
      ctx.lineTo(cx, y + h + 5);
      ctx.lineTo(cx - 4, y + h);
      ctx.lineTo(x + r, y + h);
      ctx.quadraticCurveTo(x, y + h, x, y + h - r);
      ctx.lineTo(x, y + r);
      ctx.quadraticCurveTo(x, y, x + r, y);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      ctx.fillStyle = color;
      ctx.textBaseline = "middle";
      // truncate
      let t = text;
      while (ctx.measureText(t).width > w - padX * 2 && t.length > 3) t = t.slice(0, -2);
      if (t !== text) t = t.slice(0, -1) + "…";
      ctx.fillText(t, x + padX, y + h / 2);
      void padY;
    }

    function drawAgent(r: typeof runtime[number], t: number) {
      const a = r.def;
      let img = r.imgs.idle;
      let yOff = 0;
      let alpha = 1;
      if (a.state === "working") img = r.imgs.working;
      else if (a.state === "walking") img = r.imgs.walking;
      else img = r.imgs.idle;

      if (a.state === "idle") {
        yOff = Math.sin(t / 1000 + a.home) * 2;
        // glance flip every ~12s
        if (t - r.glanceAt > 12000) {
          r.facing = (r.facing * -1) as 1 | -1;
          r.glanceAt = t;
        }
      } else if (a.state === "sleeping") {
        alpha = 0.6;
        yOff = Math.sin(t / 1800) * 1.2;
      } else if (a.state === "working") {
        yOff = Math.sin(t / 220) * 0.6;
      }

      ctx.save();
      ctx.globalAlpha = alpha;
      const drawX = r.x;
      const drawY = r.y + yOff;
      if (r.facing === -1) {
        ctx.translate(drawX + SPRITE, drawY);
        ctx.scale(-1, 1);
        if (r.loaded && img.width) ctx.drawImage(img, 0, 0, SPRITE, SPRITE);
      } else {
        if (r.loaded && img.width) ctx.drawImage(img, drawX, drawY, SPRITE, SPRITE);
      }
      ctx.restore();

      // monitor glow on face when working
      if (a.state === "working") {
        const g = 0.25 + 0.2 * (0.5 + 0.5 * Math.sin(t / 400));
        ctx.fillStyle = `rgba(167,139,250,${g})`;
        ctx.fillRect(r.x + 18, r.y + 18, 36, 18);
      }

      // bubble
      const text = a.state === "sleeping" ? "zzz" : a.task;
      drawBubble(r.x + SPRITE / 2, r.y + yOff, text, a.accent);

      // sleeping zzz floats
      if (a.state === "sleeping") {
        const zt = (t / 30) % 60;
        ctx.fillStyle = `rgba(254,243,199,${1 - zt / 60})`;
        ctx.font = "10px ui-monospace, monospace";
        ctx.fillText("z", r.x + SPRITE - 8, r.y - 8 - zt * 0.5);
      }

      // status dot near feet
      ctx.fillStyle = a.accent;
      ctx.beginPath();
      ctx.arc(r.x + SPRITE / 2, r.y + SPRITE + 4, 2.5, 0, Math.PI * 2);
      ctx.fill();
    }

    function render(now: number) {
      if (!running) return;
      const t = now - start;
      // background
      ctx.fillStyle = "#12182A";
      ctx.fillRect(0, 0, W, H);
      for (let i = 0; i < 4; i++) drawRoom(i, t);
      drawWalls();
      runtime.forEach((r) => drawAgent(r, t));
      raf = requestAnimationFrame(render);
    }
    raf = requestAnimationFrame(render);

    const onVis = () => {
      if (document.hidden) {
        running = false;
        cancelAnimationFrame(raf);
      } else if (!running) {
        running = true;
        raf = requestAnimationFrame(render);
      }
    };
    document.addEventListener("visibilitychange", onVis);

    return () => {
      running = false;
      cancelAnimationFrame(raf);
      document.removeEventListener("visibilitychange", onVis);
    };
  }, []);

  return (
    <div className="relative w-full overflow-hidden rounded-xl border border-border bg-[#12182A]">
      <canvas ref={canvasRef} className="block w-full" />
    </div>
  );
}

export default AgentOffice;