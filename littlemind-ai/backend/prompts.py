import json
import logging
import os
from schemas import AskRequest

logger = logging.getLogger(__name__)

# Load prompt templates from JSON files
_PROMPT_TEMPLATES = {}

def _load_prompt_template(name: str) -> dict:
    """Load a prompt template from JSON file, caching for performance."""
    if name not in _PROMPT_TEMPLATES:
        template_path = os.path.join(os.path.dirname(__file__), "prompts", f"{name}.json")
        try:
            with open(template_path, "r", encoding="utf-8") as f:
                _PROMPT_TEMPLATES[name] = json.load(f)
            logger.info(f"[PROMPT] Loaded template: {name}.json")
        except FileNotFoundError:
            logger.error(f"[PROMPT] Template file not found: {template_path}")
            raise
        except json.JSONDecodeError as e:
            logger.error(f"[PROMPT] Invalid JSON in template {name}.json: {e}")
            raise
    return _PROMPT_TEMPLATES[name]


def _get_hinglish_instruction(language: str) -> str:
    if language and language.lower() == "hinglish":
        logger.info("[PROMPT] Hinglish language mode enabled")
        return "- IMPORTANT: Respond entirely in Hinglish (conversational Hindi written in English vocabulary/alphabet). Example: 'Tum ek bahot brave bache ho! Chalo ek kahani sunte hain.' Do NOT write in English or Devanagari script."
    return ""


def _fill_template(template: str, **kwargs) -> str:
    """Fill a template string with provided keyword arguments."""
    return template.format(**kwargs)


def story_prompt(req: AskRequest) -> tuple[str, str]:
    """Returns (system_prompt, user_message) tuple"""
    child_name = req.name or "the child"
    interests_text = f"- Include things they like: {req.interests}" if req.interests else ""
    hinglish_text = _get_hinglish_instruction(req.language)
    
    logger.info(f"[PROMPT] Building story prompt for: {child_name} (age {req.age}), language={req.language or 'default'}")
    if req.interests:
        logger.info("[PROMPT] User interests provided")
    
    template = _load_prompt_template("story")
    
    system_prompt = _fill_template(
        template["system_prompt"],
        hinglishText=hinglish_text
    )
    
    user_message = _fill_template(
        template["user_message"],
        childName=child_name,
        childAge=req.age,
        text=req.text,
        interestsText=interests_text
    )
    
    return system_prompt, user_message


def emotion_prompt(req: AskRequest) -> tuple[str, str]:
    """Returns (system_prompt, user_message) tuple"""
    child_name = req.name or "the child"
    hinglish_text = _get_hinglish_instruction(req.language)

    logger.info(f"[PROMPT] Building emotion prompt for: {child_name} (age {req.age}), language={req.language or 'default'}")

    template = _load_prompt_template("emotion")
    
    system_prompt = _fill_template(
        template["system_prompt"],
        hinglishText=hinglish_text
    )
    
    user_message = _fill_template(
        template["user_message"],
        childName=child_name,
        childAge=req.age,
        text=req.text
    )
    
    return system_prompt, user_message


def parent_prompt(req: AskRequest) -> tuple[str, str]:
    """Returns (system_prompt, user_message) tuple"""
    hinglish_text = _get_hinglish_instruction(req.language)

    logger.info(f"[PROMPT] Building parent prompt for child (age {req.age}), language={req.language or 'default'}")

    template = _load_prompt_template("parent")
    
    system_prompt = _fill_template(
        template["system_prompt"],
        hinglishText=hinglish_text,
        childAge=req.age
    )
    
    user_message = _fill_template(
        template["user_message"],
        childName="parent",
        childAge=req.age,
        text=req.text
    )
    
    return system_prompt, user_message
