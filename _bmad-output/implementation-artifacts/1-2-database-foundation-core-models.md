# Story 1.2: Database Foundation — Core Models

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want to create the core database models for Projects, Features, and audit logging,
So that I can store user data with proper structure and relationships.

## Acceptance Criteria

**Given** SQLAlchemy and Alembic are installed
**When** I create models/base.py with Base declarative class
**Then** all models inherit from Base

**Given** Base class exists
**When** I create models/project.py
**Then** Project model has fields: id (PK), name (String 200, unique), description (Text, nullable), status (String 50, default='active'), created_at (DateTime), updated_at (DateTime)

**Given** Project model exists
**When** I create models/feature.py
**Then** Feature model has fields: id (PK), project_id (FK to Project), name (String 200), description (Text, nullable), status (String 50, default='backlog'), status_reason (Text, nullable), assigned_teams (Text, nullable), assigned_po (String 100, nullable), release_id (FK to Release, nullable), created_at, updated_at
**And** Feature has relationship to Project (many-to-one)

**Given** Base models are created
**When** I create models/event_log.py
**Then** EventLog model has fields: id (PK), user_id (String 100), action (String 100), entity_type (String 50), entity_id (Integer), timestamp (DateTime, default=now), details (JSON), created_at
**And** EventLog is append-only (no update/delete methods)

**Given** Base models are created
**When** I create models/user_context.py
**Then** UserContext model has fields: user_id (String 100, PK), active_project_id (FK to Project, nullable), updated_at
**And** UserContext has relationship to Project

**Given** Base models are created
**When** I create models/processed_message.py
**Then** ProcessedMessage model has fields: message_id (String 100, PK, unique), processed_at (DateTime, default=now)

**Given** all models are created
**When** I run `alembic revision --autogenerate -m "initial schema"`
**Then** migration file is generated in alembic/versions/
**And** migration includes create_table for Project, Feature, EventLog, UserContext, ProcessedMessage

**Given** migration is generated
**When** I run `alembic upgrade head`
**Then** all tables are created in PostgreSQL
**And** I can query tables using psql or SQLAlchemy session

## Tasks / Subtasks

- [x] Task 1: Create base declarative model (AC: 1)
  - [x] Subtask 1.1: Create models/base.py with SQLAlchemy declarative_base
  - [x] Subtask 1.2: Configure Base with common timestamp columns (created_at, updated_at)
  - [x] Subtask 1.3: Add __repr__ helper for debugging
  - [x] Subtask 1.4: Update models/__init__.py to export Base

- [x] Task 2: Implement Project model (AC: 2)
  - [x] Subtask 2.1: Create models/project.py with all required fields
  - [x] Subtask 2.2: Add unique constraint on name field
  - [x] Subtask 2.3: Add table name and indexes
  - [x] Subtask 2.4: Implement __repr__ for logging
  - [x] Subtask 2.5: Update models/__init__.py to export Project

- [x] Task 3: Implement Feature model with relationships (AC: 3)
  - [x] Subtask 3.1: Create models/feature.py with all required fields
  - [x] Subtask 3.2: Add foreign key relationship to Project (project_id)
  - [x] Subtask 3.3: Add foreign key relationship to Release (release_id, nullable)
  - [x] Subtask 3.4: Configure SQLAlchemy relationship() to Project (many-to-one)
  - [x] Subtask 3.5: Add indexes on project_id, status, release_id
  - [x] Subtask 3.6: Update models/__init__.py to export Feature

- [x] Task 4: Implement EventLog model for audit trail (AC: 4)
  - [x] Subtask 4.1: Create models/event_log.py with all required fields
  - [x] Subtask 4.2: Configure details field as JSON type
  - [x] Subtask 4.3: Add timestamp default to current time
  - [x] Subtask 4.4: Add comment: "Append-only audit trail - no updates or deletes"
  - [x] Subtask 4.5: Add indexes on user_id, entity_type, timestamp
  - [x] Subtask 4.6: Update models/__init__.py to export EventLog

- [x] Task 5: Implement UserContext model (AC: 5)
  - [x] Subtask 5.1: Create models/user_context.py with user_id as primary key
  - [x] Subtask 5.2: Add foreign key relationship to Project (active_project_id, nullable)
  - [x] Subtask 5.3: Configure SQLAlchemy relationship() to Project
  - [x] Subtask 5.4: Add updated_at field with auto-update on modification
  - [x] Subtask 5.5: Update models/__init__.py to export UserContext

- [x] Task 6: Implement ProcessedMessage model for idempotency (AC: 6)
  - [x] Subtask 6.1: Create models/processed_message.py with message_id as primary key
  - [x] Subtask 6.2: Add unique constraint on message_id
  - [x] Subtask 6.3: Add processed_at field with default=now
  - [x] Subtask 6.4: Add index on message_id for fast lookup
  - [x] Subtask 6.5: Update models/__init__.py to export ProcessedMessage

- [x] Task 7: Create Release model stub (required by Feature FK) (AC: 3)
  - [x] Subtask 7.1: Create models/release.py with minimal fields: id, project_id, version, target_date, status
  - [x] Subtask 7.2: Add foreign key to Project
  - [x] Subtask 7.3: Add relationship to Project
  - [x] Subtask 7.4: Update models/__init__.py to export Release
  - [x] Subtask 7.5: Add comment: "Full implementation in Story 1.5"

- [x] Task 8: Generate Alembic migration (AC: 7)
  - [x] Subtask 8.1: Verify alembic/env.py imports all models
  - [x] Subtask 8.2: Run `alembic revision --autogenerate -m "initial schema"`
  - [x] Subtask 8.3: Review generated migration file for correctness
  - [x] Subtask 8.4: Verify all tables, foreign keys, and indexes are included

- [x] Task 9: Apply migration and validate database (AC: 8)
  - [x] Subtask 9.1: Run `alembic upgrade head` against test database
  - [x] Subtask 9.2: Verify all tables created using psql or SQLAlchemy inspector
  - [x] Subtask 9.3: Test inserting sample Project, Feature records
  - [x] Subtask 9.4: Test foreign key constraints work correctly
  - [x] Subtask 9.5: Verify EventLog append-only behavior

## Dev Notes

### Critical Architecture Context

**Database Strategy (from Architecture.md):**
- PostgreSQL with strict relational schema
- SQLAlchemy 2.0 ORM for Python → SQL mapping
- Alembic for automatic schema migrations
- Append-only EventLog for audit trail
- Foreign keys with CASCADE on delete for referential integrity

**MVP Constraints:**
- Single user (Artem) - no multi-tenancy needed
- Tables designed for 10k-100k records (sufficient for MVP)
- No advanced indexing or partitioning needed initially

**Core Database Models (from epics.md#Epic 1 Story 1.2):**

```python
# models/project.py
class Project:
    id, name, description, status, created_at, updated_at

# models/feature.py
class Feature:
    id, project_id, name, description, status, status_reason,
    assigned_teams, assigned_po, release_id, created_at, updated_at

# models/release.py (stub for FK, full implementation in Story 1.5)
class Release:
    id, project_id, version, target_date, status, created_at

# models/event_log.py
class EventLog:
    id, user_id, action, entity_type, entity_id,
    timestamp, details (JSON), created_at

# models/user_context.py
class UserContext:
    user_id, active_project_id, updated_at

# models/processed_message.py
class ProcessedMessage:
    message_id (unique), processed_at
```

**Idempotency Strategy (from Architecture.md#Cross-Cutting Concerns):**
- Every Telegram message has unique `message_id`
- ProcessedMessage table acts as deduplication check
- Before processing: `if message_id in processed_messages: skip`
- Prevents duplicate operations on retry

**Audit Trail Strategy (from Architecture.md#Cross-Cutting Concerns):**
- EventLog is append-only (never updated or deleted)
- Records: who (user_id), what (action), when (timestamp), where (entity_type/entity_id)
- Details field (JSON) stores additional context
- Used for "История изменений" feature in Radar

**Context Resolver Strategy (from Architecture.md#Cross-Cutting Concerns):**
- UserContext table stores active_project_id per user
- All commands execute in context of active project
- "Переключись на проект X" updates active_project_id
- Every response starts with "Контекст: Проект X"

### Technical Requirements

**SQLAlchemy 2.0 Patterns:**
- Use declarative_base() for Base class
- Use Mapped[T] type hints for modern type safety
- Use relationship() for bidirectional navigation
- Use ForeignKey with ondelete='CASCADE' for cleanup
- Configure repr=False on relationships to avoid circular repr

**Field Types:**
- id: Integer, primary_key=True, autoincrement
- name/title: String(200), not nullable
- description/reason: Text, nullable=True
- status: String(50), default='active'/'backlog'
- timestamps: DateTime, default=func.now()
- JSON fields: JSON type from sqlalchemy.dialects.postgresql

**Naming Conventions:**
- Table names: lowercase with underscores (e.g., event_log, user_context)
- Column names: snake_case matching Python field names
- Foreign keys: {entity}_id (e.g., project_id, release_id)
- Indexes: idx_{table}_{column} (e.g., idx_feature_status)

**Migration Best Practices:**
- Always review autogenerated migrations before applying
- Add comments for non-obvious constraints
- Test migrations on empty database first
- Keep migrations reversible (implement downgrade)

### Architecture Compliance Requirements

**From Architecture.md - Database Schema Decision:**
- ✅ Relational tables with strict structure (NOT NoSQL/document store)
- ✅ Explicit foreign keys for relationships
- ✅ Normalized schema (no denormalization in MVP)
- ✅ PostgreSQL-specific features allowed (JSON type, array types if needed)

**From PRD v0.7 - Data Model:**
- ✅ Project ↔ Features ↔ Releases relationships
- ✅ EventLog for audit trail of all mutations
- ✅ UserContext for active project tracking
- ✅ ProcessedMessage for idempotency guarantee

**From UX Design - System Constraints:**
- ✅ All responses include current context (active_project_id lookup)
- ✅ History tracking for "Что изменилось?" command (EventLog queries)
- ✅ Support for "Отмени последнее" (EventLog provides rollback context)

### Library/Framework Requirements

**SQLAlchemy 2.0.46 (from Story 1.1):**
- Upgraded from 2.0.0 for Python 3.14 compatibility
- Use modern `Mapped[T]` type hints instead of Column()
- Use `relationship()` for ORM navigation
- Import from `sqlalchemy.orm` for declarative patterns

**Alembic 1.18.1 (from Story 1.1):**
- Already initialized with `alembic init alembic`
- Configuration in alembic.ini points to config.py for DATABASE_URL
- Autogenerate requires target_metadata = Base.metadata in env.py

**PostgreSQL Specific:**
- JSON column type: `from sqlalchemy.dialects.postgresql import JSON`
- Timestamp with timezone: use `DateTime(timezone=True)` if needed
- Unique constraints: use `unique=True` on Column or UniqueConstraint

### File Structure Requirements

**Project structure (from Story 1.1):**
```
uber-po-bot/
├── models/
│   ├── __init__.py          # Export all models
│   ├── base.py              # Base declarative class
│   ├── project.py           # Project model
│   ├── feature.py           # Feature model
│   ├── release.py           # Release model (stub)
│   ├── event_log.py         # EventLog model
│   ├── user_context.py      # UserContext model
│   └── processed_message.py # ProcessedMessage model
└── alembic/
    ├── versions/            # Migration files generated here
    └── env.py              # Must import Base.metadata
```

**models/__init__.py must export:**
```python
from models.base import Base
from models.project import Project
from models.feature import Feature
from models.release import Release
from models.event_log import EventLog
from models.user_context import UserContext
from models.processed_message import ProcessedMessage

__all__ = [
    "Base",
    "Project",
    "Feature",
    "Release",
    "EventLog",
    "UserContext",
    "ProcessedMessage",
]
```

### Testing Requirements

**Manual Validation (MVP):**
- Verify all tables created with correct schema
- Test foreign key constraints (insert valid/invalid references)
- Test unique constraints (duplicate project names)
- Test default values (status='backlog', timestamps)
- Verify EventLog records created_at timestamp

**Database Inspection:**
```bash
# Connect to PostgreSQL
psql $DATABASE_URL

# List tables
\dt

# Describe table schema
\d projects
\d features
\d event_log

# Test insert
INSERT INTO projects (name, description, status)
VALUES ('Test Project', 'Test description', 'active');

# Verify foreign key
INSERT INTO features (project_id, name, status)
VALUES (1, 'Test Feature', 'backlog');
```

**Automated tests deferred to Story 1.5 (Testing Infrastructure)**

### Previous Story Intelligence

**From Story 1.1 (Project Initialization & Setup):**

**Key Learnings:**
1. SQLAlchemy upgraded to 2.0.46 for Python 3.14 compatibility
2. All functions use type hints for better IDE support
3. Configuration validation detects placeholder values in .env
4. Git repository not initialized (working directory only)

**Code Patterns Established:**
- Type hints on all functions: `def function() -> ReturnType:`
- Configuration validation with descriptive error messages
- Environment variable loading via python-dotenv
- Graceful error handling with try/except and logging

**Files Created (Relevant to This Story):**
- `models/__init__.py` - Empty package init (needs model exports)
- `alembic/env.py` - Alembic environment (needs Base.metadata import)
- `alembic.ini` - Alembic configuration (DATABASE_URL from config.py)
- `config.py` - Configuration loader (DATABASE_URL available)

**Problems Encountered:**
1. SQLAlchemy 2.0.0 incompatible with Python 3.14 → upgraded to 2.0.46
2. .env placeholder detection added to prevent runtime errors

**Solutions Applied:**
1. Pin SQLAlchemy==2.0.46 in requirements.txt
2. Add placeholder validation in config.py validate_config()

**Dev Notes Reference from Story 1.1:**
- Database migrations will be created in Stories 1.2-1.4 (NOW!)
- Alembic initialized but no migrations yet
- PostgreSQL connection tested via config.py validation

**Implications for Current Story:**
1. ✅ Virtual environment already configured
2. ✅ SQLAlchemy 2.0.46 already installed
3. ✅ Alembic already initialized
4. ✅ DATABASE_URL loaded from .env via config.py
5. ⚠️ Must update alembic/env.py to import Base.metadata
6. ⚠️ Must update models/__init__.py to export all models

### Latest Technical Information

**SQLAlchemy 2.0.46 (Latest Stable - 2026-01-29):**

Key Features:
- Modern type hints with `Mapped[T]` syntax
- Improved async support
- Better performance with compiled queries
- Python 3.14 compatibility fixes

Best Practices:
- Use `Mapped[int]` instead of `Column(Integer)`
- Use `relationship()` with `back_populates` for bidirectional navigation
- Use `func.now()` for timestamp defaults
- Configure `repr=False` on relationships to avoid circular repr

Example Modern SQLAlchemy 2.0 Pattern:
```python
from sqlalchemy import String, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime

class Project(Base):
    __tablename__ = "projects"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(200), unique=True)
    created_at: Mapped[datetime] = mapped_column(default=func.now())

    # Relationship
    features: Mapped[list["Feature"]] = relationship(
        back_populates="project",
        cascade="all, delete-orphan"
    )
```

**Alembic 1.18.1 Best Practices:**

Migration Workflow:
1. Create/modify models in models/ directory
2. Import all models in alembic/env.py (target_metadata = Base.metadata)
3. Run `alembic revision --autogenerate -m "description"`
4. Review generated migration file
5. Run `alembic upgrade head`

Common Issues:
- Forgetting to import new models in env.py → migration incomplete
- Foreign key constraints not detected → manually add in migration
- Default values not captured → review and add manually if needed

**PostgreSQL 14+ Features (from Architecture.md):**
- JSON/JSONB column types for flexible schema
- Generated columns for computed values
- Partial indexes for query optimization
- Foreign key constraints with CASCADE/RESTRICT

### Project Context

**No project-context.md file found** - this is a greenfield project with no existing patterns to follow beyond Architecture decisions.

**Architecture Decisions to Follow:**
1. Database Schema: Relational tables (strict structure) - PostgreSQL + SQLAlchemy ORM
2. Authentication: Hardcoded Telegram ID (deferred to Story 1.3)
3. Background Jobs: APScheduler (deferred to Story 3.2)
4. Deployment: Railway (deferred to Story 4.3)

**Stack Decisions:**
- Python 3.11+ (using 3.14 in Story 1.1)
- Flask 3.0 (initialized in Story 1.1)
- SQLAlchemy 2.0.46 (installed in Story 1.1)
- Alembic 1.18.1 (initialized in Story 1.1)

### References

All technical details sourced from:

**Epic and Story Requirements:**
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 1, Story 1.2] - Acceptance criteria, field definitions
- [Source: _bmad-output/planning-artifacts/epics.md#Requirements Inventory] - Functional requirements FR-001 to FR-014
- [Source: _bmad-output/planning-artifacts/epics.md#Database Schema] - Complete model definitions with field lists

**Architecture Decisions:**
- [Source: _bmad-output/planning-artifacts/architecture.md#Database Schema Decision] - Relational tables, PostgreSQL + SQLAlchemy
- [Source: _bmad-output/planning-artifacts/architecture.md#Cross-Cutting Concerns] - Idempotency, Audit trail, Context Resolver
- [Source: _bmad-output/planning-artifacts/architecture.md#Code Organization] - File structure, naming conventions
- [Source: _bmad-output/planning-artifacts/architecture.md#Technology Versions] - SQLAlchemy 2.0, Alembic 1.18.1, PostgreSQL 14+

**PRD Requirements:**
- [Source: _bmad-output/planning-artifacts/PRD-v0.7.md#User Journeys] - Domain entities (Project, Feature, Release, etc.)
- [Source: _bmad-output/planning-artifacts/PRD-v0.7.md#Principles] - Single Source of Truth (PostgreSQL), Audit trail mandatory

**Previous Story Context:**
- [Source: _bmad-output/implementation-artifacts/1-1-project-initialization-setup.md#Implementation Notes] - SQLAlchemy 2.0.46 upgrade, Database migrations note
- [Source: _bmad-output/implementation-artifacts/1-1-project-initialization-setup.md#File List] - models/__init__.py, alembic/env.py locations

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.5

### Debug Log References

No blockers encountered. Implementation proceeded smoothly following red-green-refactor cycle for all models.

### Code Review Fixes Applied (2026-02-03)

**Adversarial Code Review performed by Amelia (Dev Agent) - 10 issues found and fixed:**

🔴 **CRITICAL ISSUES FIXED (3):**
1. ✅ Project.features relationship uncommented and properly configured with back_populates
2. ✅ Feature relationships missing back_populates - added to both project and release relationships
3. ✅ Release model missing features relationship - added bidirectional navigation

🟡 **MEDIUM ISSUES FIXED (4):**
4. ✅ Duplicate indexes removed (index=True on columns + Index in __table_args__) - affects Project, Feature, EventLog, Release
5. ✅ EventLog composite indexes added - replaced 3 single-column with 2 composite for query performance
6. ✅ Release added __table_args__ with proper index definition
7. ✅ Redundant nullable=True removed from all models (SQLAlchemy 2.0 infers from Mapped[T | None])

🟢 **LOW ISSUES FIXED (3):**
8. ✅ ProcessedMessage redundant unique=True removed (primary_key already implies unique)
9. ✅ ProcessedMessage redundant nullable=False removed
10. ✅ Migration regenerated with all fixes (17dac64f07ba replaces 1f20a53020fe)

**Remaining Known Issues (Deferred):**
- ⚠️ Problem #1: Git submodule (uber-po-bot) changes not committed - files exist but not in git history
- ⚠️ Problem #5: Base.updated_at onupdate may not work for bulk updates (event listener recommended for future)

### Completion Notes List

✅ Implemented all 7 database models using SQLAlchemy 2.0.46 modern patterns:
- Base declarative class with common timestamps and __repr__
- Project model with unique name constraint and status default
- Release model (stub) for Feature FK support
- Feature model with relationships to Project and Release
- EventLog model with JSON details field (append-only audit trail)
- UserContext model for active project tracking
- ProcessedMessage model for idempotency

✅ Generated Alembic migration covering all tables, foreign keys, and indexes
✅ Applied migration successfully to PostgreSQL database
✅ Validated database with comprehensive tests (64 unit tests + manual integration tests)
✅ All foreign key constraints work correctly (CASCADE, SET NULL)
✅ All default values applied correctly (status='active', status='backlog', timestamps)
✅ JSON field in EventLog validated with test data

### File List

**New files created:**
- `models/base.py` - Base declarative class with timestamps and __repr__
- `models/project.py` - Project model
- `models/feature.py` - Feature model with relationships
- `models/release.py` - Release model (stub for Story 1.5)
- `models/event_log.py` - EventLog audit trail model
- `models/user_context.py` - UserContext for active project tracking
- `models/processed_message.py` - ProcessedMessage for idempotency
- `alembic/versions/1f20a53020fe_initial_schema.py` - Initial migration
- `tests/test_models_base.py` - Unit tests for Base (6 tests)
- `tests/test_models_project.py` - Unit tests for Project (10 tests)
- `tests/test_models_feature.py` - Unit tests for Feature (11 tests)
- `tests/test_models_release.py` - Unit tests for Release (6 tests)
- `tests/test_models_event_log.py` - Unit tests for EventLog (12 tests)
- `tests/test_models_user_context.py` - Unit tests for UserContext (10 tests)
- `tests/test_models_processed_message.py` - Unit tests for ProcessedMessage (9 tests)

**Modified files (Code Review Fixes Applied):**
- `models/__init__.py` - Export all 7 models
- `alembic/env.py` - Import Base.metadata and all models for autogenerate
- `models/project.py` - CODE REVIEW FIX: Uncommented features relationship, added releases relationship with back_populates, removed duplicate indexes
- `models/feature.py` - CODE REVIEW FIX: Added back_populates to project/release relationships, removed duplicate indexes, removed redundant nullable=True
- `models/release.py` - CODE REVIEW FIX: Added features relationship with back_populates, added __table_args__ with index
- `models/event_log.py` - CODE REVIEW FIX: Replaced 3 single-column indexes with 2 composite indexes for better query performance
- `models/processed_message.py` - CODE REVIEW FIX: Removed redundant unique=True on primary key, removed redundant nullable=False
- `alembic/versions/1f20a53020fe_initial_schema.py` - DELETED (had duplicate indexes)
- `alembic/versions/17dac64f07ba_initial_schema_with_fixed_relationships_.py` - NEW migration with all code review fixes applied
