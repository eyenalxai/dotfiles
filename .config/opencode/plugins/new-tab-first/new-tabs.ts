// Pure bookkeeping for the "new tabs open on top" rule. No TUI, no files, no
// Solid: the plugin wiring lives in `tui.ts` so this logic can be tested
// offline and exhaustively.

export type TopMove = {
  readonly sessionID: string
  readonly index: number
}

export type Appearance = {
  /** IDs that were not in the previous snapshot, in list order. */
  readonly appeared: readonly string[]
  /** The updated snapshot. */
  readonly known: Set<string> | undefined
}

/**
 * Advance the known-tab snapshot and report which tabs appeared.
 *
 * - The first non-empty list seeds the snapshot and reports nothing, so
 *   loading or hot-reloading the plugin never reorders the tabs that are
 *   already open.
 * - An empty list keeps the snapshot unseeded, riding out the moment before
 *   persisted tabs arrive; seeding on empty would later misread the hydrated
 *   tabs as brand new.
 * - IDs are only ever added. A closed tab that is reopened later is not new,
 *   so it stays where reopening puts it.
 */
export function takeAppearance(known: Set<string> | undefined, ids: readonly string[]): Appearance {
  if (known === undefined) {
    if (ids.length === 0) return { appeared: [], known: undefined }
    return { appeared: [], known: new Set(ids) }
  }
  const appeared = ids.filter((id) => !known.has(id))
  if (appeared.length === 0) return { appeared, known }
  const next = new Set(known)
  for (const id of ids) next.add(id)
  return { appeared, known: next }
}

/**
 * One `move(id, 0)` per new tab, newest first. Inserting each at the top in
 * reverse order leaves a batch of simultaneous appearances at the top in the
 * order they appeared: [old, a, b, c] + moves for [a, b, c] -> [a, b, c, old].
 */
export function topMoves(appeared: readonly string[]): TopMove[] {
  return [...appeared].reverse().map((sessionID) => ({ sessionID, index: 0 }))
}
