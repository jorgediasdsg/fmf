# FMF — Find My Family

Jogo de ação-aventura 3D (estilo Hades, low-poly de cor chapada com contorno)
criado a partir da ideia do Zack: um menino procurando os pais, com seu
cachorro de mancha preta no olho, enfrentando ciclopes na floresta.

Feito em **Godot 4.7.2** (GDScript, renderer Compatibility). Design em
`docs/superpowers/specs/2026-11-07-fmf-design.md`.

## Como jogar

| Ação | Teclado | Controle USB | Toque |
|---|---|---|---|
| Mover | WASD / setas | analógico esquerdo / D-pad | joystick virtual (esquerda) |
| Atacar | J ou X | X (botão esquerdo) | botão da espada (direita) |
| Menus | Enter / setas | A / D-pad | toque |

Regras: 5 corações (cada golpe tira terços), XP e níveis aumentam a força,
moedas para as lojas (próximas fases), morrer reinicia a fase inteira.
O cachorro ataca sozinho os inimigos próximos.

## Builds prontos (pasta `build/`, gerar com os comandos abaixo)

- `build/fmf-web.zip` — **web**: suba no itch.io (New project → Kind: HTML →
  upload do zip → marque "This file will be played in the browser" e, em
  Frame options, habilite SharedArrayBuffer se disponível). Roda em navegador
  de PC e celular.
- `build/fmf-debug.apk` — **Android**: `adb install -r build/fmf-debug.apk`
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
