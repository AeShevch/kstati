export type AnalysisRequest = { text: string; today: string };
export type Suggestion = { kind: 'task' | 'event'; title: string; day: string | null };
export interface LlmPort {
  analyze(input: AnalysisRequest): Promise<Suggestion[]>;
}
export const LLM_PORT = Symbol('LlmPort');

export function isDay(value: unknown): value is string {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value) || value.startsWith('0000')) return false;
  const date = new Date(value);
  return Number.isFinite(date.getTime()) && date.toISOString().slice(0, 10) === value;
}

export function isAnalysisRequest(value: unknown): value is AnalysisRequest {
  if (!value || typeof value !== 'object') return false;
  const input = value as Record<string, unknown>;
  return Object.keys(input).length === 2 && typeof input.text === 'string' &&
    input.text.trim().length > 0 && [...input.text].length <= 4000 && isDay(input.today);
}

export function isSuggestion(value: unknown): value is Suggestion {
  if (!value || typeof value !== 'object') return false;
  const item = value as Record<string, unknown>;
  return Object.keys(item).length === 3 && (item.kind === 'task' || item.kind === 'event') &&
    typeof item.title === 'string' && item.title.trim().length > 0 && [...item.title].length <= 200 &&
    (item.day === null || isDay(item.day));
}
