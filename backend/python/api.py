from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import spiral_app
import kisametintesti
import cognitive_test
import meander_app

app = FastAPI()

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
    meander_app.router,
    prefix="/meander",
    tags=["meander"]
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

@app.get("/")
async def root():
    return {"message": "Neurograph API is running!", "status": "ok"}