import json
import os
import traceback

from common import log
from sorter import SorterResult


class Loader:
    output_directory: str

    def __init__(self, output_directory: str = "./outputs"):
        self.output_directory = output_directory

    def collate_results(self) -> dict[str, list[SorterResult]]:
        collated_results: dict[str, list[SorterResult]] = {}

        for filename in os.listdir(self.output_directory):
            if (os.path.isfile(os.path.join(self.output_directory, filename)) and
                    filename.lower().endswith(".json") and filename != "output.json"):
                log(f"Collating '{filename}'...")

                try:
                    with open(os.path.join(self.output_directory, filename), "r") as result_json_file:
                        result_json_string: str = result_json_file.read()
                    result_json: dict = json.loads(result_json_string)
                    filename: str = filename.replace(".json", "")

                    results: list[SorterResult] = []
                    for result in result_json.get("results", []):
                        results.append(SorterResult(api_result=result))

                    collated_results[filename] = results

                except Exception as e:
                    log(f"Failed to collate '{filename}': {str(e)}\n{traceback.format_exc()}", "error")

        return collated_results