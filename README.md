# FMF — Find My Family

Jogo de ação-aventura 3D de visual redondinho (cor chapada com contorno grosso, estilo
Brawl Stars), criado a partir da ideia do Zack: um menino procurando a família,
com seu cachorro de mancha preta no olho, atravessando 5 mundos — floresta de
ciclopes, ilha de polvos, montanha gelada de yetis, lua de aliens e montanhas de
gorilas. Roda em **PC (Linux), web (navegador/itch.io) e Android**, com teclado,
controle e toque, e tem modo para **2 jogadores**.

> Este jogo foi feito **conversando com uma IA** (Claude Code), sem escrever código à
> mão. A seção [Como este jogo foi construído](#como-este-jogo-foi-construído) conta
> como, e [Como construir um jogo igual a este](#como-construir-um-jogo-igual-a-este)
> é um passo a passo para você fazer o seu.

Feito em **Godot 4.7.2** (GDScript, renderer Compatibility). Design original em
`docs/superpowers/specs/2026-11-07-fmf-design.md`.

## Como jogar

| Ação | Teclado | Controle USB | Toque |
|---|---|---|---|
| Mover | WASD / setas | analógico esquerdo / direcional | joystick virtual |
| Soco (braço: gasta pouco, bate fraco) | J ou Z | X | botão punho |
| Chute (perna: gasta mais, bate forte) | K ou X | Y | botão bota |
| Correr (segurar) | Shift | B ou RB (ou gatilho direito) | botão >> |
| Pular | Espaço | A | botão seta |
| Especial (barra cheia) | Q | LB (ou gatilho esquerdo) | botão estrela |
| Menus / loja | Enter, setas, Esc | direcional + A / B volta | toque |

**Barra de força:** cai a cada golpe/pulo e ao correr; fica estável andando;
recupera parado. Sem força o golpe não sai.
**Combos:** correndo + soco = **super soco** (investida); correndo + pular + chute
no ar = **voadora**. **Especial:** a barra roxa enche ao bater; cheia, o botão de
especial derrota todos os bichos perto (o chefe perde uma boa parte da vida).
**Rifle** (comprado no bazar a partir da fase 3): soco com o bicho longe = tiro.
O jogo todo (menus e bazar também) é jogável só no controle.

Escolha o herói (**Léo**, **Zack** ou **Zoe**) ao começar. Todos atacam com
**chutes**. Inimigos às vezes soltam **maçãs** que curam 1 coração; a vida
enche inteira ao começar cada fase.

Cada fase é um **mapa aberto** (anda para qualquer lado) com grupos de bichos
que **se ajudam**; a seta amarela aponta o bicho mais perto. Derrotando **todos**,
o **chefe aparece**. Duas **lojinhas** por mapa: maçã, bolo gigante, **Revista de Treinamento** (chute +1), **Ração Super Prêmio**
(+2 dano do cachorro) e **Rifle** (fase 3+). Tudo caro: as moedas são poucas.

- **Fase 1 — Floresta dos Ciclopes** · chefe: Ciclope Grande
- **Fase 2 — Ilha dos Polvos** · polvos cospem tinta; as **moitas** escondem o
  herói (atacar de dentro revela por um instante) · chefe: Polvo Rei
- **Fase 3 — Montanha Gelada** · yetis com bem mais vida e dano · chefe: Yeti Gigante
- **Fase 5 — Montanhas** · gorilas fortões · chefe: Gorila Rei, com muita vida, que a
  cada 5 s arremessa 2 árvores na sua direção (cada uma tira metade da vida)
- **Fase 4 — Lua** · aliens em naves voadoras (3 golpes) · chefe: Alien Pai, que
  joga um ovo a cada 5 s (saem 5 mini aliens, 2 golpes cada) e morre com 7 golpes

As fases seguem em corrente: vencer a 1 leva à 2, depois 3, 4 e 5. **Continuar** abre
a primeira ainda não vencida.

**2 jogadores:** na tela inicial, "Jogadores: 2". Jogador 1 = teclado (WASD/setas +
J/X), jogador 2 = controle USB (analógico/direcional + X/A). A vida, as moedas e o
XP são da dupla; a câmera acompanha os dois e não dá para se afastar mais de 13 m.

Regras: 5 corações (cada golpe tira terços), XP e níveis aumentam a força,
moedas para as lojas (próximas fases), morrer reinicia a fase inteira.
O cachorro ataca sozinho os inimigos próximos.

## Builds prontos (pasta `build/`, gerar com os comandos abaixo)

- `build/fmf-web.zip` — **web**: suba no itch.io (New project → Kind: HTML →
  upload do zip → marque "This file will be played in the browser" e, em
  Frame options, habilite SharedArrayBuffer se disponível). Roda em navegador
  de PC e celular.
- `build/fmf-debug.apk` — **Android** (controles na tela; também aceita teclado e controle Bluetooth/USB — o controle vira o jogador 2 no modo de 2 jogadores): `adb install -r build/fmf-debug.apk`
  (depuração USB ativada) ou copie o arquivo para o aparelho e instale.
- `build/fmf-linux.x86_64` — **Linux**: executável direto.

Teste web local: `python3 tools/serve_web.py` → http://localhost:8060
(no celular, use o IP do PC na mesma rede).

## Desenvolvimento

- Editor: `godot --path .` (binário em `~/.local/bin/godot`).
- Testes: `godot --headless --path . --script tests/run_tests.gd` e as
  simulações `tests/sim_*.gd` com `--fixed-fps 60 --headless`.
- Regenerar assets 2D/áudio: `python3 tools/gen_sprites.py` e
  `python3 tools/gen_audio.py`.
- Exports: `godot --headless --path . --export-release "Web" build/web/index.html`,
  `--export-debug "Android" build/fmf-debug.apk`,
  `--export-release "Linux" build/fmf-linux.x86_64`.

Fonte Press Start 2P (OFL) em `assets/fonts/`. Música e efeitos são chiptune
gerados em `tools/gen_audio.py`.

## Desempenho no celular

Em aparelho fraco (celular ou tela de toque) o jogo usa gráficos mais leves: sem
sombras, malhas com menos faces e 3D a 75% da resolução. No Moto G6 Plus roda a
~38 FPS (antes 18). Em build de depuração o FPS sai no log: `adb logcat | grep "FMF fps"`.

## Como este jogo foi construído

O jogo inteiro (código, modelos 3D, músicas e efeitos) foi escrito pelo **Claude
Code** (o assistente de programação da Anthropic, no terminal) a partir de
conversas em português com o dono do projeto, que só descrevia o que queria e
testava o resultado. Não há modelo 3D nem arquivo de áudio baixado: **tudo é
gerado por código**.

- **Personagens e cenário 3D**: montados em GDScript com esferas e cápsulas
  (`src/characters/character_builder.gd`), com um shader de cor chapada + contorno
  por "casco invertido" (`src/fx/`). Animações também são geradas por código.
- **Músicas (rock) e efeitos**: sintetizados em Python, sem bibliotecas — guitarra
  distorcida, baixo e bateria (`tools/gen_audio.py`). Ícones de toque em
  `tools/gen_sprites.py`.
- **Fases**: todas partem do mesmo molde (`src/levels3d/level_base.gd`): arena
  aberta, grupos de bichos que se ajudam, o chefe aparece quando o último cai.
  Cada fase só define cores, bichos e o chefe.
- **Bazar, HUD, menus**: desenhados em código (`src/ui/`), jogáveis só no controle.
- **Testes**: simulações automáticas rodam o jogo "sem tela" (`tests/`).

### Ferramentas e skills usadas

| O quê | Para quê |
|---|---|
| **Claude Code** (CLI) | ler/escrever arquivos, rodar comandos, testes e builds |
| **Godot 4.7** | motor do jogo; exporta para web, Android e Linux |
| plugin **superpowers** (skills do Claude Code) | método de trabalho, abaixo |
| `superpowers:brainstorming` | transformar a ideia solta do dono em decisões claras antes de programar |
| `superpowers:writing-plans` / `subagent-driven-development` / `executing-plans` | planos por tarefas em `docs/superpowers/plans/` e execução passo a passo (ver os planos) |
| ferramenta **advisor** | segunda opinião de um revisor antes de começar e antes de entregar |
| `WebSearch` / `WebFetch` | pesquisar referências (quando a página abria) |
| **adb** | instalar o APK no celular, tocar na tela, ler o log e medir FPS |
| `python3` + PIL | gerar imagens e sons |

> Os arquivos em `docs/superpowers/` são os registros reais do método: a especificação
> do jogo e os planos de implementação que a IA escreveu e seguiu.

### O que deu certo (e vale copiar)

1. **Testar de verdade.** Cada recurso ganhou um teste que liga o jogo sem tela e
   confere o resultado (vida, moedas, chefe aparecendo, controle, co-op...).
   Rodar: `godot --headless --path . --script tests/run_tests.gd` e, para as
   simulações, `godot --headless --path . --fixed-fps 60 --script tests/sim_arena.gd`
   (com `SCENE=res://src/levels3d/phase_N.tscn`).
2. **Olhar o resultado.** Em vez de "acho que ficou bom", a IA tirava capturas de
   tela do jogo rodando e conferia o visual — e no celular, via `adb`.
3. **Medir antes de otimizar.** No celular o jogo estava a 18 FPS; um contador no log
   mostrou 1.900 chamadas de desenho por quadro. Cortar sombras e faces levou a ~38 FPS.
4. **Achar a causa.** Quando o botão A do controle "não funcionava", a IA simulou o
   aperto e descobriu que o Godot 4.7 não liga o A a "confirmar" nos menus.

## Como construir um jogo igual a este

Você não precisa saber programar. Precisa de uma ideia, paciência para testar e
um computador (Linux, Mac ou Windows).

**1. Instale o que precisa**
- [Godot 4.x](https://godotengine.org/download) (é grátis) e, para celular, o
  *Android export template* e o Android SDK (`adb`).
- [Claude Code](https://claude.com/claude-code) (precisa de uma conta Anthropic).
- O plugin **superpowers** dentro do Claude Code (comando `/plugin`) — ele dá as
  skills de brainstorming, planos e testes.
- `python3` (para gerar sons e imagens).

**2. Comece conversando, não programando**
- Abra uma pasta vazia, rode `claude` e conte a ideia como se explicasse a um
  amigo: quem é o herói, o que ele faz, como é o visual. Pode falar por voz.
- A skill de *brainstorming* faz perguntas curtas. Responda; ela fecha um desenho
  do jogo antes de qualquer código.
- Peça para escrever a especificação e um plano em `docs/` e para executar tarefa
  por tarefa, com **commit a cada tarefa**.

**3. Exija teste e prova**
- Peça: "toda funcionalidade nova precisa de teste automático" e "tire uma captura
  de tela e me mostre". Se algo quebrar, peça "descubra a causa antes de consertar".
- Peça que o jogo seja jogável com o que você tem: teclado, controle e toque.

**4. Evolua em pedidos pequenos** (assim foi este jogo): primeiro um herói andando
→ um inimigo → vida/moedas → uma fase → chefe → bazar → mais fases... Cada pedido
em linguagem simples ("os bichos têm que se ajudar", "o chefe só aparece quando
matar todos") virou uma funcionalidade.

**5. Publique**
- Web: `godot --headless --path . --export-release "Web" build/web/index.html`, zip
  da pasta `build/web` e suba no [itch.io](https://itch.io) (tipo *HTML*).
- Android: `godot --headless --path . --export-debug "Android" build/fmf-debug.apk`
  e `adb install -r build/fmf-debug.apk` (depuração USB ativada no celular).
- Linux: `godot --headless --path . --export-release "Linux" build/fmf-linux.x86_64`.

**Dicas**: peça "explique em uma frase" quando não entender; guarde as decisões
importantes no README; se a IA errar, diga o que você viu na tela — ela corrige
melhor com o que você observou do que com um palpite.
