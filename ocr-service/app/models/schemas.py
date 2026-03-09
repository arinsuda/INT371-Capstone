from __future__ import annotations

from typing import Any
from pydantic import BaseModel, Field


class BBox(BaseModel):
    top_left: list[float]
    top_right: list[float]
    bottom_right: list[float]
    bottom_left: list[float]

    @classmethod
    def from_easyocr(cls, bbox: list[list[float]]) -> "BBox":
        return cls(
            top_left=bbox[0],
            top_right=bbox[1],
            bottom_right=bbox[2],
            bottom_left=bbox[3],
        )


class OCRItem(BaseModel):
    text: str
    confidence: float = Field(..., ge=0.0, le=1.0)
    bbox: BBox


class PreprocessingMeta(BaseModel):
    original_width: int
    original_height: int
    processed_width: int | None = None
    processed_height: int | None = None
    preprocessing_steps: list[str] = []


class OCRResponse(BaseModel):
    success: bool = True
    count: int
    items: list[OCRItem]
    request_id: str | None = None
    elapsed_ms: float | None = None
    preprocessing: PreprocessingMeta | None = None


class HealthResponse(BaseModel):
    status: str
    version: str
    engine: str
    languages: list[str]
    gpu: bool
    workers: int


class ErrorResponse(BaseModel):
    success: bool = False
    error: str
    message: str
    request_id: str | None = None