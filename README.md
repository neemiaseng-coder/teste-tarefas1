# Teste Tarefas

Aplicação inicial para organização pessoal e gestão de tarefas em equipe.

## Estado atual
- Interface demonstrativa em `index.html`.
- Nesta primeira versão os dados ficam no armazenamento local do navegador.
- **Ainda não é uma aplicação multiusuário de produção.** Os perfis exibidos são apenas simulação no frontend.
- O próximo passo é conectar o Supabase Auth e PostgreSQL, aplicar as políticas RLS e substituir o armazenamento local por consultas autenticadas.

## Banco de dados (Supabase)
1. Crie um projeto Supabase.
2. Abra **SQL Editor → New query**.
3. Execute o conteúdo de `supabase/migrations/0001_init.sql`.
4. Crie seu usuário pelo Auth.
5. Promova sua conta inicial a administrador usando o comando de bootstrap no final da migração, substituindo o e-mail.
6. Nunca coloque a chave `service_role` no navegador. O frontend usa somente a chave pública anon/publishable, com RLS habilitado.

## Publicação estática
O repositório contém um `index.html` na raiz e pode ser conectado a um serviço de hospedagem estática como Netlify. Configure o diretório de publicação como `.` e nenhum comando de build.

## Segurança
As permissões precisam ser aplicadas no PostgreSQL via RLS; esconder botões no frontend não é controle de acesso. Antes de uso real, testar contas e cenários de administrador, gestor, usuário, tarefas fora da equipe, usuários inativos e exclusões.
