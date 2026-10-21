// Tiny node:test wrapper: one browser per file, one fresh page per scenario, `open` fixture helpers.
import test, { after } from "node:test";
import { launch, openScenario } from "./support.mjs";

let browserPromise;
const browser = () => (browserPromise ??= launchBrowser());

// SHADCN_TEST_TIMER_DELAY_MS=<ms> emulates a starved runner: every zero-delay setTimeout of the page under test fires that late
// (input is still delivered at once), which is how a press that lands before a controller's deferred listener is armed is reproduced.
async function launchBrowser() {
  const instance = await launch();
  const delay = Number(process.env.SHADCN_TEST_TIMER_DELAY_MS || 0);
  if (!delay) return instance;
  const newContext = instance.newContext.bind(instance);
  instance.newContext = async (...args) => {
    const context = await newContext(...args);
    await context.addInitScript((ms) => {
      const native = window.setTimeout.bind(window);
      window.setTimeout = (fn, wait, ...rest) => native(fn, wait ? wait : ms, ...rest);
    }, delay);
    return context;
  };
  return instance;
}
after(async () => { await (await browserPromise)?.close(); });

export function browserTest(name, fn, { touch = false } = {}) {
  return test(name, async () => {
    const pages = [];
    const open = async (scenario, component = browserTest.component) => {
      const page = await openScenario(await browser(), component, scenario, { touch });
      pages.push(page);
      return page;
    };
    try {
      await fn({ open });
      for (const page of pages) if (page.jsErrors.length) throw new Error(`page errors: ${page.jsErrors.join("; ")}`);
    } finally {
      await Promise.all(pages.map((page) => page.context().close().catch(() => {})));
    }
  });
}
