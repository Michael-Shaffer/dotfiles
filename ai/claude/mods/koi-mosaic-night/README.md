# koi-mosaic-night

A Claude Code mod: the Koi Mosaic backdrop from Anthropic's `theme-examples`
plugin, recoloured for dark windows. The two koi, lily pads and swim motion are
unchanged; the water is night teal, the stones moonlit, and the ripples glow
turquoise like bioluminescence. The orange koi's eye tiles are orange so it
reads as one colour, with small round pupils. Ripples come in several sizes.

## Use

- `/koi-night` turns it on. The choice is remembered, so new sessions show it too.
- `/koi-night off` turns it off.

A session shows one theme at a time. If a project has a `/custom-theme` set,
run `/custom-theme off` there first, or the two will replace each other.

## Loading

`ai/claude/settings.json` names this folder in `env.CLAUDE_CODE_PLUGIN_DIRS`,
so every Claude Code session on a machine with these dotfiles loads it.

## Licence

`hooks/scenes/koi-mosaic-night.ts` is modified from `hooks/scenes/koi-mosaic.ts`
in `theme-examples` 0.4.3 (Apache License 2.0, see `LICENSE`). Changes: scene
colours (water, stones, shadows, grid, ripples), ripple brightness and glow, and
the orange koi's eye tiles, and ripple sizes.
