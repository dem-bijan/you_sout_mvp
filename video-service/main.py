from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel
from typing import List

app = FastAPI(title="YouScout Video Service")

# In‑memory store for demo purposes
videos: List[dict] = []

class VideoCreate(BaseModel):
    title: str
    description: str | None = None
    url: str | None = None  # placeholder for actual storage URL

@app.post("/videos", status_code=status.HTTP_201_CREATED)
def create_video(video: VideoCreate):
    video_dict = video.dict()
    video_dict["id"] = len(videos) + 1
    videos.append(video_dict)
    return {"msg": "video created", "video": video_dict}

@app.get("/videos")
def list_videos():
    return videos

@app.get("/videos/{video_id}")
def get_video(video_id: int):
    for v in videos:
        if v["id"] == video_id:
            return v
    raise HTTPException(status_code=404, detail="Video not found")
