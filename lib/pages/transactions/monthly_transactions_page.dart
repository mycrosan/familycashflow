import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/recurring_transaction_provider.dart';
import '../../models/transaction.dart';
import '../../models/recurring_transaction.dart';
import '../transactions/add_transaction_page.dart';

class TransacoesMensaisPage extends StatefulWidget {
  @override
  _TransacoesMensaisPageState createState() => _TransacoesMensaisPageState();
}

class _TransacoesMensaisPageState extends State<TransacoesMensaisPage> {
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
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar transações...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
            prefixIcon: Icon(Icons.search, color: Colors.white70),
          ),
          style: TextStyle(color: Colors.white, fontSize: 16),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddTransactionDialog(context),
            tooltip: 'Adicionar Transação',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Controle de meses com setas
            _buildMonthNavigation(),
            
            // Saldo do mês
            _buildMonthBalance(),
            
            // Filtros
            _buildFilters(),
            
            // Lista de transações
            _buildTransactionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigation() {
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
              tooltip: 'Mês Anterior',
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
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right),
              onPressed: _nextMonth,
              tooltip: 'Próximo Mês',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthBalance() {
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo do Mês',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatCurrency(balance),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
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
                    onPressed: () => _loadMonthData(),
                    child: Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final transactions = provider.getTransactionsForMonth(_selectedMonth);
        final filteredTransactions = _filterTransactions(transactions);

        if (filteredTransactions.isEmpty) {
          return Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma transação encontrada',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Adicione transações ou verifique os filtros',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      // Filtro por tipo
      if (transaction.value > 0 && !_showIncome) return false;
      if (transaction.value < 0 && !_showExpense) return false;
      
      // Filtro por busca
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch = 
          transaction.category.toLowerCase().contains(query) ||
          (transaction.notes?.toLowerCase().contains(query) ?? false) ||
          transaction.associatedMember.name.toLowerCase().contains(query);
        
        if (!matchesSearch) return false;
      }
      
      return true;
    }).toList();
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isIncome = transaction.value > 0;
    final color = isIncome ? Colors.green : Colors.red;
    final icon = isIncome ? Icons.trending_up : Icons.trending_down;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          transaction.category,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        subtitle: Text(
          '${transaction.associatedMember.name} • ${DateFormat('dd/MM/yyyy').format(transaction.date)}',
          style: TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatCurrency(transaction.value),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (transaction.recurringTransactionId != null)
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
        onTap: () => _showTransactionEditMode(transaction),
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

  void _showTransactionEditMode(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              transaction.value > 0 ? Icons.trending_up : Icons.trending_down,
              color: transaction.value > 0 ? Colors.green : Colors.red,
            ),
            SizedBox(width: 8),
            Text('Editar Transação'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações da transação
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categoria: ${transaction.category}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('Valor: ${_formatCurrency(transaction.value)}'),
                    Text('Membro: ${transaction.associatedMember.name}'),
                    Text('Data: ${DateFormat('dd/MM/yyyy').format(transaction.date)}'),
                    if (transaction.notes != null) Text('Observações: ${transaction.notes}'),
                    if (transaction.recurringTransactionId != null) 
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Transação Recorrente',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Escolha uma ação:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditTransactionDialog(transaction);
            },
            icon: Icon(Icons.edit),
            tooltip: 'Editar',
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          if (transaction.recurringTransactionId != null)
            IconButton(
              onPressed: () {
                Navigator.pop(context);
                _showRecurringDeleteOptions(transaction);
              },
              icon: Icon(Icons.delete),
              tooltip: 'Remover',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            )
          else
            IconButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmation(transaction);
              },
              icon: Icon(Icons.delete),
              tooltip: 'Remover',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
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

  void _showRecurringDeleteOptions(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Remover Transação Recorrente'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta é uma transação recorrente. Escolha como deseja removê-la:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transação: ${transaction.category}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Valor: ${_formatCurrency(transaction.value)}'),
                    Text('Data: ${DateFormat('dd/MM/yyyy').format(transaction.date)}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Opções de remoção:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _deleteSingleTransaction(transaction);
            },
            icon: Icon(Icons.delete_outline),
            label: Text('Apenas este'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecurringTransaction(transaction);
            },
            icon: Icon(Icons.delete_forever),
            label: Text('Este e futuros'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmar Exclusão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja excluir esta transação?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transação: ${transaction.category}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Valor: ${_formatCurrency(transaction.value)}'),
                    Text('Data: ${DateFormat('dd/MM/yyyy').format(transaction.date)}'),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSingleTransaction(transaction);
            },
            icon: Icon(Icons.delete),
            tooltip: 'Excluir',
            style: IconButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSingleTransaction(Transaction transaction) async {
    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      final success = await provider.deleteTransaction(transaction.id!);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transação excluída com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMonthData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir transação'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir transação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteRecurringTransaction(Transaction transaction) async {
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final recurringProvider = Provider.of<RecurringTransactionProvider>(context, listen: false);
      
      // Mostrar diálogo de confirmação final
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Confirmação Final'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Esta ação irá:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Remover esta transação'),
              Text('• Remover a recorrência associada'),
              Text('• Remover todas as transações futuras desta recorrência'),
              SizedBox(height: 16),
              Text(
                'Esta ação não pode ser desfeita!',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar'),
            ),
                      IconButton(
            onPressed: () => Navigator.pop(context, true),
            icon: Icon(Icons.delete_forever),
            tooltip: 'Confirmar',
            style: IconButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Remover a transação atual
      await transactionProvider.deleteTransaction(transaction.id!);
      
      // Se é uma transação recorrente, remover a recorrência
      if (transaction.recurringTransactionId != null) {
        // Encontrar e remover a recorrência
        final recurringTransactions = recurringProvider.recurringTransactions;
        final recurringTransaction = recurringTransactions.firstWhere(
          (rt) => rt.id == transaction.recurringTransactionId,
          orElse: () => throw Exception('Recorrência não encontrada'),
        );
        
        await recurringProvider.deleteRecurringTransaction(recurringTransaction.id!);
        
        // Remover todas as transações futuras desta recorrência
        final futureTransactions = transactionProvider.transactions.where(
          (t) => t.recurringTransactionId == transaction.recurringTransactionId &&
                 t.date.isAfter(transaction.date)
        ).toList();
        
        for (final futureTransaction in futureTransactions) {
          await transactionProvider.deleteTransaction(futureTransaction.id!);
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transação recorrente e todas as futuras foram removidas'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      _loadMonthData();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir transação recorrente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método legado para compatibilidade
  Future<void> _deleteTransaction(Transaction transaction) async {
    await _deleteSingleTransaction(transaction);
  }
}
