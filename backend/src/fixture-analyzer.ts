import type { AnalysisRequest, LlmPort, Suggestion } from './analysis-contract.js';

export class FixtureAnalyzer implements LlmPort {
  async analyze({ text, today }: AnalysisRequest): Promise<Suggestion[]> {
    if (text === 'KST_FIXTURE_ANALYSIS_ERROR') throw new Error('Fixture failure');
    const title = [...text.trim().split(/\r?\n/, 1)[0]].slice(0, 200).join('');
    return [{ kind: 'task', title, day: today }];
  }
}
