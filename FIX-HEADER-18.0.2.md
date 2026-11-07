# Cabeçalho e painéis — 18.0.2

Botões circulares com gradientes vivos, SVGs em branco com preenchimento suave,
perfil e busca harmonizados com os cinco temas.

Painéis de busca e notificações reposicionados conforme a área visível, inclusive
redimensionamento e teclado via VisualViewport. Largura e altura limitadas,
rolagem interna, quebra de textos longos e limite acima do menu inferior.
Estado aria-expanded atualizado e fechamento por Esc com retorno de foco.
Nenhuma alteração em autenticação, pagamentos ou dados financeiros.

Validação: 17 testes Node aprovados. Chromium em 320x640, 390x844, 768x700,
1440x900 e 640x360 com cinco temas, 40 notificações fictícias com textos extensos,
busca e ajuda dentro da tela, rolagem, Esc e ARIA. Sem erros ou overflow.
Teste reproduzível: node tests/header-ui.browser.cjs (Playwright e Chromium).

Cache: v43; novos assets e URLs v18.0.2. Sem login real ou teste físico.
