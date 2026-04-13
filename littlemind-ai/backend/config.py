import logging

# Configure logger for config module
logger = logging.getLogger(__name__)

# LLM API Configuration - Using Chat API for better responses
OLLAMA_BASE_URL = "http://192.168.1.3:11434"
OLLAMA_URL = f"{OLLAMA_BASE_URL}/api/chat"  # Chat API endpoint
MODEL_NAME = "gemma3:4b"

# Generation Parameters
MAX_TOKENS = 512
TEMPERATURE = 0.7
TOP_P = 0.9

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