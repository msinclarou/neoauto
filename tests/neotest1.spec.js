import { test, chromium } from '@playwright/test';

test('Run test on an already open browser tab', async () => {
 // Connect to the running instance
  const browser = await chromium.connectOverCDP('http://localhost:9222');
  
  // Get the existing default context and pages, or open a new page
  const defaultContext = browser.contexts()[0];
  const page = await defaultContext.newPage();
  
  // Navigate to your target URL
  await page.goto('https://example.com');
});