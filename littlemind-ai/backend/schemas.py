from pydantic import BaseModel, ConfigDict, Field, field_validator

class AskRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")

    text: str = Field(..., min_length=1, max_length=2000)
    name: str | None = Field(default=None, max_length=80)
    age: int = Field(default=5, ge=2, le=12)
    interests: str | None = Field(default=None, max_length=500)
    language: str = Field(default="english", max_length=20)
    mode: str | None = Field(default=None, max_length=20)

    @field_validator("language")
    @classmethod
    def validate_language(cls, value: str) -> str:
        normalized = value.lower()
        if normalized not in {"english", "hinglish"}:
            raise ValueError("language must be english or hinglish")
        return normalized

    @field_validator("mode")
    @classmethod
    def validate_mode(cls, value: str | None) -> str | None:
        if value is None:
            return None
        normalized = value.lower()
        if normalized not in {"story", "emotion", "parent"}:
            raise ValueError("mode must be story, emotion, or parent")
        return normalized

class AskResponse(BaseModel):
    response: str
    mode: str
