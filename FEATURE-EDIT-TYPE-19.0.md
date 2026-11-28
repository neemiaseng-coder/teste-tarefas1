# Edição de tipo e parcelas, avisos próprios e situação de pagamento

- Ao editar uma conta pendente é possível trocar entre Única, Recorrente e Parcelada e ajustar parcela atual e total, sempre com confirmação.
- Nova RPC `convert_finance_entry` (migração aditiva). Contas pagas nunca são atualizadas nem excluídas. No alcance "Esta e todas as próximas", as pendentes seguintes são substituídas conforme a nova configuração.
- Os pop-ups do navegador foram trocados por diálogos do app (`js/dialog.js`).
- Lista de contas: resumo Pago x Falta pagar, selo Paga / A pagar / Atrasada e títulos de grupo na cor do tema.
