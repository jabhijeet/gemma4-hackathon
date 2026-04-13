from pydantic import BaseModel

class AskRequest(BaseModel):
    text: str
    name: str | None = None
    age: int = 5
    interests: str | None = None
    language: str = "english"
    mode: str | None = None  # 'story', 'emotion', 'parent', or None for auto-detect

class AskResponse(BaseModel):
    response: str
    mode: str