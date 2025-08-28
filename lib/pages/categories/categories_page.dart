import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/custom_button.dart';

class CategoriesPage extends StatefulWidget {
  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Categorias'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddCategoryDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterChip('all', 'Todas'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('income', 'Receitas'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('expense', 'Despesas'),
                ),
              ],
            ),
          ),

          // Lista de categorias
          Expanded(
            child: Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                if (categoryProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                if (categoryProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Erro: ${categoryProvider.error}',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => categoryProvider.loadCategories(),
                          child: Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  );
                }

                List<dynamic> filteredCategories;
                switch (_selectedType) {
                  case 'income':
                    filteredCategories = categoryProvider.incomeCategories;
                    break;
                  case 'expense':
                    filteredCategories = categoryProvider.expenseCategories;
                    break;
                  default:
                    filteredCategories = categoryProvider.categories;
                }

                if (filteredCategories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Nenhuma categoria encontrada',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Adicione categorias para organizar suas transações',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        CustomButton(
                          text: 'Adicionar Primeira Categoria',
                          onPressed: () {
                            _showAddCategoryDialog(context);
                          },
                          icon: Icons.add,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, index) {
                    final category = filteredCategories[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getCategoryColor(category.tipo).withOpacity(0.1),
                          child: Text(
                            category.icone ?? '📁',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        title: Text(
                          category.nome,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          _getCategoryTypeLabel(category.tipo),
                          style: TextStyle(
                            color: _getCategoryColor(category.tipo),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            _handleCategoryAction(value, category);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Excluir', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    final isSelected = _selectedType == type;
    final color = _getCategoryColor(type);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Color _getCategoryColor(String type) {
    switch (type) {
      case 'income':
        return Colors.green;
      case 'expense':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryTypeLabel(String type) {
    switch (type) {
      case 'income':
        return 'Receita';
      case 'expense':
        return 'Despesa';
      default:
        return 'Desconhecido';
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final iconController = TextEditingController();
    final colorController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedType = 'expense';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar Categoria'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nome da Categoria',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'expense', child: Text('Despesa')),
                  DropdownMenuItem(value: 'income', child: Text('Receita')),
                ],
                onChanged: (value) {
                  selectedType = value!;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: iconController,
                decoration: InputDecoration(
                  labelText: 'Ícone (emoji)',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 🍽️, 🚗, 💰',
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: colorController,
                decoration: InputDecoration(
                  labelText: 'Cor (hex)',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: #F44336',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final categoryProvider = context.read<CategoryProvider>();
                final success = await categoryProvider.addCategory(
                  nameController.text.trim(),
                  selectedType,
                  iconController.text.trim().isEmpty ? null : iconController.text.trim(),
                  colorController.text.trim().isEmpty ? null : colorController.text.trim(),
                );

                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Categoria adicionada com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _handleCategoryAction(String action, dynamic category) {
    switch (action) {
      case 'edit':
        // TODO: Implementar edição de categoria
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edição de categoria em desenvolvimento')),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(category);
        break;
    }
  }

  void _showDeleteConfirmation(dynamic category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir a categoria "${category.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final categoryProvider = context.read<CategoryProvider>();
              final success = await categoryProvider.deleteCategory(category.id);
              
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Categoria excluída com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
