# SortNAO

Simple illustration sorting using SauceNAO.

Place your files in a folder named "inputs" in the project root folder to begin.

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