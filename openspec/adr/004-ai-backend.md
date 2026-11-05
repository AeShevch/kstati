# ADR-004 — AI backend на TypeScript и NestJS

**Статус:** принято для будущего AI backend; сервер ещё не реализован.

## Решение

AI backend строится на TypeScript, NestJS и Ports & Adapters. Контракт REST описывается через OpenAPI. Провайдер LLM и embeddings доступен через `LlmPort` и `EmbeddingPort`; OpenAI подключается как заменяемый адаптер.

## Последствия

Сервер проверяет вход, согласие и лимиты, не хранит первичную память пользователя в MVP и не пишет чувствительный payload в логи. Схема аутентификации и квоты остаются открытыми до соответствующего change.

**Источник:** [ARCHITECTURE.md, ADR-004](../../docs/reference/ARCHITECTURE.md).
