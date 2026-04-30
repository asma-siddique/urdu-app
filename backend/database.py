import os
import uuid
from datetime import datetime
from sqlalchemy import (
    create_engine, Column, String, Float, Integer,
    DateTime, ForeignKey, JSON
)
from sqlalchemy.orm import declarative_base, sessionmaker, relationship

DATABASE_URL = os.environ.get('DATABASE_URL', 'sqlite:///./urdu_app.db')

if DATABASE_URL.startswith('postgres://'):
    DATABASE_URL = DATABASE_URL.replace('postgres://', 'postgresql://', 1)

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if 'sqlite' in DATABASE_URL else {},
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class User(Base):
    __tablename__ = 'users'
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False, default='Student')
    avatar = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    sessions = relationship('Session', back_populates='user', cascade='all, delete-orphan')
    word_attempts = relationship('WordAttempt', back_populates='user', cascade='all, delete-orphan')
    phoneme_scores = relationship('PhonemeScore', back_populates='user', cascade='all, delete-orphan')
    profile = relationship('StudentProfile', back_populates='user', uselist=False, cascade='all, delete-orphan')


class Session(Base):
    __tablename__ = 'sessions'
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey('users.id'), nullable=False)
    module = Column(String, nullable=False)
    score = Column(Float, nullable=False, default=0.0)
    stars = Column(Integer, nullable=False, default=0)
    duration_s = Column(Integer, nullable=False, default=0)
    completed_at = Column(DateTime, default=datetime.utcnow)
    user = relationship('User', back_populates='sessions')


class WordAttempt(Base):
    __tablename__ = 'word_attempts'
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey('users.id'), nullable=False)
    word_id = Column(String, nullable=False)
    word_urdu = Column(String, nullable=False)
    score = Column(Float, nullable=False, default=0.0)
    attempts = Column(Integer, nullable=False, default=0)
    last_seen = Column(DateTime, default=datetime.utcnow)
    user = relationship('User', back_populates='word_attempts')


class PhonemeScore(Base):
    __tablename__ = 'phoneme_scores'
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey('users.id'), nullable=False)
    phoneme = Column(String, nullable=False)
    score = Column(Float, nullable=False, default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)
    user = relationship('User', back_populates='phoneme_scores')


class StudentProfile(Base):
    __tablename__ = 'student_profiles'
    user_id = Column(String, ForeignKey('users.id'), primary_key=True)
    cluster_id = Column(Integer, nullable=False, default=0)
    features = Column(JSON, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    user = relationship('User', back_populates='profile')


Base.metadata.create_all(bind=engine)