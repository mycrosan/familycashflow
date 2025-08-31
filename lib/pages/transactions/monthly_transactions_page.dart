import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/recurring_transaction_provider.dart';
import '../../models/transaction.dart';
import '../../models/recurring_transaction.dart';
import '../transactions/add_transaction_page.dart';

class MonthlyTransactionsPage extends StatefulWidget {
  @override
  _MonthlyTransactionsPageState createState() => _MonthlyTransactionsPageState();
}

class _MonthlyTransactionsPageState extends State<MonthlyTransactionsPage> {
  DateTime _selectedMonth = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showIncome = true;
  bool _showExpense = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMonthData();
    });
  }

  void _loadMonthData() async {
    try {
      print('Carregando dados para o mês: ${_selectedMonth.month}/${_selectedMonth.year}');
      
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final recurringProvider = Provider.of<RecurringTransactionProvider>(context, listen: false);
      
      print('Providers obtidos com sucesso');
      
      // Carregar recorrências primeiro
      await recurringProvider.loadRecurringTransactions();
      print('Recorrências carregadas: ${recurringProvider.recurringTransactions.length}');
      
      // Carregar transações do mês
      await transactionProvider.loadTransactionsForMonth(_selectedMonth);
      print('Transações carregadas: ${transactionProvider.transactions.length}');
      
      // Gerar transações recorrentes para o mês selecionado
      await _generateRecurringTransactionsForMonth();
      
      print('Transações do mês após geração: ${transactionProvider.getTransactionsForMonth(_selectedMonth).length}');
      
    } catch (e) {
      print('Erro ao carregar dados: $e');
    }
  }

  // Gerar transações recorrentes para o mês selecionado
  Future<void> _generateRecurringTransactionsForMonth() async {
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final recurringProvider = Provider.of<RecurringTransactionProvider>(context, listen: false);
      
      final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      
      // Gerar transações recorrentes
      final recurringTransactions = await recurringProvider.generateTransactionsFromRecurring(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );
      
      print('Transações recorrentes geradas: ${recurringTransactions.length}');
      
      // Adicionar transações recorrentes que não existem no banco
      for (final recurringTransaction in recurringTransactions) {
        final exists = transactionProvider.transactions.any((t) => 
          t.recurringTransactionId == recurringTransaction.recurringTransactionId &&
          t.date.year == recurringTransaction.date.year &&
          t.date.month == recurringTransaction.date.month &&
          t.date.day == recurringTransaction.date.day
        );
        
        if (!exists) {
          print('Adicionando transação recorrente: ${recurringTransaction.notes ?? 'Sem descrição'} - ${recurringTransaction.date}');
          await transactionProvider.addTransaction(recurringTransaction);
        }
      }
      
    } catch (e) {
      print('Erro ao gerar transações recorrentes: $e');
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadMonthData();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadMonthData();
  }

  void _goToCurrentMonth() {
    setState(() {
      _selectedMonth = DateTime.now();
    });
    _loadMonthData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transações Mensais'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddTransactionDialog(context),
            tooltip: 'Adicionar Transação',
          ),
          IconButton(
            icon: Icon(Icons.repeat),
            onPressed: () => _showAddRecurringTransactionDialog(context),
            tooltip: 'Criar Recorrência',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho do mês
            _buildMonthHeader(),
            
            // Resumo financeiro
            _buildFinancialSummary(),
            
            // Filtros
            _buildFilters(),
            
            // Lista de transações
            _buildTransactionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left),
              onPressed: _previousMonth,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _goToCurrentMonth,
                    child: Text('Ir para mês atual'),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right),
              onPressed: _nextMonth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final transactions = provider.getTransactionsForMonth(_selectedMonth);
        
        double totalIncome = 0;
        double totalExpense = 0;
        
        for (final transaction in transactions) {
          if (transaction.value > 0) {
            totalIncome += transaction.value;
          } else {
            totalExpense += transaction.value.abs();
          }
        }
        
        final balance = totalIncome - totalExpense;
        
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16),
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
                        totalIncome,
                        Colors.green,
                        Icons.trending_up,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryItem(
                        'Despesas',
                        totalExpense,
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
                      _formatCurrency(balance),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.green : Colors.red,
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
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _formatCurrency(value),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Campo de busca
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar transações',
                hintText: 'Digite para buscar...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            SizedBox(height: 16),
            
            // Filtros de tipo
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: Text('Receitas'),
                    selected: _showIncome,
                    onSelected: (selected) {
                      setState(() {
                        _showIncome = selected;
                      });
                    },
                    selectedColor: Colors.green.withOpacity(0.2),
                    checkmarkColor: Colors.green,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: Text('Despesas'),
                    selected: _showExpense,
                    onSelected: (selected) {
                      setState(() {
                        _showExpense = selected;
                      });
                    },
                    selectedColor: Colors.red.withOpacity(0.2),
                    checkmarkColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Container(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null) {
          return Container(
            height: 200,
            child: Center(
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
            ),
          );
        }

        final transactions = provider.getTransactionsForMonth(_selectedMonth);
        final filteredTransactions = _filterTransactions(transactions);

        print('Transações filtradas: ${filteredTransactions.length}');

        if (filteredTransactions.isEmpty) {
          return Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma transação encontrada',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Adicione transações para este mês',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddTransactionDialog(context),
                    child: Text('Adicionar Primeira Transação'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transações (${filteredTransactions.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => provider.refresh(),
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text('Atualizar'),
                  ),
                ],
              ),
            ),
            ...filteredTransactions.map((transaction) => _buildTransactionItem(transaction)),
          ],
        );
      },
    );
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    return transactions.where((transaction) {
      // Filtro de tipo
      if (!_showIncome && transaction.value > 0) return false;
      if (!_showExpense && transaction.value < 0) return false;
      
      // Filtro de busca
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final category = transaction.category.toLowerCase();
        final memberName = transaction.associatedMember.name.toLowerCase();
        final notes = transaction.notes?.toLowerCase() ?? '';
        
        if (!category.contains(query) && 
            !memberName.contains(query) && 
            !notes.contains(query)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isIncome = transaction.value > 0;
    final color = isIncome ? Colors.green : Colors.red;
    final icon = isIncome ? Icons.add_circle : Icons.remove_circle;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          transaction.category,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${transaction.associatedMember.name} • ${transaction.formattedDate}',
          style: TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              transaction.formattedValue,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (transaction.isRecurring)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Recorrente',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                  ),
                ),
              ),
          ],
        ),
        onTap: () => _showTransactionDetails(transaction),
        onLongPress: () => _showTransactionOptions(transaction),
      ),
    );
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
      decimalDigits: 2,
    ).format(value);
  }

  void _showTransactionDetails(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalhes da Transação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categoria: ${transaction.category}'),
            Text('Valor: ${transaction.formattedValue}'),
            Text('Membro: ${transaction.associatedMember.name}'),
            Text('Data: ${transaction.formattedDate}'),
            if (transaction.notes != null) Text('Observações: ${transaction.notes}'),
            if (transaction.isRecurring) Text('Transação Recorrente: Sim'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showTransactionOptions(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Editar'),
            onTap: () {
              Navigator.pop(context);
              _showEditTransactionDialog(transaction);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Excluir', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(transaction);
            },
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(),
      ),
    ).then((_) {
      _loadMonthData();
    });
  }

  void _showAddRecurringTransactionDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(),
      ),
    ).then((_) {
      _loadMonthData();
    });
  }

  void _showEditTransactionDialog(Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(
          transactionToEdit: transaction,
        ),
      ),
    ).then((_) {
      _loadMonthData();
    });
  }

  void _showDeleteConfirmation(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir esta transação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTransaction(transaction);
            },
            child: Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      final success = await provider.deleteTransaction(transaction.id!);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transação excluída com sucesso')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir transação')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir transação: $e')),
      );
    }
  }
}
