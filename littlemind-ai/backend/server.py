import logging
import time
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
import json
from schemas import AskRequest, AskResponse
from modes import build_prompt
from ollama_client import generate_response, generate_response_stream
from config import OLLAMA_URL, OLLAMA_BASE_URL, MODEL_NAME

# Configure logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = FastAPI(title="LittleMind AI Backend")

@app.on_event("startup")
async def startup_event():
    """Log LLM configuration on server startup"""
    logger.info("=" * 60)
    logger.info("LittleMind AI Backend Starting Up")
    logger.info("=" * 60)
    logger.info("LLM Configuration:")
    logger.info(f"  Base URL:    {OLLAMA_BASE_URL}")
    logger.info(f"  Chat API URL: {OLLAMA_URL}")
    logger.info(f"  Model:       {MODEL_NAME}")
    logger.info("=" * 60)

@app.get("/")
def health():
    logger.info("Health check endpoint called")
    return {
        "status": "LittleMind AI running",
        "model": MODEL_NAME,
        "api_url": OLLAMA_URL,
        "base_url": OLLAMA_BASE_URL
    }

@app.post("/ask", response_model=AskResponse)
def ask(req: AskRequest):
    request_start_time = time.time()
    
    logger.info("=" * 60)
    logger.info("RECEIVED NEW REQUEST")
    logger.info(f"  Client Input: text='{req.text}'")
    logger.info(f"  User Profile: name={req.name}, age={req.age}")
    logger.info(f"  Interests: {req.interests}")
    logger.info(f"  Language: {req.language}")
    logger.info("=" * 60)
    
    # Build prompt
    logger.info("Building prompt based on user input...")
    system_prompt, user_message, mode = build_prompt(req)
    logger.info(f"  Mode: '{mode}'")
    logger.info(f"  System prompt length: {len(system_prompt)} characters")
    logger.info(f"  User message length: {len(user_message)} characters")
    logger.debug(f"  System prompt:\n{system_prompt}")
    logger.debug(f"  User message:\n{user_message}")

    # Call LLM
    logger.info(f"Sending request to LLM ({MODEL_NAME}) at {OLLAMA_URL}...")
    llm_start_time = time.time()
    response = generate_response(user_message, system_prompt)
    llm_elapsed = time.time() - llm_start_time
    logger.info(f"LLM response received in {llm_elapsed:.2f} seconds")
    
    logger.debug(f"  LLM Response (first 200 chars): {response[:200]}...")
    logger.debug(f"  Full response length: {len(response)} characters")

    # Build response
    result = AskResponse(
        response=response,
        mode=mode
    )
    
    total_elapsed = time.time() - request_start_time
    logger.info("=" * 60)
    logger.info("REQUEST COMPLETED")
    logger.info(f"  Total processing time: {total_elapsed:.2f} seconds")
    logger.info(f"  LLM processing time: {llm_elapsed:.2f} seconds")
    logger.info(f"  Response mode: '{mode}'")
    logger.info(f"  Response length: {len(response)} characters")
    logger.info("=" * 60)
    
    return result

@app.post("/ask_stream")
def ask_stream(req: AskRequest):
    logger.info("=" * 60)
    logger.info("RECEIVED NEW STREAMING REQUEST")
    logger.info(f"  Client Input: text='{req.text}'")
    logger.info("=" * 60)
    
    # Build prompt
    system_prompt, user_message, mode = build_prompt(req)
    
    def event_generator():
        # First yield an empty chunk to establish the mode immediately (optional but helpful)
        yield f"data: {json.dumps({'response': '', 'mode': mode})}\n\n"
        
        # Stream the actual chunks
        for chunk in generate_response_stream(user_message, system_prompt):
            yield f"data: {json.dumps({'response': chunk, 'mode': mode})}\n\n"
            
        # Send [DONE] to signal completion
        yield "data: [DONE]\n\n"
            
    return StreamingResponse(event_generator(), media_type="text/event-stream")