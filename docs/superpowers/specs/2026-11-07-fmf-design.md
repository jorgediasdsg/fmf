# FMF — Find My Family · Documento de Design

Data: 2026-11-07 · Autor do conceito: filho do usuário (10 anos) · Registrado por: Claude

## Visão

Action-RPG 2D de plataforma lateral em pixel art, no estilo visual de **Hero Tale**
(pixel "moderno", não retrô demais). **Zack**, um menino de cabelo preto, camisa
vermelha de manga curta e calça marrom, foi abandonado bebê numa cidade
desconhecida; sua única lembrança dos pais é uma **cicatriz**. Ele parte numa
jornada por cidades e fases para encontrá-los, treinado por um super-herói que
admira. No fim, descobre que **os pais são os vilões** — o chefão final. Vencendo,
ele se torna o herói da cidade, cercado dos amigos que fez no caminho.

- Ponto forte de Zack: coragem.
- Ponto fraco: a saudade dos pais — quando está triste, enfraquece.
- Melhor amigo: **George**. Melhor amiga (interesse romântico leve): **Lara**.

## Plataformas e público

- Público: crianças de ~10 anos (os filhos do usuário) e o pai. Idioma: **pt-BR**.
- Ordem de entrega: **1) navegador web** (desktop e celular), **2) Android nativo
  (APK via adb — aparelho de teste: Moto G6 Plus, Android 12, arm64, 1080×2160)**,
  **3) desktop Linux/Windows com controle USB** (dois controles no futuro, para
  co-op local com George como player 2 — fase futura, fora do MVP).
- Publicação: usuário sobe o build web no itch.io.

## Entrada (as três desde o MVP)

- **Teclado**: setas/WASD mover, espaço pular, J/X atacar, E interagir, Esc pausa.
- **Controle USB**: analógico/D-pad mover, A (bottom) pular, X (left) atacar,
  Y interagir, Start pausa.
- **Toque** (celular/tablet): joystick virtual à esquerda, botões Pular/Atacar à
  direita; overlay aparece apenas em telas de toque.

## Regras definidas pelo autor do conceito (imutáveis sem consultá-lo)

1. **5 corações**; cada golpe recebido tira frações de coração ("1/3 da vida" por
   dano). Implementação: 15 pontos de vida = 5 corações × 3 terços.
2. **Sem checkpoint dentro da fase**: morreu, recomeça a fase inteira ("tem que
   ser difícil"). Fase concluída fica concluída (estilo Rayman).
3. **Exceção do chefão final**: se perder contra os pais, volta direto para a
   luta, sem refazer o caminho.
4. **XP e níveis**: matar monstros dá XP; subir de nível aumenta a força.
5. **Moedas** derrubadas por inimigos; compram armaduras e armas nas cidades.
   Moeda 100% virtual — **sem dinheiro real, sem compras reais** (anti-goal).
6. **Cada fase tem inimigo/chefe próprio**: fase 1 ciclopes pequenos; depois
   gelatina de dois olhos, esqueleto, zumbi, dragão de duas cabeças… chefão
   final: os pais.
7. **Motivação**: perto dos amigos (George/Lara) Zack bate mais forte; momentos
   tristes da história reduzem o dano. (Mecânica de fases futuras, não do MVP.)
8. **Música clássica/de aventura, uma por mundo.**
9. **Título: FMF — Find My Family.** Logo do desenho da criança: fundo azul-claro,
   letras amarelas com contorno, o "M" feito de dois triângulos e o segundo "F"
   formado por uma espada vertical (referência:
   `docs/referencias/logo-fmf-desenho.jpeg`).

## REVISÃO 2026-11-07 (tarde) — decisões do usuário (pai)

1. **Direção visual: 3D estilo "Fogo-Fátuo"/Hades** (referência: jogo do vídeo
   youtube.com/watch?v=47N3ExwgoGs — câmera alta e inclinada, modelos low-poly
   de **cor chapada com contorno preto e luz de borda**, vinheta, cada fase com
   clima de cor próprio). Substitui a direção 2D pixel original — decisão
   explícita do pai sabendo que o filho pedira 2D; o estilo "blocado tipo
   Minecraft" citado pelo filho é a ponte. Gameplay adaptado: fases viram
   trechos/arenas 3D (movimento em 8 direções no plano), mantendo TODAS as
   regras da seção abaixo (corações, XP, moedas, chefes por fase, morte
   reinicia a fase, exceção do chefão final).
2. **Cachorro do Zack**: companheiro com **mancha preta no olho**; segue Zack
   e ataca inimigos em investidas automáticas (dano menor que a espada).
   Entra no MVP.
3. Performance é restrição dura: precisa rodar no navegador e no Moto G6 Plus
   (Adreno 508) — poucos materiais, poucas luzes dinâmicas, low-poly, renderer
   Compatibility.

## Direção de arte e som

- Pixel art, viewport base **480×270**, escala inteira, filtro nearest.
- Sprites e tiles gerados proceduralmente (scripts Python/PIL em `tools/`),
  substituíveis depois por arte desenhada. Zack ~16×24 px.
- Fonte pixel (Press Start 2P ou similar OFL).
- Música chiptune de aventura (gerada em `tools/`, substituível); SFX de golpe,
  dano, moeda, level up, vitória.
- Tom: aventura corajosa, **nada assustador ou sangrento** (anti-goal); inimigos
  "fofos-ameaçadores", derrota em puff/partículas.

## Escopo do MVP (esta entrega)

Tela de título (logo FMF, Iniciar/Continuar) → **Fase 1** (campo/floresta com
ciclopes pequenos, moedas, XP) → **chefe Ciclope Grande** → tela de vitória.
HUD de corações/moedas/nível. Morte reinicia a fase. Save automático
(progresso, moedas, XP) em `user://`. Exports: web (zip itch.io), APK Android
instalado no aparelho de teste, binário Linux.

**Fora do MVP** (fases seguintes do projeto): loja/cidades, demais fases e
chefes, mecânica de motivação, George/Lara em cena, chefão final dos pais,
co-op de 2 controles, iOS.

## Não-objetivos e anti-objetivos

- Não-objetivos: multiplayer online, 3D, mundo aberto, localização além de pt-BR.
- Anti-objetivos: compras com dinheiro real; conteúdo assustador/gore; qualquer
  coisa que exija conta/servidor para jogar.
