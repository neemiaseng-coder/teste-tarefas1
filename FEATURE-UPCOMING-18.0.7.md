# Próximas contas: hoje até 10 dias — 18.0.7

A tela usa a data atual em America/Sao_Paulo e inclui hoje e o décimo dia
seguinte, independentemente do mês selecionado no resumo. Somente despesas
pendentes entram na lista. Contas pagas, receitas e reservas ficam de fora.
Todas as despesas pendentes anteriores a hoje aparecem em Atrasadas, com fundo
vermelho claro, ícone e indicação de dias de atraso. Lista sem limite de três.

Recalcula ao abrir a tela, ao renderizar dados, ao voltar à aba e na mudança de
dia, inclusive sem conexão. Aritmética de datas evita mudanças por UTC/DST.
Privacidade de valores preservada. Nenhuma alteração de dados ou pagamentos.

34 testes Node aprovados. Chromium 320/390/1440 px: limites hoje/décimo dia,
atrasos, fundo/aviso vermelho, exclusão de pagos e além da janela, independência
do mês selecionado, privacidade e layout. Dados fictícios.
Teste: node tests/upcoming.browser.cjs.
Versão 18.0.7/cache v48.
