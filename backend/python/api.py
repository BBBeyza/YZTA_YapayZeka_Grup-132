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

app.include_router(
    meander_app.router, 
    prefix="/meander", 
    tags=["meander"]
)

app.include_router(
    clock_drawing_app.router, 
    prefix="/clock", 
    tags=["clock"]
)

app.include_router(
    handwriting_analyzer.router, 
    prefix="/handwriting", 
    tags=["handwriting"]
)

@app.get("/")
async def root():
    return {"message": "Neurograph API is running!", "status": "ok"}