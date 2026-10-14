import { assert, primitiveTest, tick } from "./primitives_support.mjs";

const html = `
  <button id="outside" style="position:fixed;left:10px;top:10px;width:80px;height:30px">outside</button>
  <button id="other" style="position:fixed;left:10px;top:60px;width:80px;height:30px">other</button>
  <div id="layer" style="position:fixed;left:300px;top:200px;width:200px;height:100px"><button id="inside">in</button></div>
  <div id="child" style="position:fixed;left:300px;top:350px;width:200px;height:100px"><button id="childButton">c</button></div>`;

primitiveTest("dismissable_layer: Escape dismisses only the top layer; onEscape can prevent the dismissal", async (page) => {
  const result = await page.evaluate(async () => {
    const { dismissable } = await import("shadcn/primitives/dismissable_layer");
    const log = [];
    const keydown = () => document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true }));
    const lower = dismissable(document.getElementById("layer"), { onEscape: () => log.push("lower:escape"), onDismiss: () => log.push("lower:dismiss") });
    let prevent = false;
    const upper = dismissable(document.getElementById("child"), {
      onEscape: (event) => { log.push("upper:escape"); if (prevent) event.preventDefault() },
      onDismiss: () => log.push("upper:dismiss"),
    });
    keydown();
    prevent = true;
    keydown();
    upper();
    keydown();
    lower();
    keydown();
    return log;
  });
  assert.deepEqual(result, ["upper:escape", "upper:dismiss", "upper:escape", "lower:escape", "lower:dismiss"]);
}, { html });

primitiveTest("dismissable_layer: pointerdown outside dismisses; inside and branches do not; a caller can cancel", async (page) => {
  await page.evaluate(async () => {
    const { dismissable } = await import("shadcn/primitives/dismissable_layer");
    window.__log = [];
    window.__cancel = false;
    window.__release = dismissable(document.getElementById("layer"), {
      onPointerDownOutside: (event) => { window.__log.push(`pdo:${event.cancelable}`); if (window.__cancel) event.preventDefault() },
      onInteractOutside: () => window.__log.push("interact"),
      onDismiss: () => window.__log.push("dismiss"),
      branches: () => [document.getElementById("other")],
    });
  });
  await tick(page);
  await page.click("#inside");
  await page.click("#other");
  assert.deepEqual(await page.evaluate(() => window.__log), []);
  await page.click("#outside");
  // The click also moves focus to the outside button, which is a second (focus) interaction outside.
  assert.deepEqual(await page.evaluate(() => window.__log), ["pdo:true", "interact", "dismiss", "interact", "dismiss"]);
  await page.evaluate(() => { window.__log.length = 0; window.__cancel = true });
  await page.click("#outside");
  assert.deepEqual(await page.evaluate(() => window.__log), ["pdo:true", "interact"]);
}, { html });

primitiveTest("dismissable_layer: the pointerdown that opened the layer cannot close it (listener starts on the next tick)", async (page) => {
  const log = await page.evaluate(async () => {
    const { dismissable } = await import("shadcn/primitives/dismissable_layer");
    const log = [];
    const release = dismissable(document.getElementById("layer"), { onDismiss: () => log.push("dismiss") });
    document.getElementById("outside").dispatchEvent(new PointerEvent("pointerdown", { bubbles: true, pointerType: "mouse" }));
    release();
    return log;
  });
  assert.deepEqual(log, []);
}, { html });

primitiveTest("dismissable_layer: focus moving outside is reported; focus inside a layer opened later is not outside", async (page) => {
  await page.evaluate(async () => {
    const { dismissable } = await import("shadcn/primitives/dismissable_layer");
    window.__log = [];
    window.__lower = dismissable(document.getElementById("layer"), { onFocusOutside: () => window.__log.push("lower:focus-outside") });
    window.__upper = dismissable(document.getElementById("child"), { onFocusOutside: () => window.__log.push("upper:focus-outside") });
  });
  await tick(page);
  await page.focus("#childButton"); // inside the upper layer: child layer content counts as inside for the lower one
  assert.deepEqual(await page.evaluate(() => window.__log), []);
  await page.focus("#outside");
  assert.deepEqual(await page.evaluate(() => window.__log), ["lower:focus-outside", "upper:focus-outside"]);
}, { html });

primitiveTest("dismissable_layer: disableOutsidePointerEvents blocks the body, keeps the layers usable and restores on release", async (page) => {
  const result = await page.evaluate(async () => {
    const { dismissable } = await import("shadcn/primitives/dismissable_layer");
    document.body.style.pointerEvents = "auto";
    const read = () => ({ body: document.body.style.pointerEvents, layer: document.getElementById("layer").style.pointerEvents, child: document.getElementById("child").style.pointerEvents });
    const modal = dismissable(document.getElementById("layer"), { disableOutsidePointerEvents: true });
    const one = read();
    const nested = dismissable(document.getElementById("child"), { disableOutsidePointerEvents: true });
    const two = read();
    nested();
    const afterNested = read();
    modal();
    return { one, two, afterNested, after: read() };
  });
  assert.deepEqual(result.one, { body: "none", layer: "auto", child: "" });
  assert.deepEqual(result.two, { body: "none", layer: "none", child: "auto" });
  assert.deepEqual(result.afterNested, { body: "none", layer: "auto", child: "" });
  assert.deepEqual(result.after, { body: "auto", layer: "", child: "" });
}, { html });

primitiveTest("dismissable_layer: release() removes every listener and style, and is safe to repeat", async (page) => {
  await page.evaluate(async () => {
    const { dismissable } = await import("shadcn/primitives/dismissable_layer");
    window.__log = [];
    const log = (name) => () => window.__log.push(name);
    window.__release = dismissable(document.getElementById("layer"), {
      onEscape: log("escape"), onPointerDownOutside: log("pointer"), onFocusOutside: log("focus"), onDismiss: log("dismiss"), disableOutsidePointerEvents: true,
    });
  });
  await tick(page);
  await page.evaluate(() => { window.__release(); window.__release() });
  await page.keyboard.press("Escape");
  await page.focus("#outside");
  await page.click("#other");
  const state = await page.evaluate(() => ({ log: window.__log, body: document.body.style.pointerEvents, layer: document.getElementById("layer").style.pointerEvents }));
  assert.deepEqual(state, { log: [], body: "", layer: "" });
}, { html });
