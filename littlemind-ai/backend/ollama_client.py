import logging
import time
import requests
import json
from config import OLLAMA_URL, MODEL_NAME, TEMPERATURE, MAX_TOKENS, TOP_P

logger = logging.getLogger(__name__)

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
        # Build messages array for chat API
        messages = []
        
        # Add system message if provided
        if system_prompt:
            messages.append({
                "role": "system",
                "content": system_prompt
            })
        
        # Add user message
        messages.append({
            "role": "user",
            "content": prompt
        })
        
        payload = {
            "model": MODEL_NAME,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": TEMPERATURE,
                "num_predict": MAX_TOKENS,
                "top_p": TOP_P,
                "think": False,
                "raw": False
            }
        }
        logger.debug(f"[LLM] Request payload: {payload}")
        
        logger.info(f"[LLM] Sending POST request to {OLLAMA_URL}...")
        response = requests.post(
            OLLAMA_URL,
            json=payload,
            timeout=60
        )
        
        elapsed_time = time.time() - start_time
        logger.info(f"[LLM] HTTP Response received in {elapsed_time:.2f} seconds")
        logger.info(f"[LLM] HTTP Status Code: {response.status_code}")

        response.raise_for_status()
        response_json = response.json()
        
        # DIAGNOSTIC: Log the full raw response to debug empty response issue
        logger.info(f"[LLM] RAW response JSON keys: {list(response_json.keys())}")
        logger.debug(f"[LLM] Full raw response JSON: {response_json}")
        
        # Chat API returns message in different format - try multiple extraction strategies
        result = ""
        extraction_method = "unknown"
        
        # Strategy 1: Standard Ollama chat API format (message.content)
        if "message" in response_json and isinstance(response_json["message"], dict):
            result = response_json["message"].get("content", "").strip()
            extraction_method = "message.content"
            # If content is empty but thinking exists, use thinking as fallback
            if not result and "thinking" in response_json["message"]:
                result = response_json["message"].get("thinking", "").strip()
                extraction_method = "message.thinking"
        
        # Strategy 2: OpenAI-compatible format (choices[0].message.content)
        if not result and "choices" in response_json and response_json["choices"]:
            try:
                result = response_json["choices"][0].get("message", {}).get("content", "").strip()
                extraction_method = "choices[0].message.content"
            except (IndexError, AttributeError) as e:
                logger.debug(f"[LLM] Failed to extract from choices: {e}")
        
        # Strategy 3: Legacy generate API format (response)
        if not result and "response" in response_json:
            result = response_json.get("response", "").strip()
            extraction_method = "response"
        
        # Strategy 4: Check if content is directly in response_json
        if not result and "content" in response_json:
            result = str(response_json.get("content", "")).strip()
            extraction_method = "content"
        
        if result:
            logger.info(f"[LLM] Extracted using '{extraction_method}': '{result[:100]}...'")
        else:
            logger.warning(f"[LLM] Could not extract content! Response keys: {list(response_json.keys())}")
            logger.warning(f"[LLM] Full response structure: {str(response_json)[:500]}")
            result = "I'm sorry, I couldn't generate a response. Please try again!"
        
        # Log additional response metadata
        logger.info(f"[LLM] Response received successfully")
        logger.info(f"[LLM] Response length: {len(result)} characters")
        logger.debug(f"[LLM] Full response: {result[:500]}...")
        
        # Log token usage if available
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
        return f"Error: Cannot connect to Ollama at {OLLAMA_URL}. Make sure Ollama is running."
    except requests.exceptions.Timeout as e:
        elapsed_time = time.time() - start_time
        logger.error(f"[LLM] Request timed out after {elapsed_time:.2f}s (limit: 60s)")
        logger.error(f"[LLM] Timeout details: {str(e)}")
        return f"Error: Request to Ollama timed out. The model may be taking too long to respond."
    except requests.exceptions.HTTPError as e:
        elapsed_time = time.time() - start_time
        logger.error(f"[LLM] HTTP Error after {elapsed_time:.2f}s: {str(e)}")
        logger.error(f"[LLM] Response content: {response.text[:500] if 'response' in dir() else 'N/A'}")
        return f"Error: LLM API returned HTTP error. Details: {str(e)}"
    except Exception as e:
        elapsed_time = time.time() - start_time
        logger.error(f"[LLM] Unexpected error after {elapsed_time:.2f}s: {str(e)}")
        logger.error(f"[LLM] Error type: {type(e).__name__}")
        return f"Error: {str(e)}"

def generate_response_stream(prompt: str, system_prompt: str = ""):
    logger.info("=" * 60)
    logger.info("[LLM] INITIATING STREAMING REQUEST")
    logger.info(f"  API Endpoint: {OLLAMA_URL}")
    logger.info(f"  Model:        {MODEL_NAME}")
    logger.info("=" * 60)
    
    start_time = time.time()
    
    try:
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})
        
        payload = {
            "model": MODEL_NAME,
            "messages": messages,
            "stream": True,
            "options": {
                "temperature": TEMPERATURE,
                "num_predict": MAX_TOKENS,
                "top_p": TOP_P,
                "think": False,
                "raw": False
            }
        }
        
        logger.info(f"[LLM] Sending Streaming POST request to {OLLAMA_URL}...")
        with requests.post(OLLAMA_URL, json=payload, stream=True, timeout=60) as response:
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
        yield f"Error: Cannot connect to Ollama at {OLLAMA_URL}."
    except Exception as e:
        logger.error(f"[LLM] Streaming error: {str(e)}")
        yield f"Error: {str(e)}"