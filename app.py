from dotenv import load_dotenv

from sorter import Sorter

load_dotenv()

if __name__ == "__main__":
    with Sorter("api") as sorter:
        sorter.lookup_files()
        while True:
            pass
