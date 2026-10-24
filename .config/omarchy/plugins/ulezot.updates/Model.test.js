const test = require("node:test")
const assert = require("node:assert/strict")
const Model = require("./Model.js")

test("parseUpdates keeps the four TSV fields and sorts by package name", () => {
  const raw = [
    "extra\tzellij\t0.41.2-1\t0.42.0-1",
    "omarchy\tt3code-nightly-bin\t1.0-1\t1.1-1",
    ""
  ].join("\n")

  assert.deepEqual(Model.parseUpdates(raw), [
    {
      repo: "omarchy",
      name: "t3code-nightly-bin",
      oldVersion: "1.0-1",
      newVersion: "1.1-1"
    },
    {
      repo: "extra",
      name: "zellij",
      oldVersion: "0.41.2-1",
      newVersion: "0.42.0-1"
    }
  ])
})

test("parseUpdates ignores malformed and empty lines", () => {
  const raw = [
    "",
    "extra\tbroken",
    "extra\tno-candidate\t1.0-1",
    "extra\tlinux\t6.12.1-1\t6.12.2-1\tunexpected",
    " \t \t \t "
  ].join("\n")

  assert.deepEqual(Model.parseUpdates(raw), [
    {
      repo: "extra",
      name: "linux",
      oldVersion: "6.12.1-1",
      newVersion: "6.12.2-1"
    }
  ])
})

test("groupUpdates sorts repositories and always places AUR last", () => {
  const system = [
    { repo: "extra", name: "mesa", oldVersion: "1", newVersion: "2" },
    { repo: "core", name: "bash", oldVersion: "1", newVersion: "2" },
    { repo: "extra", name: "zellij", oldVersion: "1", newVersion: "2" }
  ]
  const aur = [{ repo: "AUR", name: "yay", oldVersion: "1", newVersion: "2" }]

  const groups = Model.groupUpdates(system, aur)

  assert.deepEqual(
    groups.map(group => [group.repo, group.count]),
    [
      ["core", 1],
      ["extra", 2],
      ["AUR", 1]
    ]
  )
  assert.equal(groups[1].packages[0].name, "mesa")
})

test("groupUpdates returns no AUR section when the AUR has no updates", () => {
  const groups = Model.groupUpdates(
    [{ repo: "extra", name: "mesa", oldVersion: "1", newVersion: "2" }],
    []
  )

  assert.deepEqual(groups.map(group => group.repo), ["extra"])
})

test("relativeTime describes fresh and older checks", () => {
  const now = 1_700_000_000_000

  assert.equal(Model.relativeTime(0, now), "")
  assert.equal(Model.relativeTime(now - 30_000, now), "just now")
  assert.equal(Model.relativeTime(now - 60_000, now), "1 min ago")
  assert.equal(Model.relativeTime(now - 12 * 60_000, now), "12 min ago")
  assert.equal(Model.relativeTime(now - 60 * 60_000, now), "1 h ago")
  assert.equal(Model.relativeTime(now - 26 * 60 * 60_000, now), "1 d ago")
})

test("firstLine returns the first non-empty error line", () => {
  assert.equal(Model.firstLine("\n  Cannot fetch updates  \nmore"), "Cannot fetch updates")
  assert.equal(Model.firstLine(""), "")
})
