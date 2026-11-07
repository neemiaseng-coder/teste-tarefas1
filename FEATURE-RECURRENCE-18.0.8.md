# Parcelas e recorrência — 18.0.8

O formulário agora mostra parcela atual e quantidade total ao criar e editar parcelamentos, inclusive depois de alternar entre edição e novo lançamento. A edição preserva o tipo de repetição original. A ampliação do total cria somente parcelas faltantes a partir da parcela selecionada; parcelas anteriores ausentes não são inventadas.

A operação de série parcelada usa RPC transacional com RLS, bloqueio de concorrência e verificação de versão. Parcelas pagas permanecem intactas; o total de uma série com pagamentos fica protegido. Reduções que atingiriam parcelas existentes são recusadas, sem exclusão automática.

Contas recorrentes permitem escolher intervalo em meses (padrão 1), preservando a janela existente de planejamento de 24 meses. Intervalo 4 a partir de novembro gera novembro, março e julho, em seis ocorrências nessa janela. Datas no fim do mês são limitadas ao último dia válido, sem avançar indevidamente ao mês seguinte. O intervalo da série já cadastrada é mostrado em modo de leitura.

Migração aplicada pelo Supabase com versão registrada 20261107235220; valores financeiros existentes não foram alterados pela migração. O cadastro de uma conta real depende do vencimento informado pelo usuário.

Validação: 37 testes Node; navegador em 320, 390 e 1440 px com SDK simulado para criação, edição, quantidade, intervalo, proteção de histórico e reabertura; RPC real com dados sintéticos e rollback para ampliação e bloqueios de redução, pagamentos e versão desatualizada. Nenhum teste marca contas reais como pagas.
