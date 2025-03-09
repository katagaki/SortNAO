from dotenv import load_dotenv

from organizer import Organizer
from sorter import Sorter, SorterResult

load_dotenv()

if __name__ == "__main__":
    print("Starting Sorter...")
    with Sorter("api") as sorter:
        results: dict[str, list[SorterResult]] = sorter.lookup_files()

    if results:
        print("Starting Organizer...")
        organizer: Organizer = Organizer(results)
        organizer.organize_files_by_characters()

    print("All files organized!")