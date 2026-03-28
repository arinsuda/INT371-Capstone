from __future__ import annotations

from pydantic import BaseModel, Field


class OCRItem(BaseModel):
    text: str
    confidence: float = Field(..., ge=0.0, le=1.0)
    bbox: list


class OrientationMeta(BaseModel):
    rotation_applied_deg: int = 0


class OCRResponse(BaseModel):
    request_id: str
    elapsed_ms: float
    id_number: str | None
    valid: bool
    name_raw: str
    orientation: OrientationMeta | None = None
    debug: dict | None = None


class BatchItemResult(BaseModel):
    """Result for a single image within a batch request."""

    filename: str
    index: int
    success: bool
    id_number: str | None = None
    valid: bool = False
    name_raw: str = ""
    orientation: OrientationMeta | None = None
    error: str | None = None


class BatchOCRResponse(BaseModel):
    request_id: str
    elapsed_ms: float
    total: int
    succeeded: int
    failed: int
    results: list[BatchItemResult]


class ErrorResponse(BaseModel):
    success: bool = False
    error: str
    message: str
    request_id: str | None = None


class HealthResponse(BaseModel):
    status: str
    languages: list[str]
    gpu: bool
