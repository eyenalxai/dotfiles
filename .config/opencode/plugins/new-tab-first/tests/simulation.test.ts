// Offline simulation of the plugin against a mocked TUI and real temp config
// files. No OpenCode process, no live tabs: the harness drives the plugin's
// effect the way Solid would after a reactive change, and the fake store
// mirrors the real move semantics. `solid-js` is replaced at import time so
// the plugin itself is exercised end to end.
import { afterAll, beforeEach, describe, expect, mock, test } from "bun:test"
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs"
import { join } from "node:path"

const effects: Array<() => void> = []
mock.module("solid-js", () => ({
  createEffect: (callback: () => void) => {
    effects.push(callback)
    return () => {}
  },
}))

const plugin = (await import("../tui")).default

type Move = { sessionID: string; index: number }

function harness(
  initial: string[],
  options: { width?: number | undefined; channel?: string; enabled?: boolean } = {},
) {
  const tabs = initial.map((sessionID) => ({ sessionID }))
  const moves: Move[] = []
  const enabled = options.enabled ?? true
  const renderer: { width: number | undefined } = { width: "width" in options ? options.width : 200 }
  let listOverride: ((tabs: { sessionID: string }[]) => { sessionID: string }[]) | undefined

  const context = {
    options: {},
    app: { version: "test", channel: options.channel ?? "latest" },
    renderer,
    ui: {
      tabs: {
        enabled: () => enabled,
        list: () => (listOverride ? listOverride(tabs) : tabs).map((tab) => ({ ...tab })),
        move: (sessionID: string, index: number) => {
          moves.push({ sessionID, index })
          const from = tabs.findIndex((tab) => tab.sessionID === sessionID)
          if (from === -1) return false
          const to = Math.max(0, Math.min(tabs.length - 1, index))
          if (from === to) return true
          const [item] = tabs.splice(from, 1)
          tabs.splice(to, 0, item)
          return true
        },
      },
      slot: (claim: { render: (input: Record<string, never>) => unknown }) => {
        claim.render({})
        return () => {}
      },
    },
  }

  return {
    context,
    moves,
    renderer,
    get order() {
      return tabs.map((tab) => tab.sessionID)
    },
    get tabs() {
      return tabs
    },
    push(sessionID: string) {
      tabs.push({ sessionID })
    },
    useList(override: ((tabs: { sessionID: string }[]) => { sessionID: string }[]) | undefined) {
      listOverride = override
    },
  }
}

type Harness = ReturnType<typeof harness>

function pass() {
  for (const effect of [...effects]) effect()
}

function settle(h: Harness, max = 50) {
  for (let i = 0; i < max; i++) {
    const before = h.moves.length
    pass()
    if (h.moves.length === before) return i + 1
  }
  throw new Error(`simulation did not settle after ${max} passes`)
}

const roots: string[] = []
afterAll(() => {
  for (const root of roots) rmSync(root, { recursive: true, force: true })
})

/** Real config files in a temp dir, wired through the env vars the TUI uses. */
function configure(options: { layout?: "vertical" | "horizontal"; sidebar?: number; content?: string } = {}) {
  const root = mkdtempSync(join("/tmp/opencode", "new-tab-first-"))
  roots.push(root)
  const configDir = join(root, "config")
  const configPath = join(configDir, "cli.json")
  mkdirSync(configDir, { recursive: true })
  writeFileSync(configPath, JSON.stringify({ tabs: options.layout === undefined ? {} : { layout: options.layout } }))
  const stateHome = join(root, "state")
  mkdirSync(join(stateHome, "opencode", "latest", "tui"), { recursive: true })
  writeFileSync(
    join(stateHome, "opencode", "latest", "tui", "layout.json"),
    JSON.stringify(options.sidebar === undefined ? {} : { verticalTabsWidth: options.sidebar }),
  )
  process.env.OPENCODE_CONFIG_DIR = configDir
  process.env.XDG_CONFIG_HOME = join(root, "xconfig")
  process.env.XDG_STATE_HOME = stateHome
  if (options.content === undefined) delete process.env.OPENCODE_CLI_CONFIG_CONTENT
  else process.env.OPENCODE_CLI_CONFIG_CONTENT = options.content
  return { configPath, stateHome }
}

beforeEach(() => {
  effects.length = 0
})

describe("new-tab-first simulation", () => {
  test("seeds existing tabs without moving them", () => {
    configure({ layout: "vertical" })
    const h = harness(["a", "b", "c"])
    plugin.setup(h.context as never)
    settle(h)
    expect(h.moves).toEqual([])
    expect(h.order).toEqual(["a", "b", "c"])
  })

  test("a new tab appears at the top", () => {
    configure({ layout: "vertical" })
    const h = harness(["a", "b"])
    plugin.setup(h.context as never)
    settle(h)
    h.push("c")
    settle(h)
    expect(h.order).toEqual(["c", "a", "b"])
    expect(h.moves).toEqual([{ sessionID: "c", index: 0 }])
  })

  test("a batch of new tabs keeps its appearance order", () => {
    configure({ layout: "vertical" })
    const h = harness(["a"])
    plugin.setup(h.context as never)
    settle(h)
    h.push("b")
    h.push("c")
    settle(h)
    expect(h.order).toEqual(["b", "c", "a"])
    expect(h.moves.length).toBe(2)
  })

  test("horizontal layout leaves new tabs at the bottom", () => {
    configure({ layout: "horizontal" })
    const h = harness(["a", "b"])
    plugin.setup(h.context as never)
    settle(h)
    h.push("c")
    settle(h)
    expect(h.moves).toEqual([])
    expect(h.order).toEqual(["a", "b", "c"])
  })

  test("a terminal too narrow for the rail leaves new tabs alone", () => {
    configure({ layout: "vertical" })
    const h = harness(["a"], { width: 100 }) // 100 < 42 + 64
    plugin.setup(h.context as never)
    settle(h)
    h.push("b")
    settle(h)
    expect(h.moves).toEqual([])
    h.renderer.width = 160
    h.push("c")
    settle(h)
    expect(h.order).toEqual(["c", "a", "b"])
  })

  test("the persisted rail width participates in the fit check", () => {
    configure({ layout: "vertical", sidebar: 72 })
    const h = harness(["a"], { width: 135 }) // 135 < 72 + 64
    plugin.setup(h.context as never)
    settle(h)
    h.push("b")
    settle(h)
    expect(h.moves).toEqual([])
    h.renderer.width = 136
    h.push("c")
    settle(h)
    expect(h.order).toEqual(["c", "a", "b"])
  })

  test("an empty first read does not scramble the hydrated tabs", () => {
    configure({ layout: "vertical" })
    const h = harness([])
    plugin.setup(h.context as never)
    settle(h)
    h.push("a")
    h.push("b")
    h.push("c")
    settle(h)
    expect(h.moves).toEqual([])
    expect(h.order).toEqual(["a", "b", "c"])
    h.push("d")
    settle(h)
    expect(h.order).toEqual(["d", "a", "b", "c"])
  })

  test("never repeats the same move for an unchanged list", () => {
    configure({ layout: "vertical" })
    const h = harness(["a"])
    plugin.setup(h.context as never)
    settle(h)
    h.push("b")
    settle(h)
    const applied = h.moves.length
    for (let i = 0; i < 25; i++) pass()
    expect(h.moves.length).toBe(applied)
  })

  test("a stale list snapshot cannot queue duplicate moves", () => {
    configure({ layout: "vertical" })
    const h = harness(["a", "b"])
    plugin.setup(h.context as never)
    settle(h)
    h.push("c")
    const stale = h.tabs.map((tab) => ({ ...tab }))
    h.useList(() => stale)
    for (let i = 0; i < 10; i++) pass()
    h.useList(undefined)
    settle(h)
    expect(h.moves).toEqual([{ sessionID: "c", index: 0 }])
    expect(h.order).toEqual(["c", "a", "b"])
  })

  test("a config change is honored on the next appearance", () => {
    const { configPath } = configure({ layout: "horizontal" })
    const h = harness(["a"])
    plugin.setup(h.context as never)
    settle(h)
    h.push("b")
    settle(h)
    expect(h.order).toEqual(["a", "b"])
    writeFileSync(configPath, JSON.stringify({ tabs: { layout: "vertical" } }))
    h.push("c")
    settle(h)
    expect(h.order).toEqual(["c", "a", "b"])
  })

  test("OPENCODE_CLI_CONFIG_CONTENT overrides the config file", () => {
    configure({ layout: "horizontal", content: '{"tabs":{"layout":"vertical"}}' })
    const h = harness(["a"])
    plugin.setup(h.context as never)
    settle(h)
    h.push("b")
    settle(h)
    expect(h.order).toEqual(["b", "a"])
  })

  test("does nothing when tabs are disabled", () => {
    configure({ layout: "vertical" })
    const h = harness(["a"], { enabled: false })
    plugin.setup(h.context as never)
    settle(h)
    h.push("b")
    settle(h)
    expect(h.moves).toEqual([])
  })

  test("an unknown terminal width trusts the configured layout", () => {
    configure({ layout: "vertical" })
    const h = harness(["a"], { width: undefined })
    plugin.setup(h.context as never)
    settle(h)
    h.push("b")
    settle(h)
    expect(h.order).toEqual(["b", "a"])
  })
})
