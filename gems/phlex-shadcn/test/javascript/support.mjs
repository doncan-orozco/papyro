// Browser-driven tests for the shadcn Stimulus controllers: behavior that the parity runner cannot express (touch input,
// cancelable public events, positioner options). They load the real Phlex parity page (real importmap, real controllers)
// and use the Playwright of react-shadcn-catalog. Run with `bin/rails test:javascript` (starts the dev servers).
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { createRequire } from "node:module";
import assert from "node:assert/strict";

// Dev-kit coupling (ruby-gem-conventions R1/R10): the Playwright install and the running Phlex server come from the gem's dev kit
// (gems/phlex-shadcn/dev: react-shadcn-catalog/node_modules, tmp/shadcn-port/servers.json written by servers.rb). The dev root is
// PHLEX_SHADCN_DEV_ROOT (relative paths are resolved from the working directory), else the dev kit of this checkout, else the one of
// the main checkout when this is a git worktree (worktrees carry no node_modules). PHLEX_SHADCN_PLAYWRIGHT names a directory with
// node_modules/playwright (CI), PARITY_PHLEX_URL a running server, SHADCN_SERVERS_FILE another servers.json.
const GEM_ROOT = path.resolve(import.meta.dirname, "../..");

function devRoots() {
  const roots = [process.env.PHLEX_SHADCN_DEV_ROOT && path.resolve(process.env.PHLEX_SHADCN_DEV_ROOT), path.join(GEM_ROOT, "dev")];
  try {
    const git = (...args) => execFileSync("git", ["-C", GEM_ROOT, ...args], { encoding: "utf8" }).trim();
    const mainRoot = path.dirname(path.resolve(GEM_ROOT, git("rev-parse", "--git-common-dir")));
    roots.push(path.join(mainRoot, path.relative(git("rev-parse", "--show-toplevel"), GEM_ROOT), "dev"));
  } catch { /* not a git checkout */ }
  return roots.filter(Boolean);
}

function loadPlaywright() {
  const catalogs = [process.env.PHLEX_SHADCN_PLAYWRIGHT && path.resolve(process.env.PHLEX_SHADCN_PLAYWRIGHT),
    ...devRoots().map((root) => path.join(root, "react-shadcn-catalog"))].filter(Boolean);
  for (const dir of catalogs) {
    if (fs.existsSync(path.join(dir, "node_modules/playwright"))) return createRequire(path.join(dir, "package.json"))("playwright");
  }
  throw new Error(`playwright not found in ${catalogs.join(", ")}: install the catalog (npm ci in gems/phlex-shadcn/dev/react-shadcn-catalog), or set PHLEX_SHADCN_PLAYWRIGHT / PHLEX_SHADCN_DEV_ROOT`);
}

const { chromium } = loadPlaywright();

function serversFile() {
  const candidates = [process.env.SHADCN_SERVERS_FILE && path.resolve(process.env.SHADCN_SERVERS_FILE),
    ...devRoots().map((root) => path.join(root, "tmp/shadcn-port/servers.json"))].filter(Boolean);
  const found = candidates.find((file) => fs.existsSync(file));
  if (!found) throw new Error(`no servers.json in ${candidates.join(", ")}: start the dev servers (ruby .claude/scripts/shadcn/servers.rb start) or set PARITY_PHLEX_URL`);
  return found;
}

export const PHLEX = process.env.PARITY_PHLEX_URL || JSON.parse(fs.readFileSync(serversFile(), "utf8")).rails.url;

const NO_MOTION = "*,*::before,*::after{animation:none!important;transition:none!important}";

export async function launch() {
  return chromium.launch();
}

// A fresh page on a parity scenario of the Phlex port, controllers connected and settled.
export async function openScenario(browser, component, scenario, { touch = false } = {}) {
  const context = await browser.newContext({ viewport: { width: 1280, height: 720 }, hasTouch: touch });
  await context.addInitScript((css) => {
    document.addEventListener("DOMContentLoaded", () => {
      const style = document.createElement("style");
      style.textContent = css;
      document.head.append(style);
    });
  }, NO_MOTION);
  const page = await context.newPage();
  const errors = [];
  page.on("pageerror", (error) => errors.push(String(error)));
  // networkidle: the importmap modules (Stimulus, controllers) load after the load event, like parity_run.mjs.
  await page.goto(`${PHLEX}/design-system/parity/${component}/${scenario}`, { waitUntil: "networkidle" });
  await page.evaluate(() => document.fonts?.ready);
  await settle(page);
  page.jsErrors = errors;
  return page;
}

export async function settle(page) {
  await page.evaluate(() => new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(() => setTimeout(resolve, 0)))));
}

// Rewrites the options JSON of the content <template> and reconnects the controller so it reads them again.
export async function reconnectWithOptions(page, { template, controller, options = {}, values = {} }) {
  await page.evaluate(({ template, controller, options, values }) => {
    const tpl = document.querySelector(template);
    tpl.dataset.options = JSON.stringify({ ...JSON.parse(tpl.dataset.options || "{}"), ...options });
    const host = document.querySelector(`[data-controller~="${controller}"]`);
    for (const [name, value] of Object.entries(values)) host.setAttribute(`data-${controller}-${name}-value`, value);
    const original = host.getAttribute("data-controller");
    host.setAttribute("data-controller", original.split(/\s+/).filter((c) => c !== controller).join(" "));
    return new Promise((resolve) => requestAnimationFrame(() => {
      host.setAttribute("data-controller", original);
      resolve();
    }));
  }, { template, controller, options, values });
  await settle(page);
}

// Collects the public events (`shadcn--x:name`) a controller dispatches, optionally preventing some of them.
export async function recordEvents(page, prefix, { prevent = [] } = {}) {
  await page.evaluate(({ prefix, prevent }) => {
    window.__events = [];
    document.addEventListener("DOMContentLoaded", () => {}, { once: true });
    const names = ["open-change", "escape-key-down", "pointer-down-outside", "focus-outside", "interact-outside", "open-auto-focus", "close-auto-focus"];
    for (const name of names) {
      document.addEventListener(`${prefix}:${name}`, (event) => {
        window.__events.push({ name, open: event.detail?.open, cancelable: event.cancelable });
        if (prevent.includes(name)) event.preventDefault();
      });
    }
  }, { prefix, prevent });
}

export const events = (page) => page.evaluate(() => window.__events.map((e) => e.name));
export const eventLog = (page) => page.evaluate(() => window.__events);
export const contentCount = (page, selector) => page.locator(selector).count();

export { assert };
