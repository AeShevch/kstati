# «Кстати» — архитектура и C4-модель

**Версия:** 0.1 • **Дата:** 4 ноября 2026 • **Статус:** архитектурный baseline для OpenSpec / SDD; детали уточняются в отдельных changes.

> **«Кстати» — это не место, куда ты складываешь информацию. Это место, откуда информация возвращается в твою жизнь.**

## 1. Область и принципы

Приложение: персональная память + ежедневник + контекстные подсказки. На главном экране — одна крупная кнопка **«Кстати»**. Быстрый вызов — Action Button, widget, Share Extension. Пользователь может сохранять любой текст, голос, фото, скриншоты, ссылки, рецепты, идеи игр с ребёнком, встречи и желания. **Группы не фиксированы**: система предлагает группы по содержимому, пользователь может создать свои, одна запись может состоять в нескольких группах.

- **Offline first:** сначала локальное сохранение, затем необязательное AI-обогащение.
- **Источник истины:** исходная запись и вложения; группы, embeddings, извлечённые поля и рекомендации — производные данные.
- **Модель пользователя локально:** первичные записи и индексы живут на устройстве. Облачная синхронизация не включена в MVP.
- **Приватность:** на backend передаётся минимальный нужный контекст по явному согласию; медицинские/иные чувствительные записи можно исключить из облачной обработки. Нет автоматического cloud fallback для них.
- **Реальные ограничения iOS:** фоновые задачи и геонапоминания не гарантируют точное время; OS управляет доставкой, разрешениями и лимитами.

## 2. C4 — Level 1: System Context

![C1 Context](diagrams/c1_context.svg)

**Actor:** пользователь. **System of interest:** «Кстати». **Внешние зависимости:** iOS Services и заменяемый AI Provider, к которому обращается backend. OpenAI — адаптер, а не часть домена.

## 3. C4 — Level 2: Containers

![C2 Containers](diagrams/c2_containers.svg)

| Container | Технологии | Назначение |
|---|---|---|
| iOS Application | Swift 6, SwiftUI, App Intents, Vision, Speech | Capture, UX, доменная логика, планирование, локальная контекстная обработка |
| Local Memory DB (внутри устройства) | SQLite + GRDB + FTS5; vectors по мере необходимости | Исходные записи, связи, группы N:M, события, задачи, поиск и durable job queue |
| AI Backend | TypeScript + NestJS + Ports & Adapters | Валидация, политки приватности, извлечение структуры, embeddings, ограничение запросов и наблюдаемость |
| AI Provider (внешний) | OpenAI API в MVP, альтернативы позже | LLM structured outputs и embedding generation |

**Deployment boundary:** iOS App и SQLite выполняются на телефоне. NestJS — отдельный серверный контейнер, не хранящий исходную «память» пользователя в MVP.

## 4. C4 — Level 3: iOS Components

![C3 iOS Components](diagrams/c3_ios.svg)

- **Presentation/Capture:** SwiftUI, Share Extension, Action Button, widgets и Vision OCR.
- **Application / CQRS-lite:** отдельные typed Command/Query handlers без универсального message bus.
- **Domain:** `MemoryItem`, `Group`, `Task`, `CalendarEvent`, `ContextRule`, связи и инварианты.
- **Persistence:** GRDB/SQLite, app group storage для расширений, миграции.
- **Search:** гибридный поиск FTS5 + embeddings; rerank по контексту. SQLite-vec только после проверки реальной пользы и сборки на iOS.
- **Durable jobs:** записи сохраняются моментально; AI enrichment выполняется позже, обработка идемпотентна, retry и статусы хранятся в SQLite.
- **Context Engine:** время, разрешённая геолокация и календарные события; поиск кандидатов и дозирование уведомлений.

### Ключевые инварианты модели

`MemoryItem` хранится **один раз**; `MemoryItem ↔ Group` — отношение **many-to-many**. Удаление группы не удаляет запись. Извлечённые даты/названия/адреса и embeddings могут пересоздаваться, оригиналы не переписываются AI. `Task` и `CalendarEvent` отдельные сущности, которые при необходимости ссылаются на исходный `MemoryItem`.

## 5. C4 — Level 3: AI Backend Components

![C3 Backend Components](diagrams/c3_backend.svg)

- **Inbound adapters:** REST (OpenAPI/Swagger), validation, authentication, quotas, rate limit.
- **Application handlers:** AnalyzeMemory, GenerateEmbedding, SuggestGroups; structured output + schema validation.
- **Outbound ports:** `LlmPort`, `EmbeddingPort` (контракты, не зависящие от OpenAI SDK).
- **Outbound adapters:** `OpenAiAdapter` в MVP; `LocalModelAdapter`/иной provider возможны позже.
- **Cross-cutting:** минимизация личных данных, timeout, retry/backoff, tracing без чувствительного payload, метрики токенов и стоимости.

**Не используем на старте:** LangChain, LangGraph, LlamaIndex. RAG — не фреймворк, а последовательность retrieval → filtering/reranking → optional LLM synthesis.

## 6. End-to-end сценарий: скриншот рецепта

1. Пользователь нажимает «Поделиться» → «Кстати» или Action Button и выбирает захват.
2. iOS сохраняет оригинал, ссылку и метаданные **локально**, сразу возвращая подтверждение.
3. В SQLite создаётся запись на enrichment (в сети и по согласию): Vision OCR локально, модель извлекает краткую структуру и предлагает группы.
4. Пример групп: `Рецепты`, `С ребёнком`, `На выходные` — это **предложения, не жёсткие категории**. Запись можно связать со всеми тремя одновременно.
5. Сохранённые metadata и embedding индексируются локально, пользователь может изменить связи.
6. Запрос «Во что поиграть дома без подготовки?» или «Что приготовить из курицы?» → локальный гибридный поиск, затем (опционально) AI-ответ на основании найденных записей.
7. Context Engine при наличии подходящего контекста формирует предложение без непрерывного облачного мониторинга.

## 7. GoF — фиксируем осмысленное применение

| Паттерн | Решение | Границы применения |
|---|---|---|
| **Adapter** | **Да, с первого дня** | OpenAI / другие модели, OCR, системные сервисы за портами |
| **Command** | **Да, через CQRS-lite** | `SaveMemoryCommand` DTO + `SaveMemoryHandler`; GoF-паттерн родственен, но не тождествен CQRS |
| **Strategy** | **Когда появится выбор алгоритма/провайдера** | `RetrievalStrategy`, провайдер по policy; не делать ради одного OpenAI |
| **Observer** | **Доменные события, по потребности** | Локальные подписчики; для надёжности — durable jobs, не только in-memory observers |
| **Composite** | **Позже** | Сложные AND/OR условия контекстных подсказок; простые правила сначала |
| **Chain of Responsibility** | **Нет на старте** | Явный последовательный enrichment pipeline проще и прозрачнее |
| Singleton / Abstract Factory / Visitor / Mediator | **Не вводить без сценария** | DI в NestJS/Swift и простые сервисы достаточны |

**Правило:** паттерн появляется только под измеримую сложность или требование, а не ради соответствия GoF.

## 8. Архитектурные решения (ADR baseline)

| ID | Decision | Последствие |
|---|---|---|
| ADR-001 | Swift 6 + SwiftUI native iOS | Прямой доступ к App Intents, WidgetKit, Share Extension и локальным OS API |
| ADR-002 | Offline-first, primary storage = SQLite/GRDB | Быстрый захват без интернета, миграции и явная стратегия восстановления данных |
| ADR-003 | DDD-lite + Clean + CQRS-lite | Бизнес-логика изолирована от UI и LLM, без отдельной CQRS-инфраструктуры |
| ADR-004 | Backend TypeScript + NestJS + Hexagonal | OpenAI API через `LlmPort` / `EmbeddingPort`, контрактный REST через OpenAPI |
| ADR-005 | Hybrid Retrieval FTS5 + embeddings | RAG локально, без выделенной vector DB на MVP; качество сравнивать тестами |
| ADR-006 | Dynamic groups many-to-many | Свободная таксономия, многократная принадлежность одной записи |
| ADR-007 | No LangChain/LangGraph/LlamaIndex | Упрощённое сопровождение; пересмотр при подтверждённой сложности workflows |
| ADR-008 | GoF on-demand | Adapter/Command сейчас; Strategy/Observer/Composite по необходимости |

## 9. Engineering: SDD, тесты и CI/CD

**OpenSpec — обязательный источник требований:** `proposal.md` → `specs` с Given/When/Then → `design.md` (включая ADR и C4) → `tasks.md` → implement + verify → archive. Никакого кода без согласованных acceptance criteria.

| Уровень | Технология | Обязательные сценарии |
|---|---|---|
| Unit | Swift Testing; Jest/Vitest backend | Domain invariants, Commands, queries, mapping, permission policy |
| Integration | Swift Testing + GRDB/SQLite | Миграции, FTS5, group N:M, durable jobs, duplicate prevention |
| E2E | XCUITest / XCTest | Capture, сохранение офлайн, поиск, мультигруппы, календарь, восстановление после перезапуска |
| AI Evaluations | Versioned curated dataset | Согласованность extracted fields, recall@k, precision групп, ложные контекстные подсказки |

**GitHub Actions**: pull request → OpenSpec validation → format/lint → Swift build/unit/integration → iOS simulator E2E; NestJS lint/unit/contract tests; merge gate; вручную одобренный релиз через Fastlane → TestFlight. Модели мокируются в PR; настоящие AI-eval запускаются отдельно и по лимитам бюджета.

## 10. MVP Scope и ограничения

**Сделать:** iPhone one-button UI, быстрый захват текста/скриншотов, OCR, локальное сохранение, редактирование, группы N:M, FTS5-поиск, ежедневник базовых задач/встреч, простой AI extraction через порт, уведомления по времени, основные unit/E2E, GitHub Actions.

**Отложить:** произвольные комплексные геоусловия, автоматическое «исполнение желаний», семейная синхронизация, масштабная multi-user облачная БД, LangGraph агентные цепочки, отдельный векторный кластер, полнофункциональные внешние календарные интеграции.

**Открытые решения для будущих спецификаций:** способ хранения изображений в App Group, политика Cloud AI consent, защита данных/шифрование резервной копии, выбор embedding модели и индекса, iOS deployment target, серверная аутентификация/лимиты, показ уведомлений без шума.

## 11. Исходники диаграмм

Все C4 диаграммы включены как редактируемые Graphviz DOT (`diagrams/*.dot`) и экспортированы в SVG/PNG. Уровень C4 L4 (Code) намеренно не фиксируем заранее; строим по конкретным modules/change в OpenSpec.
