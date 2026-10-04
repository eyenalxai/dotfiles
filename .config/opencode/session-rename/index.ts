import type { Plugin } from "@opencode/plugin"

/**
 * Adds a `/rename` slash command that retitles the current session from its own
 * conversation.
 *
 * The command runs entirely server-side and does not touch the transcript: it
 * reads the session with `session.context`, asks a model for a short title with
 * `generate.text` (a transient request that adds nothing to session history),
 * and applies the result with `session.update`. Invoking `/rename <text>`
 * skips generation and uses `<text>` as the title.
 *
 * Local plugins cannot import the runtime `@opencode/plugin` package: OpenCode
 * does not install it next to this file, so the bare specifier fails to
 * resolve. The default export is therefore the plain definition object the
 * loader accepts, and the `import type` above is erased when Bun executes the
 * file (it only provides editor types).
 *
 * Options:
 * - `model`: title model as `providerID/modelID` or `providerID/modelID#variant`.
 *   Defaults to the session's current model, then the server default.
 * - `maxChars`: maximum title length. Default 60.
 * - `maxMessages`: how many recent messages to feed the title model. Default 24.
 * - `maxTranscriptChars`: transcript budget in characters. Default 8000.
 */

type Context = Plugin.Context
type Messages = Awaited<ReturnType<Context["session"]["context"]>>
type Message = Messages[number]
type TitleModel = { readonly id: string; readonly providerID: string; readonly variant?: string }

export default {
  id: "session-rename",
  async setup(ctx: Context) {
    const maxChars = positiveInt(ctx.options.maxChars, 60)
    const maxMessages = positiveInt(ctx.options.maxMessages, 24)
    const maxTranscriptChars = positiveInt(ctx.options.maxTranscriptChars, 8_000)
    const configuredModel = parseModel(ctx.options.model)

    await ctx.command.transform((editor) => {
      editor.add({
        name: "rename",
        description: "Rename this session with a title generated from the conversation",
        async execute({ sessionID, prompt }) {
          try {
            const manual = argumentTitle(prompt.text)
            const title =
              manual ??
              (await generateTitle(ctx, sessionID, { maxChars, maxMessages, maxTranscriptChars, configuredModel }))
            if (!title) {
              console.warn(`[session-rename] no title generated for ${sessionID}`)
              return
            }
            await ctx.session.update({ sessionID, title })
            console.log(`[session-rename] renamed ${sessionID} to "${title}"`)
          } catch (error) {
            console.error(`[session-rename] failed to rename ${sessionID}`, error)
            throw error
          }
        },
      })
    })
  },
}

async function generateTitle(
  ctx: Context,
  sessionID: string,
  options: {
    maxChars: number
    maxMessages: number
    maxTranscriptChars: number
    configuredModel: TitleModel | undefined
  },
): Promise<string | undefined> {
  const [session, messages] = await Promise.all([
    ctx.session.get({ sessionID }),
    ctx.session.context({ sessionID }),
  ])
  const transcript = buildTranscript(messages, options.maxMessages, options.maxTranscriptChars)
  if (!transcript) return undefined

  const model = options.configuredModel ?? session.model
  const prompt = [
    "Write a short, specific title for the conversation below.",
    `Rules: reply with only the title; no quotes, no markdown, no trailing punctuation; at most ${options.maxChars} characters; write it in the language the conversation uses.`,
    "",
    "<conversation>",
    transcript,
    "</conversation>",
  ].join("\n")

  const result = await ctx.generate.text(model ? { prompt, model } : { prompt })
  return cleanTitle(result.text, options.maxChars)
}

function buildTranscript(messages: Messages, maxMessages: number, maxTranscriptChars: number): string | undefined {
  const lines: string[] = []
  for (const message of messages) {
    const text = messageText(message)
    if (text) lines.push(`${message.type === "user" ? "User" : "Assistant"}: ${clip(text, 1_200)}`)
  }
  if (lines.length === 0) return undefined

  // Keep the opening message (it usually states the task) plus the most recent
  // ones, so a long conversation still yields a relevant title.
  const selected =
    lines.length <= maxMessages || maxMessages <= 1
      ? lines.slice(0, maxMessages)
      : [lines[0]!, ...lines.slice(-(maxMessages - 1))]
  let transcript = selected.join("\n\n")
  if (transcript.length > maxTranscriptChars) transcript = transcript.slice(-maxTranscriptChars)
  return transcript
}

function messageText(message: Message): string | undefined {
  if (message.type === "user") return message.text
  if (message.type === "assistant") {
    const text = message.content
      .filter((part) => part.type === "text")
      .map((part) => part.text)
      .join("\n")
      .trim()
    return text || undefined
  }
  return undefined
}

function clip(text: string, limit: number): string {
  const normalized = text.trim()
  return normalized.length <= limit ? normalized : `${normalized.slice(0, limit)}…`
}

function cleanTitle(raw: string, maxChars: number): string | undefined {
  let title = raw.replace(/\s+/g, " ").trim()
  title = title.replace(/^[`"'“”‘’]+/, "").replace(/[`"'“”‘’]+$/, "")
  title = title.replace(/^(?:title|session title)\s*[:\-–—]\s*/i, "")
  title = title.replace(/[.。]+$/, "").trim()
  if (!title) return undefined
  if (title.length <= maxChars) return title

  const clipped = title.slice(0, maxChars)
  const lastSpace = clipped.lastIndexOf(" ")
  const shortened = lastSpace >= Math.floor(maxChars * 0.6) ? clipped.slice(0, lastSpace) : clipped
  return `${shortened.trimEnd()}…`
}

function argumentTitle(text: string): string | undefined {
  const trimmed = text.trim()
  if (!trimmed) return undefined
  const argument = trimmed.replace(/^\/rename\b\s*/i, "").trim()
  return argument || undefined
}

function parseModel(value: unknown): TitleModel | undefined {
  if (typeof value !== "string") return undefined
  const [reference, variant] = value.split("#", 2)
  const separator = reference!.indexOf("/")
  if (separator <= 0 || separator === reference!.length - 1) {
    console.warn(`[session-rename] ignoring invalid model "${value}"`)
    return undefined
  }
  return {
    providerID: reference!.slice(0, separator),
    id: reference!.slice(separator + 1),
    ...(variant ? { variant } : {}),
  }
}

function positiveInt(value: unknown, fallback: number): number {
  return typeof value === "number" && Number.isSafeInteger(value) && value > 0 ? value : fallback
}
