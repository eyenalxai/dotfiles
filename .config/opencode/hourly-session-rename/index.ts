import { readFile } from "node:fs/promises"
import type { Plugin } from "@opencode/plugin"

/**
 * Hourly session rename.
 *
 * Keeps session titles current as a conversation evolves. Every interval (one
 * hour by default) the plugin looks at the sessions in its location that have
 * new activity since it last titled them, asks a model for a short title based
 * on the recent conversation, and writes the title back with
 * `ctx.session.update`.
 *
 * Why the HTTP API for listing: the plugin context exposes a curated subset of
 * the session client (`create`, `get`, `update`, `context`, ...) but no
 * `session.list`, so there is no supported way to enumerate sessions from
 * `ctx`. The plugin reads the local service registry (the same registry the
 * `opencode-go-failover` plugin uses) and calls `GET /api/session`, which
 * supports filtering by directory. Renames still go through `ctx.session.update`
 * so they use the plugin's own server client.
 *
 * Scope: each loaded location gets its own plugin instance, so the plugin only
 * considers sessions whose `location.directory` equals `ctx.location.directory`.
 * That keeps multiple open projects from re-titling the same session while
 * still covering every project the server has loaded.
 *
 * Local plugins cannot import the runtime `@opencode/plugin` package, so the
 * default export is the plain definition object the loader accepts; the
 * `import type` above is erased when Bun executes the file.
 */

type ModelRef = { providerID: string; id: string; variant?: string }

type SessionInfo = {
  id: string
  parentID?: string
  title?: string
  model?: ModelRef
  time?: { created?: number; updated?: number; archived?: number }
  location?: { directory?: string }
}

type RawMessage = {
  type?: string
  text?: string
  content?: Array<{ type?: string; text?: string }>
}

type RenameRecord = {
  /** Milliseconds after which new activity makes the session a candidate again. */
  renamedAt: number
  /** Title the plugin last produced, for logging and change detection. */
  title?: string
}

type State = {
  sessions?: Record<string, RenameRecord>
}

type Options = {
  intervalMs: number
  jitterMs: number
  startDelayMs: number
  runOnStart: boolean
  activeWindowMs: number
  maxPerRun: number
  scanLimit: number
  minMessages: number
  maxTitleChars: number
  maxTranscriptChars: number
  stateTtlMs: number
  includeChildren: boolean
  includeArchived: boolean
  scope: "location" | "all"
  model?: ModelRef
  instructions: string
  dryRun: boolean
  debug: boolean
}

type Service = { url: string; password: string }

const DEFAULT_INSTRUCTIONS =
  "You title a coding session from a conversation excerpt. " +
  "Reply with the title only: 3 to 8 words, at most 60 characters. " +
  "Describe the concrete task or topic, not the process. " +
  "No quotes, no markdown, no trailing period, and no \"Title:\" prefix. " +
  "Match the language of the conversation."

export default {
  id: "hourly-session-rename",
  async setup(ctx: Plugin.Context) {
    const options = normalize(ctx.options)
    const log = (...args: unknown[]) => console.log("[hourly-session-rename]", ...args)
    const debug = (...args: unknown[]) => {
      if (options.debug) log(...args)
    }

    let state = (await ctx.storage.get("state")) as State | undefined
    state ??= {}
    state.sessions ??= {}

    let running = false
    let stopped = false
    let timer: ReturnType<typeof setTimeout> | undefined

    const persist = async () => {
      try {
        await ctx.storage.set("state", state)
      } catch (error) {
        debug("failed to persist state:", String(error))
      }
    }

    const prune = () => {
      const cutoff = Date.now() - options.stateTtlMs
      let changed = false
      for (const [id, record] of Object.entries(state.sessions ?? {})) {
        if (record.renamedAt < cutoff) {
          delete state.sessions![id]
          changed = true
        }
      }
      return changed
    }

    const resolveModel = async (session: SessionInfo): Promise<ModelRef | undefined> => {
      if (options.model) return options.model
      if (session.model?.providerID && session.model.id) return session.model
      try {
        const resolved = (await ctx.model.default()) as
          | (ModelRef & { data?: ModelRef })
          | { data?: ModelRef }
          | undefined
        const info = resolved && typeof resolved === "object" && "data" in resolved ? resolved.data : resolved
        if (info && typeof info === "object" && info.providerID && info.id) {
          return { providerID: info.providerID, id: info.id, variant: info.variant }
        }
      } catch (error) {
        debug("could not resolve the default model:", String(error))
      }
      return undefined
    }

    const renameOne = async (session: SessionInfo) => {
      const messages = (await ctx.session.context({ sessionID: session.id })) as unknown as RawMessage[]
      const transcript = buildTranscript(messages, options)
      if (transcript === undefined) {
        debug(`${session.id}: not enough conversation to title yet`)
        return
      }

      const model = await resolveModel(session)
      if (!model) {
        debug(`${session.id}: no model available, skipping`)
        return
      }

      const generated = await ctx.generate.text({ model, prompt: buildPrompt(transcript, options) })
      const title = cleanTitle(generated?.text ?? "", options.maxTitleChars)
      if (title === undefined) {
        debug(`${session.id}: model returned no usable title`)
        return
      }

      if (options.dryRun) {
        log(`[dry-run] ${session.id}: ${quote(session.title)} -> ${quote(title)}`)
        return
      }

      if (title !== (session.title ?? "")) {
        await ctx.session.update({ sessionID: session.id, title })
        log(`renamed ${session.id}: ${quote(session.title)} -> ${quote(title)}`)
      } else {
        debug(`${session.id}: title already up to date`)
      }

      // Record the revision we just titled. A title write bumps `time.updated`,
      // and this timestamp lands after it, so the session is skipped until new
      // activity pushes `time.updated` past it.
      state.sessions![session.id] = { renamedAt: Date.now(), title }
    }

    const runOnce = async () => {
      const service = await readService()
      if (!service) {
        debug("local service registry not found; skipping this run")
        return
      }

      const directory = options.scope === "location" ? ctx.location.directory : undefined
      let sessions: SessionInfo[]
      try {
        sessions = await listSessions(service, directory, options.scanLimit)
      } catch (error) {
        debug("could not list sessions:", String(error))
        return
      }

      const now = Date.now()
      const candidates: SessionInfo[] = []
      for (const session of sessions) {
        if (!session?.id?.startsWith("ses")) continue
        if (!options.includeChildren && session.parentID) continue
        if (!options.includeArchived && session.time?.archived) continue
        const updated = session.time?.updated ?? 0
        if (now - updated > options.activeWindowMs) continue
        const record = state.sessions![session.id]
        if (record && updated <= record.renamedAt) continue
        candidates.push(session)
      }

      candidates.sort((a, b) => (b.time?.updated ?? 0) - (a.time?.updated ?? 0))
      const selected = candidates.slice(0, options.maxPerRun)
      if (selected.length === 0) {
        debug("no active sessions need a new title")
        return
      }

      log(`reviewing ${selected.length} active session${selected.length === 1 ? "" : "s"}`)
      for (const session of selected) {
        try {
          await renameOne(session)
        } catch (error) {
          debug(`${session.id}: rename failed:`, String(error))
        }
      }

      prune()
      await persist()
    }

    const tick = async () => {
      if (stopped || running) return
      running = true
      try {
        await runOnce()
      } catch (error) {
        debug("run failed:", String(error))
      } finally {
        running = false
        schedule()
      }
    }

    const schedule = () => {
      if (stopped) return
      const delay = options.intervalMs + Math.floor(Math.random() * Math.max(0, options.jitterMs))
      timer = setTimeout(() => void tick(), delay)
      timer.unref?.()
    }

    const firstDelay = options.runOnStart ? options.startDelayMs : options.intervalMs
    timer = setTimeout(() => void tick(), firstDelay + Math.floor(Math.random() * Math.max(0, options.jitterMs)))
    timer.unref?.()

    log(
      `active; interval ${Math.round(options.intervalMs / 60_000)}m, scope ${options.scope}` +
        `, window ${Math.round(options.activeWindowMs / 60_000)}m` +
        (options.dryRun ? ", dry run" : "") +
        (options.debug ? ", debug" : ""),
    )

    return () => {
      stopped = true
      if (timer) clearTimeout(timer)
    }
  },
}

/** Read the local service registry that a running OpenCode server publishes. */
async function readService(): Promise<Service | undefined> {
  const home = process.env.HOME ?? ""
  const stateHome = process.env.XDG_STATE_HOME ?? `${home}/.local/state`
  const configHome = process.env.XDG_CONFIG_HOME ?? `${home}/.config`
  const candidates = [`${stateHome}/opencode/service.json`, `${configHome}/opencode/service.json`]

  for (const path of candidates) {
    let parsed: Record<string, unknown> | undefined
    try {
      parsed = JSON.parse(await readFile(path, "utf8")) as Record<string, unknown>
    } catch {
      continue
    }
    const password = typeof parsed.password === "string" ? parsed.password : undefined
    if (!password) continue
    if (typeof parsed.url === "string") return { url: parsed.url, password }
    if (typeof parsed.port === "number") return { url: `http://127.0.0.1:${parsed.port}`, password }
  }
  return undefined
}

async function listSessions(service: Service, directory: string | undefined, limit: number): Promise<SessionInfo[]> {
  const url = new URL("/api/session", service.url)
  url.searchParams.set("limit", String(limit))
  url.searchParams.set("order", "desc")
  if (directory) url.searchParams.set("directory", directory)

  const response = await fetch(url, {
    headers: { authorization: `Basic ${Buffer.from(`opencode:${service.password}`).toString("base64")}` },
  })
  if (!response.ok) throw new Error(`GET /api/session failed: HTTP ${response.status}`)

  const body = (await response.json()) as { data?: unknown } | unknown[]
  const data = Array.isArray(body) ? body : body?.data
  return Array.isArray(data) ? (data as SessionInfo[]) : []
}

/**
 * Turn the recent messages into a short plain-text excerpt. Returns `undefined`
 * when the session does not have enough conversation to title yet, so a session
 * with a single stray message is left alone.
 */
function buildTranscript(messages: RawMessage[], options: Options): string | undefined {
  const entries: Array<{ index: number; role: string; text: string }> = []
  messages.forEach((message, index) => {
    const text = textOf(message)
    if (text && text.trim().length > 0) entries.push({ index, role: roleOf(message), text: text.trim() })
  })

  if (entries.length < options.minMessages) return undefined

  // Always include the first message (it usually states the task) plus the
  // most recent messages (they show where the work landed).
  const keep = new Set<number>()
  keep.add(0)
  for (let i = Math.max(0, entries.length - 8); i < entries.length; i++) keep.add(i)

  const chunks: string[] = []
  let total = 0
  for (const position of [...keep].sort((a, b) => a - b)) {
    const entry = entries[position]
    const line = `[${entry.role}] ${clip(entry.text, 700)}`
    if (total + line.length > options.maxTranscriptChars && chunks.length > 0) break
    chunks.push(line)
    total += line.length + 1
  }

  return chunks.length > 0 ? chunks.join("\n") : undefined
}

function buildPrompt(transcript: string, options: Options): string {
  return `${options.instructions}\n\n--- Conversation excerpt ---\n${transcript}\n--- End of excerpt ---\nTitle:`
}

function textOf(message: RawMessage): string | undefined {
  if (message.type === "user") return message.text
  if (message.type === "synthetic" || message.type === "system") return message.text
  if (message.type === "assistant") {
    const parts = (message.content ?? []).filter((part) => part.type === "text" && part.text)
    return parts.map((part) => part.text).join("\n")
  }
  return undefined
}

function roleOf(message: RawMessage): string {
  if (message.type === "assistant") return "assistant"
  if (message.type === "user") return "user"
  if (message.type === "synthetic") return "note"
  if (message.type === "system") return "system"
  return "message"
}

/** Normalize a model reply into a title. Returns `undefined` when unusable. */
function cleanTitle(raw: string, maxChars: number): string | undefined {
  const firstLine = raw
    .split("\n")
    .map((line) => line.trim())
    .find((line) => line.length > 0)
  if (!firstLine) return undefined

  let title = firstLine
    .replace(/^#+\s*/, "")
    .replace(/^title\s*[:\-]\s*/i, "")
    .replace(/^["'“”‘’`]+|["'“”‘’`]+$/g, "")
    .replace(/\s+/g, " ")
    .replace(/[.。,;:]+$/, "")
    .trim()

  if (title.length > maxChars) {
    title = title.slice(0, maxChars)
    const lastSpace = title.lastIndexOf(" ")
    if (lastSpace > maxChars * 0.6) title = title.slice(0, lastSpace)
    title = title.replace(/[.。,;:\-]+$/, "").trim()
  }

  return title.length >= 3 ? title : undefined
}

function clip(text: string, max: number): string {
  if (text.length <= max) return text
  const cut = text.slice(0, max)
  const lastSpace = cut.lastIndexOf(" ")
  return `${(lastSpace > max * 0.6 ? cut.slice(0, lastSpace) : cut).trim()}…`
}

function quote(text: string | undefined): string {
  const value = (text ?? "").replace(/\s+/g, " ").trim()
  if (value.length === 0) return "(untitled)"
  return `"${value.length > 60 ? `${value.slice(0, 57)}…` : value}"`
}

function normalize(raw: Plugin.Context["options"]): Options {
  const options = (raw ?? {}) as Record<string, unknown>
  const positive = (value: unknown, fallback: number, min = 1) =>
    typeof value === "number" && Number.isFinite(value) && value >= min ? Math.floor(value) : fallback
  const bool = (value: unknown, fallback: boolean) => (typeof value === "boolean" ? value : fallback)
  const model = (value: unknown): ModelRef | undefined => {
    if (!value || typeof value !== "object") return undefined
    const record = value as Record<string, unknown>
    const providerID = typeof record.providerID === "string" ? record.providerID : undefined
    const id = typeof record.id === "string" ? record.id : typeof record.modelID === "string" ? record.modelID : undefined
    const variant = typeof record.variant === "string" ? record.variant : undefined
    return providerID && id ? { providerID, id, variant } : undefined
  }

  const intervalMs = Math.max(10_000, positive(options.intervalMs, 60 * 60 * 1_000, 10_000))

  return {
    intervalMs,
    jitterMs: positive(options.jitterMs, 5 * 60 * 1_000, 0),
    startDelayMs: positive(options.startDelayMs, 60_000, 0),
    runOnStart: bool(options.runOnStart, true),
    activeWindowMs: positive(options.activeWindowMs, 24 * 60 * 60 * 1_000),
    maxPerRun: positive(options.maxPerRun, 5),
    scanLimit: positive(options.scanLimit, 100),
    minMessages: positive(options.minMessages, 2),
    maxTitleChars: positive(options.maxTitleChars, 60, 8),
    maxTranscriptChars: positive(options.maxTranscriptChars, 4_000, 500),
    stateTtlMs: positive(options.stateTtlMs, 7 * 24 * 60 * 60 * 1_000),
    includeChildren: bool(options.includeChildren, false),
    includeArchived: bool(options.includeArchived, false),
    scope: options.scope === "all" ? "all" : "location",
    model: model(options.model),
    instructions: typeof options.instructions === "string" && options.instructions.trim() ? options.instructions : DEFAULT_INSTRUCTIONS,
    dryRun: bool(options.dryRun, false),
    debug: bool(options.debug, false),
  }
}
