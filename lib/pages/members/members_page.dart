import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/member_provider.dart';
import '../../widgets/custom_button.dart';

class MembersPage extends StatefulWidget {
  @override
  _MembersPageState createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemberProvider>().loadMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Membros da Família'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddMemberDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<MemberProvider>(
        builder: (context, memberProvider, child) {
          if (memberProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (memberProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Erro: ${memberProvider.error}',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => memberProvider.loadMembers(),
                    child: Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (memberProvider.members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum membro cadastrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Adicione os membros da sua família para começar',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  CustomButton(
                    text: 'Adicionar Primeiro Membro',
                    onPressed: () {
                      _showAddMemberDialog(context);
                    },
                    icon: Icons.add,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: memberProvider.members.length,
            itemBuilder: (context, index) {
              final member = memberProvider.members[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  title: Text(
                    member.name,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(member.relation),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      _handleMemberAction(value, member);
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
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar Membro'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nome',
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
              TextFormField(
                controller: relationController,
                decoration: InputDecoration(
                  labelText: 'Relação',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Pai, Mãe, Filho, Filha...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Relação é obrigatória';
                  }
                  return null;
                },
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
                final memberProvider = context.read<MemberProvider>();
                final success = await memberProvider.addMember(
                  nameController.text.trim(),
                  relationController.text.trim(),
                  null, // profilePicture
                );

                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Membro adicionado com sucesso!'),
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

  void _handleMemberAction(String action, dynamic member) {
    switch (action) {
      case 'edit':
        // TODO: Implementar edição de membro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edição de membro em desenvolvimento')),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(member);
        break;
    }
  }

  void _showDeleteConfirmation(dynamic member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final memberProvider = context.read<MemberProvider>();
              final success = await memberProvider.deleteMember(member.id);
              
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Membro excluído com sucesso!'),
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
