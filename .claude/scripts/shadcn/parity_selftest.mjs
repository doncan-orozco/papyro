#!/usr/bin/env node
// Self-test of parity_run.mjs. No Rails, no React: two tiny HTTP servers play the "React" side (hash route,
// client rendered) and the "Phlex" side (path route, server rendered). Every scenario has a KNOWN expected
// outcome, so the runner is proven to (a) pass identical pages, (b) report each kind of difference, and
// (c) never let a broken render pass as a match.
//
//   cd <dir containing node_modules/playwright> && node /path/to/.claude/scripts/shadcn/parity_selftest.mjs
//   PARITY_CHROMIUM=/path/to/chromium   # when the cached browser revision differs from playwright's
//
// Exit 0 = every scenario behaved as expected. Prints a JSON summary. Skips (exit 0, status "skipped") when
// playwright is not installed in the current directory.

import http from "node:http";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const here = path.dirname(fileURLToPath(import.meta.url));
try {
  createRequire(path.join(process.cwd(), "package.json"))("playwright");
} catch {
  console.log(JSON.stringify({ status: "skipped", reason: "playwright is not installed in the current directory" }));
  process.exit(0);
}

const CSS = `
body{margin:0;padding:32px;font:16px/1.5 sans-serif}
[data-slot]{display:inline-block}
.btn{padding:8px 16px;background:#2563eb;color:#fff;border:1px solid transparent;border-radius:6px;cursor:pointer;transition:none}
.btn:focus-visible{outline:3px solid #f59e0b}
.wide{padding:8px 40px}
.on{background:#16a34a}
.themed{background:var(--c,#dddddd);padding:8px}
html.dark body{background:#111;color:#eee}
`;
const btn = (extra = "", cls = "btn") => `<button data-slot="probe" class="${cls}" ${extra}>Hi</button>`;
const toggler = `onclick="this.dataset.state=this.dataset.state==='on'?'off':'on';this.classList.toggle('on')"`;

// html: [reactHtml, phlexHtml, optional phlexStatus, optional phlexScript]
const S = [
  { id: "identical", html: [btn(), btn()], expect: { pass: true } },
  { id: "extra-class", html: [btn(), btn("", "btn wide")], expect: { kinds: ["CLASS", "STYLE", "BOX"] } },
  { id: "attr-differs", html: [btn('aria-pressed="false"'), btn('aria-pressed="true"')], expect: { kinds: ["ATTR"] } },
  { id: "text-differs", html: [btn(), btn().replace(">Hi<", ">Hello<")], expect: { kinds: ["TEXT"] } },
  { id: "framework-noise-ignored", html: [btn(), btn('id="x1" data-controller="v2--probe" data-action="click->v2--probe#go" data-v2--probe-target="t" data-turbo-permanent')], expect: { pass: true } },
  {
    id: "id-normalization",
    html: [
      `<span data-slot="l" id="radix-:r1:">Name</span><button data-slot="probe" class="btn" aria-labelledby="radix-:r1:">Hi</button>`,
      `<span data-slot="l" id="label-9">Name</span><button data-slot="probe" class="btn" aria-labelledby="label-9">Hi</button>`,
    ],
    expect: { pass: true },
  },
  {
    id: "unreferenced-ids-ignored",
    html: [
      `<i data-slot="n"></i><span data-slot="l" id="a">Name</span><button data-slot="probe" class="btn" aria-labelledby="a">Hi</button>`,
      `<i data-slot="n" id="noise-1"></i><span data-slot="l" id="b">Name</span><button data-slot="probe" class="btn" aria-labelledby="b" id="noise-2">Hi</button>`,
    ],
    expect: { pass: true },
  },
  {
    id: "id-relation-differs",
    html: [
      `<span data-slot="l" id="a">Name</span><button data-slot="probe" class="btn" aria-labelledby="a">Hi</button>`,
      `<span data-slot="l" id="a">Name</span><button data-slot="probe" class="btn" aria-labelledby="zzz">Hi</button>`,
    ],
    expect: { kinds: ["A11Y_REL"] },
  },
  { id: "click-same", steps: [{ do: "click", target: "[data-slot=probe]" }], html: [btn(toggler), btn(toggler)], expect: { pass: true } },
  { id: "click-missing-handler", steps: [{ do: "click", target: "[data-slot=probe]" }], html: [btn(toggler), btn()], expect: { kinds: ["ATTR", "CLASS", "STYLE"], step: "0:click" } },
  { id: "tab-same", steps: [{ do: "tab" }], html: [btn(), btn()], expect: { pass: true } },
  { id: "tab-not-focusable", steps: [{ do: "tab" }], html: [btn(), btn('tabindex="-1"')], expect: { kinds: ["FOCUS", "FOCUSED"], step: "0:tab" } },
  { id: "dark-same", dark: true, html: [btn(), btn()], expect: { pass: true } },
  { id: "hidden-differs", html: [btn(), btn('style="display:none"')], expect: { kinds: ["VISIBLE"] } },
  { id: "extra-node", html: [btn(), btn() + `<i data-slot="extra"></i>`], expect: { kinds: ["NODE_COUNT"] } },
  { id: "slot-order", html: [`<i data-slot="a"></i><i data-slot="b"></i>`, `<i data-slot="b"></i><i data-slot="a"></i>`], expect: { kinds: ["SLOT_ORDER"] } },
  { id: "theme-off", html: [`<div data-slot="probe" class="themed">x</div>`, `<div data-slot="probe" class="themed" style="background:#dddddd">x</div>`], expect: { pass: true } },
  { id: "theme-on", theme: "probe", html: [`<div data-slot="probe" class="themed">x</div>`, `<div data-slot="probe" class="themed" style="background:#dddddd">x</div>`], expect: { kinds: ["STYLE"] }, sameScenario: "theme-off" },
  { id: "phlex-js-error", html: [btn(), btn() + `<script>throw new Error("boom")</script>`], expect: { kinds: ["PHLEX_JS_ERROR"] } },
  // The holes this runner must not have: broken renders that would otherwise compare as equal.
  { id: "empty-both", html: ["", ""], expect: { kinds: ["EMPTY_RENDER"] } },
  { id: "parity-error-marker", html: [btn(), `<p data-parity-error>Unknown component Nope</p>`], expect: { kinds: ["PARITY_ERROR", "EMPTY_RENDER"] } },
  { id: "phlex-http-500", html: [btn(), `<h1>Internal Server Error</h1>`], status: 500, expect: { kinds: ["HTTP_STATUS", "EMPTY_RENDER"] } },
];

const reactPage = () => `<!doctype html><meta charset=utf-8><style>${CSS}</style><div id=root></div><script>
const T=${JSON.stringify(Object.fromEntries(S.map((s) => [s.id, s.html[0]])))};
const id=location.hash.split("/").pop();document.getElementById("root").innerHTML=T[id]??"";</script>`;

const phlexPage = (id) => {
  const sc = S.find((s) => s.id === id);
  return sc ? `<!doctype html><meta charset=utf-8><style>${CSS}</style><div id=root>${sc.html[1]}</div>` : "";
};

const servers = [
  http.createServer((_req, res) => { res.setHeader("content-type", "text/html"); res.end(reactPage()); }),
  http.createServer((req, res) => {
    const id = decodeURIComponent(req.url.split("/").pop().split("?")[0]);
    const sc = S.find((s) => s.id === id);
    res.statusCode = sc?.status ?? 200;
    res.setHeader("content-type", "text/html");
    res.end(phlexPage(id));
  }),
];
await Promise.all(servers.map((s) => new Promise((r) => s.listen(0, "127.0.0.1", r))));
const [reactUrl, phlexUrl] = servers.map((s) => `http://127.0.0.1:${s.address().port}`);

// Temp "repo root" with the scenario file and a theme preset, as parity_run.mjs expects.
const root = fs.mkdtempSync(path.join(os.tmpdir(), "parity-selftest-"));
fs.mkdirSync(path.join(root, "docs/shadcn-port/scenarios"), { recursive: true });
fs.mkdirSync(path.join(root, "app/assets/tailwind/theme/presets"), { recursive: true });
fs.writeFileSync(path.join(root, "app/assets/tailwind/theme/presets/probe.css"), ":root{--c:#ff0000}");
fs.writeFileSync(
  path.join(root, "docs/shadcn-port/scenarios/probe.json"),
  JSON.stringify({ component: "probe", scenarios: S.map(({ id, steps, dark, allowEmpty }) => ({ id, steps, dark, allowEmpty })) }),
);

const results = [];
for (const sc of S) {
  const args = [path.join(here, "parity_run.mjs"), "--component", "probe", "--react", reactUrl, "--phlex", phlexUrl, "--root", root, "--only", sc.id];
  if (sc.theme) args.push("--theme", sc.theme);
  // Async on purpose: the fixture servers live in THIS process, so a blocking spawn would deadlock the browser's requests.
  const run = await new Promise((resolve) => {
    const child = spawn("node", args, { cwd: process.cwd(), env: process.env });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (d) => (stdout += d));
    child.stderr.on("data", (d) => (stderr += d));
    const timer = setTimeout(() => child.kill("SIGKILL"), 60000);
    child.on("close", (status) => { clearTimeout(timer); resolve({ status, stdout, stderr }); });
  });
  let report;
  try { report = JSON.parse(run.stdout); } catch { report = { pass: false, diffs: [{ kind: "UNPARSEABLE", detail: (run.stderr || run.stdout).slice(0, 200) }] }; }
  const kinds = [...new Set(report.diffs.map((d) => d.kind))];
  let ok;
  let why = "";
  if (sc.expect.pass) {
    ok = report.pass === true && run.status === 0;
    why = ok ? "" : `expected pass, got ${kinds.join(",")}`;
  } else {
    const missing = sc.expect.kinds.filter((k) => !kinds.includes(k));
    ok = report.pass === false && run.status === 1 && missing.length === 0;
    if (ok && sc.expect.step) ok = report.diffs.some((d) => String(d.step).startsWith(sc.expect.step));
    why = ok ? "" : `expected ${sc.expect.kinds.join(",")}${sc.expect.step ? ` at ${sc.expect.step}` : ""}, got ${kinds.join(",") || "pass"}`;
  }
  results.push({ id: sc.id, ok, kinds, why });
}

servers.forEach((s) => s.close());
fs.rmSync(root, { recursive: true, force: true });
const failed = results.filter((r) => !r.ok);
console.log(JSON.stringify({ status: failed.length ? "fail" : "pass", scenarios: results.length, failed: failed.map((r) => ({ id: r.id, why: r.why, kinds: r.kinds })) }, null, 2));
process.exit(failed.length ? 1 : 0);
