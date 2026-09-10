#!/usr/bin/env nu
# opencode_sync.nu: Mirror OpenCode V2 chat transcripts through the yadm archive
#
#   opencode_sync.nu export   refresh the JSON export of every local session
#   opencode_sync.nu import   import sessions from those exports into the service
#
# export runs from the yadm pre_encrypt hook and import from post_decrypt. The
# exports directory is tracked by yadm, so it travels inside the archive.
#
# Sync is additive and session-level. A session that was continued on two
# machines is not merged: the incoming transcript is imported as an additional
# session whose title is marked "(unmerged copy <date>)", so both versions are
# kept. Deletions are not synced either; a session that still exists on another
# machine can come back until both sides have deleted it.
#
# Three nushell quirks shape how opencode2 is called here; keep them in mind
# when changing this file:
#
#   * Nushell truncates large external command output when it flows through a
#     pipe, so `... | complete` and `... | save` can silently lose data. Sending
#     the streams to files with `out>`/`err>` bypasses nushell's reader and
#     always captures everything.
#   * `save` on a record writes control characters unescaped (for example the
#     escape codes inside terminal transcripts), which makes the file invalid
#     JSON. Serialize records explicitly with `to json --raw | save`.
#   * Nushell runs every external command through its hidden `run-external`
#     command, so a custom command with that name replaces it and breaks every
#     `^command`. The redirection helper below is called `run-redirected`.

# New files are private (0600); directories are created as 0700.
umask rwx------

# Path of a private temporary file. Callers remove the file when done.
def temp-file [label: string] {
    $nu.temp-dir | path join $"opencode_sync_($label)_(random chars --length 12)"
}

# Text of a file, or an empty string when it cannot be read.
def read-text [file: path] {
    try { open --raw $file } catch { "" }
}

# Parsed JSON from a file. Temporary files have no .json extension, so `open`
# cannot infer the format; `from json` makes the parse explicit.
def read-json [file: path] {
    open --raw $file | from json
}

# Directory holding one JSON export per session.
def exports-dir [] {
    $nu.home-dir | path join ".local/share/opencode/exports"
}

# Whether the opencode2 CLI is installed.
def has-opencode2 [] {
    (which opencode2 | length) > 0
}

# Run a command with its output redirected to files. Returns true when the
# command ran and exited successfully. Do not name this `run-external`: that is
# nushell's hidden command for running all externals, and shadowing it breaks
# every `^command` in the process.
def run-redirected [stdout: path, stderr: path, body: closure] {
    try {
        do $body out> $stdout err> $stderr
        true
    } catch {
        false
    }
}

# IDs of every session known to the service, or null when it cannot be reached.
def session-ids [] {
    let file = (temp-file "sessions")
    let errfile = (temp-file "sessions-err")
    let ok = (run-redirected $file $errfile { ^opencode2 api get '/api/session?limit=10000' })
    let error = (read-text $errfile)
    let ids = (try { read-json $file | get data | get id } catch { null })
    rm --force $file $errfile
    if not $ok {
        print -e $"opencode_sync: could not list sessions: ($error | str trim)"
        null
    } else if $ids == null {
        print -e "opencode_sync: could not understand the session list"
        null
    } else {
        $ids
    }
}

# Export one session to a file with the service's own JSON. Returns true when
# the service exited successfully; the caller still verifies the file parses.
def export-to-file [id: string, file: path] {
    let errfile = (temp-file "export-err")
    let ok = (run-redirected $file $errfile { ^opencode2 export $id })
    let error = (read-text $errfile)
    rm --force $errfile
    if not $ok {
        print -e $"opencode_sync: could not export session ($id): ($error | str trim)"
    }
    $ok
}

# Hash of the transcript content. Message IDs are ignored because a conflict
# copy rewrites them, and session metadata such as projectID or time.updated
# differs between machines. Only what was actually said is compared.
def transcript-hash [session: record] {
    $session.messages | each {|message| $message | upsert id null } | to json --raw | hash sha256
}

# Fresh OpenCode-style identifier: a prefix and 24 random alphanumeric chars.
def random-id [prefix: string] {
    $prefix + (random chars --length 24)
}

# Title marking a transcript that is kept next to an unmerged twin.
def marked-title [title: string] {
    $"($title) \(unmerged copy (date now | format date '%Y-%m-%d')\)"
}

# Local index: one record per session with the hash of its transcript.
# Returns null when the service cannot be reached.
def local-index [] {
    let ids = (session-ids)
    if $ids == null {
        return null
    }
    $ids | each {|id|
        let file = (temp-file "index")
        export-to-file $id $file | ignore
        let hash = (try { transcript-hash (read-json $file) } catch { null })
        rm --force $file
        { id: $id, hash: $hash }
    }
}

# Transcript hash recorded for a local session ID, or null when there is none.
def local-hash [index: list<record>, id: string] {
    $index | where id == $id | get hash | first | default null
}

# Whether any local session has this transcript.
def hash-present [index: list<record>, hash: string] {
    $index | any {|session| $session.hash == $hash }
}

# Importable copy of a conflicting session: fresh session and message IDs and a
# title that says what happened.
def conflict-copy [session: record] {
    let title = ((try { $session.info.title? } catch { null }) | default "Untitled")
    {
        info: ($session.info | update id (random-id "ses_") | upsert title (marked-title $title))
        messages: ($session.messages | each {|message| $message | update id (random-id "msg_") })
    }
}

# Directory to import a session into: its original directory when that exists
# locally, otherwise the home directory.
def import-directory [session: record] {
    let directory = ((try { $session.info.location.directory? } catch { null }) | default "")
    if ($directory | is-empty) or (not ($directory | path exists)) {
        $nu.home-dir
    } else {
        $directory
    }
}

# Import a session file into the service. Returns "imported", "present" (the
# service already has it) or "failed".
def import-file-at [file: path, directory: string] {
    let outfile = (temp-file "import-out")
    let errfile = (temp-file "import-err")
    let status = (try {
        let ok = (run-redirected $outfile $errfile { ^opencode2 import $file --directory $directory })
        let output = ((read-text $outfile) + (read-text $errfile))
        if ($output | str contains --ignore-case "already exists") {
            "present"
        } else if not $ok {
            print -e $"opencode_sync: import failed: ($output | str trim)"
            "failed"
        } else {
            "imported"
        }
    } catch {|error|
        print -e $"opencode_sync: import failed: ($error.msg)"
        "failed"
    })
    rm --force $outfile $errfile
    $status
}

# Serialize a session value to a temporary file and import it. Used for
# conflict copies, whose IDs are rewritten.
def import-session-value [session: record, directory: string] {
    let file = (temp-file "import")
    let status = (try {
        $session | to json --raw | save --force $file
        import-file-at $file $directory
    } catch {|error|
        print -e $"opencode_sync: import failed: ($error.msg)"
        "failed"
    })
    rm --force $file
    $status
}

# Import one export file. A transcript that is already present locally is
# skipped; a conflicting version of a known session is imported as a marked
# copy. Returns a status record.
def import-file [file: path, index: list<record>] {
    let session = (try { read-json $file } catch { null })
    let hash = (try { transcript-hash $session } catch { null })
    let id = (try { $session.info.id? } catch { null })
    if $session == null or $hash == null or $id == null {
        print -e $"opencode_sync: could not read ($file); leaving it alone"
        return { status: "failed", file: $file }
    }
    let empty = ($session.messages | default [] | is-empty)
    let status = if (local-hash $index $id) == $hash {
        "present"
    } else if (not $empty) and (hash-present $index $hash) {
        "present"
    } else if ($index | any {|entry| $entry.id == $id }) {
        let copied = (try {
            import-session-value (conflict-copy $session) (import-directory $session)
        } catch {|error|
            print -e $"opencode_sync: could not copy session ($id): ($error.msg)"
            "failed"
        })
        if $copied == "imported" { "unmerged" } else { $copied }
    } else {
        import-file-at $file (import-directory $session)
    }
    { status: $status, file: $file }
}

# Refresh the export file of one session. Only transcript changes rewrite a
# file, so machine-specific metadata does not churn through the archive.
# Returns a status record.
def export-session [id: string] {
    let path = (exports-dir | path join $"($id).json")
    let temporary = ($path + ".tmp")
    if not (export-to-file $id $temporary) {
        rm --force $temporary
        return { status: "failed" }
    }
    let fresh = (try { transcript-hash (read-json $temporary) } catch { null })
    if $fresh == null {
        print -e $"opencode_sync: export of session ($id) is not valid JSON"
        rm --force $temporary
        return { status: "failed" }
    }
    let current = (try { transcript-hash (read-json $path) } catch { null })
    if $fresh == $current {
        rm --force $temporary
        return { status: "unchanged" }
    }
    mv --force $temporary $path
    { status: "exported" }
}

# Remove exports of sessions that no longer exist locally. Returns the count.
def prune-stale [ids: list<string>] {
    let stale = (glob ((exports-dir) | path join "*.json")
        | where {|file| ($file | path basename | str replace --regex '\.json$' '') not-in $ids })
    $stale | each {|file| rm --force $file }
    $stale | length
}

# Restrict the exports directory and its files to the current user.
def secure-exports [] {
    let dir = (exports-dir)
    mkdir $dir
    ^chmod 700 $dir
    let files = (glob ($dir | path join "*.json"))
    if ($files | length) > 0 {
        ^chmod 600 ...$files
    }
}

# Refresh the JSON exports of every local session.
def "main export" [] {
    if not (has-opencode2) {
        print -e "opencode_sync: opencode2 not found; skipping export"
        return
    }
    secure-exports
    let ids = (session-ids)
    if $ids == null {
        print -e "opencode_sync: could not list sessions; skipping export"
        return
    }
    let results = ($ids | each {|id| export-session $id })
    let stale = (prune-stale $ids)
    let exported = ($results | where status == "exported" | length)
    let unchanged = ($results | where status == "unchanged" | length)
    let failed = ($results | where status == "failed" | length)
    let total = ($ids | length)
    print $"✓ OpenCode chats exported: ($total) sessions, ($exported) new/updated, ($unchanged) unchanged, ($failed) failed, ($stale) stale removed"
}

# Import sessions from the exports directory into the service.
def "main import" [] {
    if not (has-opencode2) {
        print -e "opencode_sync: opencode2 not found; skipping import"
        return
    }
    secure-exports
    let files = (glob ((exports-dir) | path join "*.json"))
    if ($files | length) == 0 {
        print "✓ OpenCode chats imported: 0 new, 0 already present, 0 unmerged copies, 0 failed"
        return
    }
    let index = (local-index)
    if $index == null {
        print -e "opencode_sync: could not read local sessions; skipping import"
        return
    }
    let results = ($files | each {|file| import-file $file $index })
    let imported = ($results | where status == "imported" | length)
    let present = ($results | where status == "present" | length)
    let unmerged = ($results | where status == "unmerged" | length)
    let failed = ($results | where status == "failed" | length)
    print $"✓ OpenCode chats imported: ($imported) new, ($present) already present, ($unmerged) unmerged copies, ($failed) failed"
}

# Print usage information.
def main [] {
    print "usage: opencode_sync.nu {export|import}"
}
