import asyncio
from playwright.async_api import Playwright, async_playwright

import freebies
from neopets_accounts import users
from login import login, logout # code not provided in this gist

async def run(playwright: Playwright) -> None:
    browser = await playwright.chromium.launch(headless=True)
    context = await browser.new_context(viewport={"width":1920,"height":1080})
    page = await context.new_page()
    for a in users:
        print(a)
        await login(page, a)
        await freebies.get_omelette(page)
        await freebies.get_snowager(page)
        await freebies.get_fishing(page, a)
        await freebies.get_faerieland_springs(page)
        await logout(page)
        # ---------------------
        await context.close()
        await browser.close()

async def main() -> None:
    async with async_playwright() as playwright:
        await run(playwright)

asyncio.run(main())