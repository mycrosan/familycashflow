// lib/main.dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:fluxo_caixa_familiar/pages/categorias/categorias.dart';
import 'package:fluxo_caixa_familiar/pages/home/home.dart';
import 'package:fluxo_caixa_familiar/pages/lancamentos/adicionar_lancamento.dart';
import 'package:fluxo_caixa_familiar/pages/lancamentos/lancamentos.dart';
import 'package:fluxo_caixa_familiar/pages/responsaveis/responsaveis.dart';

void main() {
  runApp(FluxoFamiliaApp());
}

class FluxoFamiliaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluxo Família',
      theme: ThemeData(primarySwatch: Colors.indigo),

      // --- CORREÇÃO DE LOCALIZAÇÃO ADICIONADA ---
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('pt', 'BR'), // Suporte para Português do Brasil
      ],
      // --- FIM DA CORREÇÃO ---

      initialRoute: '/',
      routes: {
        '/': (context) => Home(),
        '/lancamentos': (context) => Lancamentos(),
        '/categorias': (context) => Categorias(),
        '/responsaveis': (context) => Responsaveis(),
        // --- ROTA DE EDITAR ADICIONADA ---
        '/editar': (context) => AdicionarLancamento(),
      },
    );
  }
}