import type { Plugin } from "@opencode/plugin"

/**
 * Caps model context windows so OpenCode's built-in auto-compaction triggers at
 * the configured budget instead of the provider's native window.
 *
 * The plugin changes `model.limit.context` (and `limit.input` when present)
 * through a catalog transform. OpenCode derives its automatic compaction
 * threshold from those limits, so no compaction logic is duplicated here.
 * OpenCode still compacts before a window is full, reserving room for the
 * model's output and its compaction buffer, exactly as it does for native
 * windows.
 *
 * Local plugins cannot import the runtime `@opencode/plugin` package: OpenCode
 * does not install it next to this file, so the bare specifier fails to
 * resolve. The default export is therefore the plain definition object the
 * loader accepts, and the `import type` above is erased when Bun executes the
 * file (it only provides editor types).
 */

type Cap = number | false

type Rule = {
  readonly pattern: string
  readonly regExp: RegExp
  readonly cap: Cap
  readonly specificity: number
}

export default {
  id: "max-context",
  async setup(ctx: Plugin.Context) {
    const rules = compile(ctx.options)
    if (rules.length === 0) {
      console.warn("[max-context] no maxContext or models option configured; plugin inactive")
      return
    }
    console.log(`[max-context] capping context windows with ${rules.length} rule(s)`)
    await ctx.catalog.transform((catalog) => {
      for (const provider of catalog.provider.list()) {
        for (const model of provider.models.values()) {
          const cap = select(rules, `${model.providerID}/${model.id}`)
          if (cap === undefined) continue
          // A non-positive window means the catalog does not know it. Core skips
          // automatic compaction for those models, so use the configured cap as
          // the assumed window instead of leaving them uncompacted.
          model.limit.context = model.limit.context > 0 ? Math.min(model.limit.context, cap) : cap
          if (model.limit.input !== undefined)
            model.limit.input = model.limit.input > 0 ? Math.min(model.limit.input, cap) : cap
        }
      }
    })
  },
}

/**
 * Options:
 * - `maxContext`: cap applied to every model. Number of tokens, or `false` to
 *   leave models uncapped.
 * - `models`: per-model caps keyed by `providerID/modelID`. `*` matches any
 *   run of characters. More specific patterns win; ties go to the later entry,
 *   so `models` beats `maxContext`. `false` opts a model out of every cap.
 *
 * Example:
 *   {
 *     "maxContext": 100000,
 *     "models": {
 *       "openrouter/anthropic/*": 200000,
 *       "openrouter/openai/gpt-5.2": false
 *     }
 *   }
 */
function compile(options: Plugin.Context["options"]): Rule[] {
  const configured: Array<readonly [string, unknown]> = [
    ...(options.maxContext === undefined ? [] : ([["*", options.maxContext]] as const)),
    ...(isRecord(options.models) ? Object.entries(options.models) : []),
  ]
  return configured.flatMap(([pattern, value]) => {
    const cap = parseCap(value)
    if (cap === undefined) {
      console.warn(`[max-context] ignoring invalid cap for "${pattern}"`, value)
      return []
    }
    return [{ pattern, cap, regExp: toRegExp(pattern), specificity: pattern.replaceAll("*", "").length }]
  })
}

function select(rules: readonly Rule[], id: string): number | undefined {
  let selected: Rule | undefined
  for (const rule of rules) {
    if (!rule.regExp.test(id)) continue
    if (selected === undefined || rule.specificity >= selected.specificity) selected = rule
  }
  return typeof selected?.cap === "number" ? selected.cap : undefined
}

function parseCap(value: unknown): Cap | undefined {
  if (value === false) return false
  if (typeof value === "number" && Number.isSafeInteger(value) && value > 0) return value
  return undefined
}

function toRegExp(pattern: string) {
  return new RegExp(`^${pattern.replace(/[.+?^${}()|[\]\\]/g, "\\$&").replaceAll("*", ".*")}$`)
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value)
}
