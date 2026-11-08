# Recorrência editável e padrão para despesas fixas

O formulário bloqueava os controles de repetição ao editar. Agora contas únicas podem virar recorrentes e o intervalo de contas recorrentes pode ser alterado. Novos lançamentos na categoria de despesas fixas sugerem repetição mensal; a escolha de parcelamento permanece explícita e mantém seu total.

A RPC autenticada e transacional preserva contas pagas e cobranças existentes, usa bloqueio de série e verificação de versão e reaproveita as próximas pendentes antes de criar datas adicionais. Aumentar o intervalo mantém todas as pendentes e pode estender o calendário além da janela mínima de 24 meses. Converter em única desassocia somente a cobrança selecionada, com confirmação de que as outras continuam.

Validação: 37 testes Node, Chromium em 320/390/1440 px com SDK simulado para campo de intervalo editável, conversão única → recorrente, padrão mensal da categoria fixa e edição de parcelas. RPC real com dados sintéticos e rollback: conversão, calendário quadrimestral e repetição idempotente sem duplicatas. Migração registrada pelo Supabase: 20261108023402.
