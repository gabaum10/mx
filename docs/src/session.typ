#import "lib.typ": *

#page-header("Session", "Deprecated session export.")

#deprecated[
  `mx session` is deprecated. Use #link("codex.html")[`mx codex export`] instead.
]

== What it was

`mx session export` exported the most recent Claude session as markdown. It
walked `~/.claude/projects/`, found the newest non-agent session JSONL by mtime,
and rendered it to stdout or a file.

This functionality now lives in `mx codex export`, which reads from the codex
archive, supports filtering by `--session`, `--project`, and `--date`, offers
multiple output formats, and inlines sub-agent transcripts by default.

== Current behavior

The command still works. Running it will:

+ Print a deprecation notice to stderr.
+ Run `mx codex archive --all` to ensure live sessions are ingested.
+ Forward to `mx codex export` with markdown output and default-clean includes.

The old flags are accepted:

#command("mx session export [path] [-o output]",
  [Export a session as markdown. Thin alias for `mx codex export`.],
  flags: (
    ([`path`], [positional], [Path to a session JSONL file, or a bare UUID.
    Omit for the most recent session.]),
    ([`-o`, `--output`], [path], [Output file. Defaults to stdout.]),
  ),
)

== Replacement

See #link("codex.html")[Codex] for the full replacement command surface.
