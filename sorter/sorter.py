import json
import os
import traceback
from time import sleep
from typing import Literal
from urllib.parse import urlencode

from playwright.sync_api import Response as PlaywrightResponse
from playwright.sync_api import (
    sync_playwright,
    Playwright,
    Page,
    BrowserContext,
    ElementHandle
)
from requests import Response as RequestsResponse
from requests import post

from common import log
from sorter.constants import (
    saucenao_base_url,
    saucenao_search_url,
    saucenao_api_key,
    saucenao_sleep_time,
    browser_user_agent,
    browser_args,
    browser_init_script,
    id_input_select_image,
    id_input_search_submit,
    classname_div_result,
    classname_div_result_hidden,
    id_div_result_hidden
)
from sorter.result import SorterResult


class Sorter:
    mode: str
    input_directory: str
    output_directory: str
    playwright: Playwright | None
    browser_context: BrowserContext | None
    current_page: Page | None
    current_images: dict[str, bytes]
    output: dict[str, list[SorterResult]]

    def __init__(
            self,
            mode: Literal["web", "api"] = "api",
            input_directory: str = "./inputs",
            output_directory: str = "./outputs"
    ):
        self.mode = mode
        self.input_directory = input_directory
        self.output_directory = output_directory
        self.playwright = None
        self.browser_context = None
        self.current_page = None
        self.current_images = {}
        self.output = {}

        if not os.path.exists(self.input_directory):
            raise FileNotFoundError(f"Input directory {self.input_directory} not found")

        if not os.path.exists(self.output_directory):
            os.makedirs(self.output_directory)

    # Context Manager

    def __enter__(self):
        match self.mode:
            case "web":
                self.playwright = sync_playwright().start()
                self.browser_context = self.playwright.chromium.launch_persistent_context(
                    user_data_dir="./.chromium/",
                    args=browser_args,
                    headless=False,
                    viewport={"width": 1069, "height": 573},
                    screen={"width": 1920, "height": 1080},
                    user_agent=browser_user_agent,
                    device_scale_factor=2,
                    color_scheme="light",
                    locale="en-US",
                    timezone_id="Asia/Tokyo",
                    permissions=[],
                    bypass_csp=True
                )
                self.browser_context.add_init_script(browser_init_script)
            case "api":
                pass
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.browser_context:
            self.browser_context.close()
        if self.playwright:
            self.playwright.stop()

    # Playwright

    def __on_response(self, response: PlaywrightResponse):
        if response.request.resource_type == "image":
            self.current_images[response.request.url] = response.body()

    def __lookup_file_web(self, filename: str) -> list[SorterResult]:
        # Open new page
        self.current_page = self.browser_context.new_page()
        self.current_page.on("response", self.__on_response)
        self.current_images = {}

        # Go to SauceNAO homepage
        self.current_page.goto(saucenao_base_url)

        # Upload file and submit form
        self.current_page.set_input_files(f"input[id={id_input_select_image}]",
                                          os.path.join(self.input_directory, filename))
        self.current_page.click(f"input[id={id_input_search_submit}]")
        self.current_page.wait_for_timeout(10000)

        # Use selectors to get results
        results: list[ElementHandle] = self.current_page.query_selector_all(
            f'.{classname_div_result}:not([id="{id_div_result_hidden}"]):not([class*="{classname_div_result_hidden}"])'
        )
        result_objects: list[SorterResult] = [
            SorterResult(
                element=result,
                images=self.current_images
            )
            for result in results
        ]

        return result_objects

    # API

    def __lookup_file_api(self, filename: str, lookup_url: str) -> list[SorterResult]:
        # Read image bytes
        image_bytes: bytes | None = None
        with open(os.path.join(self.input_directory, filename), "rb") as image_file:
            image_bytes = image_file.read()

        # Call API with image bytes
        response_json_output_path: str = os.path.join(self.output_directory, f"{filename}.json")
        response: RequestsResponse = post(lookup_url, files={
            "file": (filename, image_bytes)
        })
        response.raise_for_status()
        log(f"API response: {response.text}")
        response_json: dict = response.json()
        with open(response_json_output_path, "w", encoding="utf-8") as response_json_file:
            response_json_file.write(json.dumps(response_json, skipkeys=True, indent=4, ensure_ascii=False))

        # Get results from API response
        if response_results := response_json.get("results"):
            result_objects: list[SorterResult] = []
            for response_result in response_results:
                result_objects.append(SorterResult(
                    api_result=response_result
                ))
            return result_objects
        return []

    # Output Functions

    def __parse_json(self, obj):
        if isinstance(obj, bytes):
            return None
        raise TypeError(f"Object of type {type(obj).__name__} is not JSON serializable")

    def __write_json_output(self):
        results_dict: dict[str, list[dict[str, str | bytes]]] = {
            filename: [result.to_dict() for result in sorter_results]
            for filename, sorter_results in self.output.items()
        }
        output_string: str = json.dumps(
            results_dict,
            skipkeys=True,
            ensure_ascii=False,
            indent=4,
            default=self.__parse_json
        )
        with open(os.path.join(self.output_directory, "output.json"), "w", encoding="utf-8") as output_file:
            output_file.write(output_string)

    # Public Functions

    def lookup_files(self) -> dict[str, list[SorterResult]]:
        match self.mode:
            case "web":
                self.output: dict[str, list[SorterResult]] = {}
                for filename in os.listdir(self.input_directory):
                    if (os.path.isfile(os.path.join(self.input_directory, filename)) and
                            filename.lower().endswith((".jpg", ".jpeg", ".png"))):
                        log(f"Processing '{filename}'...")
                        try:
                            self.output[filename] = self.__lookup_file_web(filename)
                            self.__write_json_output()
                        except Exception as e:
                            log(f"Error processing '{filename}': {str(e)}\n{traceback.format_exc()}", "error")
                        sleep(30)

            case "api":
                self.output: dict[str, list[SorterResult]] = {}
                parameters: dict[str, str] = {
                    "db": "999",
                    "output_type": "2",
                    "api_key": saucenao_api_key,
                    "numres": "3"
                }
                lookup_url: str = f"{saucenao_search_url}?{urlencode(parameters)}"
                for filename in os.listdir(self.input_directory):
                    if (os.path.isfile(os.path.join(self.input_directory, filename)) and
                            filename.lower().endswith((".jpg", ".jpeg", ".png"))):
                        log(f"Processing '{filename}'...")
                        try:
                            self.output[filename] = self.__lookup_file_api(
                                filename,
                                lookup_url
                            )
                            self.__write_json_output()
                        except Exception as e:
                            log(f"Error processing '{filename}': {str(e)}\n{traceback.format_exc()}", "error")
                        sleep(saucenao_sleep_time)

        return self.output
