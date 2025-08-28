import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/custom_button.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Relatórios'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, child) {
          if (reportProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relatórios Financeiros',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24),

                // Resumo mensal
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumo Mensal',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'Receitas',
                                reportProvider.totalIncome,
                                Colors.green,
                                Icons.trending_up,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                'Despesas',
                                reportProvider.totalExpense,
                                Colors.red,
                                Icons.trending_down,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                'Saldo',
                                reportProvider.balance,
                                reportProvider.balance >= 0 ? Colors.green : Colors.red,
                                Icons.account_balance_wallet,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Top categorias de despesa
                if (reportProvider.expensesByCategory.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Categorias de Despesa',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          ...reportProvider.getTopExpenseCategories().map((entry) {
                            final percentage = reportProvider.formatPercentage(
                              entry.value,
                              reportProvider.totalExpense,
                            );
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.withOpacity(0.1),
                                child: Icon(Icons.category, color: Colors.red),
                              ),
                              title: Text(entry.key),
                              subtitle: Text(percentage),
                              trailing: Text(
                                reportProvider.formatCurrency(entry.value),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 24),

                // Top categorias de receita
                if (reportProvider.incomeByCategory.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Categorias de Receita',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          ...reportProvider.getTopIncomeCategories().map((entry) {
                            final percentage = reportProvider.formatPercentage(
                              entry.value,
                              reportProvider.totalIncome,
                            );
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.withOpacity(0.1),
                                child: Icon(Icons.category, color: Colors.green),
                              ),
                              title: Text(entry.key),
                              subtitle: Text(percentage),
                              trailing: Text(
                                reportProvider.formatCurrency(entry.value),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 24),

                // Ações
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Relatório Anual',
                        onPressed: () {
                          // TODO: Implementar relatório anual
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Relatório anual em desenvolvimento')),
                          );
                        },
                        outlined: true,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Exportar PDF',
                        onPressed: () {
                          // TODO: Implementar exportação PDF
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Exportação PDF em desenvolvimento')),
                          );
                        },
                        outlined: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String label, double value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            NumberFormat.currency(
              locale: 'pt_BR',
              symbol: 'R\$',
              decimalDigits: 2,
            ).format(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
