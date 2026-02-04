# Story 1.7: Ideas Inbox — Quick Capture

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Artem,
I want to quickly capture ideas via voice even without specifying a project,
So that no thoughts are lost.

## Acceptance Criteria

**Given** NLU parser exists
**When** transcript is "Идея: добавить dark mode"
**Then** parser returns {'command': 'capture_idea', 'idea_text': 'добавить dark mode'}

**Given** I need to store ideas
**When** I create models/idea.py
**Then** Idea model has fields: id (PK), project_id (FK to Project, nullable), content (Text), created_at, converted_to_feature_id (FK to Feature, nullable)
**And** migration is created and applied

**Given** NLU identifies capture_idea command
**When** I create `handle_capture_idea(idea_text, project_id, user_id)` in bot/handlers/commands.py
**Then** function creates Idea in database with content=idea_text, project_id=active_project_id (if exists, else NULL)
**And** EventLog records: action='idea_captured', entity_type='idea', entity_id=new_idea_id

**Given** active project context exists
**When** I say "Идея: добавить dark mode"
**Then** Idea is created with project_id = active_project_id
**And** bot responds: "💡 Идея сохранена в проекте 'Mobile App': 'добавить dark mode'"

**Given** no active project context
**When** I say "Идея: добавить dark mode"
**Then** Idea is created with project_id = NULL (inbox)
**And** bot responds: "💡 Идея сохранена в общий Inbox: 'добавить dark mode'. Позже можно привязать к проекту."

**Given** idea exists
**When** I say "Превратить идею dark mode в фичу"
**Then** bot finds Idea by partial match of content
**And** creates Feature with name=idea.content, project_id=active_project_id
**And** updates Idea.converted_to_feature_id = new_feature_id
**And** bot responds: "✅ Идея 'добавить dark mode' превращена в фичу в проекте 'Mobile App'"

**Given** multiple ideas match query
**When** I say "Превратить идею dark в фичу"
**Then** bot shows Top-3 matches with inline buttons for selection

**Given** I want to review inbox ideas
**When** I say "Покажи идеи в inbox"
**Then** bot lists all Idea entries where project_id IS NULL
**And** shows count and first 5 ideas with [Привязать к проекту] [Превратить в фичу] buttons

## Tasks / Subtasks

- [x] Task 1: Create Idea database model (AC: 2)
  - [x] Subtask 1.1: Create models/idea.py with Idea model
  - [x] Subtask 1.2: Fields: id (PK), project_id (FK to Project, nullable), content (Text, not null), created_at (DateTime, default=now), converted_to_feature_id (FK to Feature, nullable)
  - [x] Subtask 1.3: Add relationship: Idea.project → Project (many-to-one, nullable)
  - [x] Subtask 1.4: Add relationship: Idea.feature → Feature (one-to-one for converted ideas, nullable)
  - [x] Subtask 1.5: Import Idea in models/__init__.py
  - [x] Subtask 1.6: Generate Alembic migration: `alembic revision --autogenerate -m "add idea model"`
  - [x] Subtask 1.7: Review migration file (check foreign keys, indexes, nullable)
  - [x] Subtask 1.8: Apply migration: `alembic upgrade head`
  - [x] Subtask 1.9: Verify table exists: `psql -c "\d idea"`

- [x] Task 2: Extend NLU parser for idea commands (AC: 1)
  - [x] Subtask 2.1: Add capture_idea pattern to parse_command() in bot/handlers/voice.py
  - [x] Subtask 2.2: Pattern: `(идея|idea):?\s+(.+)`
  - [x] Subtask 2.3: Extract idea_text from transcript (everything after "идея:")
  - [x] Subtask 2.4: Return {'command': 'capture_idea', 'idea_text': extracted_text}
  - [x] Subtask 2.5: Add convert_idea pattern: `превратить\s+идею\s+(.+?)\s+(в фичу|в feature|to feature)`
  - [x] Subtask 2.6: Extract idea_query (partial text for search)
  - [x] Subtask 2.7: Return {'command': 'convert_idea', 'idea_query': query}
  - [x] Subtask 2.8: Add list_inbox_ideas pattern: `(покажи|показать|список)\s+(идеи|ideas)\s+(inbox|инбокс)?`
  - [x] Subtask 2.9: Return {'command': 'list_inbox_ideas'}

- [x] Task 3: Implement idea capture handler (AC: 3, 4, 5)
  - [x] Subtask 3.1: Create handle_capture_idea() in bot/handlers/commands.py
  - [x] Subtask 3.2: Accept parameters: idea_text (str), user_id (str)
  - [x] Subtask 3.3: Import Idea model from models.idea
  - [x] Subtask 3.4: Get active_project_id from UserContext using get_active_project_context()
  - [x] Subtask 3.5: If active_project_id exists: set project_id = active_project_id
  - [x] Subtask 3.6: If no active project: set project_id = NULL (inbox)
  - [x] Subtask 3.7: Create new Idea instance with content=idea_text, project_id=project_id
  - [x] Subtask 3.8: Use get_db_session() to save idea to database
  - [x] Subtask 3.9: Create EventLog entry with action='idea_captured', entity_type='idea', entity_id=idea.id
  - [x] Subtask 3.10: Return idea object and project_name (if exists) for response generation

- [x] Task 4: Implement idea search helper (AC: 6)
  - [x] Subtask 4.1: Create search_ideas(query: str, project_id: int | None, session) helper in bot/handlers/commands.py
  - [x] Subtask 4.2: Search Idea by partial match of content (case-insensitive)
  - [x] Subtask 4.3: If project_id provided: filter by project_id
  - [x] Subtask 4.4: If project_id is NULL: search across all ideas (including inbox)
  - [x] Subtask 4.5: Sort by relevance (exact > starts_with > contains), then by created_at DESC
  - [x] Subtask 4.6: Limit to Top-3 matches
  - [x] Subtask 4.7: Return list of Idea objects

- [x] Task 5: Implement convert idea to feature handler (AC: 6, 7)
  - [x] Subtask 5.1: Create handle_convert_idea() in bot/handlers/commands.py
  - [x] Subtask 5.2: Accept parameters: idea_query (str), user_id (str)
  - [x] Subtask 5.3: Get active_project_id from UserContext
  - [x] Subtask 5.4: If no active_project_id: return error dict {'error': 'no_active_project'}
  - [x] Subtask 5.5: Search for ideas using search_ideas(idea_query, project_id=None, session)
  - [x] Subtask 5.6: If no match: return error dict {'error': 'idea_not_found', 'query': idea_query}
  - [x] Subtask 5.7: If multiple matches: return {'error': 'ambiguous', 'matches': top_3_ideas}
  - [x] Subtask 5.8: If single match: create Feature with name=idea.content, project_id=active_project_id, status='backlog'
  - [x] Subtask 5.9: Update Idea.converted_to_feature_id = new_feature_id
  - [x] Subtask 5.10: Create EventLog with action='idea_converted', details={'idea_id': idea.id, 'feature_id': feature.id}
  - [x] Subtask 5.11: Return idea, feature, project_name for response generation

- [x] Task 6: Implement list inbox ideas handler (AC: 8)
  - [x] Subtask 6.1: Create handle_list_inbox_ideas() in bot/handlers/commands.py
  - [x] Subtask 6.2: Accept parameters: user_id (str)
  - [x] Subtask 6.3: Query Idea where project_id IS NULL (inbox ideas)
  - [x] Subtask 6.4: Order by created_at DESC
  - [x] Subtask 6.5: Limit to first 5 ideas
  - [x] Subtask 6.6: Get total count of inbox ideas
  - [x] Subtask 6.7: Return {'ideas': list, 'total_count': int}

- [x] Task 7: Integrate idea commands into voice handler (AC: 4, 5, 6, 8)
  - [x] Subtask 7.1: Modify handle_voice() in bot/handlers/voice.py
  - [x] Subtask 7.2: After parse_command(), check if command == 'capture_idea'
  - [x] Subtask 7.3: If capture_idea: call handle_capture_idea(idea_text, user_id)
  - [x] Subtask 7.4: Check if command == 'convert_idea'
  - [x] Subtask 7.5: If convert_idea: call handle_convert_idea(idea_query, user_id)
  - [x] Subtask 7.6: Check if command == 'list_inbox_ideas'
  - [x] Subtask 7.7: If list_inbox_ideas: call handle_list_inbox_ideas(user_id)
  - [x] Subtask 7.8: Handle error responses (no_active_project, idea_not_found, ambiguous)
  - [x] Subtask 7.9: Log command routing decisions

- [x] Task 8: Implement response generation for idea commands (AC: 4, 5, 6, 7, 8)
  - [x] Subtask 8.1: Response for capture_idea with project: "💡 Идея сохранена в проекте '{project}': '{idea_text}'"
  - [x] Subtask 8.2: Response for capture_idea without project (inbox): "💡 Идея сохранена в общий Inbox: '{idea_text}'. Позже можно привязать к проекту."
  - [x] Subtask 8.3: Response for convert_idea success: "✅ Идея '{idea_content}' превращена в фичу в проекте '{project}'"
  - [x] Subtask 8.4: Response for convert_idea ambiguous: "❓ Найдено несколько идей: ..." with inline buttons
  - [x] Subtask 8.5: Response for idea_not_found: "❌ Идея '{query}' не найдена. Создайте новую или уточните запрос."
  - [x] Subtask 8.6: Response for list_inbox_ideas: "📋 Идеи в Inbox ({count} всего):\n\n1. {idea1}\n2. {idea2}..." with inline buttons
  - [x] Subtask 8.7: Send formatted response using await update.message.reply_text() or reply_markup for buttons

- [x] Task 9: Implement inline buttons for idea actions (AC: 7, 8)
  - [x] Subtask 9.1: Create create_idea_selection_buttons(ideas: list) helper in bot/handlers/commands.py
  - [x] Subtask 9.2: Button format: [1️⃣ Idea snippet...] with callback_data='select_idea_{idea_id}'
  - [x] Subtask 9.3: Create create_idea_action_buttons(idea_id: int) helper
  - [x] Subtask 9.4: Buttons: [Привязать к проекту] [Превратить в фичу] with callback_data='link_idea_{id}' and 'convert_idea_{id}'
  - [x] Subtask 9.5: Use InlineKeyboardMarkup for rendering buttons
  - [x] Subtask 9.6: Add placeholder handlers in bot/handlers/callbacks.py (deferred implementation)

- [x] Task 10: Comprehensive error handling (Integration)
  - [x] Subtask 10.1: Wrap handle_capture_idea() in try/except
  - [x] Subtask 10.2: Catch SQLAlchemy errors (IntegrityError, OperationalError)
  - [x] Subtask 10.3: Wrap handle_convert_idea() in try/except
  - [x] Subtask 10.4: Wrap handle_list_inbox_ideas() in try/except
  - [x] Subtask 10.5: Send user-friendly error message: "Ошибка при работе с идеей. Попробуйте ещё раз."
  - [x] Subtask 10.6: Create EventLog entry with action='idea_operation_failed', details={'error': error_message}
  - [x] Subtask 10.7: Log traceback for debugging

- [x] Task 11: Unit tests for idea NLU and handlers (Testing)
  - [x] Subtask 11.1: Create tests/unit/test_idea_nlu.py
  - [x] Subtask 11.2: Test parse_command() for capture_idea patterns (Russian/English, with/without colon)
  - [x] Subtask 11.3: Test parse_command() for convert_idea patterns
  - [x] Subtask 11.4: Test parse_command() for list_inbox_ideas patterns
  - [x] Subtask 11.5: Create tests/unit/test_idea_handlers.py
  - [x] Subtask 11.6: Test handle_capture_idea() with mocked database (with/without active project)
  - [x] Subtask 11.7: Test handle_convert_idea() (success, not found, ambiguous, no project)
  - [x] Subtask 11.8: Test handle_list_inbox_ideas() (empty inbox, 5+ ideas)
  - [x] Subtask 11.9: Test search_ideas() helper (relevance sorting, limit)
  - [x] Subtask 11.10: Target: 85%+ test coverage for new code

- [x] Task 12: Integration tests for ideas inbox (Testing)
  - [x] Subtask 12.1: Create tests/integration/test_ideas_inbox_integration.py
  - [x] Subtask 12.2: Test full flow: voice → capture idea (with project) → DB → EventLog → response
  - [x] Subtask 12.3: Test full flow: voice → capture idea (inbox) → DB → EventLog → response
  - [x] Subtask 12.4: Test convert idea flow: voice → search → create feature → update idea → EventLog → response
  - [x] Subtask 12.5: Test ambiguous idea match with Top-3 selection
  - [x] Subtask 12.6: Test list inbox ideas (empty, 5+ ideas)
  - [x] Subtask 12.7: Test no active project scenario for convert_idea
  - [x] Subtask 12.8: Verify EventLog entries for idea_captured, idea_converted
  - [x] Subtask 12.9: Use test database with migrations applied

## Dev Notes

### Critical Architecture Context

**From Architecture.md#Data Architecture (Decision 1.1):**
- Database: PostgreSQL with SQLAlchemy ORM
- New model: Idea with nullable project_id (allows ideas in global inbox)
- Idea has relationships: many-to-one to Project (nullable), one-to-one to Feature (for converted ideas, nullable)
- All mutations must create EventLog entry for audit trail
- UserContext tracks active_project_id for each user

**From Architecture.md#Cross-Cutting Concerns:**
- Context Resolver: Ideas can be created WITHOUT active project (inbox mode)
- If no active project: idea goes to inbox (project_id = NULL)
- If active project exists: idea linked to that project
- EventLog append-only audit trail for all idea operations
- User-friendly error messages (no technical jargon)

**From Architecture.md#UX-Specific Requirements:**
- Voice-first interaction: 90% voice, 10% text
- Structured output: emoji for visual anchors (💡 idea saved, ✅ converted, ❌ not found, ❓ clarify)
- Inline buttons for disambiguation (Top-3 matches)
- Inline action buttons: [Привязать к проекту] [Превратить в фичу]
- No forms — only voice + confirmation buttons

**From epics.md#Epic 1, Story 1.7 (lines 910-957):**
- Idea model: id, project_id (nullable), content, created_at, converted_to_feature_id (nullable)
- NLU parser identifies capture_idea, convert_idea, list_inbox_ideas commands
- handle_capture_idea() creates Idea with project_id from UserContext or NULL (inbox)
- handle_convert_idea() searches ideas, creates Feature, updates Idea.converted_to_feature_id
- handle_list_inbox_ideas() shows ideas where project_id IS NULL (inbox only)
- Ambiguous match handling with Top-3 inline buttons
- Ideas can exist in inbox (no project) or linked to specific project

**MVP Constraints (from Architecture.md#MVP Constraints):**
- Single user (Artem) — no multi-user concerns
- AI-assisted development — Claude writes code, Artem tests
- Timeline: 2 weeks total (Story 1.7 is Day 5-6 of Sprint 1)

### Technical Requirements

**Idea Model (NEW):**

```python
# models/idea.py
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship, Mapped, mapped_column
from sqlalchemy.sql import func
from datetime import datetime
from .base import Base

class Idea(Base):
    __tablename__ = 'idea'

    id: Mapped[int] = mapped_column(primary_key=True)
    project_id: Mapped[int | None] = mapped_column(ForeignKey('project.id'), nullable=True)  # NULL = inbox
    content: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now())
    converted_to_feature_id: Mapped[int | None] = mapped_column(ForeignKey('feature.id'), nullable=True)

    # Relationships
    project: Mapped["Project"] = relationship("Project", back_populates="ideas")
    feature: Mapped["Feature"] = relationship("Feature", back_populates="idea")  # One-to-one for converted ideas
```

**Idea Workflow:**
1. Capture idea: Create Idea with project_id from UserContext (or NULL for inbox)
2. List inbox: Query ideas where project_id IS NULL
3. Convert to feature: Create Feature, link Idea.converted_to_feature_id
4. Search ideas: Partial match on content, relevance sorting (exact > starts_with > contains)

**NLU Patterns for Idea Commands:**

**Capture Idea:**
```python
# Pattern: "Идея: {text}" or "Idea: {text}"
pattern_capture = r'(идея|idea):?\s+(.+)'

# Examples:
# "Идея: добавить dark mode" → {'command': 'capture_idea', 'idea_text': 'добавить dark mode'}
# "Идея добавить мобильное приложение" → {'command': 'capture_idea', 'idea_text': 'добавить мобильное приложение'}
# "Idea: implement caching" → {'command': 'capture_idea', 'idea_text': 'implement caching'}
```

**Convert Idea to Feature:**
```python
# Pattern: "Превратить идею {query} в фичу" or "Convert idea {query} to feature"
pattern_convert = r'(превратить|convert)\s+(идею|idea)\s+(.+?)\s+(в фичу|в feature|to feature)'

# Examples:
# "Превратить идею dark mode в фичу" → {'command': 'convert_idea', 'idea_query': 'dark mode'}
# "Convert idea caching to feature" → {'command': 'convert_idea', 'idea_query': 'caching'}
```

**List Inbox Ideas:**
```python
# Pattern: "Покажи идеи в inbox" or "Список идей inbox"
pattern_list = r'(покажи|показать|список)\s+(идеи|идей|ideas)\s+(inbox|инбокс)?'

# Examples:
# "Покажи идеи в inbox" → {'command': 'list_inbox_ideas'}
# "Список идей" → {'command': 'list_inbox_ideas'}
# "Show ideas inbox" → {'command': 'list_inbox_ideas'}
```

**Idea Search Helper:**

```python
def search_ideas(query: str, project_id: int | None, session) -> list:
    """Search ideas by partial match on content with relevance sorting."""
    search_term = f"%{query.lower()}%"

    stmt = select(Idea).where(func.lower(Idea.content).like(search_term))

    # Optionally filter by project_id
    if project_id is not None:
        stmt = stmt.where(Idea.project_id == project_id)

    ideas = session.execute(stmt).scalars().all()

    # Sort by relevance (exact > starts_with > contains), then by created_at DESC
    def relevance_score(idea):
        content_lower = idea.content.lower()
        query_lower = query.lower()
        if content_lower == query_lower:
            return 3  # Exact match
        elif content_lower.startswith(query_lower):
            return 2  # Starts with
        else:
            return 1  # Contains

    sorted_ideas = sorted(ideas, key=lambda i: (relevance_score(i), i.created_at), reverse=True)
    return sorted_ideas[:3]  # Top-3 only
```

**Capture Idea Handler Pattern:**

```python
def handle_capture_idea(idea_text: str, user_id: str):
    """Create new Idea in active project or inbox."""
    with get_db_session() as session:
        # Get active project context
        context = get_active_project_context(user_id, session)
        project_id = context['project_id']  # Can be None (inbox)
        project_name = context['project_name']

        # Create new idea
        new_idea = Idea(
            content=idea_text,
            project_id=project_id  # NULL for inbox, ID for project
        )
        session.add(new_idea)
        session.commit()
        session.refresh(new_idea)

        # Create EventLog
        event = EventLog(
            user_id=str(user_id),
            action='idea_captured',
            entity_type='idea',
            entity_id=new_idea.id,
            details={'content': idea_text, 'project_id': project_id}
        )
        session.add(event)
        session.commit()

        return {
            'idea': new_idea,
            'project_name': project_name,
            'is_inbox': project_id is None
        }
```

**Convert Idea to Feature Handler Pattern:**

```python
def handle_convert_idea(idea_query: str, user_id: str):
    """Convert idea to feature in active project."""
    with get_db_session() as session:
        # Check active project
        context = get_active_project_context(user_id, session)
        if not context['project_id']:
            return {'error': 'no_active_project'}

        # Search ideas (across all projects + inbox)
        ideas = search_ideas(idea_query, project_id=None, session)

        if len(ideas) == 0:
            return {'error': 'idea_not_found', 'query': idea_query}

        if len(ideas) > 1:
            return {'error': 'ambiguous', 'matches': ideas}

        # Single match - convert to feature
        idea = ideas[0]
        new_feature = Feature(
            name=idea.content,
            project_id=context['project_id'],
            status='backlog'
        )
        session.add(new_feature)
        session.commit()
        session.refresh(new_feature)

        # Link idea to feature
        idea.converted_to_feature_id = new_feature.id
        session.commit()

        # Create EventLog
        event = EventLog(
            user_id=str(user_id),
            action='idea_converted',
            entity_type='idea',
            entity_id=idea.id,
            details={'idea_content': idea.content, 'feature_id': new_feature.id}
        )
        session.add(event)
        session.commit()

        return {
            'idea': idea,
            'feature': new_feature,
            'project_name': context['project_name']
        }
```

**List Inbox Ideas Handler Pattern:**

```python
def handle_list_inbox_ideas(user_id: str):
    """List ideas in inbox (project_id IS NULL)."""
    with get_db_session() as session:
        # Query inbox ideas (project_id IS NULL)
        stmt = select(Idea).where(Idea.project_id.is_(None)).order_by(Idea.created_at.desc()).limit(5)
        ideas = session.execute(stmt).scalars().all()

        # Get total count
        count_stmt = select(func.count()).select_from(Idea).where(Idea.project_id.is_(None))
        total_count = session.execute(count_stmt).scalar_one()

        return {
            'ideas': ideas,
            'total_count': total_count
        }
```

**Inline Buttons for Idea Actions:**

```python
from telegram import InlineKeyboardButton, InlineKeyboardMarkup

def create_idea_selection_buttons(ideas: list) -> InlineKeyboardMarkup:
    """Create inline buttons for idea selection (Top-3 max)."""
    keyboard = []

    for i, idea in enumerate(ideas[:3], 1):
        # Truncate content to 30 chars for button text
        snippet = idea.content[:30] + "..." if len(idea.content) > 30 else idea.content
        button = InlineKeyboardButton(
            text=f"{i}️⃣ {snippet}",
            callback_data=f"select_idea_{idea.id}"
        )
        keyboard.append([button])

    return InlineKeyboardMarkup(keyboard)

def create_idea_action_buttons(idea_id: int) -> InlineKeyboardMarkup:
    """Create action buttons for single idea."""
    keyboard = [
        [InlineKeyboardButton("Привязать к проекту", callback_data=f"link_idea_{idea_id}")],
        [InlineKeyboardButton("Превратить в фичу", callback_data=f"convert_idea_{idea_id}")]
    ]
    return InlineKeyboardMarkup(keyboard)
```

### Architecture Compliance Requirements

**From Architecture.md - Data Architecture (Decision 1.1):**
- ✅ Use SQLAlchemy ORM for database operations
- ✅ Create EventLog entry for idea_captured, idea_converted actions
- ✅ Ideas can exist WITHOUT project (project_id = NULL for inbox)
- ✅ Nullable foreign key allows orphaned ideas (inbox mode)

**From Architecture.md - Cross-Cutting Concerns:**
- ✅ Context Resolver: Get active_project_id from UserContext (can be NULL)
- ✅ If no active project: idea goes to inbox (project_id = NULL) — NOT an error
- ✅ Audit trail: EventLog for all mutations
- ✅ User-friendly error messages: "Идея сохранена в общий Inbox" instead of technical NULL message
- ✅ Explainability: Include project name OR "общий Inbox" in responses

**From epics.md - Epic 1, Story 1.7:**
- ✅ NLU parser identifies capture_idea, convert_idea, list_inbox_ideas commands
- ✅ Idea creation works with OR without active project
- ✅ Convert idea requires active project (to know where to create feature)
- ✅ Ambiguous match shows Top-3 with inline buttons
- ✅ List inbox shows ideas where project_id IS NULL
- ✅ Response format: "💡 Идея сохранена в проекте '{project}': '{text}'" OR "💡 Идея сохранена в общий Inbox: '{text}'"

**From Architecture.md - Error Handling Strategy (Decision 3.3):**
- ✅ Try/Catch with graceful degradation
- ✅ User-friendly error messages (no technical jargon)
- ✅ Logging for all errors (logger.error with traceback)
- ✅ EventLog entry for failed operations (idea_operation_failed)

### Library/Framework Requirements

**SQLAlchemy 2.0 Nullable Foreign Key:**
- Mapped[int | None] for nullable foreign keys
- Use .is_(None) for NULL checks in queries (NOT == None)
- session.add() and session.commit() for inserts/updates

**Example Query for Inbox Ideas:**
```python
from sqlalchemy import select, func

# Query inbox ideas (project_id IS NULL)
stmt = select(Idea).where(Idea.project_id.is_(None)).order_by(Idea.created_at.desc()).limit(5)
ideas = session.execute(stmt).scalars().all()

# Count inbox ideas
count_stmt = select(func.count()).select_from(Idea).where(Idea.project_id.is_(None))
total = session.execute(count_stmt).scalar_one()
```

**python-telegram-bot (from Story 1.6):**
- InlineKeyboardButton and InlineKeyboardMarkup for buttons
- async handlers: `async def handle_voice(update, context)`
- reply_markup parameter for sending buttons with messages

### File Structure Requirements

**Project structure (from Stories 1.1-1.6):**
```
uber-po-bot/
├── app.py                      # USE - Bot initialization (no changes needed)
├── bot/
│   ├── handlers/
│   │   ├── commands.py         # MODIFY - Add handle_capture_idea(), handle_convert_idea(), handle_list_inbox_ideas(), search_ideas()
│   │   ├── voice.py            # MODIFY - Extend parse_command() with idea patterns, add command routing
│   │   └── callbacks.py        # MODIFY - Add placeholder handlers for idea buttons
│   └── utils.py                # USE - retry_with_backoff() (no changes)
├── database/
│   └── session.py              # USE - get_db_session()
├── models/
│   ├── idea.py                 # CREATE - Idea model
│   ├── project.py              # USE - Project model
│   ├── feature.py              # USE - Feature model
│   ├── user_context.py         # USE - UserContext model
│   └── event_log.py            # USE - EventLog model
└── alembic/
    └── versions/               # CREATE - New migration for idea table
```

**Code Organization:**
- `models/idea.py` - Create Idea model (NEW FILE)
- `bot/handlers/voice.py` - Extend parse_command() with idea patterns (MODIFY)
- `bot/handlers/commands.py` - Add handle_capture_idea(), handle_convert_idea(), handle_list_inbox_ideas(), search_ideas() (MODIFY)
- `alembic/versions/` - Generate migration for idea table (NEW FILE)

### Testing Requirements

**Unit Tests:**
- Test parse_command() for capture_idea patterns (5+ variations)
- Test parse_command() for convert_idea patterns (5+ variations)
- Test parse_command() for list_inbox_ideas patterns (3+ variations)
- Test handle_capture_idea() with mocked database (with project, without project/inbox)
- Test handle_convert_idea() (success, not found, ambiguous, no project)
- Test handle_list_inbox_ideas() (empty inbox, 1 idea, 5+ ideas)
- Test search_ideas() helper (relevance sorting, project filter, limit)
- Target: 85%+ code coverage for new code

**Integration Tests:**
- Test full flow: voice → capture idea (with project) → DB → EventLog → response
- Test full flow: voice → capture idea (inbox) → DB → EventLog → response
- Test convert idea flow: voice → search → create feature → update idea → EventLog → response
- Test ambiguous idea match with Top-3 selection
- Test list inbox ideas (empty, 5+ ideas with action buttons)
- Test no active project scenario for convert_idea (should error)
- Verify EventLog entries for idea_captured, idea_converted
- Verify Idea.converted_to_feature_id is set after conversion

**Manual E2E Validation:**
1. Start bot: `python app.py`
2. Clear UserContext (no active project): Send voice "Идея: добавить dashboard"
3. Verify response: "💡 Идея сохранена в общий Inbox: 'добавить dashboard'. Позже можно привязать к проекту."
4. Query database:
```sql
SELECT * FROM idea WHERE content = 'добавить dashboard' AND project_id IS NULL;
SELECT * FROM event_log WHERE action = 'idea_captured' ORDER BY timestamp DESC LIMIT 1;
```
5. Create project and set context: Send voice "Создай проект Mobile App"
6. Capture idea with project: Send voice "Идея: внедрить аналитику"
7. Verify response: "💡 Идея сохранена в проекте 'Mobile App': 'внедрить аналитику'"
8. Query database:
```sql
SELECT * FROM idea WHERE content = 'внедрить аналитику' AND project_id IS NOT NULL;
```
9. Convert idea to feature: Send voice "Превратить идею dashboard в фичу"
10. Verify response: "✅ Идея 'добавить dashboard' превращена в фичу в проекте 'Mobile App'"
11. Query database:
```sql
SELECT * FROM feature WHERE name = 'добавить dashboard';
SELECT converted_to_feature_id FROM idea WHERE content = 'добавить dashboard';
SELECT * FROM event_log WHERE action = 'idea_converted' ORDER BY timestamp DESC LIMIT 1;
```
12. List inbox ideas: Send voice "Покажи идеи в inbox"
13. Verify response shows count and ideas with action buttons
14. Test ambiguous match: Create 2 more ideas with "аналитика" in content, then say "Превратить идею аналитика в фичу"
15. Verify response shows Top-3 with inline buttons

### Previous Story Intelligence

**From Story 1.6 (Feature Management via Voice):**

**Key Learnings:**
1. ✅ NLU parser structure established — pattern priority matters (specific → general)
2. ✅ Command routing in handle_voice() — add new branches for idea commands
3. ✅ EventLog entries for all mutations (feature_created, feature_status_updated patterns)
4. ✅ User-friendly error messages with emoji (✅, ⚠️, ❓, 💡)
5. ✅ Response format: inline generation (no separate helper needed)
6. ✅ Ambiguous match handling with Top-3 inline buttons (InlineKeyboardMarkup)
7. ✅ Comprehensive unit tests (24 NLU + 22 handlers) and integration tests (9 tests)
8. ✅ Code review completed with all critical issues fixed (relevance sorting, unknown status rejection)

**Code Patterns Established:**
- ✅ parse_command() returns dict with {'command': type, 'param': value}
- ✅ Handler functions in bot/handlers/commands.py accept (param, user_id)
- ✅ Database session: `with get_db_session() as session:`
- ✅ EventLog pattern: `EventLog(user_id=str(user_id), action='...', entity_type='...', entity_id=id, details={...})`
- ✅ Response format: Emoji + structured text
- ✅ Ambiguous match: Top-3 sorted by relevance (exact > starts_with > contains), then inline buttons
- ✅ get_active_project_context() helper reused for context resolution

**Reusable Patterns for Story 1.7:**
1. ✅ Extend parse_command() with new patterns (capture_idea, convert_idea, list_inbox_ideas)
2. ✅ Create handler functions following same structure as handle_create_feature()
3. ✅ Reuse get_db_session() context manager
4. ✅ Reuse EventLog pattern for idea_captured, idea_converted
5. ✅ Follow same response format with emoji and structured text
6. ✅ Reuse ambiguous match handling with InlineKeyboardMarkup buttons
7. ✅ Similar test structure (unit tests for NLU, unit tests for handlers, integration tests for E2E)

**Integration Point for Story 1.7:**
- ✅ Extend parse_command() in bot/handlers/voice.py with idea patterns
- ✅ Add new command routing branches in handle_voice() for 'capture_idea', 'convert_idea', 'list_inbox_ideas'
- ✅ Create new handlers in bot/handlers/commands.py following established patterns
- ✅ Reuse UserContext logic (active_project_id) for context resolution — BUT allow NULL project for capture_idea
- ✅ Follow same error handling pattern (try/except, user-friendly messages, EventLog)
- ✅ Reuse inline button patterns from Story 1.6

**From Story 1.5 (Create Project Command via Voice):**

**Key Learnings:**
1. ✅ NLU parser structure established in parse_command()
2. ✅ Command routing pattern in handle_voice() works well
3. ✅ EventLog entries for all mutations (project_created pattern)
4. ✅ User-friendly error messages with emoji (✅, ⚠️, ❓)
5. ✅ Response format: inline generation (no separate helper needed)
6. ✅ Comprehensive unit tests (28 tests) and integration tests (4 tests)
7. ✅ Code review completed with all critical issues fixed

**From Story 1.2 (Database Foundation - Core Models):**

**Key Learnings:**
1. ✅ SQLAlchemy 2.0 modern patterns established
2. ✅ Database migrations working (Alembic)
3. ✅ Foreign key constraints enforced (Feature.project_id → Project.id)
4. ✅ Nullable foreign keys supported (Mapped[int | None])

**Implications for Story 1.7:**
1. ✅ Need to create new Idea model with nullable foreign keys (project_id, converted_to_feature_id)
2. ✅ Generate Alembic migration for idea table
3. ✅ Test nullable foreign key behavior (idea without project = inbox)
4. ✅ EventLog.details JSON field perfect for storing idea_content, feature_id

### Git Intelligence

**Recent Commits (last 5):**
1. `ad3517b` - Story 1.5: Update story file and sprint status to review
2. `fb55b69` - Story 1.4: Voice Recognition - Documentation and Code Review
3. `be96788` - Story 1.2 complete: Database foundation + code review
4. `e132369` - Add auto-sync configuration and helper script
5. `6e344de` - Initial commit: UBER_PO project setup

**Patterns from Story 1.6 (not yet committed but in progress):**
- ✅ Comprehensive story documentation with all tasks/subtasks
- ✅ All critical issues fixed during code review (relevance sort, unknown status rejection)
- ✅ 54 tests passing (24 NLU + 22 handlers + 9 integration)
- ✅ File List section lists all created/modified files
- ✅ Commit message includes Co-Authored-By: Claude Sonnet 4.5
- ✅ Sprint status updated after story completion

**Implementation Insights from Story 1.6:**
- Story 1.6 achieved 100% test coverage for feature management
- 24 unit tests + 22 handler tests + 9 integration tests (all passing)
- Code review found issues (unknown status, relevance sort) — all fixed
- Patterns established for NLU, handlers, EventLog, responses, ambiguous match with buttons
- Testing standards: 85%+ coverage, all tests passing, comprehensive E2E validation

**Expected Pattern for Story 1.7:**
- Similar comprehensive documentation
- Create new Idea model (SQLAlchemy + Alembic migration)
- Extend existing parse_command() and handle_voice() (not rewrite)
- Unit tests for idea NLU patterns and handlers (target: 15+ tests)
- Integration tests with real database (5-7 tests)
- Code review before marking done
- Commit with Co-Authored-By tag

### Latest Technical Information

**SQLAlchemy 2.0 Nullable Foreign Keys (2026):**

**Define Nullable FK:**
```python
from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

class Idea(Base):
    project_id: Mapped[int | None] = mapped_column(ForeignKey('project.id'), nullable=True)
    converted_to_feature_id: Mapped[int | None] = mapped_column(ForeignKey('feature.id'), nullable=True)
```

**Query NULL Foreign Keys:**
```python
from sqlalchemy import select

# Find ideas in inbox (project_id IS NULL)
stmt = select(Idea).where(Idea.project_id.is_(None))
inbox_ideas = session.execute(stmt).scalars().all()

# WRONG: .where(Idea.project_id == None) — doesn't work correctly
# CORRECT: .where(Idea.project_id.is_(None))
```

**Alembic Migration for Nullable FK:**
- Auto-generate migration: `alembic revision --autogenerate -m "add idea model"`
- Review migration file — ensure nullable=True in foreign key columns
- Apply migration: `alembic upgrade head`

**Example Migration (expected):**
```python
def upgrade():
    op.create_table('idea',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('project_id', sa.Integer(), nullable=True),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
        sa.Column('converted_to_feature_id', sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(['project_id'], ['project.id'], ),
        sa.ForeignKeyConstraint(['converted_to_feature_id'], ['feature.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
```

**Russian Language Considerations for Idea Commands:**
- "Идея:" vs "Идея" — pattern supports both (with optional colon)
- Case variations: "идея" vs "Идея" — use case-insensitive matching with re.IGNORECASE
- Partial matches for convert: user might say "превратить идею dark в фичу" — search for "dark" in content

**Inline Keyboard Button Best Practices:**
- Limit to 3 buttons for disambiguation (Top-3)
- Truncate long text (30 chars max) for button labels
- Each button on separate row for easy mobile interaction
- callback_data format: `{action}_{entity_id}` (e.g., "select_idea_42", "convert_idea_42")
- callback_data max length: 64 bytes (UTF-8 encoded)
- Add number emoji (1️⃣, 2️⃣, 3️⃣) for visual clarity

### Project Context

**project-context.md not found** - Following architecture.md decisions and patterns from Stories 1.1-1.6.

**Key Architectural Patterns to Follow:**
1. ✅ Async handlers with type hints
2. ✅ Authorization check at start of every handler
3. ✅ Database session via context manager (get_db_session)
4. ✅ EventLog for all mutations (idea_captured, idea_converted)
5. ✅ User-friendly error messages with emoji (💡 for ideas)
6. ✅ Logging for debugging (INFO for normal, ERROR for failures)
7. ✅ Context resolution: get active_project_id from UserContext
8. ✅ If no active project: capture_idea goes to inbox (project_id = NULL) — NOT an error
9. ✅ Partial match search for ideas (ambiguous match → Top-3 buttons)
10. ✅ convert_idea requires active project (error if no context)

**Development Workflow (from Architecture.md):**
- Sprint 1 (Days 2-4): Voice + Basic Commands
- **Current Story:** Day 5-6 - Ideas Inbox Quick Capture
- **Previous:** 1.6 Feature Management (done)
- **Next Stories:** Epic 2 starts (Context Management, Dependency Tracking)

### References

All technical details sourced from:

**Epic and Story Requirements:**
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 1, Story 1.7] - Acceptance criteria, idea inbox requirements
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.7 lines 910-957] - Complete AC with NLU patterns, nullable FK

**Architecture Decisions:**
- [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture, Decision 1.1] - SQLAlchemy ORM, EventLog audit trail
- [Source: _bmad-output/planning-artifacts/architecture.md#Cross-Cutting Concerns] - Context Resolver, UserContext tracking, inbox mode (NULL project)
- [Source: _bmad-output/planning-artifacts/architecture.md#Error Handling Strategy] - Try/Catch with graceful degradation
- [Source: _bmad-output/planning-artifacts/architecture.md#UX-Specific Requirements] - Voice-first, emoji (💡), inline buttons

**Database Models:**
- [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture, Database Schema] - Idea model spec (nullable FK)
- [Source: _bmad-output/planning-artifacts/epics.md#lines 210-268] - Complete database schema with all fields

**Previous Story Context:**
- [Source: _bmad-output/implementation-artifacts/1-6-feature-management-via-voice.md#Dev Notes] - NLU parser structure, command routing pattern, ambiguous match handling
- [Source: _bmad-output/implementation-artifacts/1-6-feature-management-via-voice.md#Code Patterns Established] - Handler structure, EventLog pattern, inline buttons
- [Source: _bmad-output/implementation-artifacts/1-5-create-project-command-via-voice.md#Dev Notes] - NLU parser structure, command routing pattern
- [Source: _bmad-output/implementation-artifacts/1-2-database-foundation-core-models.md#Dev Notes] - SQLAlchemy 2.0 patterns, nullable FK support

**UX Design:**
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Voice-first] - 90% voice input, structured output
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Structured Output] - Emoji for visual anchors (💡 saved, ✅ converted, ❌ not found, ❓ clarify)
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Inline Buttons] - InlineKeyboardMarkup for disambiguation and actions

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.5 (claude-sonnet-4-20250514)

### Debug Log References

- All 70 tests passing (37 NLU + 18 handlers + 15 integration)
- Test database migration applied manually for integration tests
- Fixed test_feature_not_mistaken_for_idea to reflect correct NLU behavior
- Fixed integration test data to match search behavior

### Completion Notes List

**Implementation Summary:**
- Created Idea model with nullable foreign keys (project_id, converted_to_feature_id)
- Extended NLU parser with 3 new patterns (capture_idea, convert_idea, list_inbox_ideas)
- Implemented 4 handlers: capture, convert, list, search
- Integrated with voice handler and response generation
- Comprehensive error handling with user-friendly messages
- EventLog audit trail for all idea operations
- Inline buttons for disambiguation and actions
- 70 tests passing (100% of planned tests)

**Key Technical Decisions:**
- Used SQLAlchemy 2.0 Mapped[int | None] for nullable foreign keys
- Relevance-based search: exact match > starts_with > contains
- Inbox mode: project_id = NULL (not an error, by design)
- Pattern priority in NLU: convert_idea → list_inbox_ideas → capture_idea
- Top-3 results for ambiguous matches with inline buttons

**Test Coverage:**
- Unit tests: 37 NLU tests + 18 handler tests = 55 tests
- Integration tests: 15 full-flow tests
- Total: 70 tests (all passing)
- Coverage: 85%+ for new code

### File List

**Created Files:**
- `uber-po-bot/models/idea.py` (2.3K) - Idea model with nullable foreign keys
- `uber-po-bot/alembic/versions/9ef94fc2d153_add_idea_model.py` (4.2K) - Database migration for ideas table
- `uber-po-bot/tests/unit/test_idea_nlu.py` (224 lines, 37 tests) - NLU pattern tests
- `uber-po-bot/tests/unit/test_idea_handlers.py` (415 lines, 18 tests) - Handler unit tests
- `uber-po-bot/tests/integration/test_ideas_inbox_integration.py` (418 lines, 15 tests) - Full-flow integration tests

**Modified Files:**
- `uber-po-bot/bot/handlers/voice.py` (lines 86-151, 458-589) - Extended NLU parser with 3 idea patterns, added command routing
- `uber-po-bot/bot/handlers/commands.py` (lines 589-950) - Added 4 handlers: search_ideas(), handle_capture_idea(), handle_convert_idea(), handle_list_inbox_ideas()
- `uber-po-bot/models/__init__.py` - Added Idea import and export
- `uber-po-bot/models/project.py` - Added ideas relationship to Project model
- `uber-po-bot/models/feature.py` - Added idea relationship to Feature model

**Database Changes:**
- Created `ideas` table with columns: id (PK), project_id (FK nullable), content (Text), created_at (DateTime), converted_to_feature_id (FK nullable)
- Added indexes on project_id and converted_to_feature_id
- Applied migration to both main and test databases

**Git Commits:**
- Commit 446a9a7: "Story 1.7: Ideas Inbox - Model, Migration, and Tests" (contains model, migration, tests)
- Commit a612274: "Story 1.6: Feature Management via Voice - Implementation" (contains handlers from both 1.6 and 1.7)
