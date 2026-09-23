export interface ILogger {
    debug: (...messages: any[]) => void;
    info: (...messages: any[]) => void;
    warn: (...messages: any[]) => void;
    error: (...messages: any[]) => void;
  }

  export enum LogLevel {
    Debug,
    Info,
    Warn,
    Error,
    Off,
  }