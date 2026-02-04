# Story 1.5: Create Project Command via Voice

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Artem,
I want to say "Создай проект Mobile App" and have the project created in the database,
So that I can quickly capture project information without forms.

## Acceptance Criteria

**Given** voice transcription works
**When** I create NLU function `parse_command(transcript)` in bot/handlers/voice.py
**Then** function identifies command type (create_project, create_feature, create_idea, etc.)
**And** function extracts entities (project_name, feature_name, etc.)

**Given** NLU parser exists
**When** transcript is "Создай проект Mobile App"
**Then** parser returns {'command': 'create_project', 'project_name': 'Mobile App'}

**Given** NLU identifies create_project command
**When** I create `handle_create_project(project_name, user_id)` in bot/handlers/commands.py
**Then** function creates new Project in database with name=project_name, status='active'
**And** function creates EventLog entry: action='project_created', entity_type='project', entity_id=new_project_id, details={'name': project_name}

**Given** project creation handler exists
**When** I say "Создай проект Mobile App"
**Then** new Project is inserted into database
**And** bot responds: "✅ Проект 'Mobile App' создан! ID: {project_id}"
**And** EventLog contains project_created entry

**Given** project is created
**When** I create UserContext logic
**Then** newly created project is automatically set as active_project_id in UserContext for this user
**And** bot response includes: "Контекст: Проект Mobile App"

**Given** project creation works
**When** I try to create project with same name "Создай проект Mobile App" again
**Then** bot responds: "⚠️ Проект 'Mobile App' уже существует. ID: {existing_project_id}"
**And** no duplicate project is created

**Given** transcript is ambiguous (e.g., "Создай проект")
**When** NLU parser cannot extract project_name
**Then** bot responds: "❓ Как назвать проект? Скажите: 'Создай проект [название]'"
**And** no project is created

**Given** multiple projects exist
**When** I check UserContext after creating a new project
**Then** active_project_id points to the newly created project
**And** all subsequent commands use this context

## Tasks / Subtasks

- [x] Task 1: Implement NLU parser for command extraction (AC: 1, 2)
  - [x] Subtask 1.1: Create parse_command() function in bot/handlers/voice.py
  - [x] Subtask 1.2: Implement pattern matching for "Создай проект {name}" (regex or GPT-based)
  - [x] Subtask 1.3: Extract project_name from transcript using natural language patterns
  - [x] Subtask 1.4: Return dict with {'command': 'create_project', 'project_name': extracted_name}
  - [x] Subtask 1.5: Handle variations: "Создай проект", "Новый проект", "Добавь проект"
  - [x] Subtask 1.6: Return {'command': 'unknown', 'raw_text': transcript} if no match
  - [x] Subtask 1.7: Add logging for NLU parsing results

- [x] Task 2: Implement project creation handler (AC: 3)
  - [x] Subtask 2.1: Create handle_create_project() in bot/handlers/commands.py
  - [x] Subtask 2.2: Accept parameters: project_name (str), user_id (str)
  - [x] Subtask 2.3: Import Project model from models.project
  - [x] Subtask 2.4: Create new Project instance with name=project_name, status='active'
  - [x] Subtask 2.5: Use get_db_session() to save project to database
  - [x] Subtask 2.6: Create EventLog entry with action='project_created', entity_type='project', entity_id=project.id
  - [x] Subtask 2.7: Store project name in EventLog.details JSON field
  - [x] Subtask 2.8: Return project object or project_id for response generation

- [x] Task 3: Implement duplicate project check (AC: 6)
  - [x] Subtask 3.1: Query Project table for existing project with same name (case-insensitive)
  - [x] Subtask 3.2: If project exists: return error dict {'exists': True, 'project_id': id, 'project_name': name}
  - [x] Subtask 3.3: If project does not exist: proceed with creation
  - [x] Subtask 3.4: Use SQLAlchemy func.lower() for case-insensitive comparison
  - [x] Subtask 3.5: Log duplicate check result (found/not found)

- [x] Task 4: Implement UserContext management (AC: 5, 8)
  - [x] Subtask 4.1: Import UserContext model from models.user_context
  - [x] Subtask 4.2: After project creation: query UserContext for user_id
  - [x] Subtask 4.3: If UserContext exists: update active_project_id to new project_id
  - [x] Subtask 4.4: If UserContext doesn't exist: create new entry with user_id and active_project_id
  - [x] Subtask 4.5: Commit UserContext changes to database
  - [x] Subtask 4.6: Return updated context for response generation

- [x] Task 5: Integrate command routing in voice handler (AC: 4)
  - [x] Subtask 5.1: Modify handle_voice() in bot/handlers/voice.py
  - [x] Subtask 5.2: After transcription: call parse_command(transcript)
  - [x] Subtask 5.3: If command == 'create_project': call handle_create_project(project_name, user_id)
  - [x] Subtask 5.4: If command == 'unknown': respond with "🎤 Распознано: {transcript}" (current behavior)
  - [x] Subtask 5.5: Handle exceptions from command handlers (try/except)
  - [x] Subtask 5.6: Log command routing decision (command type, handler called)

- [x] Task 6: Implement response generation with context (AC: 4, 5)
  - [x] Subtask 6.1: Response generation implemented inline (no separate helper needed)
  - [x] Subtask 6.2: If project created successfully: format "✅ Проект '{name}' создан! ID: {id}\nКонтекст: Проект {name}"
  - [x] Subtask 6.3: If duplicate project: format "⚠️ Проект '{name}' уже существует. ID: {id}"
  - [x] Subtask 6.4: If ambiguous input: format "❓ Как назвать проект? Скажите: 'Создай проект [название]'"
  - [x] Subtask 6.5: Send formatted response using await update.message.reply_text()
  - [x] Subtask 6.6: Log response sent to user (via EventLog)

- [x] Task 7: Handle ambiguous input gracefully (AC: 7)
  - [x] Subtask 7.1: In parse_command(): detect if project_name is empty or too short (< 2 chars)
  - [x] Subtask 7.2: Return {'command': 'ambiguous', 'type': 'create_project', 'missing': 'project_name'}
  - [x] Subtask 7.3: In voice handler: check for 'ambiguous' command
  - [x] Subtask 7.4: Send clarification request to user with specific example
  - [x] Subtask 7.5: Log ambiguous input with transcript for analysis

- [x] Task 8: Implement comprehensive error handling (Integration)
  - [x] Subtask 8.1: Wrap handle_create_project() in try/except
  - [x] Subtask 8.2: Catch SQLAlchemy errors (IntegrityError, OperationalError)
  - [x] Subtask 8.3: Catch general exceptions and log traceback
  - [x] Subtask 8.4: Send user-friendly error message: "Ошибка при создании проекта. Попробуйте ещё раз."
  - [x] Subtask 8.5: Create EventLog entry with action='project_creation_failed', details={'error': error_message}

- [x] Task 9: Unit tests for NLU parser and project creation (Testing)
  - [x] Subtask 9.1: Create tests/unit/test_nlu_parser.py
  - [x] Subtask 9.2: Test parse_command() with various inputs (successful, ambiguous, unknown)
  - [x] Subtask 9.3: Test project name extraction with different patterns
  - [x] Subtask 9.4: Create tests/unit/test_project_creation.py
  - [x] Subtask 9.5: Test handle_create_project() with mocked database
  - [x] Subtask 9.6: Test duplicate project check
  - [x] Subtask 9.7: Test UserContext creation and update
  - [x] Subtask 9.8: Achieved 100% test coverage for new code (28 tests, all passing)

- [ ] Task 10: Integration tests with real database (Testing) - DEFERRED
  - [x] Subtask 10.1: Create tests/integration/test_project_creation_integration.py (created, needs DB migrations)
  - [ ] Subtask 10.2: Test full flow: voice → transcript → NLU → project creation → response (deferred - requires test DB setup)
  - [ ] Subtask 10.3: Test duplicate project creation scenario (deferred)
  - [ ] Subtask 10.4: Verify EventLog entries are created correctly (deferred)
  - [ ] Subtask 10.5: Verify UserContext is updated correctly (deferred)
  - [ ] Subtask 10.6: Test ambiguous input handling end-to-end (deferred)

## Dev Notes

### Critical Architecture Context

**From Architecture.md#Data Architecture (Decision 1.1):**
- Database: PostgreSQL with SQLAlchemy ORM
- Models: Project, UserContext, EventLog already exist (from Story 1.2)
- All mutations must create EventLog entry for audit trail
- UserContext tracks active_project_id for each user

**From Architecture.md#Cross-Cutting Concerns:**
- Context Resolver: Newly created project becomes active_project_id
- Каждый ответ начинается с "Контекст: Проект X"
- EventLog append-only audit trail for all project operations
- User-friendly error messages (no technical jargon)

**From Architecture.md#UX-Specific Requirements:**
- Voice-first interaction: 90% voice, 10% text
- Структурированный output: emoji для визуальных якорей (✅ создано, ⚠️ существует, ❓ уточните)
- Никаких форм — только голос + confirmation кнопки (deferred to future stories)

**From epics.md#Epic 1, Story 1.5 (lines 808-855):**
- NLU function parse_command() identifies command type and extracts entities
- handle_create_project() creates Project in database with EventLog entry
- UserContext automatically set to newly created project
- Duplicate project check prevents duplicate names
- Ambiguous input handling with clarification request

**MVP Constraints (from Architecture.md#MVP Constraints):**
- Single user (Artem) — no multi-user concerns
- AI-assisted development — Claude writes code, Artem tests
- Timeline: 2 weeks total (Story 1.5 is Day 4 of Sprint 1)

### Technical Requirements

**NLU Approaches for MVP:**

**Option 1: Regex Pattern Matching (RECOMMENDED for MVP)**
- Pros: Fast, deterministic, no API calls, easy to debug
- Cons: Limited flexibility, must enumerate patterns
- Implementation:
```python
import re

def parse_command(transcript: str) -> dict:
    # Pattern: "Создай проект {name}"
    match = re.search(r'(создай|создать|новый|добавь|добавить)\s+(проект|project)\s+(.+)', transcript, re.IGNORECASE)
    if match:
        project_name = match.group(3).strip()
        if len(project_name) >= 2:
            return {'command': 'create_project', 'project_name': project_name}
        else:
            return {'command': 'ambiguous', 'type': 'create_project', 'missing': 'project_name'}
    return {'command': 'unknown', 'raw_text': transcript}
```

**Option 2: GPT-based NLU (Future Enhancement)**
- Pros: Flexible, handles variations naturally
- Cons: API cost, latency (~500ms), requires system prompt
- Implementation: Deferred to Epic 2 (Story 2.3 - GPT Integration with System Prompts)

**Recommendation for Story 1.5:** Use regex pattern matching for simplicity and speed. GPT-based NLU can be added later when implementing multi-agent system (Epic 2).

**Database Models (from Story 1.2):**

**Project Model (models/project.py):**
```python
class Project(Base):
    __tablename__ = 'project'

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(200), unique=True, nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(50), nullable=False, default='active')
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())
```

**UserContext Model (models/user_context.py):**
```python
class UserContext(Base):
    __tablename__ = 'user_context'

    user_id: Mapped[str] = mapped_column(String(100), primary_key=True)
    active_project_id: Mapped[int | None] = mapped_column(ForeignKey('project.id'), nullable=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    # Relationship
    active_project: Mapped["Project"] = relationship("Project", foreign_keys=[active_project_id])
```

**EventLog Model (models/event_log.py):**
```python
class EventLog(Base):
    __tablename__ = 'event_log'

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[str] = mapped_column(String(100), nullable=False)
    action: Mapped[str] = mapped_column(String(100), nullable=False)
    entity_type: Mapped[str] = mapped_column(String(50), nullable=False)
    entity_id: Mapped[int | None] = mapped_column(Integer, nullable=True)  # Changed to nullable in Story 1.4
    timestamp: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now())
    details: Mapped[dict] = mapped_column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now())
```

### Architecture Compliance Requirements

**From Architecture.md - Data Architecture (Decision 1.1):**
- ✅ Use SQLAlchemy ORM for database operations
- ✅ Create EventLog entry for project_created action
- ✅ Update UserContext with active_project_id
- ✅ Check for duplicate project names (unique constraint)

**From Architecture.md - Cross-Cutting Concerns:**
- ✅ Context Resolver: Set active_project_id immediately after creation
- ✅ Audit trail: EventLog for all mutations
- ✅ User-friendly error messages: No SQL errors exposed to user
- ✅ Explainability: Response includes project ID for reference

**From epics.md - Epic 1, Story 1.5:**
- ✅ NLU parser identifies command type and extracts entities
- ✅ Project creation with automatic context switching
- ✅ Duplicate project check prevents data integrity issues
- ✅ Ambiguous input handling with helpful guidance
- ✅ Response format: "✅ Проект '{name}' создан! ID: {id}\nКонтекст: Проект {name}"

**From Architecture.md - Error Handling Strategy (Decision 3.3):**
- ✅ Try/Catch with graceful degradation
- ✅ User-friendly error messages (no technical jargon)
- ✅ Logging for all errors (logger.error with traceback)
- ✅ EventLog entry for failed operations (project_creation_failed)

### Library/Framework Requirements

**SQLAlchemy 2.0 (from Story 1.2):**
- Modern Mapped[T] type hints
- query() replaced with select() statements
- session.add() and session.commit() for inserts
- session.query() → session.execute(select(...))

**Example Query Pattern:**
```python
from sqlalchemy import select, func

# Check for duplicate project
stmt = select(Project).where(func.lower(Project.name) == func.lower(project_name))
existing_project = session.execute(stmt).scalar_one_or_none()

if existing_project:
    return {'exists': True, 'project': existing_project}

# Create new project
new_project = Project(name=project_name, status='active')
session.add(new_project)
session.commit()
session.refresh(new_project)  # Get auto-generated ID
```

**Database Session Management (from Story 1.3):**
```python
from database.session import get_db_session

with get_db_session() as session:
    # All database operations here
    # Automatic commit on success, rollback on exception
    pass
```

### File Structure Requirements

**Project structure (from Stories 1.1-1.4):**
```
uber-po-bot/
├── app.py                      # USE - Bot initialization (no changes needed)
├── bot/
│   ├── handlers/
│   │   ├── commands.py         # MODIFY - Add handle_create_project()
│   │   └── voice.py            # MODIFY - Add parse_command() + command routing
│   └── utils.py                # USE - retry_with_backoff() (no changes)
├── database/
│   └── session.py              # USE - get_db_session()
└── models/
    ├── project.py              # USE - Project model
    ├── user_context.py         # USE - UserContext model
    └── event_log.py            # USE - EventLog model
```

**Code Organization:**
- `bot/handlers/voice.py` - Add parse_command() and command routing (MODIFY)
- `bot/handlers/commands.py` - Add handle_create_project() (MODIFY)
- Models, database session - Reuse from Story 1.2 and 1.3 (NO CHANGES)

### Testing Requirements

**Unit Tests:**
- Test parse_command() with various inputs (create project, ambiguous, unknown)
- Test handle_create_project() with mocked database (success, duplicate, error)
- Test UserContext creation and update logic
- Target: 85%+ code coverage for new code

**Integration Tests:**
- Test full flow: transcript → NLU → project creation → EventLog → UserContext → response
- Test duplicate project creation with real database
- Test ambiguous input handling end-to-end
- Verify EventLog entries are created correctly
- Verify UserContext is updated correctly

**Manual E2E Validation:**
1. Start bot: `python app.py`
2. Send voice message: "Создай проект Mobile App"
3. Verify response: "✅ Проект 'Mobile App' создан! ID: 1\nКонтекст: Проект Mobile App"
4. Query database:
```sql
SELECT * FROM project WHERE name = 'Mobile App';
SELECT * FROM user_context WHERE user_id = '{telegram_id}';
SELECT * FROM event_log WHERE action = 'project_created' ORDER BY timestamp DESC LIMIT 1;
```
5. Send voice message again: "Создай проект Mobile App"
6. Verify response: "⚠️ Проект 'Mobile App' уже существует. ID: 1"
7. Send voice message: "Создай проект" (ambiguous)
8. Verify response: "❓ Как назвать проект? Скажите: 'Создай проект [название]'"

### Previous Story Intelligence

**From Story 1.4 (Voice Recognition with Whisper API):**

**Key Learnings:**
1. ✅ Voice handler structure established in bot/handlers/voice.py
2. ✅ handle_voice() processes voice messages and calls Whisper API
3. ✅ Transcript returned as text: "🎤 Распознано: {transcript_text}"
4. ✅ EventLog entries created for voice_transcribed action
5. ✅ ProcessedMessage ensures idempotency
6. ✅ Error handling with retry logic (3 retries, exponential backoff)
7. ✅ User-friendly error messages established

**Code Patterns Established:**
- ✅ Async handlers: `async def handle_voice(update: Update, context: ContextTypes.DEFAULT_TYPE)`
- ✅ Authorization check: `if not is_authorized(update): return`
- ✅ Database session: `with get_db_session() as session:`
- ✅ EventLog entries: `EventLog(user_id=str(user_id), action='action_name', ...)`
- ✅ Response format: Emoji + structured text

**Integration Point for Story 1.5:**
- ✅ Modify handle_voice() to add command routing after transcription
- ✅ Call parse_command(transcript) to identify command type
- ✅ Route to handle_create_project() if command == 'create_project'
- ✅ Keep existing transcription response for unknown commands

**From Story 1.3 (Telegram Bot Integration & Authentication):**

**Key Learnings:**
1. ✅ is_authorized() function exists in bot/handlers/commands.py
2. ✅ start_command() handler creates EventLog entry for bot_started
3. ✅ User-friendly messages established: "Привет, Artem! 👋 ..."

**Code Patterns:**
- ✅ Authorization check pattern already implemented
- ✅ EventLog entries for user actions
- ✅ Emoji for visual anchors (✅, ⚠️, ❓)

**From Story 1.2 (Database Foundation - Core Models):**

**Key Learnings:**
1. ✅ Project, UserContext, EventLog models ready to use
2. ✅ SQLAlchemy 2.0 modern patterns established
3. ✅ Database migrations working (Alembic)
4. ✅ Unique constraint on Project.name prevents duplicates at DB level

**Implications for Story 1.5:**
1. ✅ Models ready — no schema changes needed
2. ✅ Unique constraint on Project.name — check before insert to provide user-friendly message
3. ✅ UserContext model ready for active_project_id tracking
4. ✅ EventLog.details JSON field perfect for storing project_name

### Git Intelligence

**Recent Commits (last 4):**
1. `fb55b69` - Story 1.4: Voice Recognition - Documentation and Code Review (658 lines)
2. `be96788` - Story 1.2 complete: Database foundation + code review (3919+ lines)
3. `e132369` - Add auto-sync configuration and helper script
4. `6e344de` - Initial commit: UBER_PO project setup

**Patterns from Story 1.4 Commit:**
- ✅ Comprehensive story documentation (658 lines)
- ✅ All tasks and subtasks documented and completed
- ✅ Code review section with issues found and fixed
- ✅ File List section lists all created/modified files
- ✅ Commit message includes Co-Authored-By: Claude Sonnet 4.5
- ✅ Sprint status synced after story completion

**Implementation Insights:**
- Story 1.4 achieved 91% test coverage (voice.py: 90%, utils.py: 95%)
- 14 unit tests + integration tests (all passing)
- Code review found 3 HIGH, 3 MEDIUM, 2 LOW issues — all critical/medium fixed
- Testing standards: 85%+ coverage, all tests passing, comprehensive E2E validation

**Expected Pattern for Story 1.5:**
- Similar comprehensive documentation
- Unit tests for NLU parser and project creation (target: 10+ tests)
- Integration tests with real database (3-5 tests)
- Code review before marking done
- Commit with Co-Authored-By tag

### Latest Technical Information

**Natural Language Understanding (NLU) for Russian Commands:**

**Regex Pattern Matching (Recommended for MVP):**
- Simple, fast, deterministic
- No API calls or additional dependencies
- Easy to debug and maintain
- Sufficient for MVP with limited command set

**Pattern Examples:**
```python
# Create project patterns
patterns = [
    r'(создай|создать|новый|добавь|добавить)\s+(проект|project)\s+(.+)',
    r'(сделай|сделать)\s+(проект|project)\s+(.+)',
]

# Feature creation (Story 1.6)
patterns = [
    r'(создай|создать|новая|добавь|добавить)\s+(фич[ау]|feature)\s+(.+)',
]
```

**GPT-based NLU (Future Enhancement - Epic 2):**
- More flexible, handles natural variations
- Cost: ~$0.002 per command (GPT-4 mini)
- Latency: ~500ms (acceptable for single user)
- Implementation: Use system prompt with examples, parse JSON response

**SQLAlchemy 2.0 Best Practices (2026):**

**Modern Query Patterns:**
```python
# Old (deprecated):
session.query(Project).filter(Project.name == name).first()

# New (SQLAlchemy 2.0):
stmt = select(Project).where(Project.name == name)
result = session.execute(stmt).scalar_one_or_none()
```

**Case-Insensitive Search:**
```python
from sqlalchemy import func

stmt = select(Project).where(func.lower(Project.name) == func.lower(project_name))
existing = session.execute(stmt).scalar_one_or_none()
```

**Insert with Auto-generated ID:**
```python
new_project = Project(name=project_name, status='active')
session.add(new_project)
session.commit()
session.refresh(new_project)  # Populate auto-generated fields (id, created_at, etc.)
project_id = new_project.id
```

**Upsert Pattern (for UserContext):**
```python
from sqlalchemy import update

# Try to update existing
stmt = update(UserContext).where(UserContext.user_id == user_id).values(active_project_id=project_id)
result = session.execute(stmt)

# If no rows updated, insert new
if result.rowcount == 0:
    new_context = UserContext(user_id=user_id, active_project_id=project_id)
    session.add(new_context)

session.commit()
```

**Error Handling Best Practices:**
- Catch `IntegrityError` for unique constraint violations (duplicate name)
- Catch `OperationalError` for database connection issues
- Log full traceback with `logger.exception()` for debugging
- Return user-friendly messages (no SQL error details)

**Russian Language Considerations:**
- Case variations: "Создай", "создай", "СОЗДАЙ" (use re.IGNORECASE)
- Verb forms: "создай" (imperative), "создать" (infinitive), "создаю" (present) — support common forms
- Synonyms: "создай" vs "добавь" vs "новый" — handle multiple verbs
- Project name extraction: Everything after "проект" is the name (trim whitespace)

### Project Context

**project-context.md not found** - Following architecture.md decisions and patterns from Stories 1.1-1.4.

**Key Architectural Patterns to Follow:**
1. ✅ Async handlers with type hints
2. ✅ Authorization check at start of every handler
3. ✅ Database session via context manager (get_db_session)
4. ✅ EventLog for all mutations (project_created, project_creation_failed)
5. ✅ User-friendly error messages with emoji
6. ✅ Logging for debugging (INFO for normal, ERROR for failures)
7. ✅ Context switching: UserContext updated immediately after project creation
8. ✅ Duplicate checks before database operations

**Development Workflow (from Architecture.md):**
- Sprint 1 (Days 2-4): Voice + Basic Commands
- **Current Story:** Day 4 - Create Project Command via Voice
- **Next Stories:** 1.6 Feature Management, 1.7 Ideas Inbox

### References

All technical details sourced from:

**Epic and Story Requirements:**
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 1, Story 1.5] - Acceptance criteria, NLU requirements
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.5 lines 808-855] - Complete AC with command patterns

**Architecture Decisions:**
- [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture, Decision 1.1] - SQLAlchemy ORM, EventLog audit trail
- [Source: _bmad-output/planning-artifacts/architecture.md#Cross-Cutting Concerns] - Context Resolver, UserContext tracking
- [Source: _bmad-output/planning-artifacts/architecture.md#Error Handling Strategy] - Try/Catch with graceful degradation
- [Source: _bmad-output/planning-artifacts/architecture.md#UX-Specific Requirements] - Voice-first, emoji, structured output

**Database Models:**
- [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture, Database Schema] - Project, UserContext, EventLog models
- [Source: _bmad-output/planning-artifacts/epics.md#lines 210-268] - Complete database schema with all fields

**Previous Story Context:**
- [Source: _bmad-output/implementation-artifacts/1-4-voice-recognition-with-whisper-api.md#Dev Notes] - Voice handler structure, handle_voice() integration point
- [Source: _bmad-output/implementation-artifacts/1-3-telegram-bot-integration-authentication.md#Dev Notes] - is_authorized() pattern, EventLog usage
- [Source: _bmad-output/implementation-artifacts/1-2-database-foundation-core-models.md#Dev Notes] - SQLAlchemy 2.0 patterns, database models ready

**UX Design:**
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Voice-first] - 90% voice input, structured output
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Structured Output] - Emoji for visual anchors (✅ created, ⚠️ duplicate, ❓ clarify)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)

### Debug Log References

### Implementation Plan

1. [x] Implement parse_command() function in bot/handlers/voice.py (Task 1)
2. [x] Implement handle_create_project() in bot/handlers/commands.py (Task 2)
3. [x] Add duplicate project check logic (Task 3)
4. [x] Implement UserContext management (Task 4)
5. [x] Integrate command routing in handle_voice() (Task 5)
6. [x] Implement response generation with context (Task 6)
7. [x] Add ambiguous input handling (Task 7)
8. [x] Implement comprehensive error handling (Task 8)
9. [x] Create unit tests for NLU parser and project creation (Task 9)
10. [ ] Create integration tests with real database (Task 10) - DEFERRED

### Completion Notes List

**2026-02-04:** Story 1.5 implementation completed by Dev agent (Amelia - Claude Sonnet 4.5)

**Implementation Summary:**
- ✅ NLU Parser (parse_command): Regex-based pattern matching for Russian/English commands
- ✅ Project Creation (handle_create_project): Full CRUD with duplicate check, EventLog, UserContext
- ✅ Command Routing: Integrated into handle_voice() with branching logic
- ✅ Response Generation: Emoji-based structured responses (✅ created, ⚠️ duplicate, ❓ ambiguous)
- ✅ Error Handling: Comprehensive try/except with user-friendly messages and EventLog
- ✅ Testing: 28 unit tests (19 NLU + 9 project creation), all passing, 100% coverage for new code
- ✅ Regression: Updated test_voice_handler.py to work with command routing, no regressions

**Technical Decisions:**
1. **NLU Approach:** Used regex pattern matching (not GPT-based) for MVP - deterministic, fast, no API costs
2. **Pattern:** `(создай|создать|новый|добавь|добавить)\s+(проект|project)(\s+(.+))?` - supports Russian/English mixed
3. **Duplicate Check:** Case-insensitive using SQLAlchemy `func.lower()`
4. **UserContext:** Upsert pattern - update if exists, create if not
5. **Response Format:** Inline formatting (no separate helper function) for simplicity
6. **Integration Tests:** Created file structure but deferred execution (requires test DB migrations)

**Test Results:**
- Unit Tests: 28 tests passing (test_nlu_parser.py: 19, test_project_creation.py: 9)
- Voice Handler Tests: 6 tests passing (updated for command routing compatibility)
- Regression Tests: 20 tests passing (auth, start, utils, telegram factory)
- **Total: 54 tests passing, 0 failures**

**Files Modified:**
- bot/handlers/voice.py: Added parse_command() + command routing (73 lines added)
- bot/handlers/commands.py: Added handle_create_project() (136 lines added)
- tests/unit/test_voice_handler.py: Updated transcript to non-command for compatibility

**Files Created:**
- tests/unit/test_nlu_parser.py: 19 tests for parse_command()
- tests/unit/test_project_creation.py: 9 tests for handle_create_project()
- tests/integration/test_project_creation_integration.py: Integration test scaffolding (deferred execution)

### File List

**Created:**
- uber-po-bot/tests/unit/test_nlu_parser.py - NLU parser unit tests (19 tests)
- uber-po-bot/tests/unit/test_project_creation.py - Project creation unit tests (9 tests)
- uber-po-bot/tests/integration/test_project_creation_integration.py - Integration test scaffolding (deferred)

**Modified:**
- uber-po-bot/bot/handlers/voice.py - Added parse_command() function and command routing in handle_voice()
- uber-po-bot/bot/handlers/commands.py - Added handle_create_project() function
- uber-po-bot/tests/unit/test_voice_handler.py - Updated transcript to non-command for compatibility

**Reused (no changes):**
- uber-po-bot/models/project.py - Project model
- uber-po-bot/models/user_context.py - UserContext model
- uber-po-bot/models/event_log.py - EventLog model
- uber-po-bot/database/session.py - get_db_session()

## Change Log

**2026-02-04:** Story 1.5 created with comprehensive developer context by SM agent (Bob)
- Created story file with all 10 tasks and 50+ subtasks
- Loaded epics.md (1681 lines), architecture.md (801 lines)
- Analyzed previous stories: 1.4 (659 lines), 1.3, 1.2, 1.1
- Analyzed git commits for code patterns (fb55b69, be96788)
- Researched SQLAlchemy 2.0 best practices and Russian NLU patterns
- Documented all architecture compliance requirements from architecture.md
- Added detailed NLU implementation guidance (regex vs GPT-based)
- Extracted database models and patterns from Story 1.2
- Referenced voice handler integration points from Story 1.4
- Added comprehensive testing requirements (unit + integration + E2E)
- Story status: ready-for-dev
- Next: Dev agent to implement all tasks following this comprehensive context

**2026-02-04:** Story 1.5 implementation completed by Dev agent (Amelia - Claude Sonnet 4.5)
- Implemented Tasks 1-9: NLU parser, project creation, duplicate check, UserContext, command routing, response generation, ambiguous input, error handling, unit tests
- Created 28 unit tests (19 NLU + 9 project creation), all passing
- Updated test_voice_handler.py for command routing compatibility
- Deferred Task 10 (integration tests) - requires test DB migrations
- All 54 tests passing (28 new + 6 voice + 20 regression)
- Story status: review
- Next: Code review workflow recommended (fresh context, different LLM)
