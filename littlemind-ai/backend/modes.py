import logging
from prompts import story_prompt, emotion_prompt, parent_prompt
from schemas import AskRequest
from config import MODEL_NAME

logger = logging.getLogger(__name__)

def detect_mode(user_input: str) -> str:
    text = user_input.lower()
    logger.debug(f"[MODE] Detecting mode for input: '{user_input[:100]}...'")

    emotional_keywords = ["scared", "afraid", "sad", "angry", "cry", "dark"]
    parent_keywords = ["how do i explain", "my child"]

    if any(word in text for word in emotional_keywords):
        logger.debug("[MODE] Detected 'emotion' mode based on emotional keywords")
        return "emotion"

    if any(keyword in text for keyword in parent_keywords):
        logger.debug("[MODE] Detected 'parent' mode based on parent-related keywords")
        return "parent"

    logger.debug("[MODE] Defaulting to 'story' mode")
    return "story"


def build_prompt(req: AskRequest) -> tuple[str, str, str]:
    """Returns (system_prompt, user_message, mode) tuple"""
    logger.info(f"[PROMPT] Building prompt for LLM model: {MODEL_NAME}")
    logger.info(f"[PROMPT] Input text: '{req.text[:100]}...'")
    
    # Use user-specified mode if provided, otherwise auto-detect
    if req.mode and req.mode in ["story", "emotion", "parent"]:
        mode = req.mode
        logger.info(f"[PROMPT] Using user-specified mode: '{mode}'")
    else:
        mode = detect_mode(req.text)
        logger.info(f"[PROMPT] Auto-detected mode: '{mode}'")

    if mode == "emotion":
        logger.info("[PROMPT] Using emotion_prompt template")
        system_prompt, user_message = emotion_prompt(req)
        logger.info(f"[PROMPT] System prompt length: {len(system_prompt)}, User message length: {len(user_message)}")
        return system_prompt, user_message, mode

    if mode == "parent":
        logger.info("[PROMPT] Using parent_prompt template")
        system_prompt, user_message = parent_prompt(req)
        logger.info(f"[PROMPT] System prompt length: {len(system_prompt)}, User message length: {len(user_message)}")
        return system_prompt, user_message, mode

    logger.info("[PROMPT] Using story_prompt template")
    system_prompt, user_message = story_prompt(req)
    logger.info(f"[PROMPT] System prompt length: {len(system_prompt)}, User message length: {len(user_message)}")
    return system_prompt, user_message, mode