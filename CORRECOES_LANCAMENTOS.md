# Correções - Problema dos Lançamentos sendo registrados como Entradas

## Problema Identificado

Os lançamentos estavam sendo registrados incorretamente como entradas devido a problemas na aplicação dos sinais dos valores nas transações.

## Causa Raiz

O sistema usa dois modelos diferentes para transações:

1. **Transaction** (Sistema novo): Usa valores positivos para receitas e negativos para despesas
2. **Lancamento** (Sistema antigo): Usa campo `tipo` ('entrada' ou 'saida') e sempre valores positivos

## Correções Implementadas

### 1. Página de Adição de Transações (`add_transaction_page.dart`)

**Problema**: A função `_getTransactionValue()` não estava aplicando o sinal correto baseado no tipo de transação selecionado.

**Correção**: 
```dart
String _getTransactionValue() {
  // Remove a máscara e converte para double
  final cleanValue = _valueController.text
      .replaceAll('R\$ ', '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  final value = double.tryParse(cleanValue) ?? 0.0;
  
  // Aplicar sinal baseado no tipo de transação
  final finalValue = _selectedType == TransactionType.expense ? -value.abs() : value.abs();
  return finalValue.toString();
}
```

### 2. Página de Transações Recorrentes (`add_recurring_transaction_page.dart`)

**Problema**: A função `_handleSave()` estava sempre salvando valores positivos, não considerando o tipo da categoria.

**Correção**:
```dart
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
```

### 3. Página de Adição de Lançamentos (`adicionar_lancamento.dart`)

**Problema**: A página não tinha um seletor visual de tipo de lançamento, causando confusão sobre se era entrada ou saída.

**Correção**: Adicionado seletor visual de tipo com botões para "Despesa" e "Receita".

## Verificações Realizadas

### ✅ Páginas que já estavam corretas:

1. **Quick Entry Page** (`quick_entry_page.dart`): Já aplicava sinais corretamente
2. **Quick Entry Provider** (`quick_entry_provider.dart`): Já aplicava sinais corretamente

### ✅ Modelos que já estavam corretos:

1. **Transaction Model**: Já tinha getters `isIncome` e `isExpense` baseados no valor
2. **Lancamento Model**: Já tinha getters `isEntrada` e `isSaida` baseados no tipo

## Como Testar

1. **Criar uma despesa**:
   - Vá para "Adicionar Transação"
   - Selecione "Despesa"
   - Digite um valor (ex: R$ 100,00)
   - Salve
   - Verifique se aparece como despesa (vermelho, valor negativo)

2. **Criar uma receita**:
   - Vá para "Adicionar Transação"
   - Selecione "Receita"
   - Digite um valor (ex: R$ 500,00)
   - Salve
   - Verifique se aparece como receita (verde, valor positivo)

3. **Criar transação recorrente**:
   - Vá para "Adicionar Transação"
   - Ative "Transação Recorrente"
   - Selecione uma categoria de despesa
   - Digite um valor
   - Salve
   - Verifique se a recorrência é criada com sinal correto

## Resultado Esperado

- **Despesas**: Valores negativos, cor vermelha, ícone trending_down
- **Receitas**: Valores positivos, cor verde, ícone trending_up
- **Saldo**: Calculado corretamente (receitas - despesas)

## Arquivos Modificados

1. `lib/pages/transactions/add_transaction_page.dart`
2. `lib/pages/recurring/add_recurring_transaction_page.dart`
3. `lib/pages/lancamentos/adicionar_lancamento.dart`

## Observações

- O sistema agora está consistente entre as diferentes páginas
- Os sinais são aplicados corretamente baseados no tipo de transação
- A interface está mais clara com seletores visuais de tipo
- O sistema mantém compatibilidade com ambos os modelos (Transaction e Lancamento)
