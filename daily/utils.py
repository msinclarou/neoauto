from datetime import datetime
from playwright.async_api import Page
from pytz import timezone
from random import choice

from neopets_accounts import pets

def check_clock() -> datetime:
    obj = datetime.now()
    tz = timezone('America/Los_Angeles')
    return obj.astimezone(tz)

def get_all_pets(account: str) -> List[str]:
    return pets[account]

def get_random_pet(account: str) -> str:
    return choice(pets[account])