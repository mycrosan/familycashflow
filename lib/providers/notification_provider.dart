import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final DatabaseService _databaseService = DatabaseService();
  
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Inicializar notificações
  Future<void> initialize() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Configurações para Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configurações para iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Configurações gerais
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Inicializar
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Solicitar permissões
      await _requestPermissions();

      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao inicializar notificações: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Solicitar permissões
  Future<void> _requestPermissions() async {
    try {
      // TODO: Implementar solicitação de permissões
      // await _notifications.resolvePlatformSpecificImplementation<
      //     AndroidFlutterLocalNotificationsPlugin>()?.requestPermission();
      
      // await _notifications.resolvePlatformSpecificImplementation<
      //     IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      //   alert: true,
      //   badge: true,
      //   sound: true,
      // );
    } catch (e) {
      // Ignorar erros de permissão
    }
  }

  // Callback quando notificação é tocada
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Implementar navegação baseada no tipo de notificação
    print('Notificação tocada: ${response.payload}');
  }

  // Agendar notificação de transação recorrente
  Future<void> scheduleRecurringTransactionNotification(RecurringTransaction recurringTransaction) async {
    try {
      if (!_isInitialized) return;

      final id = recurringTransaction.id ?? 0;
      final title = 'Transação Recorrente';
      final body = '${recurringTransaction.category}: R\$ ${recurringTransaction.value.toStringAsFixed(2)}';
      
      // Calcular próxima data
      final nextDate = _calculateNextRecurringDate(recurringTransaction);
      
      if (nextDate != null) {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          _convertToTZDateTime(nextDate),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'recurring_transactions',
              'Transações Recorrentes',
              channelDescription: 'Notificações de transações recorrentes',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'recurring_transaction_$id',
        );
      }
    } catch (e) {
      _error = 'Erro ao agendar notificação: $e';
      notifyListeners();
    }
  }

  // Agendar notificação de resumo mensal
  Future<void> scheduleMonthlySummaryNotification(DateTime month) async {
    try {
      if (!_isInitialized) return;

      final id = 1000 + month.month; // ID único para cada mês
      final title = 'Resumo Mensal';
      final body = 'Confira seu resumo financeiro de ${_formatMonth(month)}';
      
      // Agendar para o primeiro dia do próximo mês às 9h
      final nextMonth = DateTime(month.year, month.month + 1, 1, 9, 0);
      
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        _convertToTZDateTime(nextMonth),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'monthly_summary',
            'Resumo Mensal',
            channelDescription: 'Notificações de resumo mensal',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'monthly_summary_${month.year}_${month.month}',
      );
    } catch (e) {
      _error = 'Erro ao agendar notificação mensal: $e';
      notifyListeners();
    }
  }

  // Agendar notificação de lembrete de pagamento
  Future<void> schedulePaymentReminderNotification({
    required String title,
    required String body,
    required DateTime dueDate,
    int? id,
  }) async {
    try {
      if (!_isInitialized) return;

      final notificationId = id ?? DateTime.now().millisecondsSinceEpoch % 100000;
      
      // Agendar para 1 dia antes da data de vencimento
      final reminderDate = dueDate.subtract(const Duration(days: 1));
      
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        _convertToTZDateTime(reminderDate),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'payment_reminders',
            'Lembretes de Pagamento',
            channelDescription: 'Notificações de lembretes de pagamento',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'payment_reminder_$notificationId',
      );
    } catch (e) {
      _error = 'Erro ao agendar lembrete: $e';
      notifyListeners();
    }
  }

  // Mostrar notificação imediata
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) return;

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'immediate',
            'Notificações Imediatas',
            channelDescription: 'Notificações mostradas imediatamente',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      _error = 'Erro ao mostrar notificação: $e';
      notifyListeners();
    }
  }

  // Cancelar notificação específica
  Future<void> cancelNotification(int id) async {
    try {
      if (!_isInitialized) return;
      await _notifications.cancel(id);
    } catch (e) {
      _error = 'Erro ao cancelar notificação: $e';
      notifyListeners();
    }
  }

  // Cancelar todas as notificações
  Future<void> cancelAllNotifications() async {
    try {
      if (!_isInitialized) return;
      await _notifications.cancelAll();
    } catch (e) {
      _error = 'Erro ao cancelar todas as notificações: $e';
      notifyListeners();
    }
  }

  // Verificar transações recorrentes e agendar notificações
  Future<void> checkRecurringTransactions() async {
    try {
      if (!_isInitialized) return;

      final recurringTransactions = await _databaseService.getRecurringTransactions();
      
      for (final recurringTransaction in recurringTransactions) {
        if (recurringTransaction.isActive == 1) {
          await scheduleRecurringTransactionNotification(recurringTransaction);
        }
      }
    } catch (e) {
      _error = 'Erro ao verificar transações recorrentes: $e';
      notifyListeners();
    }
  }

  // Calcular próxima data recorrente
  DateTime? _calculateNextRecurringDate(RecurringTransaction recurringTransaction) {
    final now = DateTime.now();
    DateTime currentDate = recurringTransaction.startDate;
    
    while (currentDate.isBefore(now)) {
      switch (recurringTransaction.frequency) {
        case 'daily':
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          currentDate = currentDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          currentDate = DateTime(
            currentDate.year,
            currentDate.month + 1,
            currentDate.day,
          );
          break;
        case 'yearly':
          currentDate = DateTime(
            currentDate.year + 1,
            currentDate.month,
            currentDate.day,
          );
          break;
      }
      
      if (recurringTransaction.endDate != null && 
          currentDate.isAfter(recurringTransaction.endDate!)) {
        return null;
      }
    }
    
    return currentDate;
  }

  // Converter DateTime para TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    // Inicializar timezone se necessário
    try {
      tz.initializeTimeZones();
    } catch (e) {
      // Timezone já inicializado
    }
    
    // Converter para timezone local
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  // Formatar mês para exibição
  String _formatMonth(DateTime month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month.month - 1];
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
