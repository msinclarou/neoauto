from playwright.async_api import Page
from random import randint

from utils import check_clock, get_all_pets, get_random_pet, switch_pet

async def get_omelette(page: Page):
    try:
        await page.goto("https://www.neopets.com/prehistoric/omelette.phtml", timeout=60*1000)
        await page.get_by_role("button", name="Grab some Omelette").click()
    except:
        print("Error: Could not obtain omelette.")

async def get_snowager(page: Page):
    dt = check_clock()
    if dt.month != 12 and dt.hour not in [6, 14, 22]:
        print("Snowager should be awake. Skip.")
        return
    try:
        await page.goto("https://www.neopets.com/winter/snowager.phtml")
        await page.get_by_role("button", name="Attempt to steal a piece of treasure").click()
    except:
        print("Error: Could not visit Snowager.")

async def _get_fishing_once(page: Page):
    try:
        await page.goto("https://www.neopets.com/water/fishing.phtml")
        await page.get_by_role("button", name="Reel In Your Line").click()
    except:
        print("Error: Could not go fishing.")

async def get_fishing(page: Page, account: str):
    pets = get_all_pets(account)
    try:
        for pet in pets:
            await switch_pet(page, pet) if len(pets) > 1 else False
            await _get_fishing_once(page)
        # reset to random pet
        await switch_pet(page, get_random_pet(account)) if len(pets) > 1 else False
    except:
        print(f"Error: Could not go fishing with all pets.")

async def get_healing_springs(page: Page):
    try:
        await page.goto("https://www.neopets.com/faerieland/springs.phtml")
        await page.get_by_role("button", name="Heal my Pets").click()
    except:
        print("Error: Could not visit Healing Springs.")