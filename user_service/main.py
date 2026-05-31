from fastapi import FastAPI, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import sessionmaker, declarative_base, Session
import bcrypt

DATABASE_URL = "postgresql://postgres:postgres@postgres:5432/users"
engine = create_engine(DATABASE_URL, echo=False)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=True)

class UserCreate(BaseModel):
    email: str
    password: str
    full_name: str | None = None

app = FastAPI(title="YouScout User Service")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.post("/users", status_code=status.HTTP_201_CREATED)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    hashed = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    db_user = User(email=user.email, hashed_password=hashed, full_name=user.full_name)
    db.add(db_user)
    try:
        db.commit()
        db.refresh(db_user)
    except Exception:
        db.rollback()
        raise HTTPException(status_code=400, detail="User could not be created")
    return {"id": db_user.id, "email": db_user.email, "full_name": db_user.full_name}

@app.get("/users/{user_id}")
def read_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {"id": user.id, "email": user.email, "full_name": user.full_name}

@app.get("/users")
def list_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    users = db.query(User).offset(skip).limit(limit).all()
    return [{"id": u.id, "email": u.email, "full_name": u.full_name} for u in users]
