# Voltar para o início antes de sair

Depois do acesso, a navegação mantém uma única etapa de proteção no histórico do navegador. Voltar de qualquer tela abre o menu inicial e fecha modais e popovers; o próximo Voltar permite a navegação nativa para fora do app. Trocar de menu não acumula entradas, e abrir outra tela depois de voltar ao início rearma a proteção. Recarregar não duplica essa entrada.

Não força window.close, não altera sessão nem dados financeiros. A saída efetiva segue o comportamento do navegador ou PWA do sistema operacional.

Validação: 37 testes Node existentes; Chromium em 320, 390 e 1440 px com autenticação simulada. Primeiro Voltar preserva o app e ativa início, segundo retorna a uma página anterior externa ao app; teste de recarregamento, menus sucessivos, reentrada e fechamento de modal.
