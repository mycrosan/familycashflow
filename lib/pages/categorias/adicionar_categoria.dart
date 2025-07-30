import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdicionarLancamento extends StatefulWidget {
  @override
  _AdicionarLancamentoState createState() => _AdicionarLancamentoState();
}

class _AdicionarLancamentoState extends State<AdicionarLancamento> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();

  String _tipo = 'saida';
  int _categoriaId = 2; // exemplo fixo
  int _responsavelId = 1; // exemplo fixo
  bool _parcelado = false;
  int _quantidadeParcelas = 1;
  List<Map<String, dynamic>> _parcelas = [];

  @override
  void initState() {
    super.initState();
    _dataController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  void _gerarParcelas() {
    _parcelas.clear();
    double total = double.tryParse(_valorController.text) ?? 0;
    double valorParcela = total / _quantidadeParcelas;

    DateTime dataBase = DateTime.parse(_dataController.text);
    for (int i = 0; i < _quantidadeParcelas; i++) {
      _parcelas.add({
        'numero': i + 1,
        'valor': double.parse(valorParcela.toStringAsFixed(2)),
        'vencimento': DateFormat('yyyy-MM-dd').format(
          DateTime(dataBase.year, dataBase.month + i, dataBase.day),
        ),
      });
    }
    setState(() {});
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final lancamento = {
        "descricao": _descricaoController.text,
        "valor": double.tryParse(_valorController.text) ?? 0,
        "data": _dataController.text,
        "tipo": _tipo,
        "categoria_id": _categoriaId,
        "responsavel_id": _responsavelId,
        "parcelado": _parcelado,
        "parcelas": _parcelado ? _parcelas : [],
      };

      print(lancamento); // Aqui você chama a API POST
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Novo Lançamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(labelText: 'Descrição'),
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: _valorController,
                decoration: InputDecoration(labelText: 'Valor total'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: _dataController,
                decoration: InputDecoration(labelText: 'Data (YYYY-MM-DD)'),
                readOnly: true,
                onTap: () async {
                  final data = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (data != null) {
                    _dataController.text = DateFormat('yyyy-MM-dd').format(data);
                  }
                },
              ),
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: InputDecoration(labelText: 'Tipo'),
                onChanged: (v) => setState(() => _tipo = v!),
                items: ['entrada', 'saida']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
              ),
              DropdownButtonFormField<int>(
                value: _categoriaId,
                decoration: InputDecoration(labelText: 'Categoria'),
                onChanged: (v) => setState(() => _categoriaId = v!),
                items: [
                  DropdownMenuItem(value: 1, child: Text('Alimentação')),
                  DropdownMenuItem(value: 2, child: Text('Tecnologia')),
                ],
              ),
              DropdownButtonFormField<int>(
                value: _responsavelId,
                decoration: InputDecoration(labelText: 'Responsável'),
                onChanged: (v) => setState(() => _responsavelId = v!),
                items: [
                  DropdownMenuItem(value: 1, child: Text('Sandy')),
                  DropdownMenuItem(value: 2, child: Text('Thais')),
                ],
              ),
              SwitchListTile(
                title: Text('Parcelado?'),
                value: _parcelado,
                onChanged: (v) => setState(() {
                  _parcelado = v;
                  if (!_parcelado) _parcelas.clear();
                }),
              ),
              if (_parcelado) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _quantidadeParcelas.toString(),
                        decoration: InputDecoration(labelText: 'Qtd. Parcelas'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _quantidadeParcelas = int.tryParse(v) ?? 1,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _gerarParcelas,
                      child: Text('Gerar Parcelas'),
                    ),
                  ],
                ),
                if (_parcelas.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _parcelas.map((p) {
                      return ListTile(
                        title: Text('Parcela ${p['numero']} - R\$ ${p['valor']}'),
                        subtitle: Text('Vencimento: ${p['vencimento']}'),
                      );
                    }).toList(),
                  ),
              ],
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _salvar,
                child: Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
