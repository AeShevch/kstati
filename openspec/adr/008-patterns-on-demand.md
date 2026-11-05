# ADR-008 — GoF-паттерны по необходимости

**Статус:** принято как архитектурный baseline 04.11.2026.

## Решение

Adapter и типизированные Command handlers применяются с первого сценария, где есть соответствующая граница. Strategy, Observer и Composite вводятся при реальной сложности. Chain of Responsibility, Singleton, Abstract Factory, Visitor и Mediator не вводятся заранее.

## Последствия

Каждый новый паттерн должен решать конкретную задачу. Для надёжной фоновой обработки используется durable queue, а не только in-memory Observer.

**Источник:** [ARCHITECTURE.md, ADR-008](../../docs/reference/ARCHITECTURE.md).
