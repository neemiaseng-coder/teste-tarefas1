# Foto persistente e preferências — 18.0.3

Diagnóstico confirmado no banco: theme_key aceita forest/ocean/marsala/lavender/dark,
mas o frontend enviava inter/nubank/bradesco/pan/bb. Isso impedia o upsert das
preferências, incluindo avatar_path. O bucket é privado, com limite de 2 MB e
RLS por pasta do usuário. Não havia foto gravada no momento da inspeção.

Correção sem migration: conversão bidirecional dos cinco temas existentes para
os valores aceitos, inclusive no cadastro inicial de preferências.
Foto salva automaticamente ao selecionar, com indicador e bloqueio de concorrência.
Foto antiga só é removida após a gravação confirmada da nova preferência.
Upload não confirmado é limpo em caso de falha de banco. Exclusão explícita com
confirmação, persistida antes da remoção do objeto. Caminho é permanente; link
privado temporário é renovado ao reabrir/retomar o aplicativo. Nenhum bucket público.

Validação: 17 testes Node aprovados; Chromium 390/1440 px com APIs simuladas:
autosave, recarga, cinco temas, troca e limpeza do arquivo antigo, falha do banco
preservando foto anterior, exclusão cancelada/confirmada e recarga após exclusão.
Teste: node tests/avatar.browser.cjs (Playwright e Chromium).
Não homologado upload com sessão real; nenhum dado ou objeto de produção alterado.
Versão 18.0.3; cache v44.
