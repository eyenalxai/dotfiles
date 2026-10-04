import type { Plugin } from "@opencode/plugin"

/**
 * OpenCode Go account failover.
 *
 * OpenCode Go usage limits apply per account, across 5-hour, weekly, and
 * monthly windows. When the account in use reaches a limit, requests fail with
 * a quota error even though other saved OpenCode Go accounts may still have
 * headroom.
 *
 * This plugin keeps using one saved OpenCode Go account until it reports a
 * usage limit, then selects the next available account, authenticates the
 * retried request with it, and lets the request continue. Accounts that hit a
 * limit are parked for a cooldown; repeated limits back off exponentially up
 * to a cap.
 *
 * The plugin authenticates requests through the `http.request` session hook
 * instead of changing the globally active account, so it works per request and
 * does not fight a manual `/connect` account switch. When the active account
 * changes in the TUI, the plugin follows it.
 *
 * Local plugins cannot import the runtime `@opencode/plugin` package, so the
 * default export is the plain definition object the loader accepts; the
 * `import type` above is erased when Bun executes the file.
 */

type Account = {
  readonly id: string
  readonly label: string
  readonly key: string
}

type Exhaustion = {
  /** Epoch milliseconds after which the account may be tried again. */
  readonly until: number
  /** Consecutive quota failures, used for exponential backoff. */
  readonly strikes: number
}

type State = {
  /** Stable round-robin order of credential IDs. */
  order?: string[]
  /** Credential ID currently used for requests. */
  selected?: string
  /** Globally active credential ID the plugin last observed. */
  activeKnown?: string
  /** Credential IDs parked after a usage limit. */
  exhausted?: Record<string, Exhaustion>
}

type FailoverError = {
  type?: string
  message?: string
  status?: number
}

type Options = {
  integration: string
  provider: string
  retryDelayMs: number
  cooldownMs: number
  maxCooldownMs: number
  switchOnStatus: number[]
  switchOnTypes: string[]
  patterns: RegExp[]
  injectAuth: boolean
  debug: boolean
}

const REFRESH_INTERVAL_MS = 30_000

export default {
  id: "opencode-go-failover",
  async setup(ctx: Plugin.Context) {
    const options = normalize(ctx.options)
    const log = (...args: unknown[]) => console.log("[opencode-go-failover]", ...args)
    const debug = (...args: unknown[]) => {
      if (options.debug) log(...args)
    }

    let state = (await ctx.storage.get("state")) as State | undefined
    state ??= {}
    if (state.exhausted) {
      const cutoff = Date.now()
      for (const [id, entry] of Object.entries(state.exhausted)) {
        if (entry.until <= cutoff) delete state.exhausted[id]
      }
    }

    let accounts: Account[] = []
    let refreshedAt = 0
    let refreshing: Promise<Account[]> | undefined

    /** Credential each session's in-flight request used, for accurate marking. */
    const usedBySession = new Map<string, string>()

    const persist = async () => {
      try {
        await ctx.storage.set("state", state)
      } catch (error) {
        debug("failed to persist state:", String(error))
      }
    }

    const isExhausted = (id: string | undefined) => {
      if (!id) return false
      const entry = state.exhausted?.[id]
      return entry !== undefined && entry.until > Date.now()
    }

    const accountOf = (id: string | undefined) => accounts.find((account) => account.id === id)

    const labelOf = (id: string | undefined) => accountOf(id)?.label ?? id ?? "unknown account"

    const pruneExhausted = () => {
      const cutoff = Date.now()
      let changed = false
      for (const [id, entry] of Object.entries(state.exhausted ?? {})) {
        if (entry.until <= cutoff) {
          delete state.exhausted![id]
          changed = true
        }
      }
      return changed
    }

    const markExhausted = (id: string) => {
      const exhausted = (state.exhausted ??= {})
      const strikes = (exhausted[id]?.strikes ?? 0) + 1
      const cooldown = Math.min(options.cooldownMs * 2 ** (strikes - 1), options.maxCooldownMs)
      exhausted[id] = { until: Date.now() + cooldown, strikes }
      log(`parked ${labelOf(id)} for ${Math.round(cooldown / 60_000)}m after usage limit (strike ${strikes})`)
    }

    /** Next non-exhausted account after `currentID`, in round-robin order. */
    const chooseNext = (currentID: string | undefined): Account | undefined => {
      const order = state.order ?? []
      if (order.length === 0) return undefined
      const start = currentID === undefined ? 0 : order.indexOf(currentID) + 1
      for (let i = 0; i < order.length; i++) {
        const id = order[(start + i) % order.length]
        if (id !== currentID && !isExhausted(id)) return accountOf(id)
      }
      return undefined
    }

    /**
     * Account to use for a request: the current selection while it is healthy,
     * otherwise the next available account, otherwise the selection again so a
     * fully parked setup still reports the provider's own error.
     */
    const chooseAccount = (currentID: string | undefined): Account | undefined => {
      const current = accountOf(currentID)
      if (current && !isExhausted(current.id)) return current
      return chooseNext(currentID) ?? current ?? accounts[0]
    }

    const readActive = async (): Promise<string | undefined> => {
      try {
        const active = await ctx.integration.connection.active(options.integration)
        return active?.type === "credential" ? active.id : undefined
      } catch (error) {
        debug("could not read active connection:", String(error))
        return undefined
      }
    }

    const reconcile = async (list: Account[]) => {
      const ids = list.map((account) => account.id)
      const order = (state.order ?? []).filter((id) => ids.includes(id))
      for (const id of ids) if (!order.includes(id)) order.push(id)
      state.order = order

      const activeID = await readActive()
      if (state.selected && !ids.includes(state.selected)) state.selected = undefined
      if (!state.selected && ids.length > 0) {
        state.selected = activeID !== undefined && ids.includes(activeID) ? activeID : order[0]
      }
      if (activeID !== undefined) state.activeKnown = activeID
      pruneExhausted()
      await persist()
    }

    /**
     * Detect an account switch made outside the plugin (TUI `/connect` or
     * `auth switch`). The public event stream does not carry credential events,
     * so compare the globally active credential with the last observed one.
     * Failover selections never change the global account, so they are not
     * mistaken for manual switches.
     */
    const syncManualSwitch = async () => {
      const activeID = await readActive()
      if (activeID === undefined) return
      if (!accounts.some((account) => account.id === activeID)) await refreshAccounts(true)

      const known = state.activeKnown
      if (known !== undefined && known !== activeID && accounts.some((account) => account.id === activeID)) {
        state.selected = activeID
        delete state.exhausted?.[activeID]
        debug(`following manual switch to ${labelOf(activeID)}`)
      }
      if (known !== activeID) {
        state.activeKnown = activeID
        await persist()
      }
    }

    const refreshAccounts = async (force = false): Promise<Account[]> => {
      if (!force && accounts.length > 0 && Date.now() - refreshedAt < REFRESH_INTERVAL_MS) return accounts
      if (refreshing) return refreshing
      refreshing = (async () => {
        try {
          const listed = (await ctx.integration.list()) as unknown
          const integrations = ((listed as { data?: unknown[] }).data ?? listed) as Array<{
            id: string
            connections?: Array<{ type: string; id: string; label: string; method: string }>
          }>
          const integration = integrations.find((entry) => entry.id === options.integration)
          const connections = (integration?.connections ?? []).filter(
            (connection) => connection.type === "credential" && connection.method === "key",
          )
          const resolved: Account[] = []
          for (const connection of connections) {
            try {
              const value = await ctx.integration.connection.resolve(connection as never)
              if (value?.type === "key" && value.key) {
                resolved.push({ id: connection.id, label: connection.label, key: value.key })
              }
            } catch (error) {
              debug(`could not resolve ${connection.label}:`, String(error))
            }
          }
          accounts = resolved
          refreshedAt = Date.now()
          await reconcile(resolved)
          debug(
            "accounts:",
            resolved.map((account) => `${account.label}${account.id === state.selected ? " *" : ""}`).join(", ") ||
              "none",
          )
          return accounts
        } catch (error) {
          debug("failed to list accounts:", String(error))
          return accounts
        } finally {
          refreshing = undefined
        }
      })()
      return refreshing
    }

    const isQuotaError = (error: FailoverError) => {
      if (error.type !== undefined && options.switchOnTypes.includes(error.type)) return true
      if (error.status !== undefined && options.switchOnStatus.includes(error.status)) return true
      const message = error.message ?? ""
      return options.patterns.some((pattern) => pattern.test(message))
    }

    const setAuth = (headers: Headers, key: string) => {
      const hadAuthorization = headers.has("authorization")
      const hadApiKey = headers.has("x-api-key")
      if (hadAuthorization) headers.set("authorization", `Bearer ${key}`)
      if (hadApiKey) headers.set("x-api-key", key)
      if (!hadAuthorization && !hadApiKey) headers.set("authorization", `Bearer ${key}`)
    }

    // Resolve the first account list before registering hooks so the first
    // request does not depend on a lazy refresh.
    await refreshAccounts(true)

    await ctx.session.hook(
      "http.request",
      async (event) => {
        try {
          const list = await refreshAccounts()
          if (list.length === 0 || !options.injectAuth) return
          await syncManualSwitch()

          const account = chooseAccount(state.selected)
          if (!account) return

          if (account.id !== state.selected) {
            state.selected = account.id
            await persist()
            debug(`selected ${account.label} for request in session ${event.sessionID}`)
          }
          usedBySession.set(event.sessionID, account.id)
          if (usedBySession.size > 64) {
            const oldest = usedBySession.keys().next().value
            if (oldest !== undefined) usedBySession.delete(oldest)
          }
          setAuth(event.request.headers, account.key)
        } catch (error) {
          debug("http.request hook failed:", String(error))
        }
      },
      { providerID: options.provider },
    )

    await ctx.session.hook(
      "retry",
      async (event) => {
        try {
          if (!isQuotaError(event.error)) return
          await refreshAccounts()

          const failedID = usedBySession.get(event.sessionID) ?? state.selected
          usedBySession.delete(event.sessionID)
          if (!failedID) return

          markExhausted(failedID)
          const next = chooseNext(failedID)
          if (!next) {
            log(`usage limit on ${labelOf(failedID)}; no other account is available, surfacing the error`)
            await persist()
            return
          }

          state.selected = next.id
          await persist()
          log(`usage limit on ${labelOf(failedID)}; switching to ${next.label} and retrying`)
          event.decision = { retry: true, delay: options.retryDelayMs }
        } catch (error) {
          debug("retry hook failed:", String(error))
        }
      },
      { providerID: options.provider },
    )

    log(
      `watching ${options.integration} through provider ${options.provider}` +
        (options.debug ? " (debug logging enabled)" : ""),
    )
  },
}

function normalize(raw: Plugin.Context["options"]): Options {
  const options = (raw ?? {}) as Record<string, unknown>
  const string = (value: unknown, fallback: string) => (typeof value === "string" && value.length > 0 ? value : fallback)
  const positive = (value: unknown, fallback: number) =>
    typeof value === "number" && Number.isFinite(value) && value > 0 ? value : fallback
  const stringList = (value: unknown, fallback: string[]) =>
    Array.isArray(value) ? value.filter((entry): entry is string => typeof entry === "string") : fallback
  const numberList = (value: unknown, fallback: number[]) =>
    Array.isArray(value) ? value.filter((entry): entry is number => typeof entry === "number") : fallback

  const integration = string(options.integration, "opencode-go")
  const patterns = stringList(options.patterns, ["usage limit", "limit reached", "quota", "rate limit", "too many requests"])

  return {
    integration,
    provider: string(options.provider, integration),
    retryDelayMs: positive(options.retryDelayMs, 1_000),
    cooldownMs: positive(options.cooldownMs, 5 * 60 * 60 * 1_000),
    maxCooldownMs: positive(options.maxCooldownMs, 7 * 24 * 60 * 60 * 1_000),
    switchOnStatus: numberList(options.switchOnStatus, [429, 402]),
    switchOnTypes: stringList(options.switchOnTypes, ["provider.quota"]),
    patterns: patterns.map((pattern) => new RegExp(pattern, "i")),
    injectAuth: options.injectAuth !== false,
    debug: options.debug === true,
  }
}
