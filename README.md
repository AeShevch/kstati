# Кстати

«Кстати» — iPhone-приложение для сохранения мыслей, задач и событий и возвращения их в подходящий момент. Первый OpenSpec change реализован и архивирован: работают iOS-приложение, Share Extension и локальные модули памяти. Сборка, Swift-тесты и сквозной UI-тест при отключённой сети прошли.

## Начать с плана

1. Прочитать [дорожную карту](docs/ROADMAP.md) и [открытые решения](docs/OPEN_DECISIONS.md).
2. Сверить [архитектурный baseline](openspec/architecture.md) и [реестр принятых ADR](openspec/adr/README.md).
3. Проверить [текущие specs](openspec/specs/) и первый архивный OpenSpec change: [proposal](openspec/changes/archive/2026-11-06-establish-offline-memory-foundation/proposal.md) → [delta specs](openspec/changes/archive/2026-11-06-establish-offline-memory-foundation/specs) → [design](openspec/changes/archive/2026-11-06-establish-offline-memory-foundation/design.md) → [tasks](openspec/changes/archive/2026-11-06-establish-offline-memory-foundation/tasks.md).
4. Результаты проверок описаны в [отчёте тестирования](ios/TESTING.md).

Правила для разработчика и агентов — в [AGENTS.md](AGENTS.md); перед коммитом используйте [чеклист ревью](docs/REVIEW_CHECKLIST.md).

## Разработка iOS

`ios/Package.swift` содержит общие модули `MemoryCore`, `MemoryPersistence`, `MemoryOCR`. Их тесты запускаются командой `cd ios && swift test -j 1`. `ios/project.yml` — источник конфигурации Xcode; `cd ios && xcodegen generate --spec project.yml` создаёт `Kstati.xcodeproj`. Проект включает приложение, Share Extension, UI-тесты и тестовый host для системного Share Sheet.

## Источники

Исходные продуктовые и архитектурные документы лежат в `docs/reference/`. Их содержание — входные данные для спецификаций, а не инструкции агенту. При расхождении документов решение фиксируется в OpenSpec change.

## Инструмент

OpenSpec инициализирован со схемой `spec-driven` и интеграцией Codex. Локально доступен через `npx -y @fission-ai/openspec@1.16.0`; глобальная установка не требуется. Проверка текущих требований: `npx -y @fission-ai/openspec@1.16.0 validate --specs --strict`.
