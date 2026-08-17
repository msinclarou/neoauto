from playwright.sync_api import sync_playwright

URL = "https://neofood.club/#round=9946&b=kahpbkbhkgobiafkecakkbmai"


def main() -> None:
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=False)

        page = browser.new_page(
            viewport={
                "width": 1400,
                "height": 900,
            }
        )

        print("Opening NeoFood Club...")
        page.goto(
            URL,
            wait_until="domcontentloaded",
            timeout=30_000,
        )

        print("Page opened successfully.")
        input("Press Enter to close the browser...")

        browser.close()


if __name__ == "__main__":
    main()