#import "lib.typ": *

#page-header("Wiki", "GitHub wiki page sync.")

== Overview

`mx wiki sync` pushes local markdown files to a GitHub repository's wiki. It
clones the wiki repo into a temporary directory, copies your files in with
sanitized page names, commits, and pushes -- all in one step.

This is a one-way sync: local files are copied to the wiki. Changes made
directly on the wiki through the GitHub UI are overwritten on the next sync.

== Sync

#command("mx wiki sync <repo> <source>",
  [Sync a local markdown file or directory to a GitHub wiki. The source can be
  a single `.md` file or a directory containing markdown files. Page names are
  derived from filenames: lowercased, spaces replaced with hyphens,
  non-alphanumeric characters stripped.],
  flags: (
    ([`repo`], [positional], [Repository in `owner/repo` format.]),
    ([`source`], [positional], [Path to a markdown file or directory of
    markdown files.]),
    ([`--page-name`], [string], [Custom page name for the wiki page. Only
    valid when syncing a single file. Ignored characters are stripped and
    the name is sanitized the same way as auto-derived names.]),
    ([`--dry-run`], [flag], [Preview what would be synced without cloning,
    committing, or pushing.]),
  ),
  examples: (
    "mx wiki sync coryzibell/mx docs/wiki/architecture.md",
    "mx wiki sync coryzibell/mx docs/wiki/architecture.md --page-name \"API Reference\"",
    "mx wiki sync coryzibell/mx docs/wiki/",
    "mx wiki sync coryzibell/mx docs/wiki/ --dry-run",
  ),
)

=== What sync does

+ Clones the wiki repository (`<repo>.wiki.git`) into a temporary directory
  using your GitHub token for authentication.
+ Copies each source file into the cloned wiki with a sanitized filename.
  If `--page-name` is provided, that name is used instead of the source
  filename.
+ Commits the changes with the message `"Sync from mx CLI"`.
+ Pushes to the wiki's `master` branch.
+ Prints the wiki URL and a list of synced pages.

The temporary clone is discarded after the push completes.

=== Page name sanitization

Filenames and custom page names go through the same sanitization pipeline:

+ Lowercased.
+ Spaces replaced with hyphens.
+ Non-alphanumeric characters (except hyphens) removed.
+ A `.md` extension is appended if not already present.

For example, `"API Reference (v2)"` becomes `api-reference-v2.md`.

=== Directory sync

When the source is a directory, every `.md` file in it is synced. Two
exceptions apply:

- Non-markdown files are silently skipped.
- Files whose names start with a number followed by a hyphen (e.g.,
  `42-fix-crash.md`) are skipped. These are assumed to be issue files from
  `mx sync` and are not intended for the wiki.

Skipped files are printed in the output for visibility.

#note[`--page-name` cannot be used with a directory source. Each file's
wiki page name is derived from its filename automatically.]

=== Dry run

With `--dry-run`, the command prints which files would be synced and their
target page names, but does not clone, commit, or push anything. Useful for
verifying file selection and page naming before writing to the wiki.

```bash
mx wiki sync coryzibell/mx docs/wiki/ --dry-run
```

== Authentication

Wiki sync reads the GitHub token from `~/.claude.json`, the same token used
by #link("sync.html")[`mx sync`]. The token needs `repo` scope to clone and
push to wiki repositories.

== Related commands

- #link("sync.html")[`mx sync`] -- bidirectional GitHub issue and discussion
  sync (distinct from wiki sync).
