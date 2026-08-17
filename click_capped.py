from playwright.sync_api import (
    sync_playwright,
    TimeoutError as PlaywrightTimeoutError,
)

URL = "https://neofood.club/#round=9946&b=kahpbkbhkgobiafkecakkbmai"


def main() -> None:
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(
            headless=False,
            slow_mo=300,
        )

        page = browser.new_page(
            viewport={"width": 1400, "height": 900}
        )

        try:
            print("Opening NeoFood Club...")

            page.goto(
                URL,
                wait_until="domcontentloaded",
                timeout=30_000,
            )

            capped_button = page.get_by_role(
                "button",
                name="Capped",
                exact=True,
            )

            capped_button.wait_for(
                state="visible",
                timeout=15_000,
            )

            capped_button.scroll_into_view_if_needed()
            capped_button.click()

            print("Clicked the Capped button.")

        except PlaywrightTimeoutError:
            print("Could not find the Capped button.")
            print("Check whether the page loaded and the button still says Capped.")

        finally:
            input("Press Enter to close the browser...")
            browser.close()


if __name__ == "__main__":
    main()