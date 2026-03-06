// @ts-check
const { test, expect } = require("@playwright/test");

/**
 * Visual regression tests for the design-system catalog.
 *
 * These tests capture pixel-level screenshots of the Phlex component
 * catalog and compare them against stored reference snapshots.
 *
 * To update reference snapshots after intentional changes:
 *   npm run test:visual:update
 */

const DESIGN_SYSTEM_URL = "/design-system";

test.describe("Design System — visual regression", () => {
  test.beforeEach(async ({ page }) => {
    // Disable animations and transitions to get stable screenshots
    await page.addInitScript(() => {
      const style = document.createElement("style");
      style.textContent = `
        *, *::before, *::after {
          animation-duration: 0s !important;
          transition-duration: 0s !important;
        }
      `;
      document.head.appendChild(style);
    });
  });

  test("full catalog page — light mode", async ({ page }) => {
    await page.goto(DESIGN_SYSTEM_URL);
    await page.waitForLoadState("networkidle");

    // Ensure light mode is active
    await page.evaluate(() => {
      document.documentElement.classList.remove("dark");
      document.documentElement.classList.add("light");
    });

    await expect(page).toHaveScreenshot("catalog-light.png", {
      fullPage: true,
      maxDiffPixelRatio: 0.02,
    });
  });

  test("full catalog page — dark mode", async ({ page }) => {
    await page.goto(DESIGN_SYSTEM_URL);
    await page.waitForLoadState("networkidle");

    // Activate dark mode via the theme toggle
    await page.evaluate(() => {
      document.documentElement.classList.add("dark");
      document.documentElement.classList.remove("light");
    });

    await expect(page).toHaveScreenshot("catalog-dark.png", {
      fullPage: true,
      maxDiffPixelRatio: 0.02,
    });
  });

  test("buttons section", async ({ page }) => {
    await page.goto(DESIGN_SYSTEM_URL);
    await page.waitForLoadState("networkidle");

    // Force light theme for consistent screenshots
    await page.evaluate(() => {
      document.documentElement.classList.remove("dark");
      document.documentElement.classList.add("light");
      localStorage.setItem("papyro-theme", "light");
    });

    const section = page.locator("#buttons");
    await section.scrollIntoViewIfNeeded();

    await expect(section).toHaveScreenshot("buttons.png", {
      maxDiffPixelRatio: 0.02,
    });
  });

  test("forms section", async ({ page }) => {
    await page.goto(DESIGN_SYSTEM_URL);
    await page.waitForLoadState("networkidle");

    // Force light theme for consistent screenshots
    await page.evaluate(() => {
      document.documentElement.classList.remove("dark");
      document.documentElement.classList.add("light");
      localStorage.setItem("papyro-theme", "light");
    });

    const section = page.locator("#forms");
    await section.scrollIntoViewIfNeeded();

    await expect(section).toHaveScreenshot("forms.png", {
      maxDiffPixelRatio: 0.02,
    });
  });

  test("feedback section", async ({ page }) => {
    await page.goto(DESIGN_SYSTEM_URL);
    await page.waitForLoadState("networkidle");

    // Force light theme for consistent screenshots
    await page.evaluate(() => {
      document.documentElement.classList.remove("dark");
      document.documentElement.classList.add("light");
      localStorage.setItem("papyro-theme", "light");
    });

    const section = page.locator("#feedback");
    await section.scrollIntoViewIfNeeded();

    await expect(section).toHaveScreenshot("feedback.png", {
      maxDiffPixelRatio: 0.02,
    });
  });

  test("theme toggle — persists to localStorage", async ({ page }) => {
    await page.goto(DESIGN_SYSTEM_URL);
    await page.waitForLoadState("networkidle");

    // Click the toggle button
    const toggleBtn = page.locator("[data-controller='ui--theme']");
    await toggleBtn.click();

    // Check localStorage was updated
    const stored = await page.evaluate(() => localStorage.getItem("papyro-theme"));
    expect(["dark", "light"]).toContain(stored);

    // Check the html element has the expected class
    const htmlClass = await page.evaluate(() => document.documentElement.className);
    expect(htmlClass).toMatch(/dark|light/);
  });
});
