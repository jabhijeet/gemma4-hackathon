import logging
import time
import requests
import json
from config import OLLAMA_URL, MODEL_NAME, TEMPERATURE, MAX_TOKENS, TOP_P, REQUEST_TIMEOUT_SECONDS, MAX_PROMPT_CHARS

logger = logging.getLogger(__name__)


class LLMError(Exception):
    """Base error for upstream LLM failures."""


class LLMConnectionError(LLMError):
    pass


class LLMTimeoutError(LLMError):
    pass


class LLMResponseError(LLMError):
    pass


def _build_payload(prompt: str, system_prompt: str, stream: bool) -> dict:
    if len(prompt) + len(system_prompt) > MAX_PROMPT_CHARS:
        raise LLMResponseError("Prompt is too large")

    messages = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.append({"role": "user", "content": prompt})

    return {
        "model": MODEL_NAME,
        "messages": messages,
        "stream": stream,
        "options": {
            "temperature": TEMPERATURE,
            "num_predict": MAX_TOKENS,
            "top_p": TOP_P,
            "think": False,
            "raw": False,
        },
    }


def _extract_response(response_json: dict) -> str:
    if "message" in response_json and isinstance(response_json["message"], dict):
        result = response_json["message"].get("content", "").strip()
        if result:
            return result

    if "choices" in response_json and response_json["choices"]:
        choice = response_json["choices"][0]
        if isinstance(choice, dict):
            result = choice.get("message", {}).get("content", "").strip()
            if result:
                return result

    if "response" in response_json:
        result = str(response_json.get("response", "")).strip()
        if result:
            return result

    if "content" in response_json:
        result = str(response_json.get("content", "")).strip()
        if result:
            return result

    raise LLMResponseError("LLM response did not contain generated content")


def generate_response(prompt: str, system_prompt: str = "") -> str:
    logger.info("=" * 60)
    logger.info("[LLM] INITIATING REQUEST")
    logger.info(f"  API Endpoint: {OLLAMA_URL}")
    logger.info(f"  Model:        {MODEL_NAME}")
    logger.info(f"  Temperature:  {TEMPERATURE}")
    logger.info(f"  Max Tokens:   {MAX_TOKENS}")
    logger.info(f"  Top P:        {TOP_P}")
    logger.info(f"  System prompt length: {len(system_prompt)} characters")
    logger.info(f"  User prompt length: {len(prompt)} characters")
    logger.info("=" * 60)
    
    start_time = time.time()
    
    try:
        payload = _build_payload(prompt, system_prompt, stream=False)
        
        logger.info(f"[LLM] Sending POST request to {OLLAMA_URL}...")
        response = requests.post(
            OLLAMA_URL,
            json=payload,
            timeout=REQUEST_TIMEOUT_SECONDS,
        )
        
        elapsed_time = time.time() - start_time
        logger.info(f"[LLM] HTTP Response received in {elapsed_time:.2f} seconds")
        logger.info(f"[LLM] HTTP Status Code: {response.status_code}")

        response.raise_for_status()
        response_json = response.json()
        
        logger.info(f"[LLM] RAW response JSON keys: {list(response_json.keys())}")
        result = _extract_response(response_json)
        
        logger.info("[LLM] Response received successfully")
        logger.info(f"[LLM] Response length: {len(result)} characters")
        
        if "prompt_eval_count" in response_json:
            logger.info(f"[LLM] Prompt tokens: {response_json.get('prompt_eval_count', 'N/A')}")
        if "eval_count" in response_json:
            logger.info(f"[LLM] Completion tokens: {response_json.get('eval_count', 'N/A')}")
        if "total_duration" in response_json:
            logger.info(f"[LLM] Server processing time: {response_json.get('total_duration', 'N/A')} ns")
        
        logger.info("=" * 60)
        return result

    except requests.exceptions.ConnectionError as e:
        elapsed_time = time.time() - start_time
        logger.error(f"[LLM] Connection error after {elapsed_time:.2f}s - Is Ollama running at {OLLAMA_URL}?")
        logger.error(f"[LLM] Error details: {str(e)}")
        raise LLMConnectionError("Cannot connect to LLM service") from e
    except requests.exceptions.Timeout as e:
        elapsed_time = time.time() - start_time
        logger.error(f"[LLM] Request timed out after {elapsed_time:.2f}s (limit: {REQUEST_TIMEOUT_SECONDS}s)")
        logger.error(f"[LLM] Timeout details: {str(e)}")
        raise LLMTimeoutError("LLM request timed out") from e
    except requests.exceptions.HTTPError as e:
        elapsed_time = time.time() - start_time
        logger.error(f"[LLM] HTTP Error after {elapsed_time:.2f}s: {str(e)}")
        logger.error(f"[LLM] Response content: {response.text[:500] if 'response' in locals() else 'N/A'}")
        raise LLMResponseError("LLM service returned an error") from e
    except (json.JSONDecodeError, LLMResponseError) as e:
        elapsed_time = time.time() - start_time
        logger.error(f"[LLM] Invalid response after {elapsed_time:.2f}s: {str(e)}")
        raise LLMResponseError("LLM service returned an invalid response") from e

def generate_response_stream(prompt: str, system_prompt: str = ""):
    logger.info("=" * 60)
    logger.info("[LLM] INITIATING STREAMING REQUEST")
    logger.info(f"  API Endpoint: {OLLAMA_URL}")
    logger.info(f"  Model:        {MODEL_NAME}")
    logger.info("=" * 60)
    
    start_time = time.time()
    
    try:
        payload = _build_payload(prompt, system_prompt, stream=True)
        
        logger.info(f"[LLM] Sending Streaming POST request to {OLLAMA_URL}...")
        with requests.post(OLLAMA_URL, json=payload, stream=True, timeout=REQUEST_TIMEOUT_SECONDS) as response:
            response.raise_for_status()
            for line in response.iter_lines():
                if line:
                    decoded_line = line.decode('utf-8')
                    try:
                        data = json.loads(decoded_line)
                        if "message" in data and "content" in data["message"]:
                            chunk = data["message"]["content"]
                            if chunk:
                                yield chunk
                        elif "response" in data:
                            chunk = data["response"]
                            if chunk:
                                yield chunk
                    except json.JSONDecodeError:
                        logger.warning(f"[LLM] Failed to parse streaming JSON: {decoded_line}")
                        
        elapsed_time = time.time() - start_time
        logger.info(f"[LLM] Streaming completed in {elapsed_time:.2f} seconds")
        logger.info("=" * 60)
                        
    except requests.exceptions.ConnectionError as e:
        logger.error(f"[LLM] Streaming connection error: {str(e)}")
        yield "Error: Cannot connect to LLM service."
    except requests.exceptions.Timeout as e:
        logger.error(f"[LLM] Streaming timeout: {str(e)}")
        yield "Error: LLM request timed out."
    except Exception as e:
        logger.error(f"[LLM] Streaming error: {str(e)}")
        yield "Error: LLM service failed."
