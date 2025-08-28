class ApiConfig {
  // URL base da API - ajuste conforme seu ambiente
  static const String baseUrl = 'http://192.168.0.109:5000';
  
  // Timeout para requisições HTTP
  static const int timeoutSeconds = 30;
  
  // Configurações de paginação
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Configurações de cache
  static const int cacheExpirationMinutes = 5;
  
  // Configurações de sincronização
  static const int syncIntervalMinutes = 15;
  static const int maxRetryAttempts = 3;
}

class AppConfig {
  // Configurações da aplicação
  static const String appName = 'Fluxo Família';
  static const String appVersion = '1.0.0';
  
  // Configurações de tema
  static const bool useDarkTheme = false;
  static const String primaryColor = '#3F51B5';
  static const String accentColor = '#FF4081';
  
  // Configurações de notificações
  static const bool enableNotifications = true;
  static const int notificationDelayMinutes = 5;
  
  // Configurações de backup
  static const bool enableAutoBackup = true;
  static const int backupIntervalDays = 7;
}

class DatabaseConfig {
  // Configurações do banco local
  static const String databaseName = 'fluxo_familiar.db';
  static const int databaseVersion = 1;
  
  // Configurações de tabelas
  static const String tableLancamentos = 'lancamentos';
  static const String tableCategorias = 'categorias';
  static const String tableResponsaveis = 'responsaveis';
  static const String tableRecorrencias = 'recorrencias';
  static const String tableSyncLog = 'sync_log';
}