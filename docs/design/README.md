# Refinamento visual bancário

Base: main, beb2cbfd04ed3497a6c8ae597b265664e73e8b85.

A aparência passa a usar cabeçalho colorido conforme o tema, cartão de resumo com contraste,
controles com espaçamento consistente, ícones lineares, tipografia com números
alinhados e navegação inferior flutuante. Estilos em styles/banking.css.

O HTML original é preservado, com uma única inclusão de stylesheet no head.
JavaScript da aplicação comparado byte a byte com a base, sem alterações.
Service worker: cache v35 e inclusão do CSS na lista CORE.
Sem alteração de banco, cálculos, controles ou fluxos de autenticação.

Validação: sete testes de regressão aprovados. Chromium: oito telas em 1440,
390 e 320 px, com dados fictícios; sem overflow horizontal ou erros de execução.
Verificados abertura/fechamento do modal de lançamento e ocultação dos valores.
Capturas nesta pasta usam apenas dados fictícios.

Limites: não houve login real, teste em aparelhos físicos ou teste de atualização
do cache com PWA já instalado. Não publicado.

Integração: esta revisão parte da main e é independente do dashboard (#1) e do
ícone (#2). Ao combinar as três, preservar todos os assets em CORE e incrementar
a versão do cache. Não substituir as mudanças das outras revisões.

Temas preservados: Inter, Nubank, Bradesco, PAN e Banco do Brasil.
Cores de cabeçalho, resumo e superfícies acompanham a preferência existente.
Ícones recebem cores distintas; no BB, o texto sobre amarelo usa azul escuro.
