import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/quick_entry_provider.dart';
import '../../providers/auth_provider.dart';

import '../transactions/add_transaction_page.dart';
import '../transactions/monthly_transactions_page.dart';
import '../reports/reports_page.dart';
import '../members/members_page.dart';
import '../categories/categories_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Inicializar dados quando a página carregar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final transactionProvider = context.read<TransactionProvider>();
    final reportProvider = context.read<ReportProvider>();
    final quickEntryProvider = context.read<QuickEntryProvider>();
    
    await Future.wait([
      transactionProvider.initialize(),
      reportProvider.generateMonthlyReport(_selectedMonth),
      quickEntryProvider.loadRecentTransactions(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fluxo Família'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () {
              // TODO: Implementar sincronização
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sincronização em desenvolvimento')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Perfil'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Configurações'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sair'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transações',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Relatórios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Membros',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categorias',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTransactionPage()),
          );
          
          // Se retornou com sucesso, atualizar dados
          if (result == true) {
            _refreshData();
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
        tooltip: 'Adicionar Transação',
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return TransacoesMensaisPage();
      case 2:
        return ReportsPage();
      case 3:
        return MembersPage();
      case 4:
        return CategoriesPage();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Erro: ${provider.error}',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.refresh(),
                  child: Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho do mês
                _buildMonthHeader(),
                SizedBox(height: 24),
                
                // Resumo financeiro
                _buildFinancialSummary(),
                SizedBox(height: 24),
                

                
                // Ações rápidas
                _buildQuickActions(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
            });
            _refreshMonthData();
          },
        ),
        Text(
          DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
            });
            _refreshMonthData();
          },
        ),
      ],
    );
  }

  Widget _buildFinancialSummary() {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumo do Mês',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Receitas',
                        reportProvider.totalIncome,
                        Colors.green,
                        Icons.trending_up,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryItem(
                        'Despesas',
                        reportProvider.totalExpense,
                        Colors.red,
                        Icons.trending_down,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saldo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      reportProvider.formatCurrency(reportProvider.balance),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: reportProvider.balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Text(
          NumberFormat.currency(
            locale: 'pt_BR',
            symbol: 'R\$',
            decimalDigits: 2,
          ).format(value),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

 



  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ações Rápidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Adicionar Receita',
                    Icons.add_circle,
                    Colors.green,
                    () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddTransactionPage()),
                      );
                      
                      // Se retornou com sucesso, atualizar dados
                      if (result == true) {
                        _refreshData();
                      }
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Adicionar Despesa',
                    Icons.remove_circle,
                    Colors.red,
                    () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddTransactionPage()),
                      );
                      
                      // Se retornou com sucesso, atualizar dados
                      if (result == true) {
                        _refreshData();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        // TODO: Implementar página de perfil
        break;
      case 'settings':
        // TODO: Implementar configurações
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sair'),
        content: Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Sair'),
          ),
        ],
      ),
    );
  }

  void _refreshMonthData() {
    context.read<ReportProvider>().generateMonthlyReport(_selectedMonth);
  }

  void _refreshData() {
    final transactionProvider = context.read<TransactionProvider>();
    final reportProvider = context.read<ReportProvider>();
    final quickEntryProvider = context.read<QuickEntryProvider>();
    
    // Atualizar dados em paralelo
    Future.wait([
      transactionProvider.loadAllTransactions(), // Carregar todas as transações
      reportProvider.generateMonthlyReport(_selectedMonth),
      quickEntryProvider.loadRecentTransactions(),
    ]);
  }
}

