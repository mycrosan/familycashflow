// Tela: Adicionar Lançamento com suporte a recorrência
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/rest_service.dart';

class AdicionarLancamento extends StatefulWidget {
  final Map<String, dynamic>? lancamento;
  const AdicionarLancamento({super.key, this.lancamento});

  @override
  State<AdicionarLancamento> createState() => _AdicionarLancamentoState();
}

class _AdicionarLancamentoState extends State<AdicionarLancamento> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _dataController = TextEditingController();
  final _obsController = TextEditingController();

  String _tipo = 'saida';
  int _categoriaId = 1; // pode vir de um dropdown dinâmico
  int _responsavelId = 1;
  bool _recorrente = false;

  // Recorrência
  String _tipoRecorrencia = 'mensal';
  int _qtd = 6;
  String? _dataInicio;

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    _dataController.text = DateFormat('yyyy-MM-dd').format(hoje);
    _dataInicio = _dataController.text;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final body = {
        "descricao": _descricaoController.text,
        "valor": double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0.0,
        "data": _dataController.text,
        "tipo": _tipo,
        "categoria_id": _categoriaId,
        "responsavel_id": _responsavelId,
        "observacoes": _obsController.text,
        "recorrente": _recorrente,
        if (_recorrente)
          "recorrencia": {
            "tipo": _tipoRecorrencia,
            "data_inicio": _dataInicio,
            "quantidade_ocorrencias": _qtd,
            "intervalo": 1,
            "observacoes": "Recorrência gerada via app"
          }
      };

      // final response = await LancamentoService().post(body);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lançamento salvo com sucesso.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: \$e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Adicionar Lançamento')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descricaoController,
              decoration: InputDecoration(labelText: 'Descrição'),
              validator: (v) => v == null || v.isEmpty ? 'Informe a descrição' : null,
            ),
            TextFormField(
              controller: _valorController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Valor'),
              validator: (v) => v == null || v.isEmpty ? 'Informe o valor' : null,
            ),
            TextFormField(
              controller: _dataController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Data'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  final format = DateFormat('yyyy-MM-dd');
                  setState(() {
                    _dataController.text = format.format(picked);
                    _dataInicio = _dataController.text;
                  });
                }
              },
            ),
            TextFormField(
              controller: _obsController,
              decoration: InputDecoration(labelText: 'Observações'),
              maxLines: 2,
            ),
            SwitchListTile(
              value: _recorrente,
              onChanged: (v) => setState(() => _recorrente = v),
              title: Text("Lançamento recorrente?"),
            ),
            if (_recorrente) ...[
              DropdownButtonFormField<String>(
                value: _tipoRecorrencia,
                onChanged: (v) => setState(() => _tipoRecorrencia = v!),
                items: ['mensal', 'anual', 'semanal', 'diario']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                decoration: InputDecoration(labelText: 'Tipo de recorrência'),
              ),
              TextFormField(
                initialValue: _qtd.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Qtd. Ocorrências'),
                onChanged: (v) => _qtd = int.tryParse(v) ?? 1,
              ),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvar,
              child: Text('Salvar'),
            )
          ],
        ),
      ),
    );
  }
}
