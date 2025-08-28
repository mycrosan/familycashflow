// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/member_provider.dart';
import 'providers/category_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/recurring_transaction_provider.dart';
import 'providers/report_provider.dart';
import 'providers/quick_entry_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/sync_provider.dart';
import 'pages/home/home_page.dart';
import 'pages/auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(FluxoFamiliaApp());
}

class FluxoFamiliaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MemberProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => RecurringTransactionProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => QuickEntryProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Fluxo Família',
            theme: ThemeData(
              primarySwatch: Colors.indigo,
              useMaterial3: true,
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 2,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              cardTheme: CardTheme(
                elevation: 2,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),

            // Localização
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              const Locale('pt', 'BR'),
            ],

            home: authProvider.isAuthenticated ? HomePage() : LoginPage(),
          );
        },
      ),
    );
  }
}