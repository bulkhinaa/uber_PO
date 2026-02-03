---
stepsCompleted: [1, 2, 3, 4, 5]
inputDocuments:
  - '/Users/baa/my-bmad-project/UBER_PO/_bmad-output/planning-artifacts/PRD-v0.7.md'
  - '/Users/baa/my-bmad-project/UBER_PO/_bmad-output/prd-v06-validation-report.md'
  - '/Users/baa/my-bmad-project/UBER_PO/_bmad-output/planning-artifacts/ux-design-specification.md'
workflowType: 'architecture'
project_name: 'UBER_PO'
user_name: 'Artem'
date: '2026-01-29'
mvp_constraints:
  timeline: '2 weeks'
  users: 'single user (Artem)'
  agents: 'ChatGPT-4/5 with system prompts'
  html_artifacts: 'required'
  developer_experience: 'limited - needs AI assistance for development'
architectural_decisions:
  database_schema: 'relational tables (strict structure)'
  radar_rules: 'in Python code'
  html_storage: 'local /static/artifacts/'
  authentication: 'hardcoded Telegram ID'
  background_jobs: 'APScheduler persistent'
  deployment: 'Railway'
status: 'complete'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements (15 ключевых FR из PRD v0.7):**

MVP фокусируется на core workflows:
- **FR-001-005:** Управление проектами, фичами, зависимостями, релизами, Inbox идей
- **FR-006-007:** Протоколы встреч + поручения с напоминаниями
- **FR-008-010:** Radar Top-3, Meeting Prep, справки по проектам/фичам
- **FR-011:** Исследования "не тревожь меня" с one-pager (7 разделов)
- **FR-012:** Мультиагентная архитектура (упрощённая: GPT с разными system prompts)
- **FR-013:** Auto Rendered HTML Artifacts (обязательно для презентаций CEO)
- **FR-014:** Leader Tasks Inbox с guided review

**Non-Functional Requirements (адаптированные для MVP):**

**Performance (достижимо за 2 недели):**
- API response < 500ms (вместо 200ms) — acceptable для single user
- Whisper API < 3 сек (вместо 2 сек) — зависит от OpenAI, но acceptable
- Radar generation < 10 сек для 20 проектов (вместо 5 сек) — SQL queries быстрые

**Reliability (упрощённо для MVP):**
- Idempotency через ingestion_id (критично — предотвращает дубликаты)
- EventLog append-only (простая таблица в PostgreSQL)
- Uptime: "best effort" (не 99.5%, но достаточно для личного использования)

**Security & Privacy (минимально необходимое):**
- Hardcoded Telegram ID (только Artem имеет доступ)
- Voice файлы не хранятся после транскрипции (экономия места)
- HTTPS для webhook (обязательно для Telegram)

**Scalability (не критично для MVP):**
- Single user — нет проблем с масштабированием
- PostgreSQL справится с 10k-100k записей без проблем
- Можно масштабировать позже при необходимости

**Observability (минимально):**
- Простой logging (Python logging module)
- Print statements для debugging
- PostgreSQL audit log (EventLog таблица)
- Никакого distributed tracing в MVP (overkill)

---

### Scale & Complexity Assessment

**Пересмотренная оценка сложности:** **🟢 Medium (MVP-focused, 2-week achievable)**

**Ключевые упрощения для 2-недельного MVP:**

1. **Single user** → Нет auth/permissions/multi-tenancy
2. **Агенты = System prompts** → Нет сложной orchestration, просто файлы с промтами
3. **Voice = Whisper API** → 1 API call, никакой "pipeline"
4. **Radar = SQL + Python** → Простая функция scoring, не отдельный движок
5. **EventLog = PostgreSQL table** → Append-only, без репликации в 3 датацентрах

**Complexity indicators (для MVP):**

- ✅ Voice processing: **Low** (Telegram + Whisper API)
- ✅ Multi-agent system: **Low-Medium** (GPT с разными prompts)
- ⚠️ Real-time features: **Medium** (Radar пересчёт, push-уведомления)
- ❌ Regulatory compliance: **Skip for MVP** (GDPR можно позже)
- ✅ Integration complexity: **Low** (OpenAI API + Telegram API + PostgreSQL)
- ✅ Data complexity: **Medium** (10+ tables с связями)

**Итоговая сложность:** Medium, но **achievable в 2 недели** с фокусом на core features.

**Primary technical domain:** Backend (Python) + Bot (Telegram) + AI (OpenAI GPT/Whisper)

**Estimated components for MVP:** **5 основных** (Telegram Bot, OpenAI Integration, PostgreSQL, Background Jobs, HTML Renderer)

---

### Technical Constraints & Dependencies

**MVP Constraints:**

1. **Telegram Bot API:**
   - Rate limits: 30 messages/second (достаточно для single user)
   - File download: 20MB limit (voice messages обычно < 5MB)
   - Webhook требует HTTPS (ngrok для dev, облачный сервер для prod)

2. **OpenAI API:**
   - Зависимость от внешнего сервиса (если OpenAI down → бот не работает)
   - Rate limits: GPT-4 60 requests/minute (достаточно)
   - Cost: ~$0.01-0.03 за voice transcription, ~$0.03-0.10 за GPT-4 completion

3. **PostgreSQL:**
   - Локально для dev (Docker)
   - Managed DB для prod (Render/Supabase/Neon — бесплатные tier есть)
   - Schema migrations через Alembic

4. **HTML Rendering:**
   - Jinja2 templates (Python native)
   - Tailwind CSS (CDN link, без build process)
   - Hosting: S3/Cloudflare R2 или просто Nginx на сервере

5. **Background Jobs:**
   - APScheduler (простой) или Celery (если нужны фоновые исследования)
   - Redis для Celery (можно использовать бесплатный tier Upstash)

**Deployment для MVP:**
- Dev: localhost + ngrok
- Prod: Render/Railway/Fly.io (все имеют free tier)
- Database: Render PostgreSQL или Supabase (free tier)
- Static files (HTML): Cloudflare R2 (free 10GB) или S3

---

### Cross-Cutting Concerns

**Для MVP критично:**

1. **Идемпотентность** (предотвращает дубликаты при retry):
   - Каждое Telegram message имеет уникальный `message_id`
   - Используем как `ingestion_id`
   - Check before processing: `if message_id in processed_messages: skip`

2. **Контекст пользователя** (активный проект):
   - Храним в PostgreSQL: `user_context` table с `active_project_id`
   - Context Resolver: определяет проект из сообщения или использует активный
   - Каждый ответ начинается с: `Контекст: Проект X`

3. **Audit trail** (кто/что/когда):
   - EventLog таблица: `user_id, action, entity_type, entity_id, timestamp, details (JSON)`
   - Append-only, никогда не удаляется
   - Используется для "История изменений"

4. **Error handling**:
   - Try/catch для всех API calls (OpenAI, Telegram)
   - Graceful degradation: если OpenAI unavailable → "Сервис временно недоступен, попробуйте позже"
   - Retry logic для transient errors (3 retries с exponential backoff)

5. **Explainability** (Radar):
   - Каждый Radar item содержит: `reasons[]`, `rules_triggered[]`, `entity_links[]`, `next_steps`
   - SQL queries возвращают данные для объяснения (статусы, даты, блокировки)

**Не критично для MVP (можно отложить):**

- ❌ Distributed tracing (overkill для single user)
- ❌ Advanced monitoring (Datadog/New Relic — дорого)
- ❌ Multi-region deployment (не нужно)
- ❌ GDPR compliance (можно добавить позже)

---

### UX-Specific Architectural Requirements

**Из UX Design Specification (критично для архитектуры):**

1. **Voice-first с inline-кнопками:**
   - Telegram native voice messages → Whisper API
   - Inline buttons для quick actions: `InlineKeyboardMarkup` в python-telegram-bot
   - Никаких форм — только кнопки для подтверждения

2. **Структурированный текст output:**
   - Template для ответов: `Контекст: {project} | {summary} | Top-3: {items} | [Кнопки]`
   - Markdown formatting в Telegram (bold, italic, code)
   - Emoji для визуальных якорей: 🔥 (горит), ⚠️ (риск), ✅ (готово)

3. **HTML артефакты для CEO:**
   - Jinja2 templates: `radar_report.html`, `research_onepager.html`, `meeting_prep.html`
   - Tailwind CSS для профессионального вида
   - Приватные ссылки: `/artifacts/{random_token}` (TTL=7 дней)

4. **Адаптивная глубина:**
   - Radar: краткий ответ (30 сек) → [Подробнее] → drill-down
   - System prompt GPT: "Ответь кратко в 3 пункта, добавь кнопки для деталей"

5. **System prompts для "агентов":**
   - `prompts/analyst.txt`: "Ты аналитик. Твоя задача: структурировать информацию..."
   - `prompts/researcher.txt`: "Ты исследователь. Твоя задача: найти информацию в интернете..."
   - `prompts/pm.txt`: "Ты PM. Твоя задача: создавать брифы и PRD..."
   - `prompts/risk_manager.txt`: "Ты Risk Manager. Определяй риски и scoring..."
   - Загружаются динамически в зависимости от команды

---

### Architecture Approach (Recommended for 2-week MVP)

**Архитектурный стиль:** **Monolithic Backend + Event Logging**

**Обоснование:**
- Monolith проще разрабатывать и деплоить (1 приложение)
- Event Logging достаточно для audit trail
- Микросервисы overkill для MVP с single user

**Stack:**
- **Backend:** Python 3.11+ FastAPI (или Flask если проще)
- **Bot:** python-telegram-bot (async)
- **AI:** OpenAI API (GPT-4 + Whisper)
- **Database:** PostgreSQL + SQLAlchemy ORM + Alembic migrations
- **Background Jobs:** APScheduler (простой) или Celery + Redis
- **HTML:** Jinja2 + Tailwind CSS (CDN)
- **Hosting:** Render/Railway/Fly.io (free tier)

**Преимущества этого подхода:**
- ✅ Быстрая разработка (всё в одном месте)
- ✅ Простой deployment (1 приложение + 1 database)
- ✅ Легко debugging (нет distributed system сложности)
- ✅ Можно refactor в микросервисы позже при необходимости

**Component diagram (упрощённый):**
```
User (Telegram)
  ↓ voice message
Telegram Bot API
  ↓ webhook → FastAPI
Voice Handler → Whisper API → transcript
  ↓
NLU & Router (GPT-4 с system prompt)
  ↓
Command Handler (Python functions)
  ↓
PostgreSQL (projects, features, meetings, etc.)
  ↓
Response Generator (GPT-4 + templates)
  ↓
Telegram Bot API → User
```

---

## Starter Template Evaluation

### Primary Technology Domain

**Backend Python + Telegram Bot** — голосовой бот с AI интеграцией

### Technical Preferences Discovery

**Developer Experience Level:** Ограниченный опыт в разработке — будет использоваться AI-помощь (Claude) для написания кода

**Selected Technologies (для простоты и скорости):**

- **Language:** Python 3.11+ (простой синтаксис, лучший для AI проектов)
- **Framework:** Flask 3.x (проще чем FastAPI, меньше boilerplate)
- **Bot Library:** python-telegram-bot v22.6 (async/await, современный)
- **Database:** PostgreSQL + SQLAlchemy ORM (стандарт для Python)
- **Migrations:** Alembic 1.18.1 (автоматические миграции схемы)
- **Jobs:** APScheduler 3.11.2 (проще чем Celery, без Redis)
- **Templates:** Jinja2 (встроен в Flask)
- **Styling:** Tailwind CSS via CDN (без build process)

**Deployment Preferences:**
- **Hosting:** Railway или Render (free tier, простой deploy)
- **Database:** Railway PostgreSQL (free tier, автоматический setup)
- **Dev Mode:** Polling (проще начать), Webhook для prod

---

### Starter Options Considered

**Option 1: Чистый проект от нуля**
- ✅ Полный контроль
- ❌ Нужно всё настраивать вручную (долго для 2 недель)

**Option 2: Flask-SQLAlchemy-Starter**
- ✅ Базовая структура готова
- ❌ Нет Telegram Bot интеграции

**Option 3: Python-telegram-bot examples**
- ✅ Примеры работы с ботом
- ❌ Нет database setup

**Option 4: Custom UBER_PO Starter (выбрано)**
- ✅ Всё необходимое в одном месте
- ✅ Минимальный boilerplate
- ✅ Готово к AI-assisted разработке (Claude пишет код по этой структуре)
- ✅ Простая структура папок — легко понять

---

### Selected Starter: Custom UBER_PO Starter

**Rationale for Selection:**

Для 2-недельного MVP с AI-помощью нужна простая и понятная структура:
1. ✅ Все технологии интегрированы из коробки
2. ✅ Минимум кода — только необходимое
3. ✅ Понятная организация — легко найти где что
4. ✅ AI (Claude) может писать код следуя этой структуре
5. ✅ Простой deploy на Railway в 1 клик

**Initialization Command:**

```bash
# Создание проекта
mkdir uber-po-bot
cd uber-po-bot

# Virtual environment
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Dependencies
pip install python-telegram-bot==22.6 flask==3.0 sqlalchemy==2.0 \
    alembic==1.18.1 apscheduler==3.11.2 openai jinja2 python-dotenv psycopg2-binary

# Создание .env файла
cat > .env << EOF
TELEGRAM_TOKEN=your_bot_token_here
OPENAI_API_KEY=your_openai_key_here
DATABASE_URL=postgresql://localhost/uber_po
YOUR_TELEGRAM_ID=your_telegram_id_here
EOF

# Инициализация Alembic для миграций
alembic init alembic

# Создание requirements.txt
pip freeze > requirements.txt
```

---

### Architectural Decisions Provided by Starter

**Language & Runtime:**
- Python 3.11+ (современный, с type hints)
- Virtual environment (изоляция зависимостей)
- `.env` для секретов (токены не в коде!)

**Bot Framework:**
- python-telegram-bot v22.6 (async/await)
- Polling mode для dev (просто запустить)
- Webhook для prod (лучше production)
- Inline keyboard buttons (быстрые действия)

**Database Stack:**
- PostgreSQL (надёжная реляционная БД)
- SQLAlchemy 2.0 ORM (Python классы → SQL таблицы)
- Alembic миграции (автоматическое обновление схемы)
- Connection pooling (эффективное использование соединений)

**Background Jobs:**
- APScheduler BackgroundScheduler (фоновые задачи)
- Interval jobs (каждую минуту — проверка напоминаний)
- Cron jobs (каждое утро — утренний Radar)
- Persistent в PostgreSQL (задачи не теряются при перезапуске)

**Code Organization:**

```
uber-po-bot/
├── app.py                      # Главный файл — запуск бота
├── config.py                   # Конфигурация из .env
├── requirements.txt            # Список библиотек
├── .env                        # Секреты (НЕ коммитить в git!)
├── .gitignore                  # Что не добавлять в git
├── README.md                   # Инструкции как запустить
├── alembic/                    # Миграции БД
│   ├── versions/              # История изменений схемы
│   └── env.py                 # Настройки Alembic
├── bot/
│   ├── __init__.py
│   ├── handlers/              # Обработчики сообщений
│   │   ├── __init__.py
│   │   ├── voice.py          # Голосовые сообщения
│   │   ├── commands.py       # /start, /help и т.д.
│   │   └── callbacks.py      # Нажатия на кнопки
│   ├── agent.py              # Работа с GPT
│   └── prompts/              # Инструкции для GPT
│       ├── analyst.txt       # Агент-аналитик
│       ├── researcher.txt    # Агент-исследователь
│       ├── pm.txt            # Агент-PM
│       └── risk_manager.txt  # Агент-Risk Manager
├── models/                    # Таблицы БД (SQLAlchemy)
│   ├── __init__.py
│   ├── base.py               # Базовый класс
│   ├── project.py            # Проекты
│   ├── feature.py            # Фичи
│   ├── meeting.py            # Встречи
│   ├── assignment.py         # Поручения
│   ├── artifact.py           # HTML артефакты
│   └── event_log.py          # Audit trail
├── services/                  # Бизнес-логика
│   ├── __init__.py
│   ├── radar.py              # Radar скоринг
│   ├── context.py            # Контекст пользователя
│   └── html_render.py        # Генерация HTML
├── templates/                 # HTML шаблоны (Jinja2)
│   ├── base.html             # Базовый шаблон
│   ├── radar_report.html     # Отчёт Radar
│   ├── meeting_prep.html     # Подготовка к встрече
│   └── research_onepager.html # Исследование
├── static/                    # Статические файлы
│   └── artifacts/            # Сгенерированные HTML
└── jobs/                      # Фоновые задачи
    ├── __init__.py
    ├── reminders.py          # Напоминания
    └── scheduler.py          # Настройка APScheduler
```

**Development Experience:**

- **Flask debug mode:** Автоматический перезапуск при изменении кода
- **SQLAlchemy echo:** Видны все SQL запросы (для отладки)
- **Python logging:** INFO для prod, DEBUG для dev
- **Alembic autogenerate:** Автоматическое создание миграций при изменении моделей

**Простой процесс разработки:**

1. **Пишешь/меняешь код** (с помощью Claude)
2. **Запускаешь бота:** `python app.py`
3. **Тестируешь** в Telegram
4. **Если нужно изменить БД:** `alembic revision --autogenerate -m "описание"` → `alembic upgrade head`
5. **Повторяешь** 1-4 пока не готово

**Deployment на Railway (1 клик):**

1. Push код в GitHub
2. Подключаешь Railway к репозиторию
3. Railway автоматически создаёт PostgreSQL
4. Устанавливает переменные окружения
5. Запускает бота 24/7

**Best Practices (встроены в структуру):**

- ✅ Environment variables для секретов
- ✅ Модульная архитектура (легко найти код)
- ✅ Error handling шаблоны (try/except везде)
- ✅ Logging (понятно что происходит)
- ✅ Database migrations (безопасное изменение схемы)
- ✅ .gitignore (секреты не попадут в git)

**Note:** Эта структура — отправная точка. Claude (AI) будет писать код следуя этой организации, а вы будете тестировать и давать feedback.

---

### AI-Assisted Development Workflow

**Как будет происходить разработка:**

**Sprint 0 (День 1): Инициализация**
- Claude создаёт базовую структуру проекта
- Настраивает все конфиги
- Создаёт первые модели БД
- Вы: запускаете, проверяете что работает

**Sprint 1 (Дни 2-4): Voice + Basic Commands**
- Claude пишет обработчики голоса
- Интегрирует Whisper API
- Создаёт базовые команды (/start, "Создай проект")
- Вы: тестируете голосом, говорите что не работает

**Sprint 2 (Дни 5-8): Radar + Context**
- Claude пишет Radar скоринг
- Реализует контекст проектов
- Добавляет inline кнопки
- Вы: проверяете "Что горит?", тестируете контекст

**Sprint 3 (Дни 9-12): HTML + Jobs**
- Claude создаёт HTML шаблоны
- Настраивает напоминания
- Добавляет исследования
- Вы: проверяете лендинги, тестируете напоминания

**Sprint 4 (Дни 13-14): Polish + Deploy**
- Claude исправляет баги
- Улучшает UI/UX
- Деплоит на Railway
- Вы: финальное тестирование

**Ваша роль:** Тестировать → Говорить что не так → Claude исправляет → Повторить

**Claude роль:** Писать весь код → Объяснять как запустить → Исправлять баги → Деплоить

---

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**

Все critical decisions приняты — разработка может начинаться:

1. ✅ **Database Schema:** Relational tables (строгая структура)
2. ✅ **Authentication:** Hardcoded Telegram ID
3. ✅ **Background Jobs:** APScheduler с persistent storage в PostgreSQL
4. ✅ **Deployment:** Railway (автоматический PostgreSQL, simple deploy)

**Important Decisions (Shape Architecture):**

5. ✅ **Radar Rules Storage:** В коде Python (`services/radar.py`)
6. ✅ **HTML Artifacts Storage:** Локально в `/static/artifacts/`

**Deferred Decisions (Post-MVP):**

- ❌ Multi-user support (не нужно в MVP)
- ❌ Admin UI для Radar rules (hardcoded rules проще для MVP)
- ❌ S3/Cloudflare R2 для HTML (локальное хранилище достаточно)
- ❌ Celery + Redis (APScheduler достаточно)

---

### Data Architecture

**Decision 1.1: Database Schema Approach**
- **Choice:** Relational Tables (Strict Structure)
- **Rationale:**
  - Radar — killer feature, требует быстрых SQL queries
  - SQLAlchemy автоматически создаёт таблицы из моделей
  - Целостность данных (foreign keys, cascades)
  - Проще для AI-assisted development (чёткие связи, no JSON parsing)
- **Affects:** All features (Projects, Features, Meetings, Assignments, Risks, etc.)
- **Implementation:** SQLAlchemy ORM models в `models/` folder

**Decision 1.2: Radar Rules Storage**
- **Choice:** Python Code (functions в `services/radar.py`)
- **Rationale:**
  - Проще для MVP (no admin UI needed)
  - Быстрее (no DB queries для rules)
  - Легко менять (Claude изменяет код → redeploy)
  - Можно мигрировать в БД позже если понадобится UI
- **Affects:** FR-008 (Radar Top-3)
- **Implementation:** Python functions с scoring logic

**Decision 1.3: HTML Artifacts Storage**
- **Choice:** Local Filesystem (`/static/artifacts/`)
- **Rationale:**
  - Проще для MVP (no S3 setup)
  - Бесплатно (no external service)
  - Railway даёт достаточно storage для MVP
  - Можно мигрировать на R2 позже при необходимости
- **Affects:** FR-013 (HTML Artifacts)
- **Implementation:** Generated HTML в `/static/`, Nginx serving

**Database Schema (Core Tables):**

```python
# models/project.py
class Project:
    id, name, description, status, created_at, updated_at

# models/feature.py
class Feature:
    id, project_id, name, description, status, status_reason,
    assigned_teams, assigned_po, release_id, created_at, updated_at

# models/release.py
class Release:
    id, project_id, version, target_date, status, created_at

# models/dependency.py
class Dependency:
    id, blocker_feature_id, blocked_feature_id, created_at

# models/meeting.py
class Meeting:
    id, project_id, title, date, participants, created_at

# models/decision.py
class Decision:
    id, meeting_id, project_id, description, created_at

# models/risk.py
class Risk:
    id, project_id, feature_id, severity, description,
    mitigation, created_at

# models/assignment.py
class Assignment:
    id, project_id, title, assignee, deadline, priority,
    source_type (leader|meeting|self), source_person_id,
    inbox_type (general|leader), reminder_times[], created_at

# models/artifact.py
class Artifact:
    id, project_id, type (report|brief|prep|minutes|research),
    title, content, content_format (json|markdown),
    rendered_html, rendered_url, render_version,
    access_token, expires_at, created_at

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

---

### Authentication & Security

**Decision 2.1: User Authentication**
- **Choice:** Hardcoded Telegram ID в `.env`
- **Rationale:**
  - Single user (только Artem)
  - Простая реализация (no user management)
  - Безопасно (only authorized Telegram ID gets responses)
- **Affects:** All bot interactions
- **Implementation:**
```python
ALLOWED_USER_ID = int(os.getenv('YOUR_TELEGRAM_ID'))

def is_authorized(update):
    return update.message.from_user.id == ALLOWED_USER_ID
```

**Decision 2.2: Data Security**
- **Choice:** Minimal security для MVP
- **Implementation:**
  - HTTPS для webhook (обязательно для Telegram)
  - Voice files не хранятся после транскрипции
  - `.env` для секретов (не в git)
  - PostgreSQL password в environment variables
- **Deferred:** Encryption at rest, GDPR compliance (post-MVP)

---

### API & Communication Patterns

**Decision 3.1: Bot Communication Mode**
- **Choice:** Polling для dev, Webhook для prod
- **Rationale:**
  - Polling проще для local development (no ngrok needed)
  - Webhook лучше для production (lower latency, меньше ресурсов)
  - python-telegram-bot поддерживает оба режима
- **Implementation:** Config switch в `.env`

**Decision 3.2: OpenAI API Integration**
- **Choice:** Direct API calls (no wrappers)
- **Rationale:**
  - Простая интеграция (openai library)
  - Полный контроль над prompts
  - System prompts в файлах (easy to modify)
- **Implementation:**
```python
# bot/agent.py
def call_gpt(prompt_file, user_message):
    system_prompt = load_prompt(prompt_file)
    response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_message}
        ]
    )
    return response.choices[0].message.content
```

**Decision 3.3: Error Handling Strategy**
- **Choice:** Try/Catch с graceful degradation
- **Implementation:**
  - All OpenAI calls wrapped в try/except
  - Retry logic для transient errors (3 retries, exponential backoff)
  - User-friendly error messages в Telegram
  - Logging всех errors

---

### Background Jobs Architecture

**Decision 4.1: Job Scheduler**
- **Choice:** APScheduler BackgroundScheduler
- **Rationale:**
  - Проще чем Celery (no Redis required)
  - Достаточно для single user
  - Persistent storage в PostgreSQL (jobs survive restart)
  - Runs в том же process что бот (проще deployment)
- **Affects:** FR-007 (Reminders), FR-011 (Background Research)
- **Implementation:**
```python
# jobs/scheduler.py
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.jobstores.sqlalchemy import SQLAlchemyJobStore

jobstores = {
    'default': SQLAlchemyJobStore(url=DATABASE_URL)
}
scheduler = BackgroundScheduler(jobstores=jobstores)

# Reminder check every minute
scheduler.add_job(check_reminders, 'interval', minutes=1)

# Morning Radar every day at 8 AM
scheduler.add_job(send_morning_radar, 'cron', hour=8)
```

**Decision 4.2: Background Research**
- **Choice:** APScheduler + long-running jobs
- **Implementation:**
  - User: "Исследуй: тема..." → Create job
  - Job: GPT calls с web search → Generate one-pager
  - Notify user when done via Telegram message

---

### Infrastructure & Deployment

**Decision 5.1: Hosting Platform**
- **Choice:** Railway
- **Rationale:**
  - Free tier (500 hours/month — достаточно для MVP)
  - Auto-deploy from GitHub
  - PostgreSQL включён автоматически
  - Simple UI (проще для non-developer)
  - No sleeping (bot работает 24/7 без "wake up" delays)
- **Affects:** All deployment
- **Implementation:** Connect GitHub repo → Railway auto-deploys

**Decision 5.2: Database Hosting**
- **Choice:** Railway PostgreSQL (managed)
- **Rationale:**
  - Автоматически создаётся с проектом
  - Бесплатный tier достаточно для MVP
  - Automatic backups
  - No manual setup required
- **Implementation:** Railway provides DATABASE_URL automatically

**Decision 5.3: Environment Configuration**
- **Choice:** `.env` для dev, Railway Environment Variables для prod
- **Required Variables:**
```bash
TELEGRAM_TOKEN=...
OPENAI_API_KEY=...
DATABASE_URL=postgresql://...
YOUR_TELEGRAM_ID=123456789
ENVIRONMENT=development|production
```

**Decision 5.4: Logging & Monitoring**
- **Choice:** Python logging module (stdout)
- **Rationale:**
  - Простой setup
  - Railway captures stdout logs
  - Достаточно для MVP debugging
- **Deferred:** Datadog, Sentry (post-MVP)

---

### Decision Impact Analysis

**Implementation Sequence (Priority Order):**

1. **Sprint 0 (Day 1):** Setup project structure, database models, Alembic migrations
2. **Sprint 1 (Days 2-4):** Voice handler, Whisper integration, basic commands, authentication check
3. **Sprint 2 (Days 5-8):** Radar scoring, context resolver, inline buttons, GPT integration with prompts
4. **Sprint 3 (Days 9-12):** HTML renderer, templates, APScheduler setup, reminders, background research
5. **Sprint 4 (Days 13-14):** Bug fixes, UI polish, Railway deployment, final testing

**Cross-Component Dependencies:**

- **Database Models** → All features depend on schema
- **Authentication** → All handlers require auth check first
- **Context Resolver** → Radar, Commands rely on active project context
- **EventLog** → All mutations must log to audit trail
- **GPT Integration** → Agent calls, Researcher, Analyst depend on prompt loading
- **APScheduler** → Reminders, Morning Radar depend on scheduler init

**Technology Versions (Verified 2026-01-29):**

- Python: 3.11+
- Flask: 3.0
- python-telegram-bot: 22.6
- SQLAlchemy: 2.0
- Alembic: 1.18.1
- APScheduler: 3.11.2
- OpenAI: latest
- PostgreSQL: 14+ (Railway managed)
