// @ts-check
const { defineConfig, devices } = require("@playwright/test");

/**
 * Playwright configuration for visual regression testing.
 *
 * These tests compare the Phlex/Rails design-system catalog against
 * reference screenshots to catch unintended visual regressions.
 *
 * Run:
 *   npm run test:visual           — run all visual tests
 *   npm run test:visual:update    — update reference snapshots
 *
 * Requires the Rails server to be running on port 3030:
 *   bin/dev
 */
module.exports = defineConfig({
  testDir: "./test/playwright",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: [["html", { open: "never" }], ["list"]],

  use: {
    baseURL: process.env.BASE_URL || "http://localhost:3030",
    screenshot: "only-on-failure",
    trace: "on-first-retry",
  },

  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 1280, height: 900 },
      },
    },
  ],
});
