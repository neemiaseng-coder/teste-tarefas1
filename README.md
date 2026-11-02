# Teste Tarefas

Aplicação web para organização pessoal e gestão de tarefas em equipe.

## Estado atual
- Frontend em `index.html` integrado ao Supabase Auth e PostgreSQL.
- Login por e-mail e senha, criação de conta, sessão persistente e saída.
- Lista de tarefas, filtros, cadastro, edição, conclusão e exclusão administrativa.
- Perfis reais: administrador, gestor e usuário.
- Permissões de dados aplicadas no banco por RLS e gatilhos.
- Histórico automático de alterações de tarefas no banco.
- Dados sincronizados no Supabase; não usa mais armazenamento local para tarefas.

## Projeto Supabase conectado
- Projeto: `Gestao-de-Tarefas`
- URL: `https://yzlvpbaobgermogwuypx.supabase.co`
- O frontend utiliza somente a chave publishable pública. Nunca adicionar `service_role` ou secret key ao HTML.

## Primeiro acesso / bootstrap do administrador
1. Abra o sistema e clique em **Criar minha conta**.
2. Informe o e-mail e uma senha com pelo menos 6 caracteres.
3. Se a confirmação de e-mail estiver habilitada, confirme o endereço.
4. No Supabase, acesse **SQL Editor** e execute o comando abaixo, trocando o e-mail pelo endereço cadastrado:

```sql
update public.profiles
set role = 'admin', active = true
where id = (
  select id from auth.users
  where email = 'SEU_EMAIL'
);
```

5. Entre novamente no sistema. O primeiro usuário agora terá perfil de administrador.

## Cadastro de outros usuários
- Os usuários podem criar a própria conta pela tela de acesso; novos perfis entram como `user`.
- O administrador pode alterar perfil e ativação de usuários existentes na tela **Usuários**.
- Para provisionar uma conta de outra pessoa, crie o usuário em **Supabase → Authentication → Users**. O gatilho cria o perfil automaticamente. Depois, o administrador poderá ajustar o papel e a situação.
- Usuários inativos não conseguem acessar o sistema.

## Banco e migrations
Migrations aplicadas:
- `0001_init.sql`: tabelas, enums, índices, triggers e políticas RLS.
- `0002_harden_functions.sql`: restringe funções internas e move funções SECURITY DEFINER para o schema privado.
- `0003_fix_private_function_references.sql`: atualiza a validação de permissões do gatilho para chamar as funções no schema privado.

## Limitações ainda em desenvolvimento
- Gestão completa de equipes e membros pela interface.
- Comentários, subtarefas, dependências, recorrência, notificações e calendário.
- Convites por e-mail e provisionamento de usuários diretamente pela interface (exigem fluxo server-side seguro).
- Testes completos de isolamento entre contas e papéis antes de uso em produção.

## Publicação
O projeto ainda não foi publicado. O repositório pode ser conectado a um serviço de hospedagem estática, com diretório de publicação `.` e sem comando de build.

## Segurança
A autorização real é feita pelo PostgreSQL com RLS e triggers; as restrições visuais do frontend são apenas conveniência. Nunca publicar uma chave `service_role` ou segredo no navegador.
