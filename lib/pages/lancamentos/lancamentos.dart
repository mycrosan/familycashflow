import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/rest_service.dart';
import '../lancamentos/adicionar_lancamento.dart';

class Lancamentos extends StatefulWidget {
  @override
  _ListaLancamentosPageState createState() => _ListaLancamentosPageState();
}

class _ListaLancamentosPageState extends State<Lancamentos> {
  final LancamentoService _service = LancamentoService();
  List<dynamic> _lancamentos = [];
  bool _loading = true;
  DateTime _mesAtual = DateTime.now();

  @override
  void initState() {
    super.initState();
    _carregarLancamentos();
  }

  String get _anoMes => DateFormat('yyyy-MM').format(_mesAtual);

  Future<void> _carregarLancamentos() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getMes(_anoMes);
      setState(() {
        _lancamentos = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    }
  }

  void _confirmarExclusao(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirmar exclusão'),
        content: Text('Tem certeza que deseja excluir este lançamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.delete(id);
        _carregarLancamentos();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildItem(dynamic lanc) {
    if (lanc == null || lanc is! Map) return SizedBox.shrink();

    final id = lanc['id'];
    final descricao = lanc['descricao'] ?? 'Sem descrição';
    final valor = lanc['valor'] ?? 0;
    final data = lanc['data'] ?? '';
    final tipo = lanc['tipo'] ?? '';
    final simulado = lanc['simulado'] == true;

    return Card(
      color: simulado ? Colors.grey[100] : null,
      child: ListTile(
        title: Text(descricao),
        subtitle: Text("R\$ ${valor.toString()} - $data ${simulado ? '(recorrente)' : ''}"),
        trailing: simulado
            ? null
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.pushNamed(context, '/editar', arguments: lanc)
                    .then((_) => _carregarLancamentos());
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmarExclusao(id),
            ),
          ],
        ),
      ),
    );
  }

  void _navegarParaCadastro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdicionarLancamento()),
    ).then((_) => _carregarLancamentos());
  }

  void _mudarMes(int incremento) {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + incremento);
    });
    _carregarLancamentos();
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMMM yyyy', 'pt_BR');
    return Scaffold(
      appBar: AppBar(
        title: Text('Lançamentos'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => _mudarMes(-1),
          ),
          Center(child: Text(format.format(_mesAtual))),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () => _mudarMes(1),
          )
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _carregarLancamentos,
        child: _lancamentos.isEmpty
            ? ListView(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Nenhum lançamento encontrado.'),
              ),
            ),
          ],
        )
            : ListView.builder(
          itemCount: _lancamentos.length,
          itemBuilder: (context, index) =>
              _buildItem(_lancamentos[index]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarParaCadastro,
        child: Icon(Icons.add),
      ),
    );
  }
}
