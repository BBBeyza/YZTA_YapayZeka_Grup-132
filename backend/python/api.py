from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import spiral_app
import kisametintesti
import cognitive_test

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
    kisametintesti.router,
    prefix="/text",
    tags=["text"]
)

app.include_router(
    cognitive_test.router,
    prefix="/cognitive",
    tags=["cognitive"]
)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)