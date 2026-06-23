"""Initialize SQLite database for local dev evaluation."""
import asyncio
from sqlmodel import SQLModel, create_engine
from app.core.config import settings

def main():
    print(f"Creating SQLite database at: {settings.database_url}")
    # Strip the aiosqlite+ prefix for the sync create_engine call
    sqlite_url = settings.database_url.replace("sqlite+aiosqlite:///", "sqlite:///")
    engine = create_engine(sqlite_url, echo=True)
    SQLModel.metadata.create_all(engine)
    print("Database tables created successfully.")

if __name__ == "__main__":
    main()
