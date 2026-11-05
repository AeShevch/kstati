# ADR-007 — Без LangChain, LangGraph и LlamaIndex на старте

**Статус:** принято как архитектурный baseline 04.11.2026.

## Решение

На начальном этапе enrichment и retrieval реализуются явными шагами без LangChain, LangGraph и LlamaIndex. RAG здесь — последовательность retrieval, filtering/reranking и необязательного LLM synthesis.

## Последствия

Меньше инфраструктуры и скрытого поведения. Решение можно пересмотреть при доказанной сложности workflows отдельным ADR и OpenSpec change.

**Источник:** [ARCHITECTURE.md, ADR-007](../../docs/reference/ARCHITECTURE.md).
