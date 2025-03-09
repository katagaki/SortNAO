from logging import getLogger, StreamHandler, INFO
from sys import stdout
from typing import Literal
from warnings import warn

logger = getLogger("sortnao")
logger.setLevel(INFO)
logger.addHandler(StreamHandler(stream=stdout))


def log(message: str, level: Literal["info", "warn", "error"] = "info"):
    match level:
        case "info":
            logger.info(message)
        case "warn":
            warn(message)
        case "error":
            logger.error(message)
        case _:
            logger.debug(message)
