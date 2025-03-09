import os

# SauceNAO API
saucenao_base_url: str = "https://saucenao.com"
saucenao_search_url: str = f"{saucenao_base_url}/search.php"
saucenao_api_key: str = os.environ["SAUCENAO_API_KEY"]
saucenao_sleep_time: int = int(os.environ.get("SAUCENAO_API_SLEEP_TIME", "10"))

# Browser
browser_user_agent: str = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36"
browser_args: list[str] = [
    "--password-store=basic",
    "--disable-features=site-per-process",
    "--disable-blink-features=AutomationControlled",
    "--disable-web-security",
    "--disable-audio-output",
    "--disable-gpu",
    "--disable-dev-shm-usage",
    "--disable-infobars",
    "--ignore-certificate-errors",
    "--window-position=0,0",
    "--disable-popup-blocking",
    "--no-first-run",
    "--no-default-browser-check",
    "--no-sandbox",
    "--single-process",
]
browser_init_script: str = """
Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
Object.defineProperty(navigator, 'plugins', {get: () => [1, 2, 3, 4, 5]});
Object.defineProperty(navigator, 'languages', {get: () => ['en-US', 'en']});
window.chrome = { runtime: {} };
""".strip()

# Search Page
id_input_select_image: str = "fileInput"
id_input_search_submit: str = "searchButton"

# Result page
classname_div_result: str = "result"
classname_div_result_hidden: str = "hidden"
id_div_result_hidden: str = "result-hidden-notification"
classname_div_result_image: str = "resultimage"
classname_div_result_similarity: str = "resultsimilarityinfo"
classname_div_result_title: str = "resulttitle"
classname_div_result_content: str = "resultcontentcolumn"

# Result parsing
prefix_creator: str = "Creator: "
prefix_source: str = "Source: "
prefix_material: str = "Material: "
prefix_characters: str = "Characters: "
prefix_pixiv_id: str = "pixiv ID: "
prefix_member: str = "Member: "
