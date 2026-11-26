# Edição de contas e atualização dos totais — 18.0.11

Contas pendentes têm edição visível de descrição, valor, categoria e vencimento. Séries oferecem um seletor explícito: Somente esta ou Esta e todas as próximas. O padrão é somente esta. Parcelamentos delimitam as próximas pela numeração original; recorrentes usam o vencimento original. Parcelas anteriores e pagas ficam intactas, mesmo após mudar o vencimento selecionado.

A RPC edit_finance_entry executa a edição inteira em uma transação, com RLS, bloqueio da série e verificação de versão. Os editores antigos delegam à mesma operação. A regra de repetição e a quantidade exigem alcance futuro, e séries com pagamentos preservam a quantidade original. Edições comuns não criam registros, não preenchem lacunas e não restauram parcelas excluídas. Uma ampliação explícita adiciona apenas números novos, protegidos por índice único. Excluir usa um único DELETE filtrado por pendência e pelo alcance original; uma proteção no banco impede excluir pagamentos sem estorno.

O detalhe do parcelamento mostra total de parcelas, pagas, restantes, valor atualizado, valor pago e saldo restante, além de permitir abrir suas parcelas. O saldo soma os valores pendentes atuais; não multiplica quantidade por um valor presumido. As contagens declaradas e os registros disponíveis ficam identificados quando há exclusões ou histórico incompleto.

Foram preservadas 19 associações inequívocas de pagamentos importados, em uma tabela de vínculos somente de leitura para membros. Assim, editar nome, valor ou vencimento de todas as parcelas futuras não faz o histórico pago desaparecer do resumo. Nenhum pagamento original é modificado.

Os totais mensais somam despesas pagas e pendentes; o restante soma apenas pendentes. Edição, inclusão, pagamento, estorno e exclusão atualizam resumos, gráficos e previsões. O refresh preserva a categoria e os filtros escolhidos, inclusive durante a edição. Pagamento e estorno conferem atomicamente o status esperado para evitar sobrescrever uma ação concorrente. A assinatura Realtime mantém as tabelas financeiras e passa a acompanhar salários, com recuperação ao reconectar/retomar o app.

Validação:

- 43 testes Node, incluindo duas suítes PostgreSQL/PGlite com os mesmos SQLs das migrações, RLS, duas identidades fictícias, rollback após falha, datas, pagamentos, estorno, exclusão, preservação dos anteriores, lacunas e rejeição de versão desatualizada.
- Duas sessões Chromium (320 e 390 px), conectadas ao PostgreSQL isolado, executam criação, edição individual e futura, exclusão, pagamento e estorno. As duas telas conferem os totais, saldo parcelado e previsões após cada ação.
- O transporte de autenticação e os callbacks Realtime são simulados nesses testes. Não foi realizado login nas contas reais nem um teste com os dois aparelhos reais. A publicação das tabelas e as permissões da RPC foram verificadas no Supabase.
- Regressões de quantidade/intervalo, navegação Voltar, histórico importado, personalização individual e cabeçalho nas cinco opções de tema.
- As contagens agregadas de lançamentos e pagamentos permaneceram inalteradas durante a implantação das migrações; nenhum lançamento financeiro real foi alterado. Não há duplicação de números de parcelas. RPC disponível para membros autenticados, indisponível para anon, com SECURITY INVOKER.

As seis migrações desta alteração usam as versões registradas pelo Supabase. Os testes usam apenas dados sintéticos; nenhum dado financeiro real faz parte dos arquivos de teste.

