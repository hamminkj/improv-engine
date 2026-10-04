# Improv Engine

A projected-screen improv show simulator built in Godot 4. The screen runs the show like a game master; the performers bring it to life. One person (the operator) works the keyboard or a clicker.

Developed by Julianne Hammink

## Run it

1. Install Godot 4.3 or newer (standard build, not .NET).
2. Open Godot, choose Import, and select `project.godot` in this folder.
3. Press F5.

Press F11 in the game to toggle fullscreen. The project is set up for a 1920x1080 projector.

## Play in a browser

A web build is in `docs/`. After turning on GitHub Pages (Settings, Pages, Deploy from a branch, branch `main`, folder `/docs`), it plays at https://hamminkj.github.io/improv-engine/ in Chrome, Firefox, or Edge. Click the page once so the keyboard controls work.

To rebuild it after changing the game: install the Godot 4.4 web export templates, then run `godot --headless --export-release "Web" docs/index.html`.

## How a show runs

1. **Set up**: performers (2 to 10), format, length, intensity, which twist types are allowed, whether the screen fires surprise twists on its own, and an optional seed.
2. **Ask the audience**: type their suggestion. It becomes the show's theme and the first logged fact.
3. **Scene card**: each scene deals a cast (fair rotation), place, relationship, want, obstacle, first line, feeling, and sometimes a rule. Reroll any card with keys 1 to 7, or click names to change the cast.
4. **Live scene**: a countdown timer, surprise twists, and operator tools.
5. **Rate and steer**: rate the scene, then pick one of four directions for what comes next.
6. **Intermissions**: between beats, take an optional warm-up and draw a rule for the next beat.
7. **Review**: a critic's write-up, awards, and the full scene list.

## Operator keys

| Key | Where | Action |
| --- | --- | --- |
| Space or Enter | everywhere | Advance (start scene, end scene, continue) |
| 1 to 7 | scene card | Reroll that card |
| T | live scene | Random twist |
| Y | live scene | Choose a twist from four, filter by type |
| D | live scene | Roll a d20 (fumble, complication, nudge, gift, miracle) |
| F | live scene or monologue | Log a fact the performers established |
| C | live scene | Call back a logged fact |
| P or Esc | anywhere | Pause menu (resume, end show, quit) |
| 1 to 4 | after a scene | Rate the scene, then choose a direction |
| 1 to 3 | intermission | Show a warm-up |

## The simulation

Four meters (Energy, Chaos, Heart, Coherence) respond to twists, dice rolls, facts, callbacks, and scene ratings. The Show Doctor reads the meters and suggests a move. The final review is built from the meters, ratings, and facts.

## Formats

Three-Beat Harold, Quick Montage, Two-Hander Duel, Chain Reaction, Monologue Show, Open Sandbox.

## Adding content

Everything lives in `scripts/content.gd`: locations, relationships, wants, obstacles, first lines, feelings, genres, rules, twists, warm-ups, monologue prompts, dice results, directions, and formats. Add rows and the game picks them up. Twist rows are `[name, text, kind, chaos, energy, heart, coherence]`.

## Project layout

- `scripts/content.gd`: all content (autoload `Content`)
- `scripts/game_state.gd`: settings, show state, and rules (autoload `GameState`)
- `scripts/ui.gd`: theme and UI helpers
- `scripts/main.gd`: screen switching
- `scripts/screens/`: title, setup, show, review, credits

Settings are saved to `user://improv_settings.json`.
