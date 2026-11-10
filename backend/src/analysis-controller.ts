import { BadGatewayException, BadRequestException, Body, Controller, HttpCode, Inject, Post } from '@nestjs/common';
import { isAnalysisRequest, isSuggestion, LLM_PORT, type LlmPort } from './analysis-contract.js';

@Controller('v1/memory-analysis')
export class AnalysisController {
  constructor(@Inject(LLM_PORT) private readonly analyzer: LlmPort) {}

  @Post()
  @HttpCode(200)
  async analyze(@Body() body: unknown) {
    if (!isAnalysisRequest(body)) throw new BadRequestException('Invalid analysis request');
    try {
      const suggestions = await this.analyzer.analyze(body);
      if (!Array.isArray(suggestions) || suggestions.length > 5 || !suggestions.every(isSuggestion)) {
        throw new Error('Invalid provider response');
      }
      return { suggestions };
    } catch {
      throw new BadGatewayException('Analysis unavailable');
    }
  }
}
