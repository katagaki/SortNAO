# SortNAO

Simple illustration sorting using SauceNAO.

## Setup

1. Using [uv](https://docs.astral.sh/uv/getting-started/installation/), 
create a virtual environment and sync the project's dependencies.

```zsh
uv venv
source ./.venv/bin/activate
uv sync
```

2. Place your files in a folder named "inputs" in the project root folder.

3. Prepare your `.env` file if you are using the official API implementation.

4. Execute `app.py` within the virtual environment to begin the process.



## Using the official API

Obtain an API key from your [SauceNAO account page](https://saucenao.com/user.php), 
and place it in the .env file like this:

```dotenv
SAUCENAO_API_KEY=xxxxx
```

Once you have done that, you can use the Sorter class like this:

```python
with Sorter("api") as sorter:
    sorter.lookup_files()
```



## Using Playwright web automation

The Playwright web automation implemention is only implemented as a proof-of-concept, and should not be used.
Do note that unregistered account API rate limits apply.

```python
with Sorter("web") as sorter:
    sorter.lookup_files()
```