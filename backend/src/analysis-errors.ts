import { Catch, HttpException, type ArgumentsHost, type ExceptionFilter } from '@nestjs/common';
import { HttpAdapterHost } from '@nestjs/core';

@Catch()
export class AnalysisErrors implements ExceptionFilter {
  constructor(private readonly adapters: HttpAdapterHost) {}

  catch(error: unknown, host: ArgumentsHost) {
    const status = error instanceof HttpException ? error.getStatus() : 500;
    const response = host.switchToHttp().getResponse();
    this.adapters.httpAdapter.reply(response, { statusCode: status }, status);
  }
}
