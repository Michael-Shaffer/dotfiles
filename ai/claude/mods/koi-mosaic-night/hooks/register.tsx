import type { Register, ThemeSetArgs } from 'claude-code'

import { koiMosaicNightSvg } from './scenes/koi-mosaic-night'

const SCENE_ID = 'koi-mosaic-night'
const COMMAND = 'koi-night'
/** Whether the person turned the scene on, kept across sessions: `/koi-night` sets it, `/koi-night off` clears it. */
const ON_KEY = 'on'

const LOOK: ThemeSetArgs = {
  backdrop: { scene: SCENE_ID, glass: { blur: 12, tint: '#04121a', opacity: 0.42 } },
  overrideColorScheme: 'dark',
}

let scene: string | undefined

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: COMMAND,
      description: 'Koi Mosaic Night behind the chat (the koi pond for dark windows), in every session; "off" turns it off',
    })

    if ((await $.store.get(ON_KEY)) === true) {
      const set = await $.theme.set(LOOK)

      if (!set.isDrawn) {
        $.ui.status(set.reason)
      }
    }

    return next(e)
  })

  on('command.run', { command: COMMAND }, async ($, e) => {
    if (e.args.trim().toLowerCase() === 'off') {
      await $.store.set(ON_KEY, false)
      await $.theme.clear()

      return { text: 'Koi Mosaic Night is off.' }
    }

    await $.store.set(ON_KEY, true)
    const set = await $.theme.set(LOOK)

    return {
      text: set.isDrawn
        ? 'Koi Mosaic Night is on, in this and every new session. If a /custom-theme is set for a project, run /custom-theme off there.'
        : `Koi Mosaic Night is on, but nothing draws it here: ${set.reason}`,
    }
  })

  on('ui.render', { component: 'Backdrop' }, ($, e, next) => {
    if (e.surface !== 'desktop' || e.props.scene !== SCENE_ID) {
      return next(e)
    }

    const { Svg } = $.ui.resolve(e)
    scene ??= koiMosaicNightSvg()

    return <Svg isInteractive alt="A tiled koi pond at night: two koi, lily pads, glowing ripples" source={scene} />
  })
}
