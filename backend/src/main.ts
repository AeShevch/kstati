import 'reflect-metadata';
import { Module } from '@nestjs/common';
import { HttpAdapterHost, NestFactory } from '@nestjs/core';
import { AnalysisErrors } from './analysis-errors.js';
import { AnalysisController } from './analysis-controller.js';
import { LLM_PORT, type LlmPort } from './analysis-contract.js';
import { FixtureAnalyzer } from './fixture-analyzer.js';

export async function createServer(enableFixture: boolean, analyzer: LlmPort = new FixtureAnalyzer()) {
  @Module({
    controllers: enableFixture ? [AnalysisController] : [],
    providers: enableFixture ? [{ provide: LLM_PORT, useValue: analyzer }] : [],
  })
  class AppModule {}
  const app = await NestFactory.create(AppModule, { logger: false, abortOnError: false });
  app.useGlobalFilters(new AnalysisErrors(app.get(HttpAdapterHost)));
  return app;
}

async function start() {
  const enabled = process.env.NODE_ENV !== 'production' && process.env.KSTATI_ANALYSIS_FIXTURE === '1';
  const app = await createServer(enabled);
  await app.listen(48731, '127.0.0.1');
}

if (require.main === module) {
  void start().catch(() => {
    console.error('Analysis service failed to start.');
    process.exitCode = 1;
  });
}
