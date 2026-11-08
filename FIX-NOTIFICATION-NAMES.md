# Nomes nas notificações

Notificações usam o nome escolhido no perfil do app, com fallback para o nome de cadastro. Ações autenticadas usam auth.uid(), inclusive ao desfazer pagamento feito por outro membro. Não expõe e-mail nem amplia acesso aos perfis. Mensagens antigas genéricas recebem o nome quando actor_id ainda identifica o autor; não inventa autores ausentes. Mantém os eventos existentes: cadastro, pagamento e pagamento desfeito.

Função de trigger com permissões de execução direta revogadas, search_path vazio e validação de associação financeira. Migração aplicada e registrada pelo Supabase. Teste real com duas identidades, criação/pagamento/desfazer, dados sintéticos e rollback. Nenhum pagamento real alterado. Não exige nova versão do frontend.
