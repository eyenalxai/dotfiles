import { createEffect } from "solid-js"
import type { Plugin } from "@opencode/plugin/tui"
import { verticalTabsActive } from "./config"
import { takeAppearance, topMoves } from "./new-tabs"

/**
 * New tabs open on top — vertical tabs only.
 *
 * When a tab appears that was not open before (starting a new thread, opening
 * a session that had no tab), it is moved to the top of the vertical rail
 * instead of staying at the bottom. Nothing else ever reorders, and each tab
 * moves exactly once, at the moment it appears.
 *
 * The order is written with `context.ui.tabs.move`, the same API drag-to-
 * reorder uses, so it persists with the rest of the tab layout.
 *
 * Safety properties:
 *
 * - The appearance snapshot only ever grows, so a move can never re-trigger
 *   itself — no oscillation is possible by construction (unlike a rule that
 *   ranks tabs by state).
 * - The snapshot is seeded on the first non-empty list, so loading or hot-
 *   reloading the plugin never touches existing tabs.
 * - Moves are skipped while the TUI is not showing vertical tabs. The check
 *   reads `cli.json` and the rail width when a tab appears, mirroring the
 *   TUI's own `tabs.layout === "vertical" && sessionTabsFitVertically(...)`.
 *
 * Why the `app` slot: `createEffect` must live inside a Solid component
 * scope, and `ui.slot` is the public way a CLI plugin mounts one. The render
 * output is empty; the slot only owns the effect's lifetime.
 */

export default {
  id: "new-tab-first",
  setup(context: Plugin.Context) {
    const debug = (...args: unknown[]) => {
      if (context.options?.debug === true) console.log("[new-tab-first]", ...args)
    }

    // Unseeded until the first non-empty tab list; see takeAppearance.
    let known: Set<string> | undefined

    const terminalWidth = () => {
      const width = (context.renderer as { width?: unknown } | undefined)?.width
      return typeof width === "number" && Number.isFinite(width) ? width : undefined
    }

    const unregister = context.ui.slot({
      append: "app",
      render: () => {
        createEffect(() => {
          if (!context.ui.tabs.enabled()) return
          const ids = context.ui.tabs.list().map((tab) => tab.sessionID)
          const state = takeAppearance(known, ids)
          known = state.known
          if (state.appeared.length === 0) return

          let active = false
          try {
            active = verticalTabsActive({
              channel: context.app.channel,
              terminalWidth: terminalWidth(),
            })
          } catch (error) {
            debug("vertical check failed; leaving order alone", error)
          }
          if (!active) {
            debug("not on vertical tabs; leaving", state.appeared, "where they are")
            return
          }

          for (const move of topMoves(state.appeared)) context.ui.tabs.move(move.sessionID, move.index)
          debug("moved new tabs to the top:", state.appeared)
        })
        return null
      },
    })

    // The slot component owns the effect; unregistering unmounts it.
    return () => unregister()
  },
}
