# Dashboard analítico — 06/11/2026

Base consultada: main, beb2cbfd04ed3497a6c8ae597b265664e73e8b85.
Implementação local, sem publicação nem alteração de banco.

Arquivos: index.html, sw.js, js/analytics.js, tests/analytics.test.mjs.
Acesso: Resumo > Gráficos. Filtros por mês/categoria, histórico de 6/12 meses,
indicadores de receitas, despesas, reservas, saldo, pagamentos e atrasos,
comparação com mês anterior e comprometimento com parcelas.
Valores ocultos também ocultam proporções dos gráficos.
Cálculos por mês de referência, em centavos; salários não são adicionados.
Sem projeções novas: dependem de definição da relação entre salários e receitas.

Validação: node --test tests/*.test.mjs — 12 testes aprovados.
Backup anterior verificado por SHA-256 em ../backups/.
Validação adicional: Chromium em 1440 e 390 px, dados fictícios, filtros, privacidade, mês vazio e ausência de overflow e erros de execução.
Comando: node tests/analytics.browser.cjs (requer Playwright e /usr/bin/chromium).
Prévia offline: preview/analytics.html — dados fictícios, sem Supabase.
Não executados: login real, aparelhos físicos, Realtime e offline da aplicação autenticada.
Entrega em branch de revisão; clonagem Git falhou por indisponibilidade do proxy.
Arquivos-base obtidos pelo conector GitHub; cópia local não é clone Git.
Pendências: aprovação visual do usuário e integração autenticada, depois publicação.
