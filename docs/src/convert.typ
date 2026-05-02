#import "lib.typ": *

#page-header("Convert", "Format conversion utilities.")

== Overview

`mx convert` provides bidirectional conversion between markdown and YAML. These
commands are the format bridge for the #link("sync.html")[sync] workflow:
markdown is the human-friendly authoring format, YAML is the machine format
used by `mx sync` to round-trip issues and discussions with GitHub.

Two subcommands, one for each direction:

- `md2yaml` -- markdown to YAML (for feeding into `mx sync push`)
- `yaml2md` -- YAML to markdown (for reading sync output as prose)

Both commands accept a single file or an entire directory. When given a
directory, every file with the matching extension (`.md` for md2yaml, `.yaml`
or `.yml` for yaml2md) is converted.

== md2yaml

#command("mx convert md2yaml <input>",
  [Convert markdown files to the YAML format used by `mx sync`. The input can
  be a single `.md` file or a directory of markdown files. Output YAML files
  use the same base filename with a `.yaml` extension.],
  flags: (
    ([`input`], [positional], [Path to a markdown file or directory of markdown
    files.]),
    ([`-o`, `--output`], [path], [Output directory for generated YAML files.
    Defaults to the current working directory.]),
    ([`--dry-run`], [flag], [Preview what would be created without writing any
    files. Prints the output path, title, type, and labels for each file.]),
  ),
  examples: (
    "mx convert md2yaml notes/backlog.md",
    "mx convert md2yaml notes/ --output ./yaml-issues",
    "mx convert md2yaml notes/backlog.md --dry-run",
  ),
)

=== Markdown input formats

md2yaml understands two styles of markdown input.

*Frontmatter style* uses a YAML frontmatter block delimited by `---`. This is
the preferred format for clean round-trips:

```markdown
---
title: "Add dark mode support"
type: issue
labels:
  - enhancement
  - ui
priority: P2
---

## Context

Users have requested a dark mode option...
```

Supported frontmatter fields: `title`, `type` (defaults to `issue`), `labels`
(list), and `priority` (converted to a `priority:<value>` label automatically).

*Inline style* uses a heading and bold metadata lines. This is convenient for
quick authoring:

```markdown
# Add dark mode support

**Type:** `issue`
**Labels:** `enhancement`, `ui`

## Context

Users have requested a dark mode option...
```

In both formats, everything after the metadata (frontmatter or inline fields)
becomes the `body_markdown` field in the output YAML.

=== Output format

The generated YAML matches the schema used by `mx sync`. The output can be
pushed directly to GitHub with `mx sync push`:

```bash
mx convert md2yaml notes/dark-mode.md --output ./sync-cache
mx sync push coryzibell/mx --input ./sync-cache
```

See #link("sync.html")[Sync] for the full YAML file format specification.

== yaml2md

#command("mx convert yaml2md <input>",
  [Convert YAML files (from `mx sync pull` or hand-authored) back to readable
  markdown. The input can be a single `.yaml`/`.yml` file or a directory. Output
  filenames are derived from the issue number and title slug (e.g.,
  `42-fix-crash-on-empty-input.md`) when a GitHub issue number is present,
  or from the original filename otherwise.],
  flags: (
    ([`input`], [positional], [Path to a YAML file or directory of YAML
    files.]),
    ([`-o`, `--output`], [path], [Output directory for generated markdown
    files. Defaults to the current working directory.]),
    ([`-r`, `--repo`], [string], [Repository in `owner/repo` format. Used
    for GitHub URL references in the output. If omitted, the repo is inferred
    from the parent directory name (e.g., a directory named `coryzibell-mx`
    becomes `coryzibell/mx`).]),
    ([`--dry-run`], [flag], [Preview what would be created without writing any
    files. Prints the output path, title, and issue/discussion number for each
    file.]),
  ),
  examples: (
    "mx convert yaml2md cache/sync/coryzibell-mx/42-dark-mode.yaml",
    "mx convert yaml2md cache/sync/coryzibell-mx/ --output ./readable",
    "mx convert yaml2md issue.yaml --repo coryzibell/mx",
    "mx convert yaml2md cache/sync/coryzibell-mx/ --dry-run",
  ),
)

=== Output structure

The generated markdown uses YAML frontmatter for metadata, followed by the
issue body and any comments:

```markdown
---
title: "Add dark mode support"
type: issue
labels:
  - enhancement
  - ui
state: open
github_issue: 42
github_repo: coryzibell/mx
updated_at: 2025-01-15T10:30:00Z
---

The full issue body in markdown...

---

## Comments

### username (Jan 15, 2025)
Comment text here...
```

The frontmatter preserves enough metadata for a clean round-trip back through
`md2yaml` if needed.

=== Repo inference

When `--repo` is not provided, yaml2md infers the repository from the parent
directory name by splitting on the first hyphen. A file at
`cache/sync/coryzibell-mx/42-dark-mode.yaml` infers `coryzibell/mx`. If the
directory name has no hyphen, the repo defaults to `unknown/<dirname>`.

For reliable results, pass `--repo` explicitly.

== Typical workflows

=== Bulk-importing issues from markdown notes

Convert a directory of markdown notes to YAML and push them as new GitHub
issues:

```bash
mx convert md2yaml notes/ --output ./import-batch
mx sync push coryzibell/mx --input ./import-batch
```

Each markdown file becomes a new issue. After push, the YAML files are updated
with assigned issue numbers.

=== Reading sync output as prose

Pull issues from GitHub, then convert to readable markdown for review:

```bash
mx sync pull coryzibell/mx
mx convert yaml2md ~/.wonka/cache/sync/coryzibell-mx/ --output ./issues-readable
```

=== Dry-run preview

Both commands support `--dry-run` to preview the conversion without writing
files:

```bash
mx convert md2yaml notes/ --dry-run
mx convert yaml2md cache/ --dry-run
```

Dry-run output shows the file path that would be created, along with key
metadata (title, type, labels, issue number) for each item.

== Related commands

- #link("sync.html")[`mx sync`] -- the sync workflow that consumes and produces
  the YAML format these commands convert to and from.
