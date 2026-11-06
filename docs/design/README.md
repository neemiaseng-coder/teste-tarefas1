# Visual bancário, dashboard e parcelamentos

Base: main beb2cbfd04ed3497a6c8ae597b265664e73e8b85.
Esta revisão reúne o visual colorido e o dashboard analítico (PR #1).
O ícone do celular continua na revisão independente #2.

Preserva cinco temas: Inter, Nubank, Bradesco, PAN e Banco do Brasil.
Cabeçalho, resumo e superfícies acompanham a preferência. Ícones coloridos.
Dashboard com filtros por mês/categoria, histórico de 6/12 meses e indicadores.
Módulo de cálculos analíticos preservado, sem somar salários às receitas.

Parcelamentos: gráfico circular pelo valor efetivamente pago, valores pagos e
em aberto, quantidades e próxima parcela pendente por vencimento. Parcelas
vencidas aparecem como atrasadas. Não infere pagamento pelo número da parcela.
Histórico incompleto é identificado; o progresso usa apenas registros disponíveis.
Privacidade oculta valores e proporções de ambos os dashboards.

Arquivos principais: index.html, styles/banking.css, js/analytics.js,
js/installments.js e sw.js (cache v37 com os dois módulos e o CSS em CORE).
Sem mudança em autenticação, formulários, pagamentos, schema ou dados do banco.
Mudanças JavaScript adicionais limitadas à apresentação de parcelamentos.

Validação: node --test tests/*.test.mjs — 17 testes aprovados.
Chromium em 1440, 390 e 320 px: dashboard e parcelas com dados fictícios,
filtros, cinco temas, privacidade, meses vazios, sem overflow ou erros de execução.
Capturas nesta pasta são demonstrativas, sem dados reais.

Não executados: login real, aparelhos físicos e atualização do PWA instalado.
Não publicado. Ao integrar o ícone (#2), preservar todos os assets do CORE e
incrementar o cache. Não aplicar novamente o PR #1 após esta revisão.
