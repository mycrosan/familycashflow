import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransacoesMensaisPage extends StatefulWidget {
  const TransacoesMensaisPage({super.key});

  @override
  State<TransacoesMensaisPage> createState() => _TransacoesMensaisPageState();
}

class _TransacoesMensaisPageState extends State<TransacoesMensaisPage> {
  DateTime _selectedMonth = DateTime.now();

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
    });
  }

  Widget _buildMonthNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
            tooltip: 'Mês Anterior',
          ),
          Text(
            DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
            tooltip: 'Próximo Mês',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transações Mensais"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildMonthNavigation(),
          const Divider(),
          // Aqui você pode colocar a lista das transações do mês
          Expanded(
            child: Center(
              child: Text(
                "Lista de transações do mês de ${DateFormat('MMMM', 'pt_BR').format(_selectedMonth)}",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
