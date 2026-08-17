import { test, expect } from '@playwright/test';

test('test', async ({ page }) => {
  await page.goto('https://old.reddit.com/user/nsheng');
  await page.getByRole('link', { name: 'NFC link' }).first().click();
  await page.pause(); 
});