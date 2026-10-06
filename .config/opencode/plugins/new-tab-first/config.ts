// Reads the CLI config the same way the TUI does, so the plugin only acts when
// vertical tabs are actually shown. Everything here takes its inputs (env,
// home, a text reader) so it can be tested offline against fixtures.
//
// Sources, mirroring the TUI:
// - `cli.json` in `$OPENCODE_CONFIG_DIR`, else `$XDG_CONFIG_HOME/opencode`
//   (falling back to `~/.config/opencode`).
// - `OPENCODE_CLI_CONFIG_CONTENT` merges over the file.
// - The rail width lives in the TUI storage store: layout.json under
//   `$XDG_STATE_HOME/opencode/<channel>/tui`.
// - The fit rule is `sessionTabsFitVertically` from the TUI:
//   `terminalWidth >= clamp(sidebarWidth) + 64`, with the clamp from
//   `clampSessionTabsWidth` ([5, 72] and never leaving < 44 cells to content).

import { readFileSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

export type Env = Readonly<Record<string, string | undefined>>
export type ReadTextFile = (path: string) => string | undefined

export const DEFAULT_SIDEBAR_WIDTH = 42
export const SIDEBAR_CONTENT_MIN_WIDTH = 64

export const readTextFile: ReadTextFile = (path) => {
  try {
    return readFileSync(path, "utf8")
  } catch {
    return undefined
  }
}

/** Mirrors the TUI's clampSessionTabsWidth. */
export function clampSidebarWidth(width: number, terminalWidth: number): number {
  return Math.max(5, Math.min(width, 72, terminalWidth - 44))
}

/** Mirrors the TUI's sessionTabsFitVertically. */
export function fitsVertical(terminalWidth: number, sidebarWidth: number): boolean {
  return terminalWidth >= sidebarWidth + SIDEBAR_CONTENT_MIN_WIDTH
}

/** `tabs.layout` from a parsed cli.json, when it is one of the two values. */
export function parseTabsLayout(value: unknown): "vertical" | "horizontal" | undefined {
  if (typeof value !== "object" || value === null) return undefined
  const tabs = (value as { tabs?: unknown }).tabs
  if (typeof tabs !== "object" || tabs === null) return undefined
  const layout = (tabs as { layout?: unknown }).layout
  return layout === "vertical" || layout === "horizontal" ? layout : undefined
}

/**
 * Strip `//` and block comments plus trailing commas, the way the TUI's JSON
 * parser accepts them. Strings are scanned properly, so commas and slashes
 * inside string values are untouched.
 */
export function stripJsonNoise(input: string): string {
  let output = ""
  let inString = false
  let escaped = false
  for (let index = 0; index < input.length; index++) {
    const char = input[index]
    if (inString) {
      output += char
      if (escaped) escaped = false
      else if (char === "\\") escaped = true
      else if (char === '"') inString = false
      continue
    }
    if (char === '"') {
      inString = true
      output += char
      continue
    }
    if (char === "/" && input[index + 1] === "/") {
      while (index < input.length && input[index] !== "\n") index++
      output += "\n"
      continue
    }
    if (char === "/" && input[index + 1] === "*") {
      index += 2
      while (index < input.length && !(input[index] === "*" && input[index + 1] === "/")) index++
      index++
      continue
    }
    if (char === ",") {
      let lookahead = index + 1
      while (lookahead < input.length && /\s/.test(input[lookahead])) lookahead++
      if (input[lookahead] === "}" || input[lookahead] === "]") continue
    }
    output += char
  }
  return output
}

export function parseJsonTolerant(input: string): unknown | undefined {
  const trimmed = input.trim()
  if (trimmed === "") return undefined
  try {
    return JSON.parse(trimmed)
  } catch {
    // fall through to the tolerant pass
  }
  try {
    return JSON.parse(stripJsonNoise(trimmed))
  } catch {
    return undefined
  }
}

export function cliConfigPaths(env: Env, home: string): string[] {
  const paths: string[] = []
  if (env.OPENCODE_CONFIG_DIR) paths.push(join(env.OPENCODE_CONFIG_DIR, "cli.json"))
  const configHome = env.XDG_CONFIG_HOME || join(home, ".config")
  paths.push(join(configHome, "opencode", "cli.json"))
  return [...new Set(paths)]
}

export function sidebarWidthPaths(env: Env, home: string, channel: string | undefined): string[] {
  const stateHome = env.XDG_STATE_HOME || join(home, ".local", "state")
  const base = join(stateHome, "opencode")
  const names = [channel, "latest", "beta"].filter(
    (name): name is string => typeof name === "string" && name.length > 0,
  )
  return [...new Set(names)].map((name) => join(base, name, "tui", "layout.json"))
}

export function readTabsLayout(
  env: Env,
  home: string,
  read: ReadTextFile = readTextFile,
): "vertical" | "horizontal" | undefined {
  const content = env.OPENCODE_CLI_CONFIG_CONTENT
  if (content) {
    const layout = parseTabsLayout(parseJsonTolerant(content))
    if (layout !== undefined) return layout
  }
  for (const path of cliConfigPaths(env, home)) {
    const text = read(path)
    if (text === undefined) continue
    const layout = parseTabsLayout(parseJsonTolerant(text))
    if (layout !== undefined) return layout
  }
  return undefined
}

export function readSidebarWidth(
  env: Env,
  home: string,
  channel: string | undefined,
  read: ReadTextFile = readTextFile,
): number {
  for (const path of sidebarWidthPaths(env, home, channel)) {
    const text = read(path)
    if (text === undefined) continue
    const value = parseJsonTolerant(text)
    if (typeof value !== "object" || value === null) continue
    const width = (value as { verticalTabsWidth?: unknown }).verticalTabsWidth
    if (typeof width === "number" && Number.isFinite(width)) return width
  }
  return DEFAULT_SIDEBAR_WIDTH
}

/**
 * True when the TUI is currently showing vertical tabs: the configured layout
 * is vertical and the terminal has room for the rail (the same fit check the
 * TUI applies before rendering it).
 */
export function verticalTabsActive(
  input: {
    readonly env?: Env
    readonly home?: string
    readonly channel?: string
    readonly terminalWidth?: number
    readonly read?: ReadTextFile
  } = {},
): boolean {
  const env = input.env ?? process.env
  const home = input.home ?? homedir()
  const read = input.read ?? readTextFile
  if (readTabsLayout(env, home, read) !== "vertical") return false
  // Without a width reading, trust the configured layout rather than silently
  // disabling the feature.
  if (input.terminalWidth === undefined) return true
  const sidebar = clampSidebarWidth(readSidebarWidth(env, home, input.channel, read), input.terminalWidth)
  return fitsVertical(input.terminalWidth, sidebar)
}
