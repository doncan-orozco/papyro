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
const REACT_CATALOG_URL = "/react-catalog/";
const REACT_PAGE = "/design-system-react";
const COMPARE_PAGE = "/design-system-compare";

// sections we expect in both catalogs
const SECTIONS = [
  "buttons",
  "forms",
  "feedback",
  "data-display",
  "layout",
  "interactive",
  "media",
  "navigation",
  "advanced-forms",
  "overlays",
  "toggles",
  "data-display-advanced",
  "notifications",
];

async function ensureLightMode(page) {
  await page.evaluate(() => {
    document.documentElement.classList.remove("dark");
    document.documentElement.classList.add("light");
    localStorage.setItem("papyro-theme", "light");
  });
}

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

  // ---------------------------------------------------------------------------
  // React catalog and automated audit tests
  // ---------------------------------------------------------------------------

  test("react catalog page — light mode", async ({ page }) => {
    await page.goto(REACT_PAGE);
    await page.waitForLoadState("networkidle");

    await ensureLightMode(page);
    await expect(page).toHaveScreenshot("react-catalog-light.png", {
      fullPage: true,
      maxDiffPixelRatio: 0.02,
    });
  });

  test("react catalog page — dark mode", async ({ page }) => {
    await page.goto(REACT_PAGE);
    await page.waitForLoadState("networkidle");

    // force dark theme
    await page.evaluate(() => {
      document.documentElement.classList.add("dark");
      document.documentElement.classList.remove("light");
    });

    await expect(page).toHaveScreenshot("react-catalog-dark.png", {
      fullPage: true,
      maxDiffPixelRatio: 0.02,
    });
  });

  // iterate through each section to confirm presence in the Phlex catalog
  for (const section of SECTIONS) {
    test(`section exists in phlex catalog: ${section}`, async ({ page }) => {
      await page.goto(`${DESIGN_SYSTEM_URL}#${section}`);
      await page.waitForLoadState("networkidle");

      const locator = page.locator(`#${section}`);
      await expect(locator).toHaveCount(1);

      // take a small screenshot for manual comparison if needed
      await locator.scrollIntoViewIfNeeded();
      await expect(locator).toHaveScreenshot(`section-${section}-phlex.png`, {
        maxDiffPixelRatio: 0.02,
      });
    });
  }

  // react category navigation tests
  const CATEGORIES = [
    { id: 'foundation', label: 'Foundation' },
    { id: 'forms', label: 'Forms' },
    { id: 'feedback', label: 'Feedback' },
    { id: 'overlays', label: 'Overlays' },
    { id: 'complex', label: 'Complex' },
  ];

  for (const cat of CATEGORIES) {
    test(`react category ${cat.id} renders`, async ({ page }) => {
      await page.goto(REACT_PAGE);
      await page.waitForLoadState('networkidle');

      // clear theme for consistency
      await ensureLightMode(page);

      // click the category button
      const btn = page.locator('button', { hasText: cat.label });
      await expect(btn).toBeVisible();
      await btn.click();

      // ensure there is at least one card title displayed
      const title = page.locator('h3').first();
      await expect(title).toBeVisible();

      // screenshot the viewport for manual comparison
      await page.screenshot({
        path: `react-category-${cat.id}.png`,
        fullPage: false,
      });
    });
  }

  test("compare page contains both catalog iframes", async ({ page }) => {
    await page.goto(COMPARE_PAGE);
    await page.waitForLoadState("networkidle");

    await expect(page.locator("iframe[src='/react-catalog/']")).toHaveCount(1);
    await expect(page.locator("iframe[src='/design-system']")).toHaveCount(1);
  });

});
