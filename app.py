import os

from dotenv import load_dotenv

from loader import Loader
from organizer import Organizer
from sorter import Sorter, SorterResult

load_dotenv()

if __name__ == "__main__":
    use_loader: bool = True

    if not use_loader:
        print("Starting Sorter...")
        with Sorter("api") as sorter:
            results: dict[str, list[SorterResult]] = sorter.lookup_files()
    else:
        # Loader is only supported for API mode
        print("Starting Loader...")
        loader: Loader = Loader()
        results: dict[str, list[SorterResult]] = loader.collate_results()

    if results:
        print("Starting Organizer...")
        organizer: Organizer = Organizer(results)
        organizer.organize_files_by_characters()

    print("All files organized!")