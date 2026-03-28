from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.core.engine import ocr_engine
from app.api.routes import router


@asynccontextmanager
async def lifespan(app: FastAPI):
    await ocr_engine.initialize()
    yield


app = FastAPI(lifespan=lifespan)

app.include_router(router)