# Fluxo Família - Sistema de Gerenciamento Financeiro Familiar

## Descrição

Fluxo Família é um aplicativo móvel para gerenciamento financeiro pessoal e familiar. Ele rastreia receitas e despesas por membro da família, suporta transações recorrentes, relatórios mensais, entrada rápida e funciona offline com sincronização opcional com API remota.

## Funcionalidades Implementadas

### ✅ Sistema de Usuários e Autenticação
- **Login/Registro**: Sistema completo de autenticação com hash de senha
- **Perfil de Usuário**: Gerenciamento de informações pessoais
- **Segurança**: Senhas criptografadas com SHA-256

### ✅ Gestão de Membros da Família
- **Adicionar/Editar/Excluir** membros da família
- **Relacionamentos**: Definição de relações (Pai, Mãe, Filho, etc.)
- **Fotos de Perfil**: Suporte opcional para imagens de perfil

### ✅ Sistema de Categorias
- **Categorias Padrão**: Categorias pré-definidas para receitas e despesas
- **Personalização**: Adicionar, editar e excluir categorias personalizadas
- **Ícones e Cores**: Suporte para emojis e cores personalizadas
- **Filtros**: Separação entre categorias de receita e despesa

### ✅ Gestão de Transações
- **Receitas e Despesas**: Sistema completo de transações financeiras
- **Categorização**: Associação com categorias e membros responsáveis
- **Observações**: Campo para notas adicionais
- **Imagens de Recibo**: Suporte para anexar imagens de recibos
- **Transações Recorrentes**: Sistema para pagamentos recorrentes

### ✅ Transações Recorrentes
- **Frequências**: Diária, semanal, mensal e anual
- **Configuração**: Data de início, fim e número máximo de ocorrências
- **Ativação/Desativação**: Controle de status das transações recorrentes
- **Geração Automática**: Criação automática de transações baseadas na recorrência

### ✅ Entrada Rápida
- **Interface Otimizada**: Formulário simplificado para transações rápidas
- **Seleção Inteligente**: Categorias e membros baseados no tipo de transação
- **Validação**: Verificação de campos obrigatórios
- **Feedback Visual**: Confirmação de sucesso e tratamento de erros
- **Edição**: Suporte para editar transações existentes

### ✅ Transações Mensais
- **Visualização por Mês**: Navegação entre meses com transações organizadas
- **Resumo Financeiro**: Total de receitas, despesas e saldo mensal
- **Filtros Avançados**: Busca por texto, filtro por tipo (receita/despesa)
- **Gestão Completa**: Adicionar, editar e excluir transações
- **Transações Recorrentes**: Criação e gerenciamento de recorrências
- **Interface Intuitiva**: Cards organizados com informações detalhadas

### ✅ Relatórios e Análises
- **Resumo Mensal**: Total de receitas, despesas e saldo
- **Análise por Categoria**: Top categorias de receita e despesa
- **Análise por Membro**: Gastos e receitas por membro da família
- **Relatórios Personalizados**: Filtros por período, categoria e membro
- **Relatórios Anuais**: Visão anual com dados mensais
- **Formatação**: Valores monetários em Real (R$) e percentuais

### ✅ Sistema de Notificações
- **Transações Recorrentes**: Lembretes de pagamentos recorrentes
- **Resumo Mensal**: Notificações de relatório mensal
- **Lembretes de Pagamento**: Alertas para vencimentos
- **Configuração**: Controle de permissões e tipos de notificação

### ✅ Sincronização Offline-First
- **Armazenamento Local**: Banco de dados SQLite para funcionamento offline
- **Sincronização Bidirecional**: Envio e recebimento de dados da API
- **Resolução de Conflitos**: Sistema para lidar com mudanças simultâneas
- **Log de Sincronização**: Rastreamento de ações pendentes
- **Verificação de Conectividade**: Detecção automática de status online

### ✅ Banco de Dados Local
- **SQLite**: Banco de dados embutido no dispositivo
- **Estrutura Relacional**: Tabelas para usuários, membros, categorias e transações
- **Índices**: Otimização para consultas frequentes
- **Migrações**: Sistema para atualizações futuras do banco

## Arquitetura Técnica

### Providers (Gerenciamento de Estado)
- **AuthProvider**: Autenticação e usuários
- **MemberProvider**: Gestão de membros da família
- **CategoryProvider**: Sistema de categorias
- **TransactionProvider**: Transações financeiras
- **RecurringTransactionProvider**: Transações recorrentes
- **ReportProvider**: Relatórios e análises
- **QuickEntryProvider**: Entrada rápida de transações
- **NotificationProvider**: Sistema de notificações
- **SyncProvider**: Sincronização com API

### Serviços
- **DatabaseService**: Gerenciamento do banco de dados local
- **ApiService**: Comunicação com API remota
- **NotificationService**: Sistema de notificações locais

### Modelos de Dados
- **User**: Usuários do sistema
- **Member**: Membros da família
- **Category**: Categorias de transações
- **Transaction**: Transações financeiras
- **RecurringTransaction**: Transações recorrentes

## Tecnologias Utilizadas

- **Flutter 3**: Framework de desenvolvimento
- **Dart**: Linguagem de programação
- **Provider**: Gerenciamento de estado
- **SQLite**: Banco de dados local
- **HTTP/Dio**: Comunicação com API
- **Local Notifications**: Notificações locais
- **Image Picker**: Seleção de imagens
- **Intl**: Internacionalização e formatação

## Estrutura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada da aplicação
├── models/                   # Modelos de dados
├── providers/                # Gerenciadores de estado
├── services/                 # Serviços (banco, API, notificações)
├── pages/                    # Páginas da aplicação
│   ├── auth/                # Autenticação
│   ├── home/                # Página principal
│   ├── quick_entry/         # Entrada rápida
│   ├── transactions/        # Transações mensais
│   ├── recurring/           # Transações recorrentes
│   ├── reports/             # Relatórios
│   ├── members/             # Gestão de membros
│   └── categories/          # Gestão de categorias
└── widgets/                  # Widgets reutilizáveis
```

## Navegação da Aplicação

A aplicação possui 5 abas principais:

1. **Início**: Dashboard com resumo financeiro e transações recentes
2. **Transações**: Visualização mensal completa com gestão de transações
3. **Relatórios**: Análises financeiras e gráficos
4. **Membros**: Gestão de membros da família
5. **Categorias**: Sistema de categorias para transações

## Como Executar

1. **Instalar Dependências**:
   ```bash
   flutter pub get
   ```

2. **Executar o App**:
   ```bash
   flutter run
   ```

3. **Primeira Execução**:
   - O app criará automaticamente o banco de dados local
   - Categorias padrão serão criadas automaticamente
   - Registre-se ou faça login para começar

## Funcionalidades em Desenvolvimento

- [ ] Scanner de recibos com OCR
- [ ] Exportação de relatórios (PDF/CSV)
- [ ] Gráficos interativos
- [ ] Backup e restauração de dados
- [ ] Temas personalizáveis
- [ ] Múltiplas moedas
- [ ] Metas financeiras
- [ ] Orçamentos mensais

## Contribuição

Este projeto está em desenvolvimento ativo. Contribuições são bem-vindas!

## Licença

Este projeto é privado e não possui licença pública.
