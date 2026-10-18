// One browser parity scenario against the clean app: docs/shadcn-port/scenarios/dialog.json `open__via-trigger-click`
// (click the trigger, the dialog opens with the Radix DOM and takes focus), then Escape closes it and focus returns to the trigger.
// Usage: node test/smoke/app/dialog_scenario.mjs http://127.0.0.1:PORT/demo
// Playwright comes from PHLEX_SHADCN_PLAYWRIGHT (a directory with node_modules/playwright), else the monorepo dev kit
// (react-shadcn-catalog/node_modules of this checkout or of the main checkout), else a plain `playwright` require.
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { createRequire } from "node:module";

const GEM_ROOT = path.resolve(import.meta.dirname, "../../..");
const url = process.argv[2];
if (!url) { console.error("usage: dialog_scenario.mjs URL"); process.exit(2); }

function loadPlaywright() {
  const roots = [];
  if (process.env.PHLEX_SHADCN_PLAYWRIGHT) roots.push([process.env.PHLEX_SHADCN_PLAYWRIGHT, "package.json"]);
  for (const root of [process.env.PHLEX_SHADCN_DEV_ROOT, path.resolve(GEM_ROOT, "../..")]) {
    if (root) roots.push([path.join(root, "react-shadcn-catalog"), "package.json"]);
  }
  try {
    const common = execFileSync("git", ["-C", GEM_ROOT, "rev-parse", "--git-common-dir"], { encoding: "utf8" }).trim();
    roots.push([path.join(path.dirname(path.resolve(GEM_ROOT, common)), "react-shadcn-catalog"), "package.json"]);
  } catch { /* not a git checkout */ }
  for (const [dir, manifest] of roots) {
    if (fs.existsSync(path.join(dir, "node_modules/playwright"))) return createRequire(path.join(dir, manifest))("playwright");
  }
  return createRequire(import.meta.url)("playwright");
}

// Rails' `stylesheet_link_tag :app` links every file under app/assets/builds, including the stub tailwindcss-rails writes to
// app/assets/builds/tailwind/phlex-shadcn.css; its absolute `@import` of the gem's engine.css is unresolvable from a browser and
// 404s harmlessly (the real styles are compiled into tailwind.css). Upstream tailwindcss-rails behaviour, deferred by the engine item.
const knownUpstream = (text) => /app\/assets\/tailwind\/phlex-shadcn\/engine\.css|Failed to load resource/.test(text);

const { chromium } = loadPlaywright();
const browser = await chromium.launch();
const errors = [];
try {
  const page = await browser.newPage({ viewport: { width: 900, height: 700 } });
  page.on("pageerror", (error) => errors.push(`pageerror: ${error.message}`));
  page.on("console", (message) => { if (message.type() === "error" && !knownUpstream(message.text())) errors.push(`console: ${message.text()}`); });
  page.on("response", (response) => { if (response.status() >= 400 && !knownUpstream(response.url())) errors.push(`${response.status()} ${response.url()}`); });

  await page.goto(url, { waitUntil: "load" });
  const host = page.locator('[data-controller~="shadcn--dialog"]');
  await host.waitFor({ state: "attached" });
  // Rails loads controllers with dynamic imports after the page's load event; click only once shadcn--dialog is connected.
  await page.waitForFunction(() => {
    const element = document.querySelector('[data-controller~="shadcn--dialog"]');
    return window.Stimulus && element && window.Stimulus.getControllerForElementAndIdentifier(element, "shadcn--dialog");
  }, null, { timeout: 15000 });
  // The scenario targets the trigger by role, as the parity harness does; once the modal is open Radix hides everything else from
  // assistive technology (aria-hidden on the trigger's ancestors), so the later attribute reads use the data-slot selector.
  const trigger = page.getByRole("button", { name: "Edit profile" });
  const triggerElement = page.locator('[data-slot="dialog-trigger"]');
  await trigger.waitFor();
  if ((await trigger.getAttribute("aria-expanded")) !== "false") throw new Error("the trigger does not start with aria-expanded=false");
  if ((await trigger.getAttribute("aria-haspopup")) !== "dialog") throw new Error("the trigger has no aria-haspopup=dialog");

  // open__via-trigger-click
  await trigger.click();
  const dialog = page.locator('[role="dialog"][data-state="open"]');
  await dialog.waitFor({ state: "visible", timeout: 5000 });
  const title = await dialog.getByText("Edit profile", { exact: true }).count();
  if (title < 1) throw new Error("the open dialog does not show its title");
  if ((await triggerElement.getAttribute("aria-expanded")) !== "true") throw new Error("aria-expanded did not flip to true");
  const hiddenFromAT = await triggerElement.evaluate((node) => Boolean(node.closest('[aria-hidden="true"]')));
  if (!hiddenFromAT) throw new Error("the page behind the modal is not aria-hidden (Radix hideOthers)");
  const focusInside = await dialog.evaluate((node) => node.contains(document.activeElement));
  if (!focusInside) throw new Error("focus did not move into the dialog");

  // Escape closes and returns focus to the trigger
  await page.keyboard.press("Escape");
  await page.locator('[role="dialog"]').waitFor({ state: "detached", timeout: 5000 });
  if ((await triggerElement.getAttribute("aria-expanded")) !== "false") throw new Error("aria-expanded did not return to false");
  const focusBack = await triggerElement.evaluate((node) => node === document.activeElement);
  if (!focusBack) throw new Error("focus did not return to the trigger");

  if (errors.length) throw new Error(`browser errors: ${errors.join("; ")}`);
  console.log("dialog scenario ok: open__via-trigger-click, Escape closes, focus returns");
} catch (error) {
  console.error(`dialog scenario failed: ${error.message}`);
  if (errors.length) console.error(`browser errors:\n  ${errors.join("\n  ")}`);
  process.exitCode = 1;
} finally {
  await browser.close();
}
