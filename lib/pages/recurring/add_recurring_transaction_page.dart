import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/recurring_transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/quick_entry_provider.dart';
import '../../models/category.dart';
import '../../models/member.dart';
import '../../models/recurring_transaction.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddRecurringTransactionPage extends StatefulWidget {
  final RecurringTransaction? recurringTransactionToEdit;
  
  const AddRecurringTransactionPage({
    Key? key, 
    this.recurringTransactionToEdit,
  }) : super(key: key);
  
  @override
  _AddRecurringTransactionPageState createState() => _AddRecurringTransactionPageState();
}

class _AddRecurringTransactionPageState extends State<AddRecurringTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedFrequency = 'monthly';
  String _selectedCategory = '';
  int _selectedMemberId = 0;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int? _maxOccurrences;
  int _isActive = 1;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    
    // Se estiver editando, preencher os campos
    if (widget.recurringTransactionToEdit != null) {
      _loadRecurringTransactionData();
    }
  }

  void _loadInitialData() {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final memberProvider = Provider.of<MemberProvider>(context, listen: false);
    
    categoryProvider.loadCategories();
    memberProvider.loadMembers();
    
    // Selecionar primeira categoria e membro por padrão (apenas se não estiver editando)
    if (widget.recurringTransactionToEdit == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (categoryProvider.categories.isNotEmpty) {
          setState(() {
            _selectedCategory = categoryProvider.categories.first.name;
          });
        }
        if (memberProvider.members.isNotEmpty) {
          setState(() {
            _selectedMemberId = memberProvider.members.first.id!;
          });
        }
      });
    }
  }

  void _loadRecurringTransactionData() {
    final rt = widget.recurringTransactionToEdit!;
    
    setState(() {
      _selectedFrequency = rt.frequency;
      _selectedCategory = rt.category;
      _selectedMemberId = rt.associatedMember.id!;
      _startDate = rt.startDate;
      _endDate = rt.endDate;
      _maxOccurrences = rt.maxOccurrences;
      _isActive = rt.isActive;
      _valueController.text = rt.value.abs().toString();
      _notesController.text = rt.notes ?? '';
      
      // O tipo de transação será definido automaticamente pelo valor
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recurringTransactionToEdit != null 
          ? 'Editar Transação Recorrente' 
          : 'Nova Transação Recorrente'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo de transação
              _buildTransactionTypeSelector(),
              SizedBox(height: 24),
              
              // Valor
              CustomTextField(
                controller: _valueController,
                labelText: 'Valor',
                hintText: '0,00',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icon(Icons.attach_money),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Valor é obrigatório';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Categoria
              _buildCategorySelector(),
              SizedBox(height: 16),
              
              // Membro responsável
              _buildMemberSelector(),
              SizedBox(height: 24),
              
              // Frequência
              _buildFrequencySelector(),
              SizedBox(height: 24),
              
              // Data de início
              _buildDateSelector(),
              SizedBox(height: 16),
              
              // Data de fim (opcional)
              _buildEndDateSelector(),
              SizedBox(height: 16),
              
              // Número máximo de ocorrências
              _buildMaxOccurrencesSelector(),
              SizedBox(height: 24),
              
              // Observações
              CustomTextField(
                controller: _notesController,
                labelText: 'Observações (opcional)',
                hintText: 'Adicione observações...',
                maxLines: 3,
              ),
              SizedBox(height: 24),
              
              // Status ativo
              SwitchListTile(
                title: Text('Transação ativa'),
                subtitle: Text('Gerar transações automaticamente'),
                value: _isActive == 1,
                onChanged: (value) {
                  setState(() {
                    _isActive = value ? 1 : 0;
                  });
                },
              ),
              SizedBox(height: 32),
              
              // Botão de salvar
              CustomButton(
                text: widget.recurringTransactionToEdit != null 
                  ? 'Atualizar Transação Recorrente' 
                  : 'Criar Transação Recorrente',
                onPressed: _isLoading ? null : _handleSave,
                isLoading: _isLoading,
                icon: widget.recurringTransactionToEdit != null ? Icons.edit : Icons.save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de Transação',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTypeOption(
                    'Receita',
                    Icons.trending_up,
                    Colors.green,
                    () => _setTransactionType(true),
                    _getTransactionValue() > 0,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildTypeOption(
                    'Despesa',
                    Icons.trending_down,
                    Colors.red,
                    () => _setTransactionType(false),
                    _getTransactionValue() < 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String label, IconData icon, Color color, VoidCallback onTap, bool isSelected) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setTransactionType(bool isIncome) {
    // Se estiver editando, não alterar o valor automaticamente
    if (widget.recurringTransactionToEdit != null) return;
    
    final currentValue = _getTransactionValue();
    if (currentValue != 0) {
      setState(() {
        _valueController.text = currentValue.abs().toString();
      });
    }
  }

  double _getTransactionValue() {
    final value = double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0;
    return value;
  }

  Widget _buildCategorySelector() {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return CircularProgressIndicator();
        }

        final categories = provider.categories;
        if (categories.isEmpty) {
          return Text('Nenhuma categoria disponível');
        }

        return DropdownButtonFormField<String>(
          value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
          decoration: InputDecoration(
            labelText: 'Categoria',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: categories.map((category) {
            return DropdownMenuItem<String>(
              value: category.name,
              child: Row(
                children: [
                  Text(category.icon ?? '📁'),
                  SizedBox(width: 8),
                  Text(category.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Categoria é obrigatória';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildMemberSelector() {
    return Consumer<MemberProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return CircularProgressIndicator();
        }

        final members = provider.members;
        if (members.isEmpty) {
          return Text('Nenhum membro disponível');
        }

        return DropdownButtonFormField<int>(
          value: _selectedMemberId > 0 ? _selectedMemberId : null,
          decoration: InputDecoration(
            labelText: 'Membro Responsável',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: members.map((member) {
            return DropdownMenuItem<int>(
              value: member.id,
              child: Text(member.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMemberId = value!;
            });
          },
          validator: (value) {
            if (value == null || value == 0) {
              return 'Membro é obrigatório';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildFrequencySelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequência',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _buildFrequencyOption('daily', 'Diário', Icons.calendar_today),
                _buildFrequencyOption('weekly', 'Semanal', Icons.calendar_today),
                _buildFrequencyOption('monthly', 'Mensal', Icons.calendar_today),
                _buildFrequencyOption('yearly', 'Anual', Icons.calendar_today),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyOption(String value, String label, IconData icon) {
    final isSelected = _selectedFrequency == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFrequency = value;
        });
      },
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
    );
  }

  Widget _buildDateSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data de Início',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text(
                DateFormat('dd/MM/yyyy').format(_startDate),
                style: TextStyle(fontSize: 16),
              ),
              trailing: Icon(Icons.edit),
              onTap: () => _selectStartDate(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndDateSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data de Fim (Opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text(
                _endDate != null 
                  ? DateFormat('dd/MM/yyyy').format(_endDate!)
                  : 'Sem data de fim',
                style: TextStyle(fontSize: 16),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endDate != null)
                    IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _endDate = null;
                        });
                      },
                    ),
                  Icon(Icons.edit),
                ],
              ),
              onTap: () => _selectEndDate(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaxOccurrencesSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Número Máximo de Ocorrências (Opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    labelText: 'Quantidade',
                    hintText: 'Ex: 12',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _maxOccurrences = int.tryParse(value);
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Deixe em branco para ilimitado',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final value = double.parse(_valueController.text.replaceAll(',', '.'));
      
      // Determinar o tipo baseado na categoria selecionada
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final category = categoryProvider.categories.firstWhere(
        (cat) => cat.name == _selectedCategory,
        orElse: () => Category(
          name: _selectedCategory,
          type: 'expense',
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      // Aplicar sinal baseado no tipo da categoria
      final finalValue = category.type == 'income' ? value.abs() : -value.abs();

      // Remover criação de objeto não utilizado
      // final recurringTransaction = RecurringTransaction(...);

      final provider = Provider.of<RecurringTransactionProvider>(context, listen: false);
      
      bool success;
      
      if (widget.recurringTransactionToEdit != null) {
        // Atualizar recorrência existente
        final updatedRt = widget.recurringTransactionToEdit!.copyWith(
          frequency: _selectedFrequency,
          category: _selectedCategory,
          value: finalValue,
          associatedMember: Member(
            id: _selectedMemberId,
            name: 'Membro',
            relation: 'Familiar',
            userId: 1,
            createdAt: widget.recurringTransactionToEdit!.createdAt,
            updatedAt: DateTime.now(),
          ),
          startDate: _startDate,
          endDate: _endDate,
          maxOccurrences: _maxOccurrences,
          isActive: _isActive,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          updatedAt: DateTime.now(),
        );
        
        success = await provider.updateRecurringTransaction(updatedRt);
      } else {
        // Criar nova recorrência
        success = await provider.addRecurringTransaction(
          frequency: _selectedFrequency,
          category: _selectedCategory,
          value: finalValue,
          associatedMemberId: _selectedMemberId,
          startDate: _startDate,
          endDate: _endDate,
          maxOccurrences: _maxOccurrences,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );
      }

      if (success) {
        // Mostrar mensagem de sucesso com detalhes
        final action = widget.recurringTransactionToEdit != null ? 'atualizada' : 'criada';
        final tipoValor = finalValue > 0 ? 'Receita' : 'Despesa';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transação recorrente $action com sucesso! ($tipoValor)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
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
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.recurringTransactionToEdit != null 
              ? 'Erro ao atualizar transação recorrente' 
              : 'Erro ao criar transação recorrente'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateHomeData() async {
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      final quickEntryProvider = Provider.of<QuickEntryProvider>(context, listen: false);
      
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

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
