# faf-game

A 3D fishing game, built on a custom-built Godot engine.

## Layout
- `game/` — the Godot project (open with the custom editor; `game/open_editor.bat`).
- `docs/` — design docs. Start with [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md).
- `engine/` — **not tracked here.** A local clone of the engine fork
  [4rg43n/godot](https://github.com/4rg43n/godot) (fork of
  [godotengine/godot](https://github.com/godotengine/godot)), gitignored in this repo.

## Setup
```sh
git clone https://github.com/4rg43n/faf-game.git
cd faf-game
git clone https://github.com/4rg43n/godot.git engine
cd engine
git remote add upstream https://github.com/godotengine/godot.git
scons platform=windows target=editor use_mingw=yes d3d12=no -j24
```
Then run `game/open_editor.bat`.

## Status
Early scaffolding — no gameplay yet.
