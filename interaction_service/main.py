from fastapi import FastAPI, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, ForeignKey
from sqlalchemy.orm import sessionmaker, declarative_base, Session

DATABASE_URL = "mongodb://mongo:27017/interactions"
# For simplicity, using in‑memory list (real implementation would use MongoDB driver)

app = FastAPI(title="YouScout Interaction Service")

# Simple in‑memory storage for demonstration
interactions = []

class InteractionCreate(BaseModel):
    video_id: int
    user_id: int
    like: bool = False
    rating: int | None = None

@app.post("/interactions", status_code=status.HTTP_201_CREATED)
def create_interaction(inter: InteractionCreate):
    interactions.append(inter.dict())
    return {"msg": "interaction recorded"}

@app.get("/interactions/{video_id}")
def get_interactions(video_id: int):
    filtered = [i for i in interactions if i["video_id"] == video_id]
    return filtered
