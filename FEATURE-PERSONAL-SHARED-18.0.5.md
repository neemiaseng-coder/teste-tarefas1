# Preferências individuais e dados compartilhados — 18.0.5

Foto e preferências usam user_id autenticado e pasta própria de storage.
Seleção de tema passa a salvar automaticamente no banco, com fila para manter
a última escolha em mudanças rápidas. Login lê preferências do usuário atual.
Logout limpa imagem, perfil, campos e painéis e remove canal Realtime anterior.
Respostas assíncronas de outra sessão não atualizam a interface do novo usuário.

Finanças: canal Realtime vinculado à sessão; atualização na conexão, retorno
à aba e reconexão; consulta de recuperação a cada 30 segundos enquanto visível.

20 testes Node aprovados. Duas sessões Chromium com APIs/Realtimes simulados:
fotos/temas separados, salvamento automático, recarga, última escolha mantida,
A cria conta → B vê/paga → A vê pago; B cria → A vê/paga → B vê pago;
preferências não se misturam e logout limpa perfil. Teste: node tests/two-user.browser.cjs.

Consultas reais RLS com identidade autenticada e rollback: usuário membro vê
seus registros e nenhuma preferência de terceiros; nova conta recriada ainda
não participa da família e vê zero lançamentos, com e-mail confirmado.
Restauração do vínculo Master bloqueada pela revisão automática, aguardando
autorização explícita. Nenhum vínculo foi concedido por esta publicação.
Não houve teste com duas sessões reais nem alteração de valores financeiros.
Versão 18.0.5/cache v46.
