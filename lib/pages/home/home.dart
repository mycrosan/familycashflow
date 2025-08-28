import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fluxo_caixa_familiar/providers/lancamento_provider.dart';
import 'package:fluxo_caixa_familiar/models/lancamento.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    // Carregar dados do mês atual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LancamentoProvider>().carregarLancamentosMesAtual();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fluxo Família'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              context.read<LancamentoProvider>().refresh();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.indigo.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 35,
                      color: Colors.indigo,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Fluxo Família',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Controle Financeiro',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.list_alt, color: Colors.indigo),
              title: Text('Lançamentos'),
              onTap: () => Navigator.pushNamed(context, '/lancamentos'),
            ),
            ListTile(
              leading: Icon(Icons.category, color: Colors.indigo),
              title: Text('Categorias'),
              onTap: () => Navigator.pushNamed(context, '/categorias'),
            ),
            ListTile(
              leading: Icon(Icons.people, color: Colors.indigo),
              title: Text('Responsáveis'),
              onTap: () => Navigator.pushNamed(context, '/responsaveis'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.analytics, color: Colors.indigo),
              title: Text('Relatórios'),
              onTap: () {
                // TODO: Implementar página de relatórios
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Relatórios em desenvolvimento')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.sync, color: Colors.indigo),
              title: Text('Sincronizar'),
              onTap: () {
                // TODO: Implementar sincronização
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sincronização em desenvolvimento')),
                );
              },
            ),
          ],
        ),
      ),
      body: Consumer<LancamentoProvider>(
        builder: (context, lancamentoProvider, child) {
          if (lancamentoProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (lancamentoProvider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Erro ao carregar dados',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    lancamentoProvider.error,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => lancamentoProvider.refresh(),
                    child: Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => lancamentoProvider.refresh(),
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho com mês atual
                  _buildMonthHeader(),
                  SizedBox(height: 24),
                  
                  // Cards de estatísticas
                  _buildStatisticsCards(lancamentoProvider),
                  SizedBox(height: 24),
                  
                  // Lista de lançamentos recentes
                  _buildRecentTransactions(lancamentoProvider),
                  SizedBox(height: 24),
                  
                  // Ações rápidas
                  _buildQuickActions(),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/lancamentos'),
        icon: Icon(Icons.add),
        label: Text('Novo Lançamento'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildMonthHeader() {
    final agora = DateTime.now();
    final mesAtual = DateFormat('MMMM yyyy', 'pt_BR').format(agora);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 40,
              color: Colors.indigo,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mês Atual',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    mesAtual.toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios),
              onPressed: () {
                // TODO: Implementar seletor de mês
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Seletor de mês em desenvolvimento')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(LancamentoProvider provider) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
      decimalDigits: 2,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Entradas',
                formatter.format(provider.totalEntradas),
                Icons.trending_up,
                Colors.green,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Saídas',
                formatter.format(provider.totalSaidas),
                Icons.trending_down,
                Colors.red,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildStatCard(
          'Saldo',
          formatter.format(provider.saldo),
          Icons.account_balance_wallet,
          provider.saldo >= 0 ? Colors.indigo : Colors.orange,
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isLarge = false}) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isLarge ? 24 : 20),
        child: Column(
          children: [
            Icon(
              icon,
              size: isLarge ? 48 : 32,
              color: color,
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: isLarge ? 16 : 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isLarge ? 24 : 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(LancamentoProvider provider) {
    final lancamentosRecentes = provider.lancamentosMesAtual
        .take(5)
        .toList();

    if (lancamentosRecentes.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long,
                size: 48,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'Nenhum lançamento este mês',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Adicione seu primeiro lançamento para começar',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lançamentos Recentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/lancamentos'),
              child: Text('Ver Todos'),
            ),
          ],
        ),
        ...lancamentosRecentes.map((lancamento) => _buildTransactionTile(lancamento)),
      ],
    );
  }

  Widget _buildTransactionTile(Lancamento lancamento) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: lancamento.cor.withOpacity(0.1),
          child: Icon(
            lancamento.icone,
            color: lancamento.cor,
          ),
        ),
        title: Text(
          lancamento.descricao,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${lancamento.dataFormatada} • ${lancamento.categoria?.nome ?? 'Sem categoria'}',
          style: TextStyle(fontSize: 12),
        ),
        trailing: Text(
          lancamento.valorFormatado,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: lancamento.cor,
            fontSize: 16,
          ),
        ),
        onTap: () {
          // TODO: Implementar edição de lançamento
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Edição em desenvolvimento')),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Entrada Rápida',
                Icons.add_circle_outline,
                Colors.green,
                () {
                  // TODO: Implementar entrada rápida
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Entrada rápida em desenvolvimento')),
                  );
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                'Saída Rápida',
                Icons.remove_circle_outline,
                Colors.red,
                () {
                  // TODO: Implementar saída rápida
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saída rápida em desenvolvimento')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
