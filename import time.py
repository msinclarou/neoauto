import time
import pyautogui

# Enter the URL and navigate to it.
#pyautogui.write('Start-Process "https://www.neopets.com/trudys_surprise.phtml"', interval=0.01)
#pyautogui.press("enter")
pyautogui.moveTo(944, 973, duration=1)  # Move the mouse to a safe location.

pyautogui.moveTo(947, 972, duration=1)  # Move the mouse slightly to trigger the hover effect.
pyautogui.click()