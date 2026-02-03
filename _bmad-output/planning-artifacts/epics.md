---
stepsCompleted: [1, 2, 3, 4]
inputDocuments:
  - '/Users/baa/my-bmad-project/UBER_PO/_bmad-output/planning-artifacts/PRD-v0.7.md'
  - '/Users/baa/my-bmad-project/UBER_PO/_bmad-output/planning-artifacts/architecture.md'
  - '/Users/baa/my-bmad-project/UBER_PO/_bmad-output/planning-artifacts/ux-design-specification.md'
architectureStatus: 'complete'
architectureDecisions:
  database_schema: 'relational tables (strict structure)'
  radar_rules: 'in Python code'
  html_storage: 'local /static/artifacts/'
  authentication: 'hardcoded Telegram ID'
  background_jobs: 'APScheduler persistent'
  deployment: 'Railway'
epicsApproved: true
totalEpics: 4
totalStories: 28
storiesCreated: true
validationComplete: true
workflowComplete: true
---

# UBER_PO - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for UBER_PO, decomposing the requirements from the PRD, UX Design, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

**FR-001: Проекты и структура**
- Создание проекта голосом
- Система автоматически создаёт разделы проекта (Аналитика, Продукт, Бэклог, Релизы, Встречи, Решения, Риски, Поручения, Исследования, Справки/Документы)
- Поиск проекта/фичи/артефакта голосом
- AC: Проект создаётся с уникальным id и дефолтными папками
- AC: Поиск возвращает результаты за <1 секунду, точность Top-3 ≥ 85%
- AC: При неоднозначности система возвращает Top-3 варианта для выбора

**FR-002: Inbox идей**
- Фиксация идеи голосом
- Система сохраняет идею в Inbox или привязывает к проекту
- Превращение идеи в фичу/документ через workflow
- AC: Идея всегда сохраняется даже при неполной информации
- AC: Система фиксирует аудит создания/линковки идеи к проекту

**FR-003: Фичи (2 недели)**
- Создание фичи с названием, статусом, причиной статуса, командами, PO
- Система сохраняет историю статусов фичи
- AC: Изменение статуса сохраняет аудит с причиной и временной меткой
- AC: Статус фичи влияет на Radar правила (например, Blocked → "горит")

**FR-004: Связи (Dependency)**
- "Фича A блокирует фичу B"
- Система учитывает блокировки в Radar сводках
- AC: Блокировки отражаются в Radar с причиной и explainability

**FR-005: Релизы**
- Создание релиза, добавление/удаление фич, перенос релиза
- Перенос релиза требует подтверждения (дорогая операция)
- AC: Перенос релиза запрашивает подтверждение перед выполнением
- AC: Система сохраняет аудит изменений релиза

**FR-006: Протоколы встреч**
- Система извлекает из голосового протокола: решения, поручения, риски, изменения статусов
- Все извлечённые сущности сохраняются с привязкой к встрече
- AC: Все extracted сущности связаны с уникальным идентификатором встречи
- AC: Система сохраняет аудит создания решений/поручений/рисков

**FR-007: Поручения + напоминания**
- Создание поручения голосом с дедлайном и напоминаниями (за день/2 часа/кастом)
- Система отправляет напоминания в заданное время
- AC: Дедлайн и напоминания сохраняются при создании
- AC: Просроченные поручения учитываются Radar как "горит"

**FR-008: Radar top-3**
- "Что горит?", "Где риск?", "Что изменилось?"
- Система возвращает Top-3 items с explainability
- AC: Каждый Radar item содержит ≥2 причины + ссылки на источники данных (rules + entity links)
- AC: Explainability включает: сработавшие правила, даты, статусы, next step

**FR-009: Meeting Prep**
- Подготовка к встрече
- Система генерирует 1-page prep: статус, вопросы, критичные моменты
- AC: Создаётся Artifact(type=prep) с привязкой к проекту/встрече
- AC: Опционально генерируется HTML view с приватной ссылкой

**FR-010: Справки по проектам/фичам**
- Справка по проекту/фиче
- Система генерирует: цель, описание, метрики, статус, риски, зависимости, релизы, изменения
- AC: Создаётся Artifact(type=brief)
- AC: Опционально генерируется HTML view с приватной ссылкой

**FR-011: Исследования "не тревожь меня"**
- Фоновое исследование
- Система возвращает one-pager с 7 разделами: вопрос, альтернативы, сравнение, рекомендация, риски, допущения, next steps, источники
- AC: Система сохраняет источники и допущения явно
- AC: Создаётся Artifact(type=research) со structured format (7 разделов)

**FR-012: Мультиагентная архитектура**
- Система поддерживает registry агентов, ручной вызов, guided workflows, party mode
- Трассировка: каждая операция фиксирует агента, входы, артефакты
- Agents/Workflows/Rules хранятся как code (YAML/JSON)
- AC: Аудит и трассировка обязательны для всех операций
- AC: Версии конфигов фиксируются при изменении

**FR-013: Auto Rendered HTML Artifacts**
- Система генерирует HTML view для артефактов: report, brief, prep, minutes
- Артефакты доступны через приватные ссылки с TTL=7 дней
- AC: Приватная ссылка содержит трудноугадываемый токен, TTL=7 дней
- AC: Система фиксирует события `artifact_rendered`, `artifact_viewed` в аудите

**FR-014: Leader Tasks Inbox**
- Создание поручения от руководителя
- Система создаёт отдельный inbox для leader-поручений с guided review
- Leader P1 поручения влияют на Radar с повышенным приоритетом
- AC: Assignment(source=leader, inbox=leader) создаётся при каждом leader-поручении
- AC: Leader P1 overdue/≤24ч не подавляется супрессией в Radar

### NonFunctional Requirements

**NFR-001: Performance**
- API response time < 200ms для 95th percentile запросов под нормальной нагрузкой
- ASR latency < 2 секунды от получения voice file до транскрипта
- Radar generation < 5 секунд для 20 проектов + 200 фич
- Метод измерения: APM tracing + performance logs

**NFR-002: Reliability**
- Uptime ≥ 99.5% в месячном измерении
- Message delivery guarantee: каждое voice message обрабатывается ровно 1 раз (idempotency через ingestion_id)
- Audit durability: EventLog append-only, сохраняется навсегда, репликация в 3 датацентрах
- Метод измерения: Uptime monitoring (Pingdom) + audit log integrity checks

**NFR-003: Security & Privacy**
- Voice file encryption: AES-256 at rest, TLS 1.3 in transit
- User consent: обязательное согласие перед первой обработкой голоса
- Voice retention policy: 30 дней, затем автоудаление (GDPR compliance)
- Audit trail: end-to-end audit всех доступов к данным пользователя, retention 90 дней
- Метод измерения: Security audit + penetration testing + GDPR compliance check

**NFR-004: Scalability**
- 100 concurrent users без деградации latency
- 1000 daily messages per user обрабатываются без queue delays
- PostgreSQL до 10M events в EventLog без performance degradation (p95 query latency < 500ms)
- Метод измерения: Load testing (k6/Locust) + database performance monitoring

**NFR-005: Observability**
- Distributed tracing coverage: 100% всех операций (message → workflow → agent → db → artifact)
- P95 query latency < 500ms для trace lookups
- Metrics: ASR accuracy, NLU intent/slot accuracy, Command Success Rate, Context Correctness Rate
- Метод измерения: OpenTelemetry + Jaeger/Tempo + Prometheus/Grafana

**NFR-006: Accessibility**
- Text-only fallback mode: все voice commands доступны через text input для пользователей с ограничениями речи
- HTML artifacts WCAG 2.1 AA compliant: screen reader support для всех артефактов
- Alternative input methods: text commands для всех voice commands
- Метод измерения: WCAG audit + manual accessibility testing

**NFR-007: Data Residency**
- Data stored in user-specified region (EU/US/Asia)
- No cross-border data transfer без explicit consent
- Regional PostgreSQL instances для compliance
- Метод измерения: Infrastructure audit + data flow tracing

### Additional Requirements

**Из Architecture (КРИТИЧЕСКИЕ РЕШЕНИЯ ДЛЯ MVP):**

**MVP Constraints (2 недели):**
- **Timeline:** 2 weeks (14 дней)
- **Users:** Single user (Artem) — hardcoded Telegram ID в .env
- **Developer Experience:** Limited — AI-assisted development (Claude пишет весь код, Artem тестирует)
- **Agents:** GPT-4 with system prompts (не сложная orchestration, просто файлы prompts/*.txt)
- **HTML Artifacts:** Required (критично для CEO презентаций)

**Critical Architectural Decisions (блокируют implementation):**

1. ✅ **Database Schema:** Relational tables (strict structure) — PostgreSQL + SQLAlchemy ORM
2. ✅ **Authentication:** Hardcoded Telegram ID в .env (только Artem)
3. ✅ **Background Jobs:** APScheduler с persistent storage в PostgreSQL (jobs survive restart)
4. ✅ **Deployment:** Railway (автоматический PostgreSQL, simple deploy, free tier 500 hours/month)

**Important Architectural Decisions (формируют архитектуру):**

5. ✅ **Radar Rules Storage:** В коде Python (`services/radar.py` — простые функции scoring)
6. ✅ **HTML Artifacts Storage:** Локально в `/static/artifacts/` (не S3, Railway даёт достаточно storage)
7. ✅ **Bot Communication Mode:** Polling для dev (no ngrok), Webhook для prod (Railway автоматически настроит HTTPS)
8. ✅ **OpenAI Integration:** Direct API calls (openai library, system prompts в файлах)
9. ✅ **Error Handling:** Try/Catch с graceful degradation + retry logic (3 retries, exponential backoff)

**Deferred Decisions (Post-MVP):**
- ❌ Multi-user support (не нужно в MVP)
- ❌ Admin UI для Radar rules (hardcoded rules проще)
- ❌ S3/Cloudflare R2 для HTML (локальное хранилище достаточно)
- ❌ Celery + Redis (APScheduler достаточно)
- ❌ Encryption at rest, GDPR compliance (post-MVP)

**Starter Template & Stack (финальный выбор):**
- **Framework:** Flask 3.x (проще чем FastAPI, меньше boilerplate)
- **Bot Library:** python-telegram-bot v22.6 (async/await)
- **Database:** PostgreSQL + SQLAlchemy 2.0 ORM + Alembic 1.18.1 migrations
- **Background Jobs:** APScheduler 3.11.2 (без Redis, persistent в PostgreSQL)
- **AI:** OpenAI API (GPT-4 для NLU/responses, Whisper для ASR)
- **Templates:** Jinja2 (встроен в Flask)
- **Styling:** Tailwind CSS via CDN (без build process)
- **Language:** Python 3.11+ (simple syntax, AI-friendly)

**Database Schema (Core Tables — SQLAlchemy Models):**

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

**Code Organization (Custom UBER_PO Starter):**

```
uber-po-bot/
├── app.py                      # Главный файл — запуск бота
├── config.py                   # Конфигурация из .env
├── requirements.txt            # Список библиотек
├── .env                        # Секреты (НЕ коммитить!)
├── .gitignore
├── README.md
├── alembic/                    # Миграции БД
│   ├── versions/
│   └── env.py
├── bot/
│   ├── __init__.py
│   ├── handlers/              # Обработчики сообщений
│   │   ├── voice.py          # Голосовые сообщения
│   │   ├── commands.py       # /start, /help
│   │   └── callbacks.py      # Нажатия на кнопки
│   ├── agent.py              # Работа с GPT
│   └── prompts/              # System prompts для агентов
│       ├── analyst.txt
│       ├── researcher.txt
│       ├── pm.txt
│       └── risk_manager.txt
├── models/                    # Таблицы БД (SQLAlchemy)
│   ├── base.py
│   ├── project.py
│   ├── feature.py
│   ├── meeting.py
│   ├── assignment.py
│   ├── artifact.py
│   └── event_log.py          # Audit trail
├── services/                  # Бизнес-логика
│   ├── radar.py              # Radar скоринг (Python функции)
│   ├── context.py            # Контекст пользователя
│   └── html_render.py        # Генерация HTML
├── templates/                 # HTML шаблоны (Jinja2)
│   ├── base.html
│   ├── radar_report.html
│   ├── meeting_prep.html
│   └── research_onepager.html
├── static/                    # Статические файлы
│   └── artifacts/            # Сгенерированные HTML (локальное хранение)
└── jobs/                      # Фоновые задачи
    ├── reminders.py          # Напоминания
    └── scheduler.py          # APScheduler setup
```

**Initialization Command (для Epic 1 Story 1):**

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
ENVIRONMENT=development
EOF

# Инициализация Alembic для миграций
alembic init alembic

# Создание requirements.txt
pip freeze > requirements.txt
```

**Technology Versions (Verified 2026-01-29):**
- Python: 3.11+
- Flask: 3.0
- python-telegram-bot: 22.6
- SQLAlchemy: 2.0
- Alembic: 1.18.1
- APScheduler: 3.11.2
- OpenAI: latest
- PostgreSQL: 14+ (Railway managed)

**Infrastructure Decisions:**

- **PostgreSQL Schema:** Relational tables (strict structure) с явными связями через foreign keys
  - Projects ↔ Features ↔ Releases
  - Features ↔ Dependencies (blocker/blocked)
  - Meetings ↔ Decisions ↔ Risks ↔ Assignments
  - Artifacts ↔ Projects
  - EventLog (append-only audit trail)
  - UserContext (активный проект)
  - ProcessedMessage (idempotency check)

- **Idempotency:** Каждое Telegram message имеет уникальный message_id
  - Используем как ingestion_id
  - Check before processing: `if message_id in processed_messages: skip`
  - Предотвращает дубликаты при retry

- **Context Resolver:** Активный проект хранится в user_context table
  - Каждый ответ начинается с: `Контекст: Проект X`
  - Переключение: "Переключись на проект Y"
  - При неоднозначности: Top-3 варианта с inline-кнопками

- **Bot Communication Modes:**
  - Dev: Polling (no ngrok needed, просто запустить)
  - Prod: Webhook (Railway автоматически настроит HTTPS)
  - Config switch в .env: `ENVIRONMENT=development|production`

- **Authentication Check (все handlers):**
```python
ALLOWED_USER_ID = int(os.getenv('YOUR_TELEGRAM_ID'))

def is_authorized(update):
    return update.message.from_user.id == ALLOWED_USER_ID
```

- **GPT Integration (bot/agent.py):**
```python
def call_gpt(prompt_file, user_message):
    system_prompt = load_prompt(prompt_file)  # prompts/analyst.txt
    response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_message}
        ]
    )
    return response.choices[0].message.content
```

- **APScheduler Setup (jobs/scheduler.py):**
```python
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

- **Error Handling Strategy:**
  - All OpenAI calls wrapped в try/except
  - Retry logic для transient errors (3 retries, exponential backoff)
  - User-friendly error messages в Telegram
  - Logging всех errors

**Deployment на Railway (Epic 4 Final Step):**

1. Push код в GitHub
2. Подключить Railway к репозиторию
3. Railway автоматически создаёт PostgreSQL (DATABASE_URL)
4. Устанавливает environment variables:
   - TELEGRAM_TOKEN
   - OPENAI_API_KEY
   - YOUR_TELEGRAM_ID
   - ENVIRONMENT=production
5. Запускает бота 24/7 (free tier: 500 hours/month)

**Logging & Monitoring (MVP):**
- Python logging module (stdout) — Railway captures logs
- EventLog таблица в PostgreSQL (audit trail)
- Print statements для debugging
- Deferred: Datadog, Sentry (post-MVP)

**Development Workflow (AI-assisted, 2 weeks = 4 sprints):**

**Sprint 0 (Day 1): Инициализация**
- Claude создаёт базовую структуру проекта (папки, файлы)
- Настраивает все конфиги (.env, requirements.txt, alembic)
- Создаёт первые модели БД (Project, Feature, Meeting, Assignment, Artifact, EventLog, UserContext, ProcessedMessage)
- Artem: запускает, проверяет что работает (`python app.py`)

**Sprint 1 (Days 2-4): Voice + Basic Commands**
- Claude пишет обработчики голоса (bot/handlers/voice.py)
- Интегрирует Whisper API (ASR)
- Создаёт базовые команды (/start, "Создай проект", "Создай фичу")
- Добавляет authentication check (is_authorized)
- Artem: тестирует голосом, говорит что не работает

**Sprint 2 (Days 5-8): Radar + Context**
- Claude пишет Radar скоринг (services/radar.py — Python функции)
- Реализует Context Resolver (services/context.py)
- Добавляет inline кнопки (InlineKeyboardMarkup)
- Интегрирует GPT-4 с system prompts (bot/agent.py)
- Artem: проверяет "Что горит?", тестирует контекст, переключение проектов

**Sprint 3 (Days 9-12): HTML + Jobs**
- Claude создаёт HTML шаблоны (templates/*.html, Jinja2 + Tailwind CSS CDN)
- Настраивает APScheduler (jobs/scheduler.py, jobs/reminders.py)
- Добавляет фоновые исследования (GPT web search → one-pager)
- Генерирует HTML artifacts (/static/artifacts/, приватные ссылки)
- Artem: проверяет лендинги для CEO, тестирует напоминания

**Sprint 4 (Days 13-14): Polish + Deploy**
- Claude исправляет баги (на основе фидбека Artem)
- Улучшает UI/UX (inline кнопки, структура ответов)
- Деплоит на Railway (GitHub push → Railway auto-deploy)
- Настраивает environment variables в Railway
- Artem: финальное тестирование в prod

**Ваша роль (Artem):** Тестировать → Говорить что не так → Claude исправляет → Повторить

**Claude роль:** Писать весь код → Объяснять как запустить → Исправлять баги → Деплоить

**NFR Adjustments для 2-week MVP:**

**Performance (релаксированы для MVP):**
- API response < 500ms для 95th percentile (вместо 200ms) — acceptable для single user
- Whisper API < 3 сек (вместо 2 сек) — зависит от OpenAI, но acceptable
- Radar generation < 10 сек для 20 проектов (вместо 5 сек) — SQL queries быстрые

**Reliability (упрощённо для MVP):**
- ✅ Idempotency через ingestion_id (критично — предотвращает дубликаты)
- ✅ EventLog append-only (простая таблица в PostgreSQL)
- ⚠️ Uptime: "best effort" (не 99.5%, но достаточно для личного использования)

**Security & Privacy (минимально необходимое):**
- ✅ Hardcoded Telegram ID (только Artem имеет доступ)
- ✅ Voice файлы не хранятся после транскрипции (экономия места + privacy)
- ✅ HTTPS для webhook (обязательно для Telegram, Railway автоматически)
- ✅ `.env` для секретов (не в git!)
- ❌ Encryption at rest: Skip for MVP
- ❌ GDPR compliance: Skip for MVP (можно добавить позже)

**Scalability (не критично для MVP):**
- Single user — нет проблем с масштабированием
- PostgreSQL справится с 10k-100k записей без проблем
- Можно масштабировать позже при необходимости

**Observability (минимально):**
- ✅ Python logging module (stdout) — Railway captures logs
- ✅ Print statements для debugging
- ✅ EventLog таблица в PostgreSQL (audit trail)
- ❌ Distributed tracing: Skip for MVP (overkill)
- ❌ Datadog/Sentry: Skip for MVP (дорого)

**Accessibility:**
- ✅ Text fallback для voice commands (все команды доступны через текст)
- ✅ WCAG 2.1 AA для HTML artifacts (screen reader support)

**Data Residency:**
- ❌ Skip for MVP (можно добавить позже)

**Implementation Sequence (Priority Order из Architecture):**

1. **Sprint 0 (Day 1):** Setup project structure, database models, Alembic migrations
2. **Sprint 1 (Days 2-4):** Voice handler, Whisper integration, basic commands, authentication check
3. **Sprint 2 (Days 5-8):** Radar scoring, context resolver, inline buttons, GPT integration with prompts
4. **Sprint 3 (Days 9-12):** HTML renderer, templates, APScheduler setup, reminders, background research
5. **Sprint 4 (Days 13-14):** Bug fixes, UI polish, Railway deployment, final testing

**Cross-Component Dependencies (критично для порядка разработки):**

- **Database Models** → All features depend on schema
- **Authentication** → All handlers require auth check first
- **Context Resolver** → Radar, Commands rely on active project context
- **EventLog** → All mutations must log to audit trail
- **GPT Integration** → Agent calls, Researcher, Analyst depend on prompt loading
- **APScheduler** → Reminders, Morning Radar depend on scheduler init

**Из UX Design:**

**Voice-first с inline-кнопками:**
- 90% ввод голосом, 10% текст
- Структурированный текстовый output с inline-кнопками Telegram
- Quick actions: [✅ Подтвердить] [❌ Отменить] [📊 Подробнее] [❓ Почему?]
- Никаких форм с полями — только голос + кнопки для подтверждения

**Контекстная видимость:**
- Каждый ответ начинается с `Контекст: Проект X` или `Контекст: Все проекты`
- Явный индикатор активного проекта/режима в каждом ответе
- Режим агента показывается: `Режим: Агент Researcher`

**Адаптивная глубина ответов:**
- Radar (утро понедельника): 30 секунд → Top-3 кратко
- Meeting Prep (за 10 минут до встречи): 2-3 минуты → статус + вопросы + риски
- Research "не тревожь меня": 15-30 минут в фоне → structured one-pager

**HTML Артефакты (критично для CEO презентаций!):**
- Jinja2 templates: `radar_report.html`, `research_onepager.html`, `meeting_prep.html`, `project_brief.html`
- Tailwind CSS для профессионального вида
- Приватные ссылки `/artifacts/{random_token}` с TTL=7 дней
- Responsive design (Tailwind responsive classes)
- WCAG 2.1 AA compliant для accessibility

**Эмоциональные требования:**
- "Спокойствие через контроль" → Radar Trust ≥ 80% (доля items, где explainability признана полезной)
- "Доверие" → Command Success Rate ≥ 85% (голос→правильное действие без ремонта)
- "Профессионализм" → красивые HTML лендинги для презентации идей руководству
- "Эффективность" → экономия 30-60 минут в день

**Repair/Undo:**
- "Отмени последнее" должно работать (откат последней операции с аудитом)
- "Нет, я имел в виду проект X, а не Z" → исправление контекста
- Repair/Undo Rate ≤ 15% (доля команд, требующих исправления)

**System Prompts для агентов:**
- `prompts/orchestrator.txt`: маршрутизация, workflow-шаги, handoff, QC
- `prompts/analyst.txt`: брифы/структуры/справки v1, уточнения
- `prompts/pm.txt`: PRD-lite, user stories, AC
- `prompts/researcher.txt`: "не тревожь", one-pager, источники/допущения
- `prompts/meeting_secretary.txt`: minutes → decisions/actions/risks/changes
- `prompts/risk_manager.txt`: "где риск/что горит" + причины
- `prompts/release_manager.txt`: релизы/переносы/состав
- `prompts/reviewer.txt`: чеклисты полноты/согласованности/стандарты R9
- Загружаются динамически в зависимости от команды/workflow

### FR Coverage Map

| FR | Epic | Description |
|----|------|-------------|
| FR-001 | Epic 1 | Проекты и структура — голосовое создание |
| FR-002 | Epic 1 | Inbox идей — голосовая фиксация |
| FR-003 | Epic 1 | Фичи — создание, статусы голосом |
| FR-004 | Epic 2 | Dependency tracking → блокировки влияют на Radar |
| FR-005 | Epic 1 | Релизы — создание, добавление фич |
| FR-006 | Epic 3 | Протоколы встреч → auto-extraction |
| FR-007 | Epic 3 | Поручения + напоминания |
| FR-008 | Epic 2 | Radar Top-3 с explainability |
| FR-009 | Epic 3 | Meeting Prep за 2 минуты |
| FR-010 | Epic 3 | Справки для CEO (HTML) |
| FR-011 | Epic 4 | Исследования "не тревожь меня" |
| FR-012 | Epic 2, 4 | Мультиагентность (prompts + researcher) |
| FR-013 | Epic 3 | HTML Artifacts (лендинги для CEO) |
| FR-014 | Epic 3 | Leader Tasks Inbox |

## Epic List

### Epic 1: Voice Capture — Быстрая фиксация проектов и задач голосом

Artem может **мгновенно фиксировать любую информацию голосом** без форм и кликов — проекты, фичи, идеи сохраняются в базу за 10 секунд.

**FRs covered:** FR-001, FR-002, FR-003, FR-005, NFR-002, Architecture (Database models, Authentication, Whisper, Basic commands)

**Sprint:** Sprint 0 + Sprint 1 (Days 1-4)

### Epic 2: Intelligence Radar — Система раннего предупреждения

Artem может **мгновенно увидеть все проблемы** в 20 проектах через команду "Что горит?" — система сама находит блокировки, риски, просроченные задачи и объясняет почему.

**FRs covered:** FR-004, FR-008, FR-012 (partial), Architecture (Radar scoring, Context Resolver, GPT integration), UX (Inline-кнопки, explainability)

**Sprint:** Sprint 2 (Days 5-8)

### Epic 3: Workflow Automation — Встречи, поручения, презентации для CEO

Artem может **автоматизировать рутину**: надиктовать протокол встречи (система извлечёт решения/поручения), получить напоминания о дедлайнах, и сгенерировать красивый HTML-лендинг для презентации CEO.

**FRs covered:** FR-006, FR-007, FR-009, FR-010, FR-013, FR-014, Architecture (APScheduler, HTML rendering)

**Sprint:** Sprint 3 (Days 9-12)

### Epic 4: Autonomous Research — Делегирование исследований + Production

Artem может **делегировать исследования** системе ("Не тревожь меня") и получить готовый one-pager утром, а также иметь **работающий 24/7 бот** на Railway.

**FRs covered:** FR-011, FR-012 (full), NFR-001, NFR-002, NFR-003, Architecture (Railway deployment, Webhook mode, Background research)

**Sprint:** Sprint 3 (partial) + Sprint 4 (Days 9-14)

---

## Epic 1: Voice Capture — Быстрая фиксация проектов и задач голосом

**Goal:** Artem может мгновенно фиксировать любую информацию голосом без форм и кликов — проекты, фичи, идеи сохраняются в базу за 10 секунд.

### Story 1.1: Project Initialization & Setup

As a developer,
I want to initialize the UBER_PO bot project structure with all required dependencies,
So that I have a working foundation ready for development.

**Acceptance Criteria:**

**Given** I have Python 3.11+ installed
**When** I run the initialization commands
**Then** the project structure is created with all folders (bot/, models/, services/, templates/, static/, jobs/)
**And** all dependencies are installed (python-telegram-bot==22.6, flask==3.0, sqlalchemy==2.0, alembic==1.18.1, apscheduler==3.11.2, openai, jinja2, python-dotenv, psycopg2-binary)
**And** .env file is created with placeholders for TELEGRAM_TOKEN, OPENAI_API_KEY, DATABASE_URL, YOUR_TELEGRAM_ID, ENVIRONMENT
**And** .gitignore is configured to exclude .env, venv/, __pycache__/, *.pyc
**And** requirements.txt contains all pinned versions
**And** README.md has setup instructions

**Given** the project structure is initialized
**When** I run `python app.py`
**Then** the application starts without errors
**And** I see "Bot initialization successful" in logs

### Story 1.2: Database Foundation — Core Models

As a developer,
I want to create the core database models for Projects, Features, and audit logging,
So that I can store user data with proper structure and relationships.

**Acceptance Criteria:**

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

### Story 1.3: Telegram Bot Integration & Authentication

As Artem,
I want the bot to authenticate only my Telegram ID and respond to /start command,
So that only I can use the bot.

**Acceptance Criteria:**

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

### Story 1.4: Voice Recognition with Whisper API

As Artem,
I want to send voice messages to the bot and receive transcriptions,
So that I can interact with the system using voice instead of typing.

**Acceptance Criteria:**

**Given** OpenAI library is installed and OPENAI_API_KEY is set in .env
**When** I create bot/handlers/voice.py with voice message handler
**Then** handler function `handle_voice(update, context)` exists

**Given** voice handler exists
**When** unauthorized user sends voice message
**Then** bot responds with "Извините, доступ запрещён."
**And** no voice processing occurs

**Given** voice handler exists and user is authorized
**When** I send a voice message to the bot
**Then** bot downloads voice file from Telegram using `update.message.voice.get_file()`
**And** bot saves voice file temporarily to `/tmp/{message_id}.ogg`

**Given** voice file is downloaded
**When** bot calls Whisper API
**Then** bot opens voice file and calls `openai.Audio.transcribe(model="whisper-1", file=audio_file, language="ru")`
**And** bot receives transcript text

**Given** transcript is received
**When** processing completes
**Then** bot deletes temporary voice file from `/tmp/`
**And** voice file is NOT stored permanently

**Given** transcript text exists
**When** transcription is successful
**Then** bot responds to user with: "🎤 Распознано: {transcript_text}"
**And** EventLog records: user_id, action='voice_transcribed', entity_type='message', entity_id=message_id, details={'transcript': transcript_text, 'duration': voice_duration}

**Given** voice handler is implemented
**When** I send 5-second voice message "Создай проект Mobile App"
**Then** bot responds within 3 seconds with transcription
**And** transcript accuracy is at least 90% for clear Russian speech

**Given** Whisper API call fails (network error, API down)
**When** bot attempts transcription
**Then** bot retries up to 3 times with exponential backoff (1s, 2s, 4s)
**And** if all retries fail, bot responds: "Ошибка распознавания голоса. Попробуйте ещё раз или введите текстом."
**And** EventLog records error details

**Given** voice handler is complete
**When** I check ProcessedMessage table after voice processing
**Then** message_id is recorded to prevent duplicate processing
**And** if same message_id is received again (retry), bot responds immediately without reprocessing

### Story 1.5: Create Project Command via Voice

As Artem,
I want to say "Создай проект Mobile App" and have the project created in the database,
So that I can quickly capture project information without forms.

**Acceptance Criteria:**

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

### Story 1.6: Feature Management via Voice

As Artem,
I want to create features and update their status via voice commands,
So that I can track work without manual data entry.

**Acceptance Criteria:**

**Given** NLU parser exists
**When** transcript is "Создай фичу интеграция аналитики"
**Then** parser returns {'command': 'create_feature', 'feature_name': 'интеграция аналитики'}

**Given** NLU identifies create_feature command
**When** I create `handle_create_feature(feature_name, project_id, user_id)` in bot/handlers/commands.py
**Then** function creates Feature in database with name=feature_name, project_id=active_project_id, status='backlog'
**And** EventLog records: action='feature_created', entity_type='feature', entity_id=new_feature_id

**Given** active project context exists (UserContext.active_project_id is set)
**When** I say "Создай фичу интеграция аналитики"
**Then** Feature is created with project_id = active_project_id
**And** bot responds: "✅ Фича 'интеграция аналитики' создана в проекте 'Mobile App'. Статус: backlog"

**Given** no active project context (UserContext.active_project_id is NULL)
**When** I say "Создай фичу интеграция аналитики"
**Then** bot responds: "❓ Сначала выберите проект. Скажите: 'Переключись на проект [название]' или создайте новый проект."
**And** no feature is created

**Given** NLU parser exists
**When** transcript is "Фича интеграция аналитики готова"
**Then** parser returns {'command': 'update_feature_status', 'feature_name': 'интеграция аналитики', 'new_status': 'готова'}

**Given** NLU identifies update_feature_status command
**When** I create `handle_update_feature_status(feature_name, new_status, project_id, user_id)`
**Then** function finds Feature by name in active project
**And** function updates Feature.status = map_status(new_status) where map maps 'готова' → 'done', 'в работе' → 'in_progress', 'заблокирована' → 'blocked'
**And** EventLog records: action='feature_status_updated', entity_type='feature', entity_id, details={'old_status': old, 'new_status': new, 'reason': reason if provided}

**Given** feature "интеграция аналитики" exists in active project
**When** I say "Фича интеграция аналитики готова"
**Then** Feature.status is updated to 'done'
**And** Feature.updated_at is set to now
**And** bot responds: "✅ Статус фичи 'интеграция аналитики' изменён: backlog → done"

**Given** feature name is ambiguous (multiple matches)
**When** I say "Фича интеграция готова"
**Then** bot responds with Top-3 matches and inline buttons:
"❓ Найдено несколько фич:
[1️⃣ интеграция аналитики] [2️⃣ интеграция платежей] [3️⃣ интеграция уведомлений]"
**And** I can click button to select correct feature

**Given** feature does not exist
**When** I say "Фича несуществующая готова"
**Then** bot responds: "❌ Фича 'несуществующая' не найдена в проекте 'Mobile App'. Создайте её сначала."

### Story 1.7: Ideas Inbox — Quick Capture

As Artem,
I want to quickly capture ideas via voice even without specifying a project,
So that no thoughts are lost.

**Acceptance Criteria:**

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

---

## Epic 2: Intelligence Radar — Система раннего предупреждения

**Goal:** Artem может мгновенно увидеть все проблемы в 20 проектах через команду "Что горит?" — система сама находит блокировки, риски, просроченные задачи и объясняет почему.

### Story 2.1: Context Management — Project Switching

As Artem,
I want to switch between projects via voice commands and see the active context in every response,
So that I always know which project I'm working with.

**Acceptance Criteria:**

**Given** I create services/context.py with ContextResolver class
**When** ContextResolver is initialized
**Then** it can get and set active project for a user_id

**Given** ContextResolver exists
**When** I create `get_active_project(user_id)` method
**Then** method queries UserContext table for user_id
**And** returns active_project_id or None if not set

**Given** ContextResolver exists
**When** I create `set_active_project(user_id, project_id)` method
**Then** method inserts or updates UserContext with user_id and project_id
**And** sets updated_at to now

**Given** NLU parser exists
**When** transcript is "Переключись на проект Mobile App"
**Then** parser returns {'command': 'switch_project', 'project_name': 'Mobile App'}

**Given** switch_project command is identified
**When** I create `handle_switch_project(project_name, user_id)` in bot/handlers/commands.py
**Then** function searches for Project by name (case-insensitive, partial match)
**And** if found: updates UserContext.active_project_id
**And** if not found: responds with "Проект не найден"
**And** if multiple matches: shows Top-3 with inline buttons

**Given** project "Mobile App" exists
**When** I say "Переключись на проект Mobile App"
**Then** UserContext.active_project_id is updated to Mobile App project_id
**And** bot responds: "✅ Контекст переключён на проект 'Mobile App'"

**Given** I create response formatting function `format_response(message, user_id)`
**When** function is called
**Then** it prepends "Контекст: {active_project_name}" to message if active project exists
**And** it prepends "Контекст: Все проекты" if active_project_id is NULL

**Given** active project is "Mobile App"
**When** bot sends any response
**Then** response starts with "Контекст: Проект Mobile App\n\n{actual_message}"

### Story 2.2: Dependency Tracking

As Artem,
I want to mark features as blocking each other,
So that Radar can identify blocked features.

**Acceptance Criteria:**

**Given** I need to track dependencies
**When** I create models/dependency.py
**Then** Dependency model has fields: id (PK), blocker_feature_id (FK to Feature), blocked_feature_id (FK to Feature), created_at
**And** migration is created and applied

**Given** NLU parser exists
**When** transcript is "Фича интеграция аналитики блокирует фичу дашборд метрик"
**Then** parser returns {'command': 'create_dependency', 'blocker_name': 'интеграция аналитики', 'blocked_name': 'дашборд метрик'}

**Given** create_dependency command is identified
**When** I create `handle_create_dependency(blocker_name, blocked_name, project_id, user_id)`
**Then** function finds blocker Feature by name in active project
**And** function finds blocked Feature by name in active project
**And** creates Dependency with blocker_feature_id and blocked_feature_id
**And** EventLog records: action='dependency_created'

**Given** features "интеграция аналитики" and "дашборд метрик" exist
**When** I say "Фича интеграция аналитики блокирует фичу дашборд метрик"
**Then** Dependency is created
**And** bot responds: "✅ Зависимость создана: 'интеграция аналитики' блокирует 'дашборд метрик'"

**Given** dependency exists
**When** I query Feature with relationships
**Then** Feature has `blockers` (features that block this one) and `blocking` (features this one blocks) relationships

### Story 2.3: GPT Integration with System Prompts

As Artem,
I want the bot to use GPT-4 with different system prompts for different tasks,
So that responses are contextual and intelligent.

**Acceptance Criteria:**

**Given** I create bot/agent.py
**When** I create `load_prompt(prompt_file)` function
**Then** function reads file from bot/prompts/{prompt_file}.txt
**And** returns content as string

**Given** I create bot/prompts/analyst.txt
**Then** file contains system prompt: "Ты аналитик проектов. Твоя задача: структурировать информацию, создавать справки и отчёты. Отвечай кратко, используй маркированные списки. Всегда указывай источники данных."

**Given** I create bot/prompts/risk_manager.txt
**Then** file contains: "Ты Risk Manager. Твоя задача: находить проблемы, блокировки, риски. Для каждой проблемы объясняй: почему это проблема + что делать дальше. Используй приоритизацию: P1 (критично), P2 (важно), P3 (можно отложить)."

**Given** load_prompt function exists
**When** I create `call_gpt(prompt_file, user_message, context=None)` function in bot/agent.py
**Then** function loads system prompt from prompt_file
**And** constructs messages: [{"role": "system", "content": system_prompt}, {"role": "user", "content": user_message}]
**And** if context provided: adds context to user_message
**And** calls `openai.ChatCompletion.create(model="gpt-4", messages=messages)`
**And** returns response.choices[0].message.content

**Given** call_gpt function exists
**When** OpenAI API call fails
**Then** function retries up to 3 times with exponential backoff (1s, 2s, 4s)
**And** if all retries fail: raises exception with error details
**And** logs error to EventLog

**Given** GPT integration works
**When** I test with prompt_file='analyst', user_message='Создай справку по проекту X'
**Then** GPT returns structured response following analyst prompt style

### Story 2.4: Radar Scoring Engine

As Artem,
I want the system to automatically score projects and features to identify "what's burning",
So that I can see top problems instantly.

**Acceptance Criteria:**

**Given** I create services/radar.py
**When** I create `RadarScorer` class
**Then** class has methods: `score_feature(feature)`, `score_project(project)`, `get_top_issues(user_id, limit=3)`

**Given** RadarScorer exists
**When** I implement `score_feature(feature)` method
**Then** method calculates score based on:
- Feature.status == 'blocked' → +50 points
- Dependency exists where this feature is blocked → +30 points
- Feature linked to Release with target_date ≤ 7 days → +40 points
- Feature.status == 'in_progress' for > 14 days → +20 points
**And** returns {'score': int, 'reasons': [list of why], 'next_steps': [list of actions]}

**Given** score_feature method exists
**When** feature is blocked and linked to release in 5 days
**Then** score = 50 (blocked) + 40 (release soon) = 90
**And** reasons = ['Фича заблокирована', 'Релиз через 5 дней']
**And** next_steps = ['Разблокировать фичу', 'Проверить зависимости']

**Given** RadarScorer exists
**When** I implement `get_top_issues(user_id, limit=3)` method
**Then** method gets active_project_id from UserContext
**And** if active_project_id: scores all features in that project
**And** if active_project_id is NULL: scores all features across all projects
**And** sorts by score descending
**And** returns top N items with {feature, project, score, reasons, next_steps}

**Given** multiple features with different scores exist
**When** I call `get_top_issues(user_id, limit=3)`
**Then** returns exactly 3 highest-scoring items
**And** each item includes full explainability (reasons + next_steps)

### Story 2.5: "Что горит?" Command with Explainability

As Artem,
I want to ask "Что горит?" and see Top-3 problems with explanations,
So that I instantly know what needs attention.

**Acceptance Criteria:**

**Given** NLU parser exists
**When** transcript is "Что горит?"
**Then** parser returns {'command': 'radar_burning'}

**Given** radar_burning command identified
**When** I create `handle_radar_burning(user_id)` in bot/handlers/commands.py
**Then** function calls RadarScorer.get_top_issues(user_id, limit=3)
**And** formats response with GPT using prompt='risk_manager'

**Given** RadarScorer returns 3 items
**When** I format response
**Then** response structure is:
```
🔥 Что горит (Top-3):

1. Фича: {feature_name} (Проект: {project_name})
   Почему: {reasons joined}
   Что делать: {next_steps joined}
   [Подробнее] [Исправить]

2. ...
3. ...
```

**Given** active project is "Mobile App"
**When** I say "Что горит?"
**Then** bot shows Top-3 problems only from "Mobile App" project
**And** response starts with "Контекст: Проект Mobile App"

**Given** no active project (context is NULL)
**When** I say "Что горит?"
**Then** bot shows Top-3 problems across ALL projects
**And** each item shows project name

**Given** no problems found (all scores are 0)
**When** I say "Что горит?"
**Then** bot responds: "✅ Всё спокойно! Нет критичных проблем."

### Story 2.6: Inline Buttons for Quick Actions

As Artem,
I want to see inline buttons with Radar responses for quick navigation,
So that I can drill down without typing.

**Acceptance Criteria:**

**Given** python-telegram-bot supports InlineKeyboardMarkup
**When** I create `create_inline_buttons(button_configs)` helper in bot/handlers/commands.py
**Then** function takes list of {text, callback_data} dicts
**And** returns InlineKeyboardMarkup with buttons

**Given** Radar response is generated
**When** I add inline buttons to each Top-3 item
**Then** buttons are: [📊 Подробнее] [❓ Почему?] [▶️ Следующее]
**And** callback_data for [Подробнее] = 'radar_detail_{feature_id}'
**And** callback_data for [Почему?] = 'radar_explain_{feature_id}'
**And** callback_data for [Следующее] = 'radar_next_{current_index}'

**Given** inline buttons are created
**When** I create bot/handlers/callbacks.py with callback query handler
**Then** handler function `handle_callback(update, context)` exists

**Given** callback handler exists
**When** callback_data is 'radar_detail_{feature_id}'
**Then** bot fetches full Feature details from database
**And** shows: name, description, status, status_reason, assigned_teams, dependencies, created_at, updated_at
**And** adds buttons: [История изменений] [Назад к Radar]

**Given** callback_data is 'radar_explain_{feature_id}'
**When** callback is triggered
**Then** bot calls GPT with prompt='risk_manager' and context=feature details
**And** GPT explains in detail why this is a problem and what to do

**Given** I click [Подробнее] button on Radar item #1
**Then** bot edits original message to show detailed view
**And** I can click [Назад к Radar] to return to Top-3 list

### Story 2.7: "Где риск?" and "Что изменилось?" Commands

As Artem,
I want additional Radar views for risks and recent changes,
So that I have multiple perspectives on project health.

**Acceptance Criteria:**

**Given** NLU parser exists
**When** transcript is "Где риск?"
**Then** parser returns {'command': 'radar_risks'}

**Given** I need to store risks
**When** I create models/risk.py (if not exists from Story 1.2)
**Then** Risk model has fields: id (PK), project_id (FK), feature_id (FK, nullable), severity (String: low|medium|high|critical), description (Text), mitigation (Text, nullable), created_at

**Given** radar_risks command identified
**When** I create `handle_radar_risks(user_id)` in bot/handlers/commands.py
**Then** function queries Risk table for active project (or all if no context)
**And** sorts by severity (critical > high > medium > low)
**And** returns Top-3 with explainability

**Given** NLU parser exists
**When** transcript is "Что изменилось?"
**Then** parser returns {'command': 'radar_changes'}

**Given** radar_changes command identified
**When** I create `handle_radar_changes(user_id)`
**Then** function queries EventLog for last 24 hours in active project
**And** filters for significant events: project_created, feature_created, feature_status_updated, dependency_created, risk_created
**And** groups by entity and shows Top-5 most recent changes

**Given** I say "Что изменилось?" in project with recent activity
**Then** bot responds:
```
📅 Изменения за последние 24 часа (Проект: Mobile App):

1. Фича "интеграция аналитики": backlog → in_progress (2 часа назад)
2. Новая зависимость: "интеграция" блокирует "дашборд" (5 часов назад)
3. Новый риск добавлен: "Задержка API" (severity: high) (8 часов назад)
...
```

---

## Epic 3: Workflow Automation — Встречи, поручения, презентации для CEO

**Goal:** Artem может автоматизировать рутину: надиктовать протокол встречи (система извлечёт решения/поручения), получить напоминания о дедлайнах, и сгенерировать красивый HTML-лендинг для презентации CEO.

### Story 3.1: Meeting Protocol Extraction

As Artem,
I want to dictate a meeting protocol and have the system extract decisions, assignments, and risks,
So that I don't manually structure meeting notes.

**Acceptance Criteria:**

**Given** I need to store meetings and related entities
**When** I create models/meeting.py, models/decision.py (if not exist)
**Then** Meeting model: id, project_id (FK), title, date, participants (Text), created_at
**And** Decision model: id, meeting_id (FK), project_id (FK), description (Text), created_at

**Given** NLU parser exists
**When** transcript starts with "Протокол встречи:" or "Встреча:"
**Then** parser returns {'command': 'meeting_protocol', 'full_transcript': text}

**Given** meeting_protocol command identified
**When** I create `handle_meeting_protocol(transcript, user_id)` in bot/handlers/commands.py
**Then** function creates Meeting entity in database
**And** calls GPT with prompt='meeting_secretary' and full transcript

**Given** I create bot/prompts/meeting_secretary.txt
**Then** prompt instructs GPT: "Extract from meeting notes: 1) Decisions (what was decided), 2) Assignments (who does what by when), 3) Risks (what concerns were raised). Return JSON: {decisions: [], assignments: [], risks: []}"

**Given** GPT extracts structured data
**When** response is received
**Then** function parses JSON
**And** creates Decision entities for each decision
**And** creates Assignment entities for each assignment
**And** creates Risk entities for each risk
**And** all entities linked to meeting_id and project_id

**Given** I dictate: "Протокол встречи: Решили запустить MVP через 2 недели. Олег делает интеграцию до пятницы. Риск: нехватка ресурсов для тестирования."
**When** processing completes
**Then** Meeting created with title extracted by GPT
**And** 1 Decision created: "Запустить MVP через 2 недели"
**And** 1 Assignment created: assignee="Олег", title="интеграция", deadline=пятница
**And** 1 Risk created: description="нехватка ресурсов для тестирования", severity="medium"
**And** bot responds: "✅ Протокол обработан: 1 решение, 1 поручение, 1 риск зафиксированы"

### Story 3.2: Assignments & Reminders with APScheduler

As Artem,
I want to create assignments with deadlines and receive reminders,
So that I never miss important tasks.

**Acceptance Criteria:**

**Given** Assignment model exists
**When** I verify schema
**Then** Assignment has: id, project_id, title, assignee, deadline (DateTime), priority (String), source_type (leader|meeting|self), source_person_id (String, nullable), inbox_type (general|leader), reminder_times (JSON array), created_at

**Given** NLU parser exists
**When** transcript is "Напомни мне про отчёт через 2 часа"
**Then** parser returns {'command': 'create_reminder', 'task': 'отчёт', 'reminder_time': '2 hours'}

**Given** create_reminder command identified
**When** I create `handle_create_reminder(task, reminder_time, user_id)`
**Then** function creates Assignment with deadline=now+2hours, assignee=user_id
**And** calculates reminder_times (e.g., [deadline-2hours, deadline-24hours] if deadline > 24h)
**And** stores in Assignment.reminder_times as JSON array

**Given** I create jobs/scheduler.py with APScheduler setup
**When** scheduler is initialized
**Then** SQLAlchemyJobStore is configured with DATABASE_URL
**And** BackgroundScheduler is started

**Given** scheduler is running
**When** I create jobs/reminders.py with `check_reminders()` function
**Then** function queries Assignments where deadline is upcoming
**And** checks if now >= any reminder_time in reminder_times array
**And** sends Telegram message for due reminders

**Given** scheduler setup exists
**When** I add interval job to check reminders every minute
**Then** `scheduler.add_job(check_reminders, 'interval', minutes=1)` is configured

**Given** Assignment exists with deadline in 2 hours and reminder_times=[now+2hours]
**When** 2 hours pass and scheduler runs check_reminders
**Then** bot sends Telegram message: "⏰ Напоминание: отчёт (дедлайн через 2 часа)"
**And** removes that reminder_time from array to avoid duplicate

**Given** multiple assignments have reminders due
**When** check_reminders runs
**Then** sends separate message for each assignment
**And** messages include: task title, deadline, [Выполнено] [Отложить] buttons

### Story 3.3: Leader Tasks Inbox

As Artem,
I want to create assignments that came from my manager with special handling,
So that I never miss CEO requests.

**Acceptance Criteria:**

**Given** Assignment model has inbox_type field
**When** NLU parser identifies leader task
**Then** transcript pattern: "От Сергея: подготовить отчёт к понедельнику" or "CEO просит: анализ конкурентов"
**And** parser returns {'command': 'leader_task', 'leader_name': 'Сергея', 'task': text, 'deadline': extracted}

**Given** leader_task command identified
**When** I create `handle_leader_task(leader_name, task, deadline, user_id)`
**Then** function creates Assignment with source_type='leader', source_person_id=leader_name, inbox_type='leader', priority='P1'
**And** EventLog records: action='leader_task_created'

**Given** Leader task exists
**When** Radar scoring runs
**Then** Leader tasks (inbox_type='leader') get +100 bonus points
**And** they never get suppressed (always appear in Top-3 if deadline ≤ 48 hours)

**Given** I say "От CEO: подготовить презентацию к пятнице"
**Then** Assignment created with inbox_type='leader', source_person_id='CEO', priority='P1'
**And** bot responds: "✅ Поручение от руководителя зафиксировано: 'подготовить презентацию' (дедлайн: пятница, приоритет: P1)"
**And** reminder set for 24 hours before deadline

### Story 3.4: HTML Template Foundation

As Artem,
I want Jinja2 templates with Tailwind CSS for rendering beautiful artifacts,
So that I can present polished reports to CEO.

**Acceptance Criteria:**

**Given** I create templates/base.html
**Then** template includes: HTML5 structure, Tailwind CSS CDN link, responsive meta tags, base content block

**Given** base.html exists
**When** I create templates/radar_report.html extending base.html
**Then** template has sections: header with project name, Top-3 issues list, explainability for each, footer with timestamp

**Given** I create services/html_render.py
**When** I create `HTMLRenderer` class
**Then** class has method: `render_artifact(artifact_type, data)`

**Given** HTMLRenderer exists
**When** I implement `render_artifact('radar_report', data)` method
**Then** method loads radar_report.html template
**And** renders with Jinja2 using data
**And** returns HTML string

**Given** HTML is rendered
**When** I create `save_artifact(html_content, artifact_type, project_id, title)` method
**Then** method generates random access_token (uuid4)
**And** saves HTML to /static/artifacts/{access_token}.html
**And** creates Artifact record in database with rendered_url=/static/artifacts/{access_token}.html, expires_at=now+7days

**Given** artifact is saved
**When** I access URL /static/artifacts/{access_token}.html
**Then** HTML file is served by Flask static files
**And** page renders beautifully with Tailwind CSS

**Given** artifact expires_at < now
**When** cleanup job runs (deferred to Story 3.7)
**Then** file is deleted from /static/artifacts/
**And** Artifact.rendered_url is set to NULL

### Story 3.5: Meeting Prep Artifact

As Artem,
I want to say "Подготовь к встрече с Олегом" and receive a brief with status, questions, and risks,
So that I'm always prepared in 2 minutes.

**Acceptance Criteria:**

**Given** NLU parser exists
**When** transcript is "Подготовь к встрече с Олегом по проекту Mobile App"
**Then** parser returns {'command': 'meeting_prep', 'person': 'Олегом', 'project_name': 'Mobile App'}

**Given** meeting_prep command identified
**When** I create `handle_meeting_prep(person, project_id, user_id)`
**Then** function gathers data: recent feature statuses, open assignments, recent decisions, active risks
**And** calls GPT with prompt='analyst' and context data
**And** GPT generates structured prep: Project status summary, Key questions to ask (3-5), Critical risks to discuss (Top-3), Recent changes

**Given** GPT returns meeting prep content
**When** I create templates/meeting_prep.html
**Then** template displays: Header with meeting title, Status section, Questions list, Risks section, Recent changes timeline

**Given** meeting prep is generated
**When** rendering completes
**Then** HTMLRenderer.render_artifact('meeting_prep', data) is called
**And** artifact saved to /static/artifacts/{token}.html
**And** Artifact record created with type='prep'

**Given** I say "Подготовь к встрече с Олегом по проекту Mobile App"
**Then** bot responds: "📋 Meeting Prep готов! [Открыть лендинг] (link: /static/artifacts/{token}.html)"
**And** link expires in 7 days

### Story 3.6: Project Brief Artifact for CEO

As Artem,
I want to generate a beautiful project brief HTML to show to CEO,
So that I look professional and well-prepared.

**Acceptance Criteria:**

**Given** NLU parser exists
**When** transcript is "Справка по проекту Mobile App"
**Then** parser returns {'command': 'project_brief', 'project_name': 'Mobile App'}

**Given** project_brief command identified
**When** I create `handle_project_brief(project_id, user_id)`
**Then** function gathers: Project description, Key features (all features grouped by status), Releases with target dates, Recent decisions, Active risks, Metrics (total features, completion %, blocked count)
**And** calls GPT with prompt='analyst' to create executive summary

**Given** I create templates/project_brief.html
**Then** template includes: Hero section with project name, Executive summary (GPT-generated), Metrics cards (features count, completion %, risks), Features table grouped by status, Timeline with releases, Risks section with severity badges

**Given** Tailwind CSS is used
**When** project_brief.html renders
**Then** design is professional: gradient headers, card layouts, color-coded status badges (green=done, yellow=in_progress, red=blocked), responsive grid

**Given** I say "Справка по проекту Mobile App"
**Then** bot generates HTML artifact
**And** responds: "📊 Справка по проекту готова! [Открыть лендинг] (приватная ссылка, TTL=7 дней)"
**And** I can open link and show beautiful report to CEO

### Story 3.7: Artifact Cleanup & Management

As Artem,
I want old artifacts (> 7 days) to be automatically deleted,
So that storage doesn't grow indefinitely.

**Acceptance Criteria:**

**Given** APScheduler is configured
**When** I create jobs/artifact_cleanup.py with `cleanup_expired_artifacts()` function
**Then** function queries Artifact table where expires_at < now
**And** deletes files from /static/artifacts/{access_token}.html
**And** sets Artifact.rendered_url = NULL, rendered_html = NULL

**Given** cleanup function exists
**When** I add daily cron job
**Then** `scheduler.add_job(cleanup_expired_artifacts, 'cron', hour=2)` runs every day at 2 AM

**Given** artifact created 8 days ago (expired)
**When** cleanup job runs
**Then** HTML file deleted from /static/artifacts/
**And** Artifact record still exists but rendered_url is NULL
**And** EventLog records: action='artifact_expired', entity_id=artifact_id

**Given** I try to access expired artifact URL
**When** file doesn't exist
**Then** Flask returns 404 or custom "Artifact expired" page

---

## Epic 4: Autonomous Research — Делегирование исследований + Production

**Goal:** Artem может делегировать исследования системе ("Не тревожь меня") и получить готовый one-pager утром, а также иметь работающий 24/7 бот на Railway.

### Story 4.1: Background Research Task

As Artem,
I want to delegate research tasks to the bot and have it work autonomously,
So that I get structured results without my involvement.

**Acceptance Criteria:**

**Given** NLU parser exists
**When** transcript is "Исследуй: лучшие практики real-time collaboration, не тревожь меня"
**Then** parser returns {'command': 'research_task', 'query': 'лучшие практики real-time collaboration', 'autonomous': true}

**Given** research_task command identified
**When** I create `handle_research_task(query, user_id, project_id)`
**Then** function creates ResearchTask model (new) in database
**And** schedules APScheduler job to run research in background

**Given** I create models/research_task.py
**Then** ResearchTask model has: id, project_id (FK), query (Text), status (pending|in_progress|completed|failed), result_artifact_id (FK to Artifact, nullable), created_at, completed_at (nullable)

**Given** research task is scheduled
**When** APScheduler triggers job
**Then** job calls `execute_research(research_task_id)` function

**Given** I create `execute_research(research_task_id)` in jobs/research.py
**When** function runs
**Then** updates ResearchTask.status = 'in_progress'
**And** calls GPT with prompt='researcher' and query
**And** GPT performs web search (using GPT browsing or search plugin if available, or mock for MVP)
**And** GPT generates one-pager with 7 sections: Question, Alternatives (3-5 options), Comparison table, Recommendation, Risks, Assumptions, Next Steps, Sources

**Given** research completes
**When** one-pager is generated
**Then** creates Artifact with type='research', content=one_pager JSON
**And** renders HTML using templates/research_onepager.html
**And** updates ResearchTask.status='completed', result_artifact_id=artifact_id, completed_at=now

**Given** research completes
**When** I create notification logic
**Then** bot sends Telegram message: "🔬 Исследование завершено: '{query}' [Открыть one-pager] (link)"

**Given** I say "Исследуй: лучшие практики real-time collaboration, не тревожь меня"
**Then** bot responds: "🔬 Исследование запущено. Когда закончу, пришлю уведомление."
**And** research runs in background (5-15 minutes)
**And** I receive notification with link to HTML one-pager

### Story 4.2: Research One-Pager Template

As Artem,
I want research results presented as beautiful HTML one-pagers,
So that I can quickly review and make decisions.

**Acceptance Criteria:**

**Given** I create templates/research_onepager.html
**Then** template structure includes:
- Header: Research question
- Section 1: Question restatement
- Section 2: Alternatives (cards with pros/cons)
- Section 3: Comparison table (criteria vs alternatives)
- Section 4: Recommendation (highlighted, with reasoning)
- Section 5: Risks (color-coded by severity)
- Section 6: Assumptions (listed)
- Section 7: Next Steps (actionable items)
- Section 8: Sources (links to references)

**Given** Tailwind CSS is used
**When** research_onepager.html renders
**Then** design is professional: header with gradient, card-based alternatives, comparison table with borders, highlighted recommendation box, color-coded risks (red=high, yellow=medium, green=low)

**Given** research data is passed to template
**When** rendering occurs
**Then** all 7 sections populated from JSON data
**And** sources rendered as clickable links
**And** responsive design works on mobile

### Story 4.3: Railway Deployment Setup

As Artem,
I want to deploy the bot to Railway so it runs 24/7,
So that I can use it from anywhere anytime.

**Acceptance Criteria:**

**Given** code is in GitHub repository
**When** I connect Railway to GitHub repo
**Then** Railway detects Python app automatically

**Given** Railway project is created
**When** I configure environment variables in Railway dashboard
**Then** variables set: TELEGRAM_TOKEN, OPENAI_API_KEY, YOUR_TELEGRAM_ID, ENVIRONMENT=production
**And** DATABASE_URL automatically provided by Railway PostgreSQL

**Given** I create Procfile or railway.toml
**Then** start command is: `python app.py`

**Given** deployment configuration exists
**When** I push code to GitHub
**Then** Railway auto-deploys
**And** runs migrations: `alembic upgrade head`
**And** starts bot in webhook mode (ENVIRONMENT=production triggers webhook instead of polling)

**Given** bot is deployed on Railway
**When** I send message to Telegram bot
**Then** webhook receives update from Telegram
**And** bot processes and responds
**And** response time < 2 seconds

### Story 4.4: Webhook Mode Configuration

As Artem,
I want the bot to use webhook mode in production instead of polling,
So that it's more efficient and reliable.

**Acceptance Criteria:**

**Given** ENVIRONMENT=production in .env
**When** app.py initializes
**Then** bot uses webhook mode instead of polling

**Given** I create `setup_webhook()` function in app.py
**When** ENVIRONMENT=production
**Then** function sets webhook URL: `bot.set_webhook(url=f'https://{railway_domain}/webhook/{TELEGRAM_TOKEN}')`

**Given** I create webhook route in app.py (Flask)
**When** route `/webhook/{token}` receives POST request
**Then** verifies token matches TELEGRAM_TOKEN
**And** processes update from Telegram
**And** returns 200 OK

**Given** webhook is set up
**When** Railway provides HTTPS domain automatically
**Then** Telegram delivers updates to webhook URL
**And** bot processes without polling

### Story 4.5: Production Testing & Bug Fixes

As Artem,
I want to test the bot in production and fix any bugs found,
So that it's stable and reliable for daily use.

**Acceptance Criteria:**

**Given** bot is deployed on Railway
**When** I test all core commands: /start, voice messages, "Создай проект", "Что горит?", "Подготовь к встрече"
**Then** all commands work correctly
**And** response times are acceptable (< 3 seconds for voice, < 1 second for text)

**Given** testing reveals bugs
**When** I report bug to Claude
**Then** Claude fixes bug in code
**And** pushes fix to GitHub
**And** Railway auto-deploys new version

**Given** I test Radar with real data (10+ projects, 50+ features)
**When** I say "Что горит?"
**Then** Radar returns Top-3 in < 10 seconds
**And** results are accurate (blocked features, deadline pressure, etc.)

**Given** I test reminders
**When** I create assignment with reminder in 1 hour
**Then** APScheduler sends reminder exactly on time
**And** reminder message includes [Выполнено] button

**Given** I test HTML artifacts
**When** I generate meeting prep and project brief
**Then** HTML renders correctly on mobile and desktop
**And** Tailwind CSS styles load from CDN
**And** private links work and expire after 7 days

**Given** all features tested and working
**When** I use bot for 3 consecutive days
**Then** no crashes, no missed commands, all data persists
**And** Railway free tier hours sufficient (< 500 hours/month usage)
