import os
from shutil import copy2

from sorter import SorterResult


class Organizer:
    inputs: dict[str, list[SorterResult]]
    input_directory: str
    output_directory: str

    def __init__(
            self,
            inputs: dict[str, list[SorterResult]],
            input_directory: str = "./inputs",
            output_directory: str = "./outputs_organized"
    ):
        # TODO: Implement way to load inputs from output.json
        self.inputs = inputs
        self.input_directory = input_directory
        self.output_directory = output_directory

        if not os.path.exists(self.input_directory):
            raise FileNotFoundError(f"Input directory {self.input_directory} not found")

        if not os.path.exists(self.output_directory):
            os.makedirs(self.output_directory)

    def organize_files_by_characters(self):
        for filename, results in self.inputs.items():
            new_filename: str = f"_{filename}"
            for result in results:
                filename_suffix: str = ""
                if characters := result.characters:
                    filename_suffix = f"{characters}"
                if material := result.material:
                    filename_suffix = (
                        filename_suffix
                        .replace(f" ({material}), ", ",")
                        .replace(f" ({material})", "")
                    )
                    filename_suffix = f"{material}_{filename_suffix}"

                if len(filename_suffix) > 0:
                    new_filename = f"{filename_suffix}{filename}"
                    break

            source_file_path: str = os.path.join(self.input_directory, filename)
            destination_file_path: str = os.path.join(self.output_directory, new_filename)
            copy2(source_file_path, destination_file_path)
