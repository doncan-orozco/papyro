import { browserTest } from "./harness.mjs";
import { assert, settle } from "./support.mjs";

// Turbo page cache: the snapshot is taken after turbo:before-cache, so the overlays must be gone by then (radix-stimulus
// R10). The restore is simulated by re-inserting the controller host as it is in that snapshot, which connects a new one.
const CASES = [
  { component: "dialog", controller: "shadcn--dialog", scenario: "closed__rest", content: "[data-slot=dialog-content]", overlay: "[data-slot=dialog-overlay]" },
  { component: "sheet", controller: "shadcn--sheet", scenario: "closed__rest", content: "[data-slot=sheet-content]", overlay: "[data-slot=sheet-overlay]" },
  { component: "alert-dialog", controller: "shadcn--alert-dialog", scenario: "closed__rest", content: "[data-slot=alert-dialog-content]", overlay: "[data-slot=alert-dialog-overlay]" }
];

const trigger = (c) => `[data-controller~="${c.controller}"] [data-shadcn--dialog-part=trigger], [data-controller~="${c.controller}"] [data-slot$=-trigger]`;

// What Turbo's snapshot would contain one timer tick after the event (the controller restores a staying page after that).
const snapshotAfterBeforeCache = (page, controller, content, overlay) => page.evaluate(async ({ controller, content, overlay }) => {
  document.dispatchEvent(new Event("turbo:before-cache"))
  await new Promise((resolve) => setTimeout(resolve))
  const host = document.querySelector(`[data-controller~="${controller}"]`)
  return {
    contents: document.querySelectorAll(content).length,
    overlays: document.querySelectorAll(overlay).length,
    overflow: document.body.style.overflow,
    pointerEvents: document.body.style.pointerEvents,
    hidden: document.querySelectorAll("[aria-hidden=true]").length,
    open: host.getAttribute(`data-${controller}-open-value`),
    expanded: [...host.querySelectorAll("[aria-expanded]")].map((el) => el.getAttribute("aria-expanded")),
    html: host.outerHTML
  }
}, { controller, content, overlay })

for (const c of CASES) {
  browserTest(`${c.component}: the Turbo snapshot has no overlay, scroll lock or aria-hidden and the dialog is closed`, async ({ open }) => {
    const page = await open(c.scenario, c.component)
    await page.locator(trigger(c)).first().click()
    await page.waitForSelector(c.content)
    await settle(page)
    assert.ok(await page.evaluate(() => document.body.style.overflow === "hidden" || document.body.hasAttribute("data-scroll-locked") || document.body.style.pointerEvents === "none"), "precondition: the modal locked the page")

    const snapshot = await snapshotAfterBeforeCache(page, c.controller, c.content, c.overlay)

    assert.equal(snapshot.contents, 0)
    assert.equal(snapshot.overlays, 0)
    assert.notEqual(snapshot.overflow, "hidden")
    assert.notEqual(snapshot.pointerEvents, "none")
    assert.equal(snapshot.hidden, 0)
    assert.notEqual(snapshot.open, "true")
    assert.ok(snapshot.expanded.every((value) => value === "false"))
  })

  browserTest(`${c.component}: the restored snapshot has at most one overlay and can be opened again`, async ({ open }) => {
    const page = await open(c.scenario, c.component)
    await page.locator(trigger(c)).first().click()
    await page.waitForSelector(c.content)
    const { html } = await snapshotAfterBeforeCache(page, c.controller, c.content, c.overlay)
    // Restore: the snapshot's host replaces the live one (which disconnects), so a new controller connects to it.
    await page.evaluate(({ controller, html }) => {
      const host = document.querySelector(`[data-controller~="${controller}"]`)
      host.insertAdjacentHTML("afterend", html)
      host.remove()
    }, { controller: c.controller, html })
    await settle(page)
    assert.equal(await page.locator(c.content).count(), 0)
    assert.ok((await page.locator(c.overlay).count()) <= 1)
    await page.locator(trigger(c)).first().click()
    await page.waitForSelector(c.content)
    assert.equal(await page.locator(c.content).count(), 1)
    assert.equal(await page.locator(c.overlay).count(), 1)
  })

  browserTest(`${c.component}: a visit that keeps the page (link to #hash) leaves the dialog open`, async ({ open }) => {
    const page = await open(c.scenario, c.component)
    await page.locator(trigger(c)).first().click()
    await page.waitForSelector(c.content)
    await snapshotAfterBeforeCache(page, c.controller, c.content, c.overlay)
    await page.waitForSelector(c.content)
    await settle(page)
    assert.equal(await page.locator(c.content).count(), 1)
    assert.equal(await page.locator(c.overlay).count(), 1)
    assert.equal(await page.locator(trigger(c)).first().getAttribute("aria-expanded"), "true")
  })
}

// The destructive Action comes before Cancel in the DOM, so only the redirect to Cancel (not the first tabbable) passes.
browserTest("alert-dialog: open on first paint focuses the Cancel button, not the first tabbable", async ({ open }) => {
  const page = await open("closed__rest", "alert-dialog");
  await page.evaluate(() => {
    const host = document.querySelector('[data-controller~="shadcn--alert-dialog"]');
    const restored = host.cloneNode(true);
    const content = restored.querySelector("template[data-shadcn--dialog-template]").content;
    const cancel = content.querySelector("[data-shadcn--alert-dialog-part=cancel]");
    const action = content.querySelector("[data-slot=alert-dialog-action]");
    cancel.before(action);
    restored.setAttribute("data-shadcn--alert-dialog-open-value", "true");
    host.replaceWith(restored);
  });
  await page.waitForSelector("[data-slot=alert-dialog-content]");
  await settle(page);
  const active = await page.evaluate(() => document.activeElement?.getAttribute("data-shadcn--alert-dialog-part"));
  assert.equal(active, "cancel");
});
