#import "lib.typ": *

#page-header("GitHub", "GitHub operations: cleanup and commenting.")

== Overview

`mx github` groups operations that interact with GitHub repositories beyond
the commit-and-merge workflow covered by #link("commit.html")[commit] and
#link("pr.html")[PR]. Currently this means two things: bulk cleanup of issues
and discussions, and posting comments to either.

== Cleanup

#command("mx github cleanup <repo>",
  [Close issues and delete discussions in a GitHub repository. Useful for
  sweeping stale tracking items after a batch of work lands. Both flags are
  optional, but at least one must be provided -- the command does nothing if
  neither `--issues` nor `--discussions` is set.],
  flags: (
    ([`repo`], [positional], [Repository in `owner/repo` format.]),
    ([`--issues`], [string], [Comma-separated issue numbers to close.]),
    ([`--discussions`], [string], [Comma-separated discussion numbers to delete.]),
    ([`--dry-run`], [flag], [Show what would be done without making any changes.]),
  ),
  examples: (
    "mx github cleanup coryzibell/mx --issues 10,11,12",
    "mx github cleanup coryzibell/mx --discussions 5,8",
    "mx github cleanup coryzibell/mx --issues 10 --discussions 5 --dry-run",
  ),
)

#tip[Run with `--dry-run` first to verify the target list before closing or
deleting anything. Deleted discussions cannot be recovered.]

== Commenting

`mx github comment` posts a comment to an issue or discussion. Both
subcommands accept an optional `--identity` flag that appends a signature
line to the comment, useful when multiple agents or personas share a GitHub
account.

=== Issues

#command("mx github comment issue <repo> <number> <message>",
  [Post a comment on a GitHub issue.],
  flags: (
    ([`repo`], [positional], [Repository in `owner/repo` format.]),
    ([`number`], [positional], [Issue number.]),
    ([`message`], [positional], [Comment body text.]),
    ([`--identity`], [string], [Identity signature appended to the comment (e.g. `"smith"`, `"neo"`).]),
  ),
  examples: (
    "mx github comment issue coryzibell/mx 42 \"Fixed in abc123.\"",
    "mx github comment issue coryzibell/mx 42 \"Resolved.\" --identity smith",
  ),
)

=== Discussions

#command("mx github comment discussion <repo> <number> <message>",
  [Post a comment on a GitHub discussion.],
  flags: (
    ([`repo`], [positional], [Repository in `owner/repo` format.]),
    ([`number`], [positional], [Discussion number.]),
    ([`message`], [positional], [Comment body text.]),
    ([`--identity`], [string], [Identity signature appended to the comment (e.g. `"smith"`, `"neo"`).]),
  ),
  examples: (
    "mx github comment discussion coryzibell/mx 7 \"Sounds good, let's proceed.\"",
    "mx github comment discussion coryzibell/mx 7 \"Acknowledged.\" --identity neo",
  ),
)
