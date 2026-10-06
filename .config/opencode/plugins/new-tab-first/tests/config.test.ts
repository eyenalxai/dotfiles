import { describe, expect, test } from "bun:test"
import {
  clampSidebarWidth,
  cliConfigPaths,
  DEFAULT_SIDEBAR_WIDTH,
  fitsVertical,
  parseJsonTolerant,
  parseTabsLayout,
  readSidebarWidth,
  readTabsLayout,
  sidebarWidthPaths,
  stripJsonNoise,
  verticalTabsActive,
  type Env,
  type ReadTextFile,
} from "../config"

const env = (values: Record<string, string | undefined> = {}): Env => values
const reader =
  (files: Record<string, string>): ReadTextFile =>
  (path) =>
    files[path]

describe("parseTabsLayout", () => {
  test("reads vertical and horizontal", () => {
    expect(parseTabsLayout({ tabs: { layout: "vertical" } })).toBe("vertical")
    expect(parseTabsLayout({ tabs: { layout: "horizontal" } })).toBe("horizontal")
  })

  test("rejects missing or invalid values", () => {
    expect(parseTabsLayout(undefined)).toBeUndefined()
    expect(parseTabsLayout({})).toBeUndefined()
    expect(parseTabsLayout({ tabs: {} })).toBeUndefined()
    expect(parseTabsLayout({ tabs: { layout: "diagonal" } })).toBeUndefined()
  })
})

describe("stripJsonNoise / parseJsonTolerant", () => {
  test("strips line and block comments", () => {
    const input = `{
      // which rail
      "tabs": { /* inline */ "layout": "vertical" }
    }`
    expect(stripJsonNoise(input)).not.toContain("//")
    expect(parseJsonTolerant(input)).toEqual({ tabs: { layout: "vertical" } })
  })

  test("strips trailing commas in objects and arrays", () => {
    expect(parseJsonTolerant('{"a": [1, 2,], "b": 3,}')).toEqual({ a: [1, 2], b: 3 })
  })

  test("leaves comment-like and comma-like content inside strings alone", () => {
    const input = '{"url": "https://x//y", "note": "a, } b", "tabs": {"layout": "vertical"}}'
    expect(parseJsonTolerant(input)).toEqual({
      url: "https://x//y",
      note: "a, } b",
      tabs: { layout: "vertical" },
    })
  })

  test("returns undefined for empty or invalid input", () => {
    expect(parseJsonTolerant("")).toBeUndefined()
    expect(parseJsonTolerant("not json at all {{{")).toBeUndefined()
  })
})

describe("fit rule (mirrors the TUI)", () => {
  test("clamps the rail width like clampSessionTabsWidth", () => {
    expect(clampSidebarWidth(42, 200)).toBe(42)
    expect(clampSidebarWidth(80, 200)).toBe(72)
    expect(clampSidebarWidth(42, 90)).toBe(42)
    expect(clampSidebarWidth(10, 50)).toBe(6)
    expect(clampSidebarWidth(1, 40)).toBe(5)
  })

  test("fits only when the terminal leaves 64 cells beyond the rail", () => {
    expect(fitsVertical(106, 42)).toBe(true)
    expect(fitsVertical(105, 42)).toBe(false)
    expect(fitsVertical(69, 5)).toBe(true)
    expect(fitsVertical(68, 5)).toBe(false)
  })
})

describe("paths", () => {
  test("config dir override comes before the XDG default", () => {
    expect(cliConfigPaths(env({ OPENCODE_CONFIG_DIR: "/custom" }), "/home/u")).toEqual([
      "/custom/cli.json",
      "/home/u/.config/opencode/cli.json",
    ])
    expect(cliConfigPaths(env({ XDG_CONFIG_HOME: "/xdg" }), "/home/u")).toEqual(["/xdg/opencode/cli.json"])
  })

  test("sidebar width looks at the active channel, then latest and beta", () => {
    expect(sidebarWidthPaths(env({ XDG_STATE_HOME: "/state" }), "/home/u", "beta")).toEqual([
      "/state/opencode/beta/tui/layout.json",
      "/state/opencode/latest/tui/layout.json",
    ])
    expect(sidebarWidthPaths(env({}), "/home/u", undefined)).toEqual([
      "/home/u/.local/state/opencode/latest/tui/layout.json",
      "/home/u/.local/state/opencode/beta/tui/layout.json",
    ])
  })
})

describe("readTabsLayout", () => {
  test("OPENCODE_CLI_CONFIG_CONTENT wins over the file", () => {
    const files = { "/cfg/cli.json": '{"tabs":{"layout":"horizontal"}}' }
    const read = reader(files)
    expect(
      readTabsLayout(env({ OPENCODE_CONFIG_DIR: "/cfg", OPENCODE_CLI_CONFIG_CONTENT: '{"tabs":{"layout":"vertical"}}' }), "/home/u", read),
    ).toBe("vertical")
  })

  test("falls back to the config dir, then XDG", () => {
    const read = reader({
      "/xdg/opencode/cli.json": '{"tabs":{"layout":"vertical"}}',
    })
    expect(readTabsLayout(env({ XDG_CONFIG_HOME: "/xdg" }), "/home/u", read)).toBe("vertical")
  })

  test("returns undefined when nothing declares a layout", () => {
    expect(readTabsLayout(env({}), "/home/u", reader({}))).toBeUndefined()
    expect(readTabsLayout(env({}), "/home/u", reader({ "/home/u/.config/opencode/cli.json": "{}" }))).toBeUndefined()
  })
})

describe("readSidebarWidth", () => {
  test("reads the persisted rail width", () => {
    const read = reader({ "/state/opencode/latest/tui/layout.json": '{"verticalTabsWidth":57}' })
    expect(readSidebarWidth(env({ XDG_STATE_HOME: "/state" }), "/home/u", "latest", read)).toBe(57)
  })

  test("falls back to the default when the store is missing or malformed", () => {
    expect(readSidebarWidth(env({}), "/home/u", "latest", reader({}))).toBe(DEFAULT_SIDEBAR_WIDTH)
    expect(
      readSidebarWidth(env({ XDG_STATE_HOME: "/state" }), "/home/u", "latest", reader({ "/state/opencode/latest/tui/layout.json": "{}" })),
    ).toBe(DEFAULT_SIDEBAR_WIDTH)
  })
})

describe("verticalTabsActive", () => {
  const vertical = { "/cfg/cli.json": '{"tabs":{"layout":"vertical"}}' }
  const configEnv = env({ OPENCODE_CONFIG_DIR: "/cfg" })

  test("true only for a vertical layout with room for the rail", () => {
    const read = reader(vertical)
    expect(verticalTabsActive({ env: configEnv, home: "/home/u", terminalWidth: 200, read })).toBe(true)
    expect(verticalTabsActive({ env: configEnv, home: "/home/u", terminalWidth: 105, read })).toBe(false)
  })

  test("uses the persisted rail width in the fit check", () => {
    const read = reader({ ...vertical, "/state/opencode/latest/tui/layout.json": '{"verticalTabsWidth":72}' })
    const stateEnv = env({ OPENCODE_CONFIG_DIR: "/cfg", XDG_STATE_HOME: "/state" })
    expect(verticalTabsActive({ env: stateEnv, home: "/home/u", channel: "latest", terminalWidth: 136, read })).toBe(true)
    expect(verticalTabsActive({ env: stateEnv, home: "/home/u", channel: "latest", terminalWidth: 135, read })).toBe(false)
  })

  test("false for horizontal, missing, or invalid layouts", () => {
    expect(
      verticalTabsActive({ env: configEnv, home: "/home/u", read: reader({ "/cfg/cli.json": '{"tabs":{"layout":"horizontal"}}' }) }),
    ).toBe(false)
    expect(verticalTabsActive({ env: env({}), home: "/home/u", read: reader({}) })).toBe(false)
    expect(
      verticalTabsActive({ env: env({ OPENCODE_CLI_CONFIG_CONTENT: "nonsense" }), home: "/home/u", read: reader({}) }),
    ).toBe(false)
  })

  test("trusts the configured layout when the terminal width is unknown", () => {
    expect(verticalTabsActive({ env: configEnv, home: "/home/u", read: reader(vertical) })).toBe(true)
  })
})
