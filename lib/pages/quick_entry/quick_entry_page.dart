import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quick_entry_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/report_provider.dart';
import '../../models/category.dart';
import '../../models/member.dart';
import '../../models/transaction.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'package:intl/intl.dart';

class QuickEntryPage extends StatefulWidget {
  final Transaction? transactionToEdit;
  
  const QuickEntryPage({Key? key, this.transactionToEdit}) : super(key: key);
  
  @override
  _QuickEntryPageState createState() => _QuickEntryPageState();
}

class _QuickEntryPageState extends State<QuickEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = 'expense';
  String? _selectedCategory;
  int? _selectedMemberId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _updateHomeData() async {
    try {
      final transactionProvider = context.read<TransactionProvider>();
      final reportProvider = context.read<ReportProvider>();
      final quickEntryProvider = context.read<QuickEntryProvider>();
      
      // Atualizar dados em paralelo
      await Future.wait([
        transactionProvider.loadAllTransactions(), // Carregar todas as transações
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

  Future<void> _loadData() async {
    final categoryProvider = context.read<CategoryProvider>();
    final memberProvider = context.read<MemberProvider>();
    
    await Future.wait([
      categoryProvider.loadCategories(),
      memberProvider.loadMembers(),
    ]);

    // Selecionar primeira categoria e membro por padrão (apenas se não estiver editando)
    if (widget.transactionToEdit == null) {
      if (categoryProvider.categories.isNotEmpty) {
        _selectedCategory = categoryProvider.categories.first.name;
      }
      if (memberProvider.members.isNotEmpty) {
        _selectedMemberId = memberProvider.members.first.id;
      }
    } else {
      // Se estiver editando, preencher os campos
      _loadTransactionData();
    }
  }

  void _loadTransactionData() {
    final transaction = widget.transactionToEdit!;
    
    setState(() {
      _selectedType = transaction.value > 0 ? 'income' : 'expense';
      _valueController.text = transaction.value.abs().toString();
      _selectedCategory = transaction.category;
      _selectedMemberId = transaction.associatedMember.id!;
      _notesController.text = transaction.notes ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transactionToEdit != null ? 'Editar Transação' : 'Entrada Rápida'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tipo de transação
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo de Transação',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeButton(
                              'expense',
                              'Despesa',
                              Icons.remove_circle_outline,
                              Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTypeButton(
                              'income',
                              'Receita',
                              Icons.add_circle_outline,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Valor
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valor',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _valueController,
                        labelText: 'Valor',
                        hintText: '0,00',
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Valor é obrigatório';
                          }
                          final doubleValue = double.tryParse(value.replaceAll(',', '.'));
                          if (doubleValue == null || doubleValue <= 0) {
                            return 'Valor deve ser um número positivo';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Categoria
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  final categories = _selectedType == 'income' 
                    ? categoryProvider.incomeCategories 
                    : categoryProvider.expenseCategories;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categoria',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (categories.isNotEmpty)
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
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
                                      const SizedBox(width: 8),
                                      Text(category.name),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Categoria é obrigatória';
                                }
                                return null;
                              },
                            )
                          else
                            Text('Nenhuma categoria disponível', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Membro responsável
              Consumer<MemberProvider>(
                builder: (context, memberProvider, child) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Membro Responsável',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (memberProvider.members.isNotEmpty)
                            DropdownButtonFormField<int>(
                              value: _selectedMemberId,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              items: memberProvider.members.map((member) {
                                return DropdownMenuItem<int>(
                                  value: member.id,
                                  child: Text(member.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedMemberId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Membro é obrigatório';
                                }
                                return null;
                              },
                            )
                          else
                            Text('Nenhum membro disponível', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Observações
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Observações (opcional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _notesController,
                        labelText: 'Observações',
                        hintText: 'Adicione uma observação...',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botão de salvar
              Consumer<QuickEntryProvider>(
                builder: (context, quickEntryProvider, child) {
                  return CustomButton(
                    text: widget.transactionToEdit != null ? 'Atualizar Transação' : 'Salvar Transação',
                    onPressed: _isLoading ? null : _handleSave,
                    isLoading: _isLoading || quickEntryProvider.isLoading,
                    icon: widget.transactionToEdit != null ? Icons.edit : Icons.save,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Mensagem de erro
              Consumer<QuickEntryProvider>(
                builder: (context, quickEntryProvider, child) {
                  if (quickEntryProvider.error != null) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        quickEntryProvider.error!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedCategory = null; // Reset categoria ao mudar tipo
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedMemberId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final quickEntryProvider = context.read<QuickEntryProvider>();
      final value = double.parse(_valueController.text.replaceAll(',', '.'));
      
      bool success;
      
      if (widget.transactionToEdit != null) {
        // Atualizar transação existente
        final updatedTransaction = widget.transactionToEdit!.copyWith(
          value: _selectedType == 'income' ? value : -value,
          category: _selectedCategory!,
          associatedMember: Member(
            id: _selectedMemberId!,
            name: 'Membro',
            relation: 'Familiar',
            userId: 1,
            createdAt: widget.transactionToEdit!.createdAt,
            updatedAt: DateTime.now(),
          ),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          updatedAt: DateTime.now(),
        );
        
        final transactionProvider = context.read<TransactionProvider>();
        success = await transactionProvider.updateTransaction(updatedTransaction);
      } else {
        // Criar nova transação
        if (_selectedType == 'income') {
          success = await quickEntryProvider.addQuickIncome(
            value: value,
            category: _selectedCategory!,
            memberId: _selectedMemberId!,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
        } else {
          success = await quickEntryProvider.addQuickExpense(
            value: value,
            category: _selectedCategory!,
            memberId: _selectedMemberId!,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
        }
      }

      if (success) {
        // Mostrar mensagem de sucesso com detalhes
        final action = widget.transactionToEdit != null ? 'atualizada' : 'salva';
        final tipoValor = _selectedType == 'income' ? 'Receita' : 'Despesa';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transação $action com sucesso! ($tipoValor)'),
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
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar transação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
