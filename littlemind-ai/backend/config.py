import logging
import os
from urllib.parse import urlparse

# Configure logger for config module
logger = logging.getLogger(__name__)

def _get_int(name: str, default: int, *, minimum: int | None = None) -> int:
    value = os.getenv(name)
    if value is None:
        return default
    try:
        parsed = int(value)
    except ValueError as exc:
        raise ValueError(f"{name} must be an integer") from exc
    if minimum is not None and parsed < minimum:
        raise ValueError(f"{name} must be at least {minimum}")
    return parsed


def _get_float(name: str, default: float, *, minimum: float | None = None, maximum: float | None = None) -> float:
    value = os.getenv(name)
    if value is None:
        return default
    try:
        parsed = float(value)
    except ValueError as exc:
        raise ValueError(f"{name} must be a number") from exc
    if minimum is not None and parsed < minimum:
        raise ValueError(f"{name} must be at least {minimum}")
    if maximum is not None and parsed > maximum:
        raise ValueError(f"{name} must be at most {maximum}")
    return parsed


def _get_url(name: str, default: str) -> str:
    value = os.getenv(name, default).rstrip("/")
    parsed = urlparse(value)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise ValueError(f"{name} must be an http(s) URL")
    return value


def _get_bool(name: str, default: bool = False) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


# LLM API Configuration - Using Chat API for better responses.
OLLAMA_BASE_URL = _get_url("OLLAMA_BASE_URL", "http://127.0.0.1:11434")
OLLAMA_URL = f"{OLLAMA_BASE_URL}/api/chat"
MODEL_NAME = os.getenv("MODEL_NAME", "gemma3:4b")

# Generation Parameters
MAX_TOKENS = _get_int("MAX_TOKENS", 512, minimum=1)
TEMPERATURE = _get_float("TEMPERATURE", 0.7, minimum=0.0, maximum=2.0)
TOP_P = _get_float("TOP_P", 0.9, minimum=0.0, maximum=1.0)

# Request and upstream limits
REQUEST_TIMEOUT_SECONDS = _get_float("REQUEST_TIMEOUT_SECONDS", 60.0, minimum=1.0)
MAX_PROMPT_CHARS = _get_int("MAX_PROMPT_CHARS", 4000, minimum=100)

# Rate limiting is per client IP and process-local. Use an external store for
# multi-worker deployments.
RATE_LIMIT_REQUESTS = _get_int("RATE_LIMIT_REQUESTS", 20, minimum=1)
RATE_LIMIT_WINDOW_SECONDS = _get_int("RATE_LIMIT_WINDOW_SECONDS", 60, minimum=1)
TRUST_PROXY_HEADERS = _get_bool("TRUST_PROXY_HEADERS", False)

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.getenv("ALLOWED_ORIGINS", "").split(",")
    if origin.strip()
]

# Log configuration on module load
logger.info("=" * 60)
logger.info("LLM CONFIGURATION LOADED")
logger.info(f"  Base URL:    {OLLAMA_BASE_URL}")
logger.info(f"  Chat API URL: {OLLAMA_URL}")
logger.info(f"  Model:       {MODEL_NAME}")
logger.info(f"  Max Tokens:  {MAX_TOKENS}")
logger.info(f"  Temperature: {TEMPERATURE}")
logger.info(f"  Top P:       {TOP_P}")
logger.info("=" * 60)
