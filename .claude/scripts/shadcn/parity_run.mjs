#!/usr/bin/env node
// Gates G2-G5 (DOM / style / behavior / theme parity) for the shadcn -> Phlex port.
//
// Renders every scenario of a component on BOTH catalogs (React = oracle, Phlex = port),
// replays the same interaction steps, snapshots after each step and diffs the snapshots.
//
//   cd react-shadcn-catalog && node ../.claude/scripts/shadcn/parity_run.mjs --component button
//   ... --theme slate       inject app/assets/tailwind/theme/presets/slate.css into both pages (theme gate G4)
//   ... --dark              force .dark on <html> for every scenario
//   ... --shots DIR         also save side by side PNGs (artifact for humans, not a gate)
//   ... --only id1,id2      subset of scenario ids
//
// Contract (see .ai/skills/shadcn-port/references/parity-gates.md):
//   React  : {REACT}/#/parity/<component>/<scenarioId>
//   Phlex  : {PHLEX}/design-system/parity/<component>/<scenarioId>
//   Scenarios: docs/shadcn-port/scenarios/<component>.json  (single source of truth for both sides)
// Failed renders never match: HTTP >= 400, [data-parity-error] and zero [data-slot] nodes are reported (PARITY_ERROR / HTTP_STATUS / EMPTY_RENDER).
// Output: JSON on stdout { component, pass, scenarios, diffs[] }; exit 1 when diffs exist.

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const require = createRequire(path.join(process.cwd(), "package.json"));
const { chromium } = require("playwright");

const args = Object.fromEntries(process.argv.slice(2).reduce((acc, a, i, all) => {
  if (a.startsWith("--")) acc.push([a.slice(2), all[i + 1]?.startsWith("--") || all[i + 1] === undefined ? true : all[i + 1]]);
  return acc;
}, []));
const component = args.component;
if (!component) { console.error("usage: --component NAME"); process.exit(2); }

const REACT = args.react || "http://localhost:5173";
const PHLEX = args.phlex || "http://localhost:3000";
const ROOT = path.resolve(process.cwd(), args.root || "..");
const scenariosFile = path.join(ROOT, "docs/shadcn-port/scenarios", `${component}.json`);
const spec = JSON.parse(fs.readFileSync(scenariosFile, "utf8"));
const only = args.only ? String(args.only).split(",") : null;
const themeCss = args.theme ? fs.readFileSync(path.join(ROOT, "app/assets/tailwind/theme/presets", `${args.theme}.css`), "utf8") : null;

const NO_MOTION = "*,*::before,*::after{animation:none!important;transition:none!important;caret-color:transparent!important}";
const STYLE_PROPS = [
  "display", "position", "color", "backgroundColor", "borderTopColor", "borderRightColor", "borderBottomColor", "borderLeftColor",
  "borderTopWidth", "borderRightWidth", "borderBottomWidth", "borderLeftWidth", "borderTopLeftRadius", "borderTopRightRadius",
  "borderBottomLeftRadius", "borderBottomRightRadius", "paddingTop", "paddingRight", "paddingBottom", "paddingLeft",
  "marginTop", "marginRight", "marginBottom", "marginLeft", "fontFamily", "fontSize", "fontWeight", "lineHeight", "letterSpacing",
  "textAlign", "boxShadow", "opacity", "transform", "cursor", "pointerEvents", "overflow", "gap", "outlineColor", "outlineWidth",
  "outlineStyle", "zIndex", "flexDirection", "alignItems", "justifyContent", "whiteSpace", "textDecorationLine",
];
// Attributes that legitimately differ between React/Radix and Rails/Stimulus and carry no contract.
const IGNORED_ATTR = /^(class|style|id|for|selected|data-controller|data-action|data-turbo.*|data-.*-target|data-.*-value|data-.*-class|data-parity.*|aria-labelledby|aria-controls|aria-describedby|aria-owns|aria-activedescendant|tabindex-managed)$|^data-v2--|^data-radix|^data-reactroot/;

async function snapshot(page) {
  return page.evaluate(({ STYLE_PROPS, IGNORED_ATTR }) => {
    const ignored = new RegExp(IGNORED_ATTR);
    const ids = new Map();
    const norm = (v) => (v == null ? v : v.split(/\s+/).map((t) => (ids.has(t) ? ids.get(t) : t)).join(" "));
    // Ids only matter through the relations that reference them, so number REFERENCED ids by first reference (DOM order).
    // An unreferenced id (or a different id string) must not register as a difference.
    const REF_ATTRS = ["aria-labelledby", "aria-controls", "aria-describedby", "aria-owns", "aria-activedescendant", "for"];
    document.querySelectorAll("*").forEach((el) => REF_ATTRS.forEach((a) => (el.getAttribute(a) ?? "").split(/\s+/).filter(Boolean).forEach((t) => { if (!ids.has(t)) ids.set(t, `#${ids.size + 1}`); })));
    const active = document.activeElement;
    const slotPath = (el) => (el && el !== document.body ? (el.closest("[data-slot]")?.getAttribute("data-slot") ?? el.tagName.toLowerCase()) : "body");
    const rel = (el, name) => { const v = el.getAttribute(name); return v ? norm(v) : null; };
    return {
      focus: slotPath(active),
      scrollLocked: getComputedStyle(document.body).overflow === "hidden" || document.body.hasAttribute("data-scroll-locked"),
      nodes: [...document.querySelectorAll("[data-slot]")].map((el) => {
        const cs = getComputedStyle(el);
        const r = el.getBoundingClientRect();
        const attrs = {};
        for (const a of el.attributes) if (!ignored.test(a.name)) attrs[a.name] = a.value;
        return {
          slot: el.getAttribute("data-slot"),
          tag: el.tagName.toLowerCase(),
          classes: [...new Set(el.className?.baseVal === undefined ? el.className.split(/\s+/) : el.className.baseVal.split(/\s+/))].filter(Boolean).sort(),
          attrs,
          rel: { labelledby: rel(el, "aria-labelledby"), controls: rel(el, "aria-controls"), describedby: rel(el, "aria-describedby"), owns: rel(el, "aria-owns"), activedescendant: rel(el, "aria-activedescendant"), for: rel(el, "for"), id: el.id ? (ids.get(el.id) ?? null) : null },
          text: [...el.childNodes].filter((n) => n.nodeType === 3).map((n) => n.textContent.trim()).filter(Boolean).join(" "),
          visible: el.checkVisibility?.({ checkOpacity: false, checkVisibilityCSS: true }) ?? true,
          focused: el === active,
          // React sets these as DOM properties, never as attributes; a server render can only write the attribute. Compare the property.
          props: el.tagName === "OPTION" ? { selected: el.selected } : el.tagName === "SELECT" ? { value: el.value } : {},
          box: [r.x, r.y, r.width, r.height].map((n) => Math.round(n * 2) / 2),
          style: Object.fromEntries(STYLE_PROPS.map((p) => [p, cs[p]])),
        };
      }),
    };
  }, { STYLE_PROPS, IGNORED_ATTR: IGNORED_ATTR.source });
}

async function frames(page) { await page.evaluate(() => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)))); }

async function runStep(page, step) {
  const target = step.target ? page.locator(step.target).first() : null;
  switch (step.do) {
    case "click": await target.click({ ...(step.position ? { position: step.position } : {}), ...(step.button ? { button: step.button } : {}) }); break; // button: "left"|"right"|"middle" (context-menu opens on a right click); position: {x, y} relative to the element's top-left
    case "wait": await page.waitForTimeout(step.ms); break; // real timers: Radix delays (100ms sub-open, 300ms grace, 1000ms typeahead reset)
    case "mousedown": if (target) await target.hover(step.position ? { position: step.position } : {}); await page.mouse.down(step.button ? { button: step.button } : {}); break;
    case "mouseup": if (target) await target.hover(step.position ? { position: step.position } : {}); await page.mouse.up(step.button ? { button: step.button } : {}); break; // press-drag-release selection
    case "dblclick": await target.dblclick(); break;
    case "hover": await target.hover(); break;
    case "focus": await target.focus(); break;
    case "fill": await target.fill(step.value ?? ""); break;
    case "press": await page.keyboard.press(step.key); break;
    case "type": await page.keyboard.type(step.text, { delay: 5 }); break;
    case "tab": await page.keyboard.press(step.shift ? "Shift+Tab" : "Tab"); break;
    case "viewport": await page.setViewportSize({ width: step.width, height: step.height ?? 800 }); break;
    case "snapshot": break;
    default: throw new Error(`unknown step ${step.do}`);
  }
  await frames(page);
}

async function capture(browser, base, urlPath, sc, side) {
  const ctx = await browser.newContext({ viewport: { width: sc.viewport?.width ?? 900, height: sc.viewport?.height ?? 700 }, deviceScaleFactor: 1, reducedMotion: "reduce" });
  const page = await ctx.newPage();
  const errors = [];
  page.on("pageerror", (e) => errors.push(String(e)));
  const response = await page.goto(`${base}${urlPath}`, { waitUntil: "networkidle" });
  const httpStatus = response ? response.status() : 0;
  await page.addStyleTag({ content: sc.animations ? "" : NO_MOTION });
  if (themeCss) await page.addStyleTag({ content: themeCss });
  if (args.dark || sc.dark) await page.evaluate(() => document.documentElement.classList.add("dark"));
  await page.evaluate(() => document.fonts?.ready);
  await frames(page);
  const parityError = await page.evaluate(() => document.querySelector("[data-parity-error]")?.textContent?.trim() ?? null);
  const snaps = [{ step: "initial", ...(await snapshot(page)) }];
  for (const [i, step] of (sc.steps ?? []).entries()) {
    await runStep(page, step);
    snaps.push({ step: `${i}:${step.do}${step.target ? `(${step.target})` : step.key ? `(${step.key})` : ""}`, ...(await snapshot(page)) });
  }
  if (args.shots) {
    fs.mkdirSync(args.shots, { recursive: true });
    await page.screenshot({ path: path.join(args.shots, `${component}__${sc.id}__${side}.png`), fullPage: true });
  }
  await ctx.close();
  return { snaps, errors, httpStatus, parityError };
}

const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

function diffSnapshots(id, reactSnap, phlexSnap) {
  const out = [];
  const add = (kind, extra) => out.push({ scenario: id, step: reactSnap.step, kind, ...extra });
  if (reactSnap.focus !== phlexSnap.focus) add("FOCUS", { react: reactSnap.focus, phlex: phlexSnap.focus });
  if (reactSnap.scrollLocked !== phlexSnap.scrollLocked) add("SCROLL_LOCK", { react: reactSnap.scrollLocked, phlex: phlexSnap.scrollLocked });
  if (reactSnap.nodes.length !== phlexSnap.nodes.length) {
    add("NODE_COUNT", { react: reactSnap.nodes.map((n) => n.slot), phlex: phlexSnap.nodes.map((n) => n.slot) });
    return out;
  }
  reactSnap.nodes.forEach((rn, i) => {
    const pn = phlexSnap.nodes[i];
    const at = `${rn.slot}[${i}]`;
    if (rn.slot !== pn.slot) return add("SLOT_ORDER", { at, react: rn.slot, phlex: pn.slot });
    if (rn.tag !== pn.tag) add("TAG", { at, react: rn.tag, phlex: pn.tag });
    if (!same(rn.classes, pn.classes)) add("CLASS", { at, onlyReact: rn.classes.filter((c) => !pn.classes.includes(c)), onlyPhlex: pn.classes.filter((c) => !rn.classes.includes(c)) });
    if (!same(rn.attrs, pn.attrs)) add("ATTR", { at, react: rn.attrs, phlex: pn.attrs });
    if (!same(rn.props, pn.props)) add("PROP", { at, react: rn.props, phlex: pn.props });
    if (!same(rn.rel, pn.rel)) add("A11Y_REL", { at, react: rn.rel, phlex: pn.rel });
    if (rn.text !== pn.text) add("TEXT", { at, react: rn.text, phlex: pn.text });
    if (rn.visible !== pn.visible) add("VISIBLE", { at, react: rn.visible, phlex: pn.visible });
    if (rn.focused !== pn.focused) add("FOCUSED", { at, react: rn.focused, phlex: pn.focused });
    if (!same(rn.box, pn.box)) add("BOX", { at, react: rn.box, phlex: pn.box });
    const styleDiff = Object.keys(rn.style).filter((k) => rn.style[k] !== pn.style[k]).map((k) => ({ prop: k, react: rn.style[k], phlex: pn.style[k] }));
    if (styleDiff.length) add("STYLE", { at, props: styleDiff });
  });
  return out;
}

const browser = await chromium.launch(process.env.PARITY_CHROMIUM ? { executablePath: process.env.PARITY_CHROMIUM } : {});
const WORKERS = Math.max(1, Number(args.workers ?? 4)); // scenarios in flight at once (use --workers 1 for timing-sensitive reruns)
const todo = spec.scenarios.filter((s) => !only || only.includes(s.id));
const ran = todo.map((s) => s.id);

async function runScenario(sc) {
  const diffs = [];
  try {
    const [r, p] = await Promise.all([
      capture(browser, REACT, `/#/parity/${component}/${sc.id}`, sc, "react"),
      capture(browser, PHLEX, `/design-system/parity/${component}/${sc.id}`, sc, "phlex"),
    ]);
    // A page that failed to render must never "match": both sides empty/erroring would otherwise compare equal.
    for (const [side, cap] of [["react", r], ["phlex", p]]) {
      if (cap.httpStatus >= 400) diffs.push({ scenario: sc.id, kind: "HTTP_STATUS", side, detail: String(cap.httpStatus) });
      if (cap.parityError) diffs.push({ scenario: sc.id, kind: "PARITY_ERROR", side, detail: cap.parityError.slice(0, 200) });
      if (!sc.allowEmpty && cap.snaps[0].nodes.length === 0) diffs.push({ scenario: sc.id, kind: "EMPTY_RENDER", side, detail: "no [data-slot] elements rendered" });
    }
    r.errors.forEach((e) => diffs.push({ scenario: sc.id, kind: "REACT_PAGE_ERROR", detail: e }));
    p.errors.forEach((e) => diffs.push({ scenario: sc.id, kind: "PHLEX_JS_ERROR", detail: e }));
    r.snaps.forEach((rs, i) => diffs.push(...diffSnapshots(sc.id, rs, p.snaps[i])));
  } catch (e) {
    diffs.push({ scenario: sc.id, kind: "HARNESS_ERROR", detail: String(e).split("\n")[0] });
  }
  return diffs;
}

// Fixed-size pool; results are kept in scenario order so the report is identical for any --workers value.
const results = new Array(todo.length);
let cursor = 0;
await Promise.all(Array.from({ length: Math.min(WORKERS, todo.length) }, async () => {
  for (let i = cursor++; i < todo.length; i = cursor++) results[i] = await runScenario(todo[i]);
}));
const diffs = results.flat();
await browser.close();

const capped = diffs.slice(0, Number(args.max ?? 200));
console.log(JSON.stringify({ component, theme: args.theme ?? "default", dark: Boolean(args.dark), pass: diffs.length === 0, scenarios: ran, total_diffs: diffs.length, diffs: capped }, null, 2));
process.exit(diffs.length ? 1 : 0);
