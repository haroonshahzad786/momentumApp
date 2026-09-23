
import Config from 'react-native-config';
import { ILogger, LogLevel } from '../typescript/logger';

function getLogLevelFromEnv(): LogLevel {
    console.log("LOG_LEVEL: ", Config.LOG_LEVEL?.toUpperCase())
  const logLevelString = Config.LOG_LEVEL?.toUpperCase();

  switch (logLevelString) {
    case 'DEBUG':
      return LogLevel.Debug;
    case 'INFO':
      return LogLevel.Info;
    case 'WARN':
      return LogLevel.Warn;
    case 'ERROR':
      return LogLevel.Error;
    default:
      return LogLevel.Off;
  }
}

export class Logger implements ILogger {
  private currentLogLevel: LogLevel;

  constructor() {
    this.currentLogLevel = getLogLevelFromEnv();
  }

  private shouldLog(logLevel: LogLevel): boolean {
    return logLevel >= this.currentLogLevel;
  }

  debug(message: string, ...params: any[]): void {
    if (this.shouldLog(LogLevel.Debug)) {
      console.debug(message, ...params);
    }
  }

  info(message: string, ...params: any[]): void {
    console.info(message, ...params);
  }

  warn(message: string, ...params: any[]): void {
    console.warn(message, ...params);
    
  }

  error(message: string, ...params: any[]): void {
    console.error(message, ...params);
    
  }
}

export const logger = new Logger();