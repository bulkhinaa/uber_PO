# Story 1.3: Telegram Bot Integration & Authentication

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Artem,
I want the bot to authenticate only my Telegram ID and respond to /start command,
So that only I can use the bot.

## Acceptance Criteria

**Given** python-telegram-bot is installed
**When** I create bot/handlers/commands.py with /start handler
**Then** handler function `start_command(update, context)` exists

**Given** .env has YOUR_TELEGRAM_ID set
**When** I create authentication check function `is_authorized(update)` in bot/handlers/commands.py
**Then** function returns True if update.message.from_user.id == int(os.getenv('YOUR_TELEGRAM_ID'))
**And** function returns False otherwise

**Given** /start handler exists
**When** an unauthorized user sends /start
**Then** bot responds with "Извините, доступ запрещён." (Access denied)
**And** no further processing occurs

**Given** /start handler and auth check exist
**When** I (authorized user) send /start to the bot
**Then** bot responds with welcome message: "Привет, Artem! 👋 UBER_PO бот готов к работе. Отправь голосовое сообщение или команду."
**And** EventLog records: user_id=my_telegram_id, action='bot_started', entity_type='user', timestamp=now

**Given** app.py exists
**When** I configure bot in polling mode (ENVIRONMENT=development in .env)
**Then** app.py initializes bot with `Application.builder().token(TELEGRAM_TOKEN).build()`
**And** app.py adds /start handler
**And** app.py starts polling with `application.run_polling()`

**Given** bot is running in polling mode
**When** I send /start from Telegram
**Then** I receive welcome message within 2 seconds
**And** bot logs "Received /start command from user {telegram_id}"

## Tasks / Subtasks

- [x] Task 1: Create authentication utility function (AC: 2)
  - [x] Subtask 1.1: Create bot/handlers/__init__.py package
  - [x] Subtask 1.2: Create bot/handlers/commands.py with is_authorized() function
  - [x] Subtask 1.3: Import YOUR_TELEGRAM_ID from config.py
  - [x] Subtask 1.4: Implement is_authorized() to check update.message.from_user.id matches
  - [x] Subtask 1.5: Add type hints for update parameter (Update type from python-telegram-bot)
  - [x] Subtask 1.6: Add logging for unauthorized access attempts

- [x] Task 2: Implement /start command handler (AC: 1, 3, 4)
  - [x] Subtask 2.1: Create async function start_command(update: Update, context: ContextTypes.DEFAULT_TYPE)
  - [x] Subtask 2.2: Add authentication check at start of handler
  - [x] Subtask 2.3: If unauthorized: send "Извините, доступ запрещён." and return early
  - [x] Subtask 2.4: If authorized: send welcome message with Artem's name
  - [x] Subtask 2.5: Create EventLog entry with user_id, action='bot_started', entity_type='user'
  - [x] Subtask 2.6: Add error handling for database connection failures
  - [x] Subtask 2.7: Log command execution with logger.info()

- [x] Task 3: Create database session management utility (Required for EventLog)
  - [x] Subtask 3.1: Create database/session.py for session management
  - [x] Subtask 3.2: Implement get_db_session() context manager
  - [x] Subtask 3.3: Configure session with DATABASE_URL from config
  - [x] Subtask 3.4: Add connection pooling configuration
  - [x] Subtask 3.5: Export SessionLocal for use in handlers

- [x] Task 4: Integrate bot initialization in app.py (AC: 5)
  - [x] Subtask 4.1: Import Application from python-telegram-bot
  - [x] Subtask 4.2: Load TELEGRAM_TOKEN and ENVIRONMENT from config.py
  - [x] Subtask 4.3: Create Application with Application.builder().token(TELEGRAM_TOKEN).build()
  - [x] Subtask 4.4: Add start_command handler to application
  - [x] Subtask 4.5: Check ENVIRONMENT variable to determine polling vs webhook
  - [x] Subtask 4.6: For ENVIRONMENT='development': call application.run_polling()
  - [x] Subtask 4.7: Add startup log message: "Bot starting in {mode} mode"

- [x] Task 5: Test bot end-to-end (AC: 6)
  - [x] Subtask 5.1: Start PostgreSQL database
  - [x] Subtask 5.2: Run alembic upgrade head to apply migrations (including new entity_id nullable migration)
  - [x] Subtask 5.3: Set YOUR_TELEGRAM_ID in .env to actual Telegram ID (96715446)
  - [x] Subtask 5.4: Start bot with python app.py
  - [x] Subtask 5.5: Send /start from authorized Telegram account
  - [x] Subtask 5.6: Verify welcome message received within 2 seconds ✅ (< 2 seconds)
  - [x] Subtask 5.7: Check EventLog table for bot_started entry ✅ (ID: 2, user_id: 96715446)
  - [x] Subtask 5.8: Test unauthorized access receives denial ✅ (returns False, sends denial message)

## Dev Notes

### Critical Architecture Context

**Authentication Strategy (from Architecture.md#Authentication & Security):**
- Hardcoded Telegram ID в .env (только Artem)
- Простая проверка: `update.message.from_user.id == ALLOWED_USER_ID`
- Все handlers должны вызывать is_authorized() перед обработкой
- Неавторизованные пользователи получают "Доступ запрещён" без логирования деталей

**Bot Communication Mode (from Architecture.md#API & Communication Patterns):**
- Dev mode: Polling (no ngrok, просто запустить)
- Prod mode: Webhook (Railway HTTPS) - реализация в Story 4.4
- Config switch: `ENVIRONMENT=development|production` в .env

**MVP Constraints:**
- Single user (Artem) - no user management, no sessions
- No rate limiting needed (single user)
- No user database table (just hardcoded ID)

### Technical Requirements

**python-telegram-bot 22.6 (from Story 1.1):**
- Async/await patterns required (все handlers async)
- Use `Application.builder()` pattern (modern v22.x API)
- Handler signature: `async def handler(update: Update, context: ContextTypes.DEFAULT_TYPE)`
- CommandHandler для /start: `CommandHandler("start", start_command)`
- Use `await update.message.reply_text()` for responses

**Telegram API Integration:**
- Bot token from @BotFather в .env as TELEGRAM_TOKEN
- Polling mode: `application.run_polling()` blocks and runs forever
- Webhook mode: deferred to Story 4.4 (Railway deployment)
- Message types: update.message for text, update.message.voice for voice (Story 1.4)

**Error Handling Patterns:**
- Try/except для всех database operations
- Graceful degradation: если DB unavailable → "Сервис временно недоступен"
- Log errors with logger.error() and exception details
- User-friendly messages, technical details in logs

### Architecture Compliance Requirements

**From Architecture.md - Authentication Decision:**
- ✅ Hardcoded Telegram ID (single user MVP)
- ✅ is_authorized() check в каждом handler
- ✅ No user registration or login flows
- ⚠️ Future: Multi-user support deferred post-MVP

**From Architecture.md - Bot Communication:**
- ✅ Polling для development (простой запуск)
- ⚠️ Webhook для production (Story 4.4)
- ✅ Config-based mode switching (ENVIRONMENT variable)

**From PRD v0.7 - Security Requirements:**
- ✅ Only authorized user can interact with bot
- ✅ EventLog audit trail for all user actions
- ✅ No sensitive data in logs (just user_id and action)

**From UX Design - Voice-first with fallback:**
- ✅ /start command as fallback (text input)
- ⚠️ Voice messages в Story 1.4 (primary interaction)
- ✅ Structured responses with emoji (👋 в welcome message)

### Library/Framework Requirements

**python-telegram-bot 22.6 Documentation:**
- Modern async API (v20+ breaking changes from older versions)
- Application pattern: `Application.builder().token().build()`
- Handler types: CommandHandler, MessageHandler, CallbackQueryHandler
- Update object contains message, callback_query, etc.
- ContextTypes.DEFAULT_TYPE for context parameter type hint

**Database Session Management:**
- SQLAlchemy Session required for EventLog insert
- Use context manager pattern: `with get_db_session() as session:`
- Session configuration from DATABASE_URL in config.py
- Connection pooling for efficiency (SQLAlchemy default pool)

**Configuration Loading:**
- config.py already has load_config() from Story 1.1
- Access values: config.TELEGRAM_TOKEN, config.YOUR_TELEGRAM_ID
- Validation already in place for placeholder detection
- Type conversion: int(config.YOUR_TELEGRAM_ID) для Telegram ID comparison

### File Structure Requirements

**Project structure (from Story 1.1):**
```
uber-po-bot/
├── app.py                      # Main entry point - ADD bot initialization
├── config.py                   # Already exists with TELEGRAM_TOKEN, YOUR_TELEGRAM_ID
├── bot/
│   ├── __init__.py
│   └── handlers/
│       ├── __init__.py         # NEW - Package init
│       └── commands.py         # NEW - /start handler + is_authorized()
├── database/
│   ├── __init__.py             # NEW - Package init
│   └── session.py              # NEW - Session management
└── models/
    └── event_log.py            # Already exists from Story 1.2
```

**Code Organization:**
- `bot/handlers/commands.py` - All command handlers (/start, /help, etc.)
- `bot/handlers/voice.py` - Voice message handlers (Story 1.4)
- `bot/handlers/callbacks.py` - Inline button callbacks (Story 2.6)
- `database/session.py` - Database session management (reusable)

### Testing Requirements

**Manual Validation (MVP):**
1. Start bot with `python app.py`
2. Send /start from authorized Telegram ID
3. Verify welcome message received
4. Check logs for "Received /start command"
5. Query EventLog table for bot_started entry
6. Test unauthorized access (different Telegram ID)
7. Verify denial message and no EventLog entry

**Database Verification:**
```sql
-- Check EventLog for bot_started entry
SELECT * FROM event_log WHERE action = 'bot_started' ORDER BY timestamp DESC LIMIT 5;
```

**Automated tests deferred to Story 1.5 (Testing Infrastructure)**

### Previous Story Intelligence

**From Story 1.2 (Database Foundation):**

**Key Learnings:**
1. SQLAlchemy 2.0.46 with modern Mapped[T] type hints
2. EventLog model exists with fields: id, user_id, action, entity_type, entity_id, timestamp, details (JSON), created_at
3. EventLog is append-only (no updates/deletes)
4. Database session management not yet implemented - need to create database/session.py
5. All models use UTC timestamps with func.now() defaults

**Code Patterns Established:**
- Type hints on all functions
- Import models from models/ package
- Use SQLAlchemy session for database operations
- Alembic migrations already applied (tables exist in PostgreSQL)

**Files Created (Relevant to This Story):**
- `models/event_log.py` - EventLog model ready to use
- `models/__init__.py` - Exports EventLog for import
- `alembic/versions/17dac64f07ba_initial_schema...py` - Migration applied

**Implications for Current Story:**
1. ✅ EventLog model ready to use for audit trail
2. ⚠️ Need to create database/session.py for session management
3. ✅ Database migrations applied (event_log table exists)
4. ✅ Foreign key relationships work (tested in Story 1.2)

**From Story 1.1 (Project Initialization):**

**Key Learnings:**
1. python-telegram-bot 22.6 already installed
2. config.py has load_config() with TELEGRAM_TOKEN and YOUR_TELEGRAM_ID
3. Configuration validation detects placeholder values
4. app.py exists but only has Flask placeholder (needs bot integration)

**Code Patterns:**
- Type hints: `def function() -> ReturnType:`
- Environment variable loading via python-dotenv
- Graceful error handling with try/except
- Logging with Python logging module

**Implications:**
1. ✅ TELEGRAM_TOKEN already in config.py
2. ✅ YOUR_TELEGRAM_ID already in config.py
3. ⚠️ app.py needs bot initialization (currently just Flask placeholder)
4. ✅ Logging infrastructure already set up

### Git Intelligence

**Recent Commits (last 5):**
1. `be96788` - Story 1.2 complete: Database foundation + code review
2. `e132369` - Add auto-sync configuration and helper script
3. `6e344de` - Initial commit: UBER_PO project setup

**Patterns from Recent Work:**
- Commits after story completion with descriptive messages
- Code review fixes applied in same commit as implementation
- All tests passing before commit
- Story status updated to 'done' in story file

**Implementation Insights:**
- Story 1.2 completed database models successfully
- Code review process found and fixed 10 issues (relationships, indexes)
- Project structure follows architecture.md guidelines
- Type hints and modern Python patterns used consistently

### Latest Technical Information

**python-telegram-bot 22.6 (Latest Stable - 2026-01-29):**

Breaking Changes from v20+:
- Old `Updater` class removed → use `Application.builder()`
- All handlers must be async (async/await required)
- `CallbackContext` renamed to `ContextTypes.DEFAULT_TYPE`
- Message handlers use filters: `filters.TEXT`, `filters.VOICE`

Modern Pattern:
```python
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes

async def start_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text("Hello!")

def main() -> None:
    application = Application.builder().token("TOKEN").build()
    application.add_handler(CommandHandler("start", start_command))
    application.run_polling()

if __name__ == "__main__":
    main()
```

**SQLAlchemy Session Management Best Practices:**

Context Manager Pattern:
```python
from contextlib import contextmanager
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)

@contextmanager
def get_db_session():
    session = SessionLocal()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()

# Usage in handlers:
with get_db_session() as session:
    log_entry = EventLog(user_id=str(user_id), action='bot_started')
    session.add(log_entry)
```

**Telegram Bot Security Best Practices:**
- Never log TELEGRAM_TOKEN (keep in .env only)
- Validate user_id on every message (is_authorized check)
- Rate limiting for production (not needed for single user MVP)
- Use HTTPS for webhooks (Railway provides automatically)

### Project Context

**Project-context.md not found** - greenfield project, following architecture.md decisions.

**Architecture Decisions to Follow:**
1. ✅ Authentication: Hardcoded Telegram ID в .env
2. ✅ Bot mode: Polling for dev, Webhook for prod (Story 4.4)
3. ⚠️ Background Jobs: APScheduler (Story 3.2)
4. ⚠️ Deployment: Railway (Story 4.3)

**Development Workflow (from Architecture.md):**
- Sprint 1 (Days 2-4): Voice + Basic Commands
- **Current Story:** Day 2-3 - Bot Integration & Authentication
- **Next Stories:** 1.4 Voice Recognition, 1.5 Create Project Command

### References

All technical details sourced from:

**Epic and Story Requirements:**
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 1, Story 1.3] - Acceptance criteria, handler requirements
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.3 lines 717-754] - Complete AC with Telegram patterns

**Architecture Decisions:**
- [Source: _bmad-output/planning-artifacts/architecture.md#Authentication & Security] - Hardcoded Telegram ID decision
- [Source: _bmad-output/planning-artifacts/architecture.md#API & Communication Patterns] - Polling vs Webhook modes
- [Source: _bmad-output/planning-artifacts/architecture.md#Code Organization] - bot/handlers/ structure
- [Source: _bmad-output/planning-artifacts/architecture.md#Technology Versions] - python-telegram-bot 22.6

**PRD Requirements:**
- [Source: _bmad-output/planning-artifacts/PRD-v0.7.md#Security Requirements] - Only authorized user access
- [Source: _bmad-output/planning-artifacts/PRD-v0.7.md#NFR-003] - Audit trail mandatory

**Previous Story Context:**
- [Source: _bmad-output/implementation-artifacts/1-2-database-foundation-core-models.md#Dev Notes] - EventLog model structure
- [Source: _bmad-output/implementation-artifacts/1-1-project-initialization-setup.md#File List] - app.py, config.py locations

**UX Design:**
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Voice-first] - Structured text responses with emoji

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)

### Debug Log References

- bot/handlers/commands.py:6 - Logger initialized for command handlers
- bot/handlers/commands.py:31 - Unauthorized access logging
- bot/handlers/commands.py:46 - /start command execution logging
- app.py:72 - Bot mode startup logging

### Completion Notes List

**Implementation Summary:**
- ✅ Created is_authorized() authentication function with logging and graceful error handling
- ✅ Implemented async start_command() handler with EventLog integration
- ✅ Created database/session.py with connection pooling
- ✅ Integrated /start handler in app.py with mode detection
- ✅ All unit tests pass (9 tests for auth and start_command)
- ✅ Fixed alembic migration import bug (missing Text import)
- ✅ Code review: Fixed EventLog entity_id nullable constraint (critical bug)
- ✅ Code review: Fixed is_authorized() edge cases (None update, missing from_user)
- ✅ Code review: Enhanced database error logging
- ⚠️ E2E testing (Task 5.3-5.8) requires user setup of YOUR_TELEGRAM_ID in .env

**Test Coverage:**
- Unit tests: tests/unit/test_auth.py (4 tests) - is_authorized() validation
- Unit tests: tests/unit/test_auth_edge_cases.py (8 tests) - edge cases and error scenarios
- Unit tests: tests/unit/test_start_command.py (5 tests) - /start command behavior
- Unit tests: tests/unit/test_start_command_edge_cases.py - additional edge cases
- Integration tests: tests/integration/test_start_command_integration.py (8 tests) - real database
- Integration tests: tests/integration/test_database_session.py - session management
- All automated tests pass ✅ (awaiting E2E manual validation)

**Acceptance Criteria Validation:**
- AC 1 (handler function exists): ✅ start_command() in bot/handlers/commands.py:40
- AC 2 (authentication function): ✅ is_authorized() in bot/handlers/commands.py:11
- AC 3 (unauthorized denial): ✅ bot/handlers/commands.py:51 (tested manually + unit tests)
- AC 4 (authorized welcome + EventLog): ✅ bot/handlers/commands.py:57-72 (verified in DB: EventLog ID 2)
- AC 5 (app.py integration): ✅ app.py:49-52 handler registration (bot successfully started)
- AC 6 (end-to-end test): ✅ Tested with real Telegram (@Uber_po_bot), response < 2 seconds, all checks passed

**Code Review Fixes Applied:**
- CRITICAL: EventLog.entity_id now nullable (prevents IntegrityError on bot_started)
- MEDIUM: is_authorized() handles None update gracefully (no AttributeError)
- MEDIUM: Enhanced database failure logging (CRITICAL level + exc_info)
- LOW: Updated File List with 5 missing test files

### File List

**Created:**
- database/__init__.py - Database package initialization
- database/session.py - SQLAlchemy session management with context manager
- tests/unit/test_auth.py - Unit tests for is_authorized()
- tests/unit/test_auth_edge_cases.py - Edge case tests for authentication (None update, missing from_user)
- tests/unit/test_start_command.py - Unit tests for /start command handler
- tests/unit/test_start_command_edge_cases.py - Edge case tests for /start command
- tests/integration/test_database_session.py - Integration tests for database session management
- tests/integration/test_start_command_integration.py - Integration tests for /start with real database
- alembic/versions/a3f2b1c8d9e0_make_event_log_entity_id_nullable.py - Migration to make entity_id nullable

**Modified:**
- bot/handlers/commands.py - Added logging, start_command() handler, is_authorized() function
- app.py - Imported CommandHandler, registered /start handler, added bot mode logging
- alembic/versions/17dac64f07ba_initial_schema_with_fixed_relationships_.py - Fixed missing Text import
- tests/support/factories/telegram_factory.py - Factory for creating mock Telegram Update objects
- models/event_log.py - Made entity_id nullable to support system events (code review fix)

**Existing (No changes):**
- bot/__init__.py - Already existed from Story 1.1
- bot/handlers/__init__.py - Already existed from Story 1.1
- config.py - Used for TELEGRAM_TOKEN, YOUR_TELEGRAM_ID access
- models/event_log.py - Used for EventLog entries (from Story 1.2)

## Change Log

**2026-02-04:** E2E Testing Complete - Story Ready for Final Review
- Applied alembic migration a3f2b1c8d9e0 (make entity_id nullable)
- Configured .env with actual Telegram ID (96715446)
- Started bot in polling mode successfully (@Uber_po_bot)
- Tested /start command from authorized account: ✅ Response < 2 seconds, correct message
- Verified EventLog entry created: ✅ ID 2, user_id: 96715446, entity_id: None
- Tested unauthorized access: ✅ Returns False, sends denial message, no EventLog created
- All Task 5 subtasks completed successfully
- All 6 Acceptance Criteria validated ✅

**2026-02-04:** Code Review Fixes Applied
- CRITICAL: Made EventLog.entity_id nullable to support system events (bot_started has no entity)
- Created alembic migration a3f2b1c8d9e0 for entity_id nullable change
- Fixed is_authorized() to handle None update and missing from_user gracefully
- Enhanced database error logging with CRITICAL level and exc_info
- Updated edge case tests to reflect corrected behavior (no AttributeError)
- Updated File List with 5 previously missing files

**2026-02-03:** Story 1.3 Implementation Complete
- Implemented authentication system with is_authorized() function
- Created /start command handler with EventLog integration
- Added database session management utility with connection pooling
- Integrated bot handlers in app.py with polling mode support
- Fixed alembic migration Text import bug
- All unit tests passing (12/12)
- Ready for manual E2E testing with actual Telegram ID
