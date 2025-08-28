import 'package:flutter/foundation.dart';
import 'package:fluxo_caixa_familiar/models/lancamento.dart';
import 'package:fluxo_caixa_familiar/services/api_service.dart';

class LancamentoProvider with ChangeNotifier {
  List<Lancamento> _lancamentos = [];
  List<Lancamento> _lancamentosFiltrados = [];
  bool _isLoading = false;
  String _error = '';
  String _mesAtual = '';
  
  // Getters
  List<Lancamento> get lancamentos => _lancamentos;
  List<Lancamento> get lancamentosFiltrados => _lancamentosFiltrados;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get mesAtual => _mesAtual;
  
  // Estatísticas
  double get totalEntradas => _lancamentos
    .where((l) => l.isEntrada)
    .fold(0.0, (sum, l) => sum + l.valor);
  
  double get totalSaidas => _lancamentos
    .where((l) => l.isSaida)
    .fold(0.0, (sum, l) => sum + l.valor);
  
  double get saldo => totalEntradas - totalSaidas;
  
  int get totalLancamentos => _lancamentos.length;
  
  // Lançamentos do mês atual
  List<Lancamento> get lancamentosMesAtual {
    if (_mesAtual.isEmpty) return [];
    
    final ano = int.parse(_mesAtual.split('-')[0]);
    final mes = int.parse(_mesAtual.split('-')[1]);
    
    return _lancamentos.where((l) {
      return l.data.year == ano && l.data.month == mes;
    }).toList();
  }
  
  // Carregar lançamentos por mês
  Future<void> carregarLancamentosPorMes(String anoMes) async {
    try {
      _isLoading = true;
      _error = '';
      _mesAtual = anoMes;
      notifyListeners();
      
      _lancamentos = await ApiService.getLancamentosPorMes(anoMes);
      _aplicarFiltros();
      
    } catch (e) {
      _error = 'Erro ao carregar lançamentos: $e';
      debugPrint('Erro ao carregar lançamentos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Carregar lançamentos do mês atual
  Future<void> carregarLancamentosMesAtual() async {
    final agora = DateTime.now();
    final anoMes = '${agora.year}-${agora.month.toString().padLeft(2, '0')}';
    await carregarLancamentosPorMes(anoMes);
  }
  
  // Adicionar novo lançamento
  Future<void> adicionarLancamento(Lancamento lancamento) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();
      
      final novoLancamento = await ApiService.criarLancamento(lancamento.toJson());
      
      _lancamentos.add(novoLancamento);
      _aplicarFiltros();
      
    } catch (e) {
      _error = 'Erro ao adicionar lançamento: $e';
      debugPrint('Erro ao adicionar lançamento: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Atualizar lançamento
  Future<void> atualizarLancamento(Lancamento lancamento) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();
      
      final lancamentoAtualizado = await ApiService.atualizarLancamento(
        lancamento.id!,
        lancamento.toJson(),
      );
      
      final index = _lancamentos.indexWhere((l) => l.id == lancamento.id);
      if (index != -1) {
        _lancamentos[index] = lancamentoAtualizado;
        _aplicarFiltros();
      }
      
    } catch (e) {
      _error = 'Erro ao atualizar lançamento: $e';
      debugPrint('Erro ao atualizar lançamento: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Deletar lançamento
  Future<void> deletarLancamento(int id) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();
      
      await ApiService.deletarLancamento(id);
      
      _lancamentos.removeWhere((l) => l.id == id);
      _aplicarFiltros();
      
    } catch (e) {
      _error = 'Erro ao deletar lançamento: $e';
      debugPrint('Erro ao deletar lançamento: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Buscar lançamento por ID
  Lancamento? buscarLancamentoPorId(int id) {
    try {
      return _lancamentos.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Filtrar lançamentos
  void filtrarLancamentos({
    String? tipo,
    int? categoriaId,
    int? responsavelId,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? termoBusca,
  }) {
    _lancamentosFiltrados = _lancamentos.where((lancamento) {
      // Filtro por tipo
      if (tipo != null && lancamento.tipo != tipo) return false;
      
      // Filtro por categoria
      if (categoriaId != null && lancamento.categoriaId != categoriaId) return false;
      
      // Filtro por responsável
      if (responsavelId != null && lancamento.responsavelId != responsavelId) return false;
      
      // Filtro por data
      if (dataInicio != null && lancamento.data.isBefore(dataInicio)) return false;
      if (dataFim != null && lancamento.data.isAfter(dataFim)) return false;
      
      // Filtro por termo de busca
      if (termoBusca != null && termoBusca.isNotEmpty) {
        final termo = termoBusca.toLowerCase();
        if (!lancamento.descricao.toLowerCase().contains(termo) &&
            !(lancamento.observacoes?.toLowerCase().contains(termo) ?? false)) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    notifyListeners();
  }
  
  // Limpar filtros
  void limparFiltros() {
    _lancamentosFiltrados = List.from(_lancamentos);
    notifyListeners();
  }
  
  // Aplicar filtros padrão
  void _aplicarFiltros() {
    _lancamentosFiltrados = List.from(_lancamentos);
  }
  
  // Ordenar lançamentos
  void ordenarLancamentos({String? campo, bool? crescente}) {
    final crescenteValue = crescente ?? true;
    
    switch (campo) {
      case 'data':
        _lancamentosFiltrados.sort((a, b) => crescenteValue 
          ? a.data.compareTo(b.data)
          : b.data.compareTo(a.data));
        break;
      case 'valor':
        _lancamentosFiltrados.sort((a, b) => crescenteValue 
          ? a.valor.compareTo(b.valor)
          : b.valor.compareTo(a.valor));
        break;
      case 'descricao':
        _lancamentosFiltrados.sort((a, b) => crescenteValue 
          ? a.descricao.compareTo(b.descricao)
          : b.descricao.compareTo(a.descricao));
        break;
      default:
        // Ordenação padrão por data (mais recente primeiro)
        _lancamentosFiltrados.sort((a, b) => b.data.compareTo(a.data));
    }
    
    notifyListeners();
  }
  
  // Agrupar lançamentos por data
  Map<String, List<Lancamento>> agruparPorData() {
    final agrupados = <String, List<Lancamento>>{};
    
    for (final lancamento in _lancamentosFiltrados) {
      final dataStr = lancamento.dataFormatada;
      if (!agrupados.containsKey(dataStr)) {
        agrupados[dataStr] = [];
      }
      agrupados[dataStr]!.add(lancamento);
    }
    
    return agrupados;
  }
  
  // Agrupar lançamentos por categoria
  Map<String, List<Lancamento>> agruparPorCategoria() {
    final agrupados = <String, List<Lancamento>>{};
    
    for (final lancamento in _lancamentosFiltrados) {
      final categoriaNome = lancamento.categoria?.nome ?? 'Sem categoria';
      if (!agrupados.containsKey(categoriaNome)) {
        agrupados[categoriaNome] = [];
      }
      agrupados[categoriaNome]!.add(lancamento);
    }
    
    return agrupados;
  }
  
  // Limpar erro
  void limparErro() {
    _error = '';
    notifyListeners();
  }
  
  // Refresh dos dados
  Future<void> refresh() async {
    if (_mesAtual.isNotEmpty) {
      await carregarLancamentosPorMes(_mesAtual);
    }
  }
}

