import os
import platform
import subprocess
from shutil import copy2

from common import log
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

    # Public Functions

    def organize_files_by_characters(self):
        for filename, results in self.inputs.items():
            new_filename: str = f"_{filename}"
            for result in results:
                filename_suffix: str = ""
                if characters := result.characters:
                    characters = characters.replace("/", "-")
                    filename_suffix = f"{characters}"
                if material := result.material:
                    material = material.replace("/", "-")
                    filename_suffix = (
                        filename_suffix
                        .replace(f" ({material}), ", ",")
                        .replace(f" ({material})", "")
                    )
                    filename_suffix = f"{material}_{filename_suffix}"

                if len(filename_suffix) > 0:
                    new_filename = f"{filename_suffix}_{filename}"
                    break

            log(f"Copying '{filename}' to '{new_filename}'...")
            source_file_path: str = os.path.join(self.input_directory, filename)
            destination_file_path: str = os.path.join(self.output_directory, new_filename)
            copy2(source_file_path, destination_file_path)

            if platform.system() in ["Darwin", "Linux"]:
                log(f"Attempting to preserve creation date...")
                try:
                    if platform.system() == "Linux":
                        source_file_stat: os.stat_result = os.stat(source_file_path)
                        os.utime(
                            destination_file_path,
                            times=(source_file_stat.st_atime, source_file_stat.st_mtime),
                            ns=(source_file_stat.st_atime_ns, source_file_stat.st_mtime_ns)
                        )
                    elif platform.system() == "Darwin":
                        source_file_creation_date: str = subprocess.run(
                            ["GetFileInfo", "-d", source_file_path],
                            capture_output=True, text=True, check=True
                        ).stdout.strip()
                        source_file_modification_date: str = subprocess.run(
                            ["GetFileInfo", "-m", source_file_path],
                            capture_output=True, text=True, check=True
                        ).stdout.strip()
                        subprocess.run(
                            ["SetFile", "-d", source_file_creation_date, destination_file_path],
                            check=True
                        )
                        subprocess.run(
                            ["SetFile", "-m", source_file_modification_date, destination_file_path],
                            check=True
                        )
                except:
                    log("One or more creation date preservation strategies failed", "warn")
