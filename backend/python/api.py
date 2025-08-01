from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import spiral_app
import kisametintesti
import cognitive_test
import meander_app
import clock_drawing_app
import handwriting_analyzer
import logging

app = FastAPI()
logger = logging.getLogger("uvicorn.error")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(
    spiral_app.router,
    prefix="/spiral",
    tags=["spiral"]
)

app.include_router(
    kisametintesti.router,
    prefix="/text",
    tags=["text"]
)

app.include_router(
    cognitive_test.router,
    prefix="/cognitive",
    tags=["cognitive"]
)

try:
    import meander_app
    app.include_router(meander_app.router, prefix="/meander", tags=["meander"])
    logger.info("[OK] meander_app başarıyla yüklendi")
except Exception as e:
    logger.error("[ERROR] meander_app yüklenemedi: %s", e)

try:
    import clock_drawing_app
    app.include_router(clock_drawing_app.router, prefix="/clock", tags=["clock"])
    logger.info("[OK] clock_drawing_app başarıyla yüklendi")
except Exception as e:
    logger.error("[ERROR] clock_drawing_app yüklenemedi: %s", e)

try:
    import handwriting_analyzer
    app.include_router(handwriting_analyzer.router, prefix="/handwriting", tags=["handwriting"])
    logger.info("[OK] handwriting_analyzer başarıyla yüklendi")
except Exception as e:
    logger.error("[ERROR] handwriting_analyzer yüklenemedi: %s", e)

@app.get("/")
async def root():
    return {"message": "Neurograph API is running!", "status": "ok"}