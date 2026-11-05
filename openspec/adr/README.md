# Реестр ADR

Все решения ниже перенесены из раздела 8 [архитектурного baseline](../../docs/reference/ARCHITECTURE.md). Статус «Принято» относится к выбору направления, а не означает, что соответствующая функция уже реализована. Конкретное поведение и порядок реализации фиксируются в OpenSpec changes.

| ADR | Решение | Статус |
|---|---|---|
| [001](001-native-ios.md) | Swift 6 + SwiftUI native iOS | Принято |
| [002](002-offline-first-storage.md) | Offline-first и SQLite/GRDB | Принято |
| [003](003-domain-boundaries.md) | DDD-lite + Clean + CQRS-lite | Принято |
| [004](004-ai-backend.md) | TypeScript + NestJS + Hexagonal backend | Принято для этапа AI backend |
| [005](005-hybrid-retrieval.md) | FTS5 + embeddings без отдельной vector DB | Принято поэтапно |
| [006](006-dynamic-groups.md) | Динамические группы many-to-many | Принято |
| [007](007-no-ai-framework.md) | Не вводить LangChain/LangGraph/LlamaIndex на старте | Принято |
| [008](008-patterns-on-demand.md) | GoF-паттерны по необходимости | Принято |
| [009](009-ios-17-target.md) | iOS 17.0 как минимальная версия первого проекта | Принято для первого change |

Новые решения получают следующий номер. Изменение принятого ADR требует причины, последствий и ссылки на OpenSpec change; старый текст сохраняется для истории.
