"""Create demo data directly via ORM, bypassing API gateway requirements."""
import asyncio
from uuid import uuid4
from datetime import datetime
from sqlmodel import select

# We need to set env vars before importing app
import os
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///./dev_mission_control.db")
os.environ.setdefault("AUTH_MODE", "local")
os.environ.setdefault("LOCAL_AUTH_TOKEN", "dev-local-auth-token-0123456789-0123456789-01234567890123456789")

from sqlmodel.ext.asyncio.session import AsyncSession
from app.db.session import async_engine, async_session_maker, init_db
from app.models.organizations import Organization
from app.models.board_groups import BoardGroup
from app.models.boards import Board
from app.models.gateways import Gateway
from app.models.tasks import Task
from app.models.tags import Tag
from app.models.users import User

async def main():
    async with async_session_maker() as session:
        # Check if data already exists
        result = await session.exec(select(Organization))
        org = result.first()
        if org:
            print(f"Data already exists: {org.name}")
            return
        
        print("Creating demo data...")
        
        # Create a fake user
        user_id = uuid4()
        user = User(
            id=user_id,
            email="eval@local.dev",
            name="Evaluator",
        )
        session.add(user)
        await session.flush()
        print(f"User: {user.name} ({user.id})")
        
        # Create organization
        org_id = uuid4()
        org = Organization(
            id=org_id,
            name="Demo Organization",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        session.add(org)
        await session.flush()
        print(f"Org: {org.name} ({org.id})")
        
        # Create gateway
        gw_id = uuid4()
        gateway = Gateway(
            id=gw_id,
            organization_id=org.id,
            name="Local Dev Gateway",
            url="ws://localhost:8789",
            workspace_root="/tmp",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        session.add(gateway)
        await session.flush()
        print(f"Gateway: {gateway.name} ({gateway.id})")
        
        # Create board group
        group_id = uuid4()
        group = BoardGroup(
            id=group_id,
            organization_id=org.id,
            name="Engineering",
            slug="engineering",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        session.add(group)
        await session.flush()
        print(f"Group: {group.name} ({group.id})")
        
        # Create board
        board_id = uuid4()
        board = Board(
            id=board_id,
            organization_id=org.id,
            name="Sprint Board",
            slug="sprint-board",
            description="Framework evaluation sprint",
            gateway_id=gateway.id,
            board_group_id=group.id,
            objective="Evaluate framework candidate",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        session.add(board)
        await session.flush()
        print(f"Board: {board.name} ({board.id})")
        
        # Create tags
        bug_tag = Tag(id=uuid4(), organization_id=org.id, name="bug", color="ef4444", created_at=datetime.utcnow(), updated_at=datetime.utcnow())
        feat_tag = Tag(id=uuid4(), organization_id=org.id, name="feature", color="3b82f6", created_at=datetime.utcnow(), updated_at=datetime.utcnow())
        urgent_tag = Tag(id=uuid4(), organization_id=org.id, name="urgent", color="f59e0b", created_at=datetime.utcnow(), updated_at=datetime.utcnow())
        session.add_all([bug_tag, feat_tag, urgent_tag])
        await session.flush()
        print(f"Tags: bug, feature, urgent")
        
        # Create tasks in various statuses
        tasks = [
            Task(id=uuid4(), board_id=board.id, title="Review framework architecture", description="Analyze the candidate framework codebase", status="inbox", priority="high", created_at=datetime.utcnow(), updated_at=datetime.utcnow()),
            Task(id=uuid4(), board_id=board.id, title="Setup local dev environment", description="Get the framework running locally", status="inbox", priority="medium", created_at=datetime.utcnow(), updated_at=datetime.utcnow()),
            Task(id=uuid4(), board_id=board.id, title="Evaluate frontend components", description="Review React components and UI patterns", status="inbox", priority="medium", created_at=datetime.utcnow(), updated_at=datetime.utcnow()),
            Task(id=uuid4(), board_id=board.id, title="Test API endpoints", description="Verify REST API functionality", status="in_progress", priority="medium", created_at=datetime.utcnow(), updated_at=datetime.utcnow()),
            Task(id=uuid4(), board_id=board.id, title="Review database models", description="Compare SQLModel schemas with our current approach", status="in_progress", priority="high", created_at=datetime.utcnow(), updated_at=datetime.utcnow()),
            Task(id=uuid4(), board_id=board.id, title="Evaluate approval workflow", description="Test the approval system for tasks", status="in_progress", priority="low", created_at=datetime.utcnow(), updated_at=datetime.utcnow()),
            Task(id=uuid4(), board_id=board.id, title="Compare with current MC", description="Side-by-side feature comparison", status="review", priority="high", created_at=datetime.utcnow(), updated_at=datetime.utcnow()),
            Task(id=uuid4(), board_id=board.id, title="Write migration plan", description="Document the migration roadmap", status="review", priority="medium", created_at=datetime.utcnow(), updated_at=datetime.utcnow()),
            Task(id=uuid4(), board_id=board.id, title="Framework documentation review", description="Read through all docs and README", status="done", priority="low", created_at=datetime.utcnow(), updated_at=datetime.utcnow()),
            Task(id=uuid4(), board_id=board.id, title="Initial code checkout", description="Clone and explore the repository", status="done", priority="high", created_at=datetime.utcnow(), updated_at=datetime.utcnow()),
        ]
        session.add_all(tasks)
        await session.flush()
        print(f"Created {len(tasks)} tasks")
        
        await session.commit()
        print("Demo data created successfully!")
        print(f"\nUser ID for auth: {user.id}")

if __name__ == "__main__":
    asyncio.run(main())
