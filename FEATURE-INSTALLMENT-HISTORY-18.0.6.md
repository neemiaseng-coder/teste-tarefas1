# Histórico de pagamentos na tela de parcelas — 18.0.6

A tela passa a reconciliar os registros importados do lote Granna com séries
existentes, somente na apresentação. Nenhum lançamento ou status é alterado.
Isso respeita a proteção do banco contra edição de registros já pagos.

Associação exige título normalizado, valor igual à primeira parcela cadastrada,
dia de vencimento compatível, sequência mensal consistente e número ainda ausente
entre 1 e o total da série. Acentos/pontuação e a grafia bancária Nubanck/Nubank
são normalizados. Nomes de pessoas semelhantes permanecem para revisão.
Dois registros no mesmo número, séries ambíguas, valores de R$0,01 e montantes
diferentes não são associados automaticamente.

A numeração histórica é calculada pela sequência da série, e a tela identifica
essa origem. Status de pagamento é sempre o registrado no histórico.
Detalhes expansíveis mostram registros considerados e exceções para conferência.
No conjunto conferido: 24 associações (19 pagas e 5 pendentes), 17 para revisão.
Sem duplicação de despesas, mudança de valores, vencimentos ou parcelas futuras.

29 testes Node aprovados. Chromium em 320/390/1440 px: progresso com histórico,
detalhes, exceções, privacidade e manutenção de pendências. APIs simuladas.
Teste: node tests/installment-history.browser.cjs.
Versão 18.0.6/cache v47. Nenhuma escrita no banco por esta mudança.
