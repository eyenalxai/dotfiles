import { describe, expect, test } from "bun:test"
import { takeAppearance, topMoves } from "../new-tabs"

describe("takeAppearance", () => {
  test("stays unseeded while the list is empty", () => {
    const state = takeAppearance(undefined, [])
    expect(state.known).toBeUndefined()
    expect(state.appeared).toEqual([])
  })

  test("seeds on the first non-empty list without reporting tabs", () => {
    const state = takeAppearance(undefined, ["a", "b"])
    expect(state.appeared).toEqual([])
    expect(state.known && [...state.known]).toEqual(["a", "b"])
  })

  test("reports only ids that were never seen", () => {
    const state = takeAppearance(new Set(["a", "b"]), ["a", "b", "c"])
    expect(state.appeared).toEqual(["c"])
    expect(state.known?.has("c")).toBe(true)
  })

  test("does not report the same id twice", () => {
    const first = takeAppearance(new Set(["a"]), ["a", "b"])
    expect(first.appeared).toEqual(["b"])
    const second = takeAppearance(first.known, ["a", "b"])
    expect(second.appeared).toEqual([])
  })

  test("keeps ids that left the list, so a reopened tab is not new", () => {
    const closed = takeAppearance(new Set(["a", "b"]), ["a"])
    expect(closed.appeared).toEqual([])
    const reopened = takeAppearance(closed.known, ["a", "b"])
    expect(reopened.appeared).toEqual([])
  })

  test("reports a batch of appearances in list order", () => {
    const state = takeAppearance(new Set(["a"]), ["a", "b", "c", "d"])
    expect(state.appeared).toEqual(["b", "c", "d"])
  })

  test("hydration after an empty first read seeds instead of reordering", () => {
    const empty = takeAppearance(undefined, [])
    const hydrated = takeAppearance(empty.known, ["a", "b", "c"])
    expect(hydrated.appeared).toEqual([])
    expect(hydrated.known && [...hydrated.known]).toEqual(["a", "b", "c"])
  })
})

describe("topMoves", () => {
  test("returns nothing when nothing appeared", () => {
    expect(topMoves([])).toEqual([])
  })

  test("moves a single tab to index 0", () => {
    expect(topMoves(["x"])).toEqual([{ sessionID: "x", index: 0 }])
  })

  test("applied in order, a batch lands at the top in appearance order", () => {
    const order = ["old1", "old2", "a", "b", "c"]
    for (const move of topMoves(["a", "b", "c"])) {
      const from = order.indexOf(move.sessionID)
      order.splice(from, 1)
      order.splice(move.index, 0, move.sessionID)
    }
    expect(order).toEqual(["a", "b", "c", "old1", "old2"])
  })
})
