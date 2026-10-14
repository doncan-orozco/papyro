import { assert, primitiveTest } from "./primitives_support.mjs";

const css = `
  @keyframes fade-in { from { opacity: 0 } to { opacity: 1 } }
  @keyframes fade-out { from { opacity: 1 } to { opacity: 0 } }
  .animated[data-state=open] { animation: fade-in 30ms }
  .animated[data-state=closed] { animation: fade-out 30ms }
`;
const options = { motion: true, css };

primitiveTest("presence: without an exit animation the element exits in the same call", async (page) => {
  await page.evaluate(() => { document.body.innerHTML = '<div id="el" data-state="open"></div>' });
  const calls = await page.evaluate(async () => {
    const { presence } = await import("shadcn/primitives/presence");
    const el = document.getElementById("el");
    const calls = [];
    const p = presence(el, { onExited: () => calls.push("exited") });
    el.dataset.state = "closed";
    p.exit();
    calls.push("after-exit");
    return calls;
  });
  assert.deepEqual(calls, ["exited", "after-exit"]);
}, options);

primitiveTest("presence: waits for animationend of the exit animation before onExited", async (page) => {
  await page.evaluate(() => { document.body.innerHTML = '<div id="el" class="animated" data-state="open"></div>' });
  const result = await page.evaluate(async () => {
    const { presence } = await import("shadcn/primitives/presence");
    const el = document.getElementById("el");
    let exited = false;
    const done = new Promise((resolve) => {
      const p = presence(el, { onExited: () => { exited = true; resolve() } });
      el.dataset.state = "closed";
      p.exit();
    });
    const syncExited = exited;
    await done;
    return { syncExited, exited };
  });
  assert.deepEqual(result, { syncExited: false, exited: true });
}, options);

primitiveTest("presence: enter() cancels a pending exit", async (page) => {
  await page.evaluate(() => { document.body.innerHTML = '<div id="el" class="animated" data-state="open"></div>' });
  const exited = await page.evaluate(async () => {
    const { presence } = await import("shadcn/primitives/presence");
    const el = document.getElementById("el");
    let exited = 0;
    const p = presence(el, { onExited: () => exited++ });
    el.dataset.state = "closed";
    p.exit();
    el.dataset.state = "open";
    p.enter();
    await new Promise((resolve) => el.addEventListener("animationend", resolve, { once: true }));
    return exited;
  });
  assert.equal(exited, 0);
}, options);

primitiveTest("presence: release() removes the animation listeners; calling it twice is safe", async (page) => {
  await page.evaluate(() => { document.body.innerHTML = '<div id="el" class="animated" data-state="open"></div>' });
  const exited = await page.evaluate(async () => {
    const { presence } = await import("shadcn/primitives/presence");
    const el = document.getElementById("el");
    let exited = 0;
    const p = presence(el, { onExited: () => exited++ });
    el.dataset.state = "closed";
    p.exit();
    p.release();
    p.release();
    await new Promise((resolve) => el.addEventListener("animationend", resolve, { once: true }));
    return exited;
  });
  assert.equal(exited, 0);
}, options);

primitiveTest("presence: display none exits immediately even with an exit animation", async (page) => {
  await page.evaluate(() => { document.body.innerHTML = '<div id="el" class="animated" data-state="open"></div>' });
  const exited = await page.evaluate(async () => {
    const { presence } = await import("shadcn/primitives/presence");
    const el = document.getElementById("el");
    let exited = 0;
    const p = presence(el, { onExited: () => exited++ });
    el.style.display = "none";
    el.dataset.state = "closed";
    p.exit();
    return exited;
  });
  assert.equal(exited, 1);
}, options);
