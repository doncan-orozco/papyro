import { browserTest } from "./harness.mjs";
import { assert, settle } from "./support.mjs";

// Sonner (Toaster). What the parity runner cannot express: the three entry points (flash rendered with the page, Turbo Stream append,
// the JS API and the show event), live regions, callbacks as events, hostile input, and cleanup on disconnect / Turbo cache.
browserTest.component = "sonner";
const section = "section[aria-live]";
const toasts = "[data-sonner-toast]";
const count = (page, selector = toasts) => page.locator(selector).count();
const titles = (page) => page.locator(`${toasts} [data-title]`).allTextContents();

// What Phlex::Shadcn::Sonner::Toast renders (test/phlex/shadcn/sonner_test.rb asserts the same markup).
const toastTemplate = (attrs, title, description) =>
  `<template data-shadcn--sonner-toast="" ${attrs}><div data-title="">${title}</div>${description ? `<div data-description="">${description}</div>` : ""}</template>`;

// Reconnects the Toaster controller the way a page load does: templates already inside the section are the flash.
const reconnectWith = (page, html) => page.evaluate((html) => new Promise((resolve) => {
  const host = document.querySelector("section[aria-live]");
  host.setAttribute("data-controller", "");
  host.insertAdjacentHTML("beforeend", html);
  requestAnimationFrame(() => { host.setAttribute("data-controller", "shadcn--sonner"); resolve(); });
}), html);

const streamAppend = (page, html) => page.evaluate((html) => window.Turbo.renderStreamMessage(`<turbo-stream action="append" target="toaster"><template>${html}</template></turbo-stream>`), html);

browserTest("sonner: the Toaster section is a polite live region and holds no toast until one is shown", async ({ open }) => {
  const page = await open("empty__no-toasts");
  const attrs = await page.locator(section).evaluate((el) => ({ live: el.getAttribute("aria-live"), relevant: el.getAttribute("aria-relevant"), atomic: el.getAttribute("aria-atomic"), label: el.getAttribute("aria-label"), tab: el.getAttribute("tabindex"), ols: el.querySelectorAll("ol").length }));
  assert.deepEqual(attrs, { live: "polite", relevant: "additions text", atomic: "false", label: "Notifications alt+T", tab: "-1", ols: 0 });
});

browserTest("sonner: flash toasts rendered with the page are shown on connect, typed, and their templates are consumed", async ({ open }) => {
  const page = await open("empty__no-toasts");
  await reconnectWith(page, toastTemplate('data-type="success"', "Saved") + toastTemplate('data-type="error"', "Nope") + toastTemplate("", "Plain"));
  await page.waitForSelector(toasts);
  await settle(page);
  assert.equal(await count(page), 3);
  assert.deepEqual((await titles(page)).sort(), ["Nope", "Plain", "Saved"]);
  assert.deepEqual(await page.locator(toasts).evaluateAll((els) => els.map((el) => el.getAttribute("data-type")).filter(Boolean).sort()), ["error", "success"]);
  assert.equal(await count(page, `${toasts}:not([data-type])`), 1, "a plain toast has no type");
  assert.equal(await count(page, `${section} > template[data-shadcn--sonner-toast]`), 0);
});

browserTest("sonner: a Turbo Stream append onto the Toaster id shows a toast", async ({ open }) => {
  const page = await open("empty__no-toasts");
  await streamAppend(page, toastTemplate('data-type="success" data-id="saved"', "Saved from a stream", "All changes stored"));
  await page.waitForSelector(toasts);
  assert.deepEqual(await titles(page), ["Saved from a stream"]);
  assert.equal(await page.locator(`${toasts} [data-description]`).textContent(), "All changes stored");
  assert.equal(await page.locator(toasts).getAttribute("data-type"), "success");
  // The same id again updates the toast instead of adding one.
  await streamAppend(page, toastTemplate('data-type="info" data-id="saved"', "Updated"));
  await page.waitForFunction(() => document.querySelector("[data-sonner-toast] [data-title]")?.textContent === "Updated");
  assert.equal(await count(page), 1);
});

browserTest("sonner: titles and descriptions are text, never markup", async ({ open }) => {
  const page = await open("empty__no-toasts");
  await streamAppend(page, toastTemplate("", "&lt;img src=x onerror=&quot;window.__pwned=1&quot;&gt;", "&lt;b&gt;bold&lt;/b&gt;"));
  await page.waitForSelector(toasts);
  assert.equal(await count(page, `${toasts} img, ${toasts} b`), 0);
  assert.equal(await page.evaluate(() => window.__pwned), undefined);
  assert.equal(await page.locator(`${toasts} [data-title]`).textContent(), '<img src=x onerror="window.__pwned=1">');
});

browserTest("sonner: window.Toaster shows, updates and dismisses toasts", async ({ open }) => {
  const page = await open("empty__no-toasts");
  const id = await page.evaluate(() => window.Toaster.success("Saved", { description: "Stored" }));
  await page.waitForSelector(toasts);
  assert.equal(await page.locator(toasts).getAttribute("data-type"), "success");
  assert.equal(await page.evaluate(() => window.Toaster.getToasts().length), 1);
  await page.evaluate((id) => window.Toaster.dismiss(id), id);
  await page.waitForSelector(toasts, { state: "detached" });
  assert.equal(await count(page, "ol"), 0, "the empty list is removed");
});

browserTest("sonner: the show event creates a toast from any element", async ({ open }) => {
  const page = await open("empty__no-toasts");
  await page.evaluate(() => document.body.dispatchEvent(new CustomEvent("shadcn--sonner:show", { bubbles: true, detail: { message: "From an event", type: "warning" } })));
  await page.waitForSelector(toasts);
  assert.deepEqual(await titles(page), ["From an event"]);
  assert.equal(await page.locator(toasts).getAttribute("data-type"), "warning");
});

browserTest("sonner: an error is also announced through an assertive alert region, other types are not", async ({ open }) => {
  const page = await open("empty__no-toasts");
  await page.evaluate(() => window.Toaster.success("Fine"));
  await page.waitForSelector(toasts);
  await settle(page);
  assert.equal(await count(page, "[data-shadcn-sonner-announcer]"), 0);
  await page.evaluate(() => window.Toaster.error("Could not save", { description: "Try again" }));
  await page.waitForFunction(() => document.querySelector("[data-shadcn-sonner-announcer]")?.textContent === "Could not save. Try again");
  assert.equal(await page.locator("[data-shadcn-sonner-announcer]").getAttribute("role"), "alert");
  assert.equal(await page.locator(section).getAttribute("aria-live"), "polite");
});

browserTest("sonner: action and cancel dispatch events; an unsafe href never navigates", async ({ open }) => {
  const page = await open("empty__no-toasts");
  await page.evaluate(() => { window.__log = []; document.addEventListener("shadcn--sonner:action", (e) => window.__log.push(["action", e.detail.name, e.detail.id])); document.addEventListener("shadcn--sonner:cancel", (e) => window.__log.push(["cancel", e.detail.name])); });
  await streamAppend(page, toastTemplate('data-id="a" data-duration="100000" data-action-label="Undo" data-action-event="undo" data-action-href="javascript:window.__pwned=1" data-cancel-label="Keep" data-cancel-event="keep"', "Deleted"));
  await page.waitForSelector("[data-action]");
  const before = page.url();
  await page.click("[data-action]");
  await page.waitForSelector(toasts, { state: "detached" });
  assert.equal(page.url(), before);
  assert.equal(await page.evaluate(() => window.__pwned), undefined);
  assert.deepEqual(await page.evaluate(() => window.__log), [["action", "undo", "a"]]);
});

browserTest("sonner: dismiss and auto-close are dispatched with the toast id", async ({ open }) => {
  const page = await open("empty__no-toasts");
  await page.evaluate(() => { window.__log = []; for (const name of ["dismiss", "auto-close"]) document.addEventListener(`shadcn--sonner:${name}`, (e) => window.__log.push([name, e.detail.id])); });
  await page.evaluate(() => { window.Toaster.message("Short", { id: "short", duration: 100 }); window.Toaster.message("Closed by hand", { id: "hand", duration: 100000, dismissible: true }); });
  await page.waitForFunction(() => window.__log.some(([name]) => name === "auto-close"));
  await page.evaluate(() => window.Toaster.dismiss("hand"));
  await page.waitForFunction(() => window.__log.some(([name]) => name === "dismiss"));
  const log = await page.evaluate(() => window.__log);
  assert.ok(log.some(([name, id]) => name === "auto-close" && id === "short"));
  assert.ok(log.some(([name, id]) => name === "dismiss" && id === "hand"));
});

browserTest("sonner: the hotkey expands and focuses the stack, Escape collapses it", async ({ open }) => {
  const page = await open("empty__no-toasts");
  await page.evaluate(() => { window.Toaster.success("One"); window.Toaster.info("Two"); });
  await page.waitForFunction(() => document.querySelectorAll("[data-sonner-toast]").length === 2);
  assert.equal(await page.locator(toasts).first().getAttribute("data-expanded"), "false");
  await page.keyboard.press("Alt+KeyT");
  await settle(page);
  assert.equal(await page.locator(toasts).first().getAttribute("data-expanded"), "true");
  assert.equal(await page.evaluate(() => document.activeElement.hasAttribute("data-sonner-toaster")), true);
  await page.keyboard.press("Escape");
  await settle(page);
  assert.equal(await page.locator(toasts).first().getAttribute("data-expanded"), "false");
});

browserTest("sonner: a Turbo cache snapshot leaves no toast behind and a reconnect does not duplicate them", async ({ open }) => {
  const page = await open("empty__no-toasts");
  await page.evaluate(() => window.Toaster.success("Before cache", { duration: 100000 }));
  await page.waitForSelector(toasts);
  await page.evaluate(() => document.dispatchEvent(new Event("turbo:before-cache")));
  assert.equal(await count(page, "ol"), 0);
  await reconnectWith(page, "");
  await settle(page);
  assert.equal(await count(page), 0);
});

browserTest("sonner: removing the Toaster clears its timers and listeners (no errors afterwards)", async ({ open }) => {
  const page = await open("empty__no-toasts");
  await page.evaluate(() => window.Toaster.message("Gone soon", { duration: 150 }));
  await page.waitForSelector(toasts);
  await page.evaluate(() => document.querySelector("section[aria-live]").remove());
  await page.waitForTimeout(600);
  await page.evaluate(() => window.Toaster.message("Nobody listens"));
  await page.waitForTimeout(100);
  assert.equal(await count(page), 0);
});

browserTest("sonner: a loading toast stays until updated, then closes on its own", async ({ open }) => {
  const page = await open("empty__no-toasts");
  await page.evaluate(() => window.Toaster.loading("Saving...", { id: "job", duration: 200 }));
  await page.waitForSelector(toasts);
  await page.waitForTimeout(500);
  assert.equal(await count(page), 1, "a loading toast has no timer");
  assert.equal(await page.locator(toasts).getAttribute("data-type"), "loading");
  await page.evaluate(() => window.Toaster.success("Saved", { id: "job", duration: 200 }));
  await page.waitForSelector(toasts, { state: "detached", timeout: 3000 });
});

browserTest("sonner: window.Toaster.promise follows the promise", async ({ open }) => {
  const page = await open("empty__no-toasts");
  await page.evaluate(() => window.Toaster.promise(new Promise((resolve) => setTimeout(resolve, 150)), { loading: "Working", success: "Done", error: "Failed" }));
  await page.waitForFunction(() => document.querySelector("[data-sonner-toast]")?.getAttribute("data-type") === "loading");
  await page.waitForFunction(() => document.querySelector("[data-sonner-toast]")?.getAttribute("data-type") === "success");
  assert.equal(await page.locator(`${toasts} [data-title]`).textContent(), "Done");
});
