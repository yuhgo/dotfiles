#!/usr/bin/env bun
// Claude Code Statusline (TypeScript + Bun)
// 5-line dashboard: identity/location, context bar, 5h bar, 7d bar, harness-mem
// Colors: TrueColor gradient (green → yellow → red)

// ── Types ──

interface StatusLineInput {
  model?: { display_name?: string };
  context_window?: { used_percentage?: number };
  cost?: { total_lines_added?: number; total_lines_removed?: number };
  workspace?: { current_dir?: string };
  session_id?: string;
  rate_limits?: {
    five_hour?: { used_percentage?: number; resets_at?: number };
    seven_day?: { used_percentage?: number; resets_at?: number };
  };
}

// ── Colors (Kanagawa Wave base) ──

const GRAY = "\x1b[38;2;114;113;105m"; // fujiGray    #727169  (also used for │ separators)
const BLUE = "\x1b[38;2;126;156;216m"; // crystalBlue #7E9CD8
const CYAN = "\x1b[38;2;127;180;202m"; // springBlue  #7FB4CA
const ORANGE = "\x1b[38;2;255;160;102m"; // surimiOrange #FFA066
const GREEN = "\x1b[38;2;152;187;108m"; // springGreen #98BB6C
const YELLOW = "\x1b[38;2;230;195;132m"; // carpYellow  #E6C384
const RED = "\x1b[38;2;255;93;98m"; // peachRed    #FF5D62
const RESET = "\x1b[0m";

// ── TrueColor gradient (springGreen → yellow → red) ──
// 0%: rgb(152,187,108) = Kanagawa springGreen
// 50%: rgb(255,187,108) = warm yellow
// 100%: rgb(255,0,60) = deep red

function gradientColor(pct: number): string {
  if (pct < 50) {
    const r = Math.floor(152 + (pct * 103) / 50);
    return `\x1b[38;2;${r};187;108m`;
  }
  const g = Math.max(0, Math.floor(187 - ((pct - 50) * 187) / 50));
  const b = Math.max(60, Math.floor(108 - ((pct - 50) * 48) / 50));
  return `\x1b[38;2;255;${g};${b}m`;
}

// ── Fine Bar + Gradient (█ filled, ░ dimmed dot pattern for empty) ──

const BLOCKS = [" ", "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"];

function progressBar(pct: number): string {
  const width = 10;
  pct = Math.max(0, Math.min(100, pct));

  const filledX1000 = pct * width * 10;
  const full = Math.floor(filledX1000 / 1000);
  const frac = Math.floor(((filledX1000 % 1000) * 8) / 1000);

  // Gradient RGB
  let r: number, g: number, b: number;
  if (pct < 50) {
    r = Math.floor(152 + (pct * 103) / 50);
    g = 187;
    b = 108;
  } else {
    r = 255;
    g = Math.max(0, Math.floor(187 - ((pct - 50) * 187) / 50));
    b = Math.max(60, Math.floor(108 - ((pct - 50) * 48) / 50));
  }

  let bar = `\x1b[38;2;${r};${g};${b}m`;

  // Filled: █ with gradient foreground
  bar += "█".repeat(full);

  // Partial + empty (only if not fully filled)
  if (full < width) {
    if (frac > 0) {
      bar += BLOCKS[frac];
      const emptyCount = width - full - 1;
      bar += `\x1b[38;2;${Math.floor(r / 3)};${Math.floor(g / 3)};${Math.floor(b / 3)}m`;
      bar += "░".repeat(emptyCount);
    } else {
      const emptyCount = width - full;
      bar += `\x1b[38;2;${Math.floor(r / 3)};${Math.floor(g / 3)};${Math.floor(b / 3)}m`;
      bar += "░".repeat(emptyCount);
    }
  }

  bar += RESET;
  return bar;
}

// ── Date formatting ──

function format5hReset(epoch: number): string {
  const d = new Date(epoch * 1000);
  const hour = d.toLocaleString("en-US", {
    timeZone: "Asia/Tokyo",
    hour: "numeric",
    hour12: true,
  });
  // "5 PM" → "5pm"
  return `Resets ${hour.toLowerCase().replace(" ", "")} (Asia/Tokyo)`;
}

function format7dReset(epoch: number): string {
  const d = new Date(epoch * 1000);
  const month = d.toLocaleString("en-US", {
    timeZone: "Asia/Tokyo",
    month: "short",
  });
  const day = d.toLocaleString("en-US", {
    timeZone: "Asia/Tokyo",
    day: "numeric",
  });
  const hour = d.toLocaleString("en-US", {
    timeZone: "Asia/Tokyo",
    hour: "numeric",
    hour12: true,
  });
  // "Resets Mar 6 at 12pm (Asia/Tokyo)"
  return `Resets ${month} ${day} at ${hour.toLowerCase().replace(" ", "")} (Asia/Tokyo)`;
}

function formatTimeAgo(isoDate: string): string {
  const epoch = new Date(isoDate).getTime();
  if (isNaN(epoch)) return "";
  const diffSec = Math.floor((Date.now() - epoch) / 1000);
  if (diffSec < 60) return `${diffSec}s ago`;
  if (diffSec < 3600) return `${Math.floor(diffSec / 60)}m ago`;
  if (diffSec < 86400) return `${Math.floor(diffSec / 3600)}h ago`;
  return `${Math.floor(diffSec / 86400)}d ago`;
}

// ── Shell command helper ──

async function run(cmd: string[]): Promise<string> {
  try {
    const proc = Bun.spawn(cmd, { stdout: "pipe", stderr: "ignore" });
    const text = await new Response(proc.stdout).text();
    return text.trim();
  } catch {
    return "";
  }
}

// ── Git info ──

async function getGitInfo(
  cwd: string
): Promise<{ branch: string; repo: string }> {
  if (!cwd) return { branch: "", repo: "" };
  try {
    await run(["git", "-C", cwd, "rev-parse", "--git-dir"]);
    const [branch, toplevel] = await Promise.all([
      run(["git", "-C", cwd, "symbolic-ref", "--short", "HEAD"]).catch(() =>
        run(["git", "-C", cwd, "rev-parse", "--short", "HEAD"])
      ),
      run(["git", "-C", cwd, "rev-parse", "--show-toplevel"]),
    ]);
    const repo = toplevel ? toplevel.split("/").pop() ?? "" : "";
    return { branch, repo };
  } catch {
    return { branch: "", repo: "" };
  }
}

// ── Harness-mem ──

type HarnessMemStatus = "connected" | "degraded" | "disconnected";

interface HarnessMemResult {
  status: HarnessMemStatus;
  warnings: string[];
}

async function getHarnessMem(): Promise<HarnessMemResult> {
  try {
    const healthRes = await fetch("http://127.0.0.1:37888/health", {
      signal: AbortSignal.timeout(1000),
    });
    const health = (await healthRes.json()) as {
      ok?: boolean;
      warnings?: unknown;
    };
    if (!health.ok) return { status: "disconnected", warnings: [] };

    const warnings = Array.isArray(health.warnings)
      ? health.warnings.map((w) => String(w)).filter((w) => w.length > 0)
      : [];

    return {
      status: warnings.length > 0 ? "degraded" : "connected",
      warnings,
    };
  } catch {
    return { status: "disconnected", warnings: [] };
  }
}

// ── Main ──

async function main() {
  const input: StatusLineInput = await Bun.stdin.json();

  const model = input.model?.display_name ?? "";
  const usedPct = input.context_window?.used_percentage ?? 0;
  const ctxInt = Math.round(usedPct);
  const linesAdded = input.cost?.total_lines_added ?? 0;
  const linesRemoved = input.cost?.total_lines_removed ?? 0;
  const cwd = input.workspace?.current_dir ?? "";

  const fivePct = input.rate_limits?.five_hour?.used_percentage;
  const fiveResetEpoch = input.rate_limits?.five_hour?.resets_at;
  const sevenPct = input.rate_limits?.seven_day?.used_percentage;
  const sevenResetEpoch = input.rate_limits?.seven_day?.resets_at;

  // Parallel: git info + harness-mem
  const [gitInfo, hmem] = await Promise.all([
    getGitInfo(cwd),
    getHarnessMem(),
  ]);

  const sep = `${GRAY} │ ${RESET}`;
  const ctxColor = gradientColor(ctxInt);

  // ── Line 1: Model, repo/branch, diff ──
  let line1 = `🤖 ${CYAN}${model}${RESET}`;
  if (gitInfo.repo) {
    line1 += `${sep}📁 ${BLUE}${gitInfo.repo}${RESET}`;
    if (gitInfo.branch) {
      line1 += ` ${GRAY}/${RESET} ${ORANGE}${gitInfo.branch}${RESET}`;
    }
  } else if (gitInfo.branch) {
    line1 += `${sep}🔀 ${ORANGE}${gitInfo.branch}${RESET}`;
  }
  line1 += `${sep}✏️ ${GREEN}+${linesAdded}${RESET}/${RED}-${linesRemoved}${RESET}`;

  // ── Line 2: Context window bar ──
  let line2 = "";
  if (ctxInt > 0) {
    const ctxBar = progressBar(ctxInt);
    line2 = `${ctxColor}📊 ctx${RESET} ${ctxBar}  ${ctxColor}${ctxInt}%${RESET}`;
  }

  // ── Line 3: 5h rate limit ──
  let line3 = "";
  if (fivePct != null) {
    const fi = Math.round(fivePct);
    const fiveColor = gradientColor(fi);
    const fiveBar = progressBar(fi);
    line3 = `${fiveColor}🕐 5h ${RESET} ${fiveBar}  ${fiveColor}${fi}%${RESET}`;
    if (fiveResetEpoch) {
      line3 += `  ${GRAY}${format5hReset(fiveResetEpoch)}${RESET}`;
    }
  }

  // ── Line 4: 7d rate limit ──
  let line4 = "";
  if (sevenPct != null) {
    const si = Math.round(sevenPct);
    const sevenColor = gradientColor(si);
    const sevenBar = progressBar(si);
    line4 = `${sevenColor}📅 7d ${RESET} ${sevenBar}  ${sevenColor}${si}%${RESET}`;
    if (sevenResetEpoch) {
      line4 += `  ${GRAY}${format7dReset(sevenResetEpoch)}${RESET}`;
    }
  }

  // ── Line 5: harness-mem connection status ──
  // Three-state indicator:
  //   🟢 Connected   — health.ok && no warnings
  //   🟡 Degraded    — health.ok but warnings[] present (show count + detail)
  //   🔴 Disconnected — health failed / daemon offline
  let line5 = "";
  if (hmem.status === "connected") {
    line5 = `🟢 ${GREEN}mem Connected${RESET}`;
  } else if (hmem.status === "degraded") {
    const count = hmem.warnings.length;
    const head = hmem.warnings[0] ?? "";
    const headTrunc = head.length > 50 ? head.slice(0, 49) + "…" : head;
    line5 = `🟡 ${YELLOW}mem Degraded${RESET}  ${GRAY}${count} warning${count === 1 ? "" : "s"}${RESET}`;
    if (headTrunc) line5 += `  ${YELLOW}${headTrunc}${RESET}`;
  } else {
    line5 = `🔴 ${RED}mem Disconnected — daemon unreachable at 127.0.0.1:37888${RESET}`;
  }

  // ── Output ──
  let output = line1;
  if (line2) output += "\n" + line2;
  if (line3) output += "\n" + line3;
  if (line4) output += "\n" + line4;
  if (line5) output += "\n" + line5;

  process.stdout.write(output);
}

main();
