 import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/member.dart';
import '../../models/recurring_transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/recurring_transaction_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/quick_entry_provider.dart';

// Enum para tipo de transação
enum TransactionType { income, expense }

// Enum para tipo de recorrência
enum RecurrenceType { daily, weekly, monthly, yearly }

class AddTransactionPage extends StatefulWidget {
  final Transaction? transactionToEdit;
  final RecurringTransaction? recurringTransactionToEdit;

  const AddTransactionPage({
    Key? key,
    this.transactionToEdit,
    this.recurringTransactionToEdit,
  }) : super(key: key);

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  TransactionType _selectedType = TransactionType.expense;
  Category? _selectedCategory;
  Member? _selectedMember;
  DateTime _selectedDate = DateTime.now();
  
  // Campos de recorrência
  bool _isRecurring = false;
  RecurrenceType _recurrenceType = RecurrenceType.monthly;
  int _interval = 1;
  DateTime? _endDate;
  int? _maxOccurrences;
  
  // Controladores para máscara de valor
  final _valueFocusNode = FocusNode();
  final _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _valueFocusNode.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    if (widget.transactionToEdit != null) {
      _loadTransactionData();
    } else if (widget.recurringTransactionToEdit != null) {
      _loadRecurringTransactionData();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadTransactionData() {
    final transaction = widget.transactionToEdit!;
    // Determinar tipo baseado na categoria
    _selectedType = _getTransactionTypeFromCategory(transaction.category);
    _selectedCategory = _findCategoryByName(transaction.category);
    _selectedMember = transaction.associatedMember;
    _selectedDate = transaction.date;
    _valueController.text = _currencyFormatter.format(transaction.value);
    _descriptionController.text = transaction.notes ?? '';
    _notesController.text = transaction.notes ?? '';
  }

  void _loadRecurringTransactionData() {
    final recurring = widget.recurringTransactionToEdit!;
    // Determinar tipo baseado na categoria
    _selectedType = _getTransactionTypeFromCategory(recurring.category);
    _selectedCategory = _findCategoryByName(recurring.category);
    _selectedMember = recurring.associatedMember;
    _selectedDate = recurring.startDate;
    _valueController.text = _currencyFormatter.format(recurring.value);
    _descriptionController.text = recurring.notes ?? '';
    _notesController.text = recurring.notes ?? '';
    _isRecurring = true;
    _recurrenceType = _getRecurrenceTypeFromString(recurring.frequency);
    _interval = 1; // Default, não temos essa informação no modelo atual
    _endDate = recurring.endDate;
    _maxOccurrences = recurring.maxOccurrences;
  }

  TransactionType _getTransactionTypeFromCategory(String categoryName) {
    // Buscar categoria para determinar o tipo
    final categoryProvider = context.read<CategoryProvider>();
    final category = categoryProvider.categories.firstWhere(
      (cat) => cat.name == categoryName,
      orElse: () => Category(
        name: categoryName,
        type: 'expense',
        userId: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return category.type == 'income' ? TransactionType.income : TransactionType.expense;
  }

  Category? _findCategoryByName(String categoryName) {
    final categoryProvider = context.read<CategoryProvider>();
    try {
      return categoryProvider.categories.firstWhere((cat) => cat.name == categoryName);
    } catch (e) {
      return null;
    }
  }

  RecurrenceType _getRecurrenceTypeFromString(String frequency) {
    switch (frequency) {
      case 'daily':
        return RecurrenceType.daily;
      case 'weekly':
        return RecurrenceType.weekly;
      case 'monthly':
        return RecurrenceType.monthly;
      case 'yearly':
        return RecurrenceType.yearly;
      default:
        return RecurrenceType.monthly;
    }
  }

  String _getRecurrenceTypeString(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return 'daily';
      case RecurrenceType.weekly:
        return 'weekly';
      case RecurrenceType.monthly:
        return 'monthly';
      case RecurrenceType.yearly:
        return 'yearly';
    }
  }

  void _loadData() async {
    final categoryProvider = context.read<CategoryProvider>();
    final memberProvider = context.read<MemberProvider>();
    
    await Future.wait([
      categoryProvider.loadCategories(),
      memberProvider.loadMembers(),
    ]);
    
    if (mounted) {
      setState(() {});
    }
  }

  void _setTransactionType(TransactionType type) {
    setState(() {
      _selectedType = type;
      // Limpar categoria se mudar o tipo
      if (_selectedCategory != null && _selectedCategory!.type != _getTypeString(type)) {
        _selectedCategory = null;
      }
    });
  }

  String _getTypeString(TransactionType type) {
    return type == TransactionType.income ? 'income' : 'expense';
  }

  String _getTransactionValue() {
    // Remove a máscara e converte para double
    final cleanValue = _valueController.text
        .replaceAll('R\$ ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final value = double.tryParse(cleanValue) ?? 0.0;
    
    // Aplicar sinal baseado no tipo de transação
    final finalValue = _selectedType == TransactionType.expense ? -value.abs() : value.abs();
    return finalValue.toString();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria')),
      );
      return;
    }
    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um membro')),
      );
      return;
    }

    try {
      if (_isRecurring) {
        await _saveRecurringTransaction();
      } else {
        await _saveTransaction();
      }
      
      if (mounted) {
        // Mostrar mensagem de sucesso
        final tipoTransacao = _isRecurring ? 'Transação Recorrente' : 'Transação';
        final tipoValor = _selectedType == TransactionType.income ? 'Receita' : 'Despesa';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$tipoTransacao salva com sucesso! ($tipoValor)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ),
        );
        
        // Atualizar dados da tela inicial
        await _updateHomeData();
        
        // Aguardar um pouco antes de fechar
        await Future.delayed(Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateHomeData() async {
    try {
      final transactionProvider = context.read<TransactionProvider>();
      final reportProvider = context.read<ReportProvider>();
      final quickEntryProvider = context.read<QuickEntryProvider>();
      
      // Atualizar dados em paralelo
      await Future.wait([
        transactionProvider.refresh(),
        reportProvider.generateMonthlyReport(DateTime.now()),
        quickEntryProvider.loadRecentTransactions(),
      ]);
    } catch (e) {
      print('Erro ao atualizar dados da tela inicial: $e');
    }
  }

  Future<void> _saveTransaction() async {
    final transactionProvider = context.read<TransactionProvider>();
    
    if (widget.transactionToEdit != null) {
      // Atualizar transação existente
      final updatedTransaction = widget.transactionToEdit!.copyWith(
        value: double.parse(_getTransactionValue()),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        category: _selectedCategory!.name,
        associatedMember: _selectedMember!,
        date: _selectedDate,
        updatedAt: DateTime.now(),
      );
      
      await transactionProvider.updateTransaction(updatedTransaction);
    } else {
      // Criar nova transação
      final newTransaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch,
        value: double.parse(_getTransactionValue()),
        date: _selectedDate,
        category: _selectedCategory!.name,
        associatedMember: _selectedMember!,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await transactionProvider.addTransaction(newTransaction);
    }
  }

  Future<void> _saveRecurringTransaction() async {
    final recurringProvider = context.read<RecurringTransactionProvider>();
    
    if (widget.recurringTransactionToEdit != null) {
      // Atualizar recorrência existente
      final updatedRecurring = widget.recurringTransactionToEdit!.copyWith(
        value: double.parse(_getTransactionValue()),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        category: _selectedCategory!.name,
        associatedMember: _selectedMember!,
        startDate: _selectedDate,
        frequency: _getRecurrenceTypeString(_recurrenceType),
        endDate: _endDate,
        maxOccurrences: _maxOccurrences,
        isActive: 1,
        updatedAt: DateTime.now(),
      );
      
      await recurringProvider.updateRecurringTransaction(updatedRecurring);
    } else {
      // Criar nova recorrência
      final newRecurring = RecurringTransaction(
        id: DateTime.now().millisecondsSinceEpoch,
        frequency: _getRecurrenceTypeString(_recurrenceType),
        category: _selectedCategory!.name,
        value: double.parse(_getTransactionValue()),
        associatedMember: _selectedMember!,
        startDate: _selectedDate,
        endDate: _endDate,
        maxOccurrences: _maxOccurrences,
        isActive: 1,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        userId: 1, // TODO: Pegar do usuário logado
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await recurringProvider.addRecurringTransaction(
        frequency: _getRecurrenceTypeString(_recurrenceType),
        category: _selectedCategory!.name,
        value: double.parse(_getTransactionValue()),
        associatedMemberId: _selectedMember!.id!,
        startDate: _selectedDate,
        endDate: _endDate,
        maxOccurrences: _maxOccurrences,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transactionToEdit != null || widget.recurringTransactionToEdit != null;
    final pageTitle = isEditing ? 'Editar Transação' : 'Nova Transação';
    final saveButtonText = isEditing ? 'Atualizar' : 'Salvar';

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tipo de transação
              _buildTypeSelector(),
              const SizedBox(height: 24),
              
              // Valor
              _buildValueField(),
              const SizedBox(height: 24),
              
              // Descrição
              _buildDescriptionField(),
              const SizedBox(height: 24),
              
              // Categoria
              _buildCategoryField(),
              const SizedBox(height: 24),
              
              // Membro
              _buildMemberField(),
              const SizedBox(height: 24),
              
              // Data
              _buildDateField(),
              const SizedBox(height: 24),
              
              // Notas
              _buildNotesField(),
              const SizedBox(height: 24),
              
              // Opção de recorrência
              _buildRecurrenceToggle(),
              
              // Campos de recorrência
              if (_isRecurring) ...[
                const SizedBox(height: 16),
                _buildRecurrenceFields(),
              ],
              
              const SizedBox(height: 32),
              
              // Botão salvar
              ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(
                  saveButtonText,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Transação',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeButton(
                TransactionType.expense,
                'Despesa',
                Icons.remove_circle_outline,
                Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTypeButton(
                TransactionType.income,
                'Receita',
                Icons.add_circle_outline,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton(
    TransactionType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;
    return ElevatedButton(
      onPressed: () => _setTransactionType(type),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildValueField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Valor',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _valueController,
          focusNode: _valueFocusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CurrencyInputFormatter(),
          ],
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.attach_money),
            hintText: 'R\$ 0,00',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Digite um valor';
            }
            final cleanValue = value.replaceAll('R\$ ', '').replaceAll('.', '').replaceAll(',', '.');
            if (double.tryParse(cleanValue) == null || double.parse(cleanValue) <= 0) {
              return 'Digite um valor válido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descrição',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            hintText: 'Ex: Conta de luz, Salário, etc.',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Digite uma descrição';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories
        .where((cat) => cat.type == _getTypeString(_selectedType))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoria',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Category>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          hint: const Text('Selecione uma categoria'),
          items: categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Row(
                children: [
                  Icon(
                    category.icon != null ? _getIconFromString(category.icon!) : Icons.category,
                    color: category.color != null ? _getColorFromString(category.color!) : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(category.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (Category? newValue) {
            setState(() {
              _selectedCategory = newValue;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Selecione uma categoria';
            }
            return null;
          },
        ),
      ],
    );
  }

  IconData _getIconFromString(String iconString) {
    // Mapear strings para ícones
    switch (iconString.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_cart;
      case 'health':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'entertainment':
        return Icons.movie;
      case 'work':
        return Icons.work;
      default:
        return Icons.category;
    }
  }

  Color _getColorFromString(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.replaceAll('#', '0xFF')));
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  Widget _buildMemberField() {
    final memberProvider = context.watch<MemberProvider>();
    final members = memberProvider.members;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Membro da Família',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Member>(
          value: _selectedMember,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          hint: const Text('Selecione um membro'),
          items: members.map((member) {
            return DropdownMenuItem(
              value: member,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _getMemberColor(member),
                    child: Text(
                      member.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(member.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (Member? newValue) {
            setState(() {
              _selectedMember = newValue;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Selecione um membro';
            }
            return null;
          },
        ),
      ],
    );
  }

  Color _getMemberColor(Member member) {
    // Gerar cor baseada no nome do membro
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    
    final index = member.name.hashCode % colors.length;
    return colors[index.abs()];
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              DateFormat('dd/MM/yyyy').format(_selectedDate),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observações (opcional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
            hintText: 'Adicione observações se necessário...',
          ),
        ),
      ],
    );
  }

  Widget _buildRecurrenceToggle() {
    return SwitchListTile(
      title: const Text(
        'Transação Recorrente',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: const Text('Marque se esta transação se repete'),
      value: _isRecurring,
      onChanged: (bool value) {
        setState(() {
          _isRecurring = value;
          if (!value) {
            _endDate = null;
            _maxOccurrences = null;
          }
        });
      },
      secondary: const Icon(Icons.repeat),
    );
  }

  Widget _buildRecurrenceFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações de Recorrência',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Tipo de recorrência
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<RecurrenceType>(
                    value: _recurrenceType,
                    decoration: const InputDecoration(
                      labelText: 'Frequência',
                      border: OutlineInputBorder(),
                    ),
                    items: RecurrenceType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getRecurrenceTypeLabel(type)),
                      );
                    }).toList(),
                    onChanged: (RecurrenceType? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _recurrenceType = newValue;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _interval.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Intervalo',
                      border: OutlineInputBorder(),
                      hintText: '1',
                    ),
                    onChanged: (value) {
                      final interval = int.tryParse(value);
                      if (interval != null && interval > 0) {
                        setState(() {
                          _interval = interval;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Data de fim
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data de Fim (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event_busy),
                      ),
                      child: Text(
                        _endDate != null
                            ? DateFormat('dd/MM/yyyy').format(_endDate!)
                            : 'Sem data de fim',
                        style: TextStyle(
                          color: _endDate != null ? null : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _endDate != null
                      ? () {
                          setState(() {
                            _endDate = null;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Limpar data de fim',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Número máximo de ocorrências
            TextFormField(
              initialValue: _maxOccurrences?.toString() ?? '',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número máximo de ocorrências (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat_one),
                hintText: 'Deixe em branco para ilimitado',
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  setState(() {
                    _maxOccurrences = null;
                  });
                } else {
                  final maxOcc = int.tryParse(value);
                  if (maxOcc != null && maxOcc > 0) {
                    setState(() {
                      _maxOccurrences = maxOcc;
                    });
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getRecurrenceTypeLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return 'Diária';
      case RecurrenceType.weekly:
        return 'Semanal';
      case RecurrenceType.monthly:
        return 'Mensal';
      case RecurrenceType.yearly:
        return 'Anual';
    }
  }
}

// Formatter para máscara de moeda
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove tudo que não é dígito
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Converte para centavos
    final cents = int.parse(digits);
    final reais = cents / 100;
    
    // Formata como moeda brasileira
    final formatted = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
      decimalDigits: 2,
    ).format(reais);

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
