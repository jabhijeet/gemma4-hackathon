from contextlib import asynccontextmanager
import logging
import time
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
import json
from schemas import AskRequest, AskResponse
from modes import build_prompt
from ollama_client import (
    LLMConnectionError,
    LLMResponseError,
    LLMTimeoutError,
    generate_response,
    generate_response_stream,
)
from rate_limiter import InMemoryRateLimiter, RateLimitExceeded
from config import (
    ALLOWED_ORIGINS,
    LOG_LEVEL,
    OLLAMA_URL,
    OLLAMA_BASE_URL,
    MODEL_NAME,
    RATE_LIMIT_REQUESTS,
    RATE_LIMIT_WINDOW_SECONDS,
    TRUST_PROXY_HEADERS,
)

logging.basicConfig(level=LOG_LEVEL, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI):
    """Log LLM configuration on server startup"""
    logger.info("=" * 60)
    logger.info("LittleMind AI Backend Starting Up")
    logger.info("=" * 60)
    logger.info("LLM Configuration:")
    logger.info(f"  Base URL:    {OLLAMA_BASE_URL}")
    logger.info(f"  Chat API URL: {OLLAMA_URL}")
    logger.info(f"  Model:       {MODEL_NAME}")
    logger.info(f"  Rate limit:  {RATE_LIMIT_REQUESTS}/{RATE_LIMIT_WINDOW_SECONDS}s per client")
    logger.info("=" * 60)
    yield


app = FastAPI(title="LittleMind AI Backend", lifespan=lifespan)
rate_limiter = InMemoryRateLimiter(RATE_LIMIT_REQUESTS, RATE_LIMIT_WINDOW_SECONDS)

if ALLOWED_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=ALLOWED_ORIGINS,
        allow_credentials=False,
        allow_methods=["GET", "POST"],
        allow_headers=["Content-Type", "Authorization"],
    )


@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response: Response = await call_next(request)
    response.headers.setdefault("X-Content-Type-Options", "nosniff")
    response.headers.setdefault("X-Frame-Options", "DENY")
    response.headers.setdefault("Referrer-Policy", "no-referrer")
    response.headers.setdefault("Cache-Control", "no-store")
    return response


def _client_key(request: Request) -> str:
    forwarded_for = request.headers.get("x-forwarded-for")
    if TRUST_PROXY_HEADERS and forwarded_for:
        return forwarded_for.split(",", 1)[0].strip()
    return request.client.host if request.client else "unknown"


def _check_rate_limit(request: Request) -> None:
    try:
        rate_limiter.check(_client_key(request))
    except RateLimitExceeded as exc:
        raise HTTPException(
            status_code=429,
            detail="Too many requests. Please try again later.",
            headers={"Retry-After": str(exc.retry_after)},
        ) from exc


def _log_request(req: AskRequest, stream: bool) -> None:
    logger.info("=" * 60)
    logger.info("RECEIVED NEW %sREQUEST", "STREAMING " if stream else "")
    logger.info("  Client input length: %s", len(req.text))
    logger.info("  User profile: name_provided=%s, age=%s", bool(req.name), req.age)
    logger.info("  Interests provided: %s", bool(req.interests))
    logger.info("  Language: %s", req.language)
    logger.info("=" * 60)


def _raise_llm_http_error(exc: Exception) -> None:
    if isinstance(exc, LLMConnectionError):
        raise HTTPException(status_code=503, detail="LLM service is unavailable") from exc
    if isinstance(exc, LLMTimeoutError):
        raise HTTPException(status_code=504, detail="LLM service timed out") from exc
    if isinstance(exc, LLMResponseError):
        raise HTTPException(status_code=502, detail="LLM service returned an invalid response") from exc
    raise HTTPException(status_code=500, detail="Internal server error") from exc

@app.get("/")
def health():
    logger.info("Health check endpoint called")
    return {
        "status": "LittleMind AI running",
        "model": MODEL_NAME,
        "rate_limit": {
            "requests": RATE_LIMIT_REQUESTS,
            "window_seconds": RATE_LIMIT_WINDOW_SECONDS,
        },
    }

@app.post("/ask", response_model=AskResponse)
def ask(req: AskRequest, request: Request):
    _check_rate_limit(request)
    request_start_time = time.time()
    
    _log_request(req, stream=False)
    
    # Build prompt
    logger.info("Building prompt based on user input...")
    system_prompt, user_message, mode = build_prompt(req)
    logger.info(f"  Mode: '{mode}'")
    logger.info(f"  System prompt length: {len(system_prompt)} characters")
    logger.info(f"  User message length: {len(user_message)} characters")

    # Call LLM
    logger.info(f"Sending request to LLM ({MODEL_NAME}) at {OLLAMA_URL}...")
    llm_start_time = time.time()
    try:
        response = generate_response(user_message, system_prompt)
    except (LLMConnectionError, LLMTimeoutError, LLMResponseError) as exc:
        _raise_llm_http_error(exc)
    llm_elapsed = time.time() - llm_start_time
    logger.info(f"LLM response received in {llm_elapsed:.2f} seconds")
    
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
def ask_stream(req: AskRequest, request: Request):
    _check_rate_limit(request)
    _log_request(req, stream=True)
    
    # Build prompt
    system_prompt, user_message, mode = build_prompt(req)
    
    def event_generator():
        yield f"data: {json.dumps({'response': '', 'mode': mode})}\n\n"
        
        for chunk in generate_response_stream(user_message, system_prompt):
            yield f"data: {json.dumps({'response': chunk, 'mode': mode})}\n\n"
            
        yield "data: [DONE]\n\n"
            
    return StreamingResponse(event_generator(), media_type="text/event-stream")
