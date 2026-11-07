# Guardar mais para um sonho — 18.0.4

No Planejamento, tocar no sonho abre Quanto você guardou a mais? com valor
atual, meta e prévia. O valor informado soma ao saved_amount existente.
Reservas já pagas são contabilizadas uma única vez; não são criados ou
alterados lançamentos. A tela orienta não repetir reservas já marcadas pagas.

Atualização compara saved_amount original para evitar perda de alterações
concorrentes. Em conflito, recarrega plano e pede reabertura. Bloqueia envio
duplicado e preserva dados e formulário em falha. Privacidade oculta valores.
RLS e trigger de financial_plans inspecionados; sem mudança de schema.

20 testes Node aprovados. Chromium 320/390/1440 px: abertura e limites do
modal, zero, adição/recarga, reserva paga sem duplicar, concorrência, falha
e privacidade. APIs simuladas; nenhum valor real alterado nos testes.
Teste: node tests/goals.browser.cjs. Versão 18.0.4/cache v45.
Sem teste de gravação com sessão real.
