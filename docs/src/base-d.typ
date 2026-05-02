#import "lib.typ": *

#page-header("Base-d Encoding", "Dictionary-based commit message encoding.")

== Overview

Base-d is a universal, multi-dictionary encoding library published as the
#link("https://crates.io/crates/base-d")[base-d] crate. mx uses it to encode
every commit message made with `mx commit`, producing output that is
intentionally unreadable in raw `git log` but decodes cleanly with `mx log`.

The purpose is *obfuscation through encoding*. Commit messages are transformed
into sequences of glyphs -- hieroglyphs, chess pieces, alchemical symbols,
emoji, or any of 50+ dictionaries -- that carry no human-readable meaning on
their own. The original message is fully recoverable because each commit
carries a footer tag identifying the exact algorithms and dictionaries used.

This is not encryption. The footer is plaintext and the dictionaries are
public. Anyone with `mx log` (or the base-d crate) can decode the message. The
goal is not secrecy but *noise reduction*: encoded commits are visually
distinct from human-authored text, making the commit log resistant to casual
reading while remaining fully reversible by tooling.

== How it works

Every encoded commit has three parts:

+ *Title* -- a hash of the staged diff, encoded through a randomly selected
  dictionary.
+ *Body* -- the human-readable commit message, compressed and then encoded
  through a second randomly selected dictionary.
+ *Footer* -- a bracket-delimited tag recording the algorithms and dictionary
  names used: `[hash_algo:title_dict|compress_algo:body_dict]`.

The title is a fingerprint of what changed. The body is the author's
description of why it changed. The footer is the decoder ring.

When you run:

```bash
mx commit "fix session export crash on empty JSONL" -a
```

mx internally:

+ Runs `git diff --staged` to capture the diff.
+ Hashes the diff with a randomly chosen hash algorithm and encodes the hash
  through a random dictionary. This becomes the commit title.
+ Compresses your message with a randomly chosen compression algorithm and
  encodes the compressed bytes through another random dictionary. This becomes
  the commit body.
+ Assembles the footer tag from the algorithm and dictionary names.
+ Commits with the three-part message: title, body, footer.

The result in raw `git log` looks something like:

```
commit abc1234...
    U+1F711 U+1F754 U+1F72E U+1F716...

    8NO48P3FCDPIGSJ5C5I6QP9978G76R39...

    [sha384:base32hex|snappy:base32hex]
```

But `mx log` shows:

```
abc1234 fix session export crash on empty JSONL
```

== Dictionaries

A dictionary is a mapping from binary data to a character set (or word list).
Base-d ships with over 50 built-in dictionaries spanning several categories:

- *RFC standards* -- base2, base4, base8, base16, base32, base32hex,
  base32\_crockford, base32\_zbase, base32\_geohash, base36, base45, base58,
  base58flickr, base58ripple, base62, base64, base64url, base64\_imap,
  base64\_radix, base85, base91, base100, base1024.
- *Legacy formats* -- ascii85, z85, uuencode, xxencode, binhex.
- *Ancient scripts* -- hieroglyphs, cuneiform, runic.
- *Symbols* -- alchemy, arrows, blocks, blocks\_full, boxdraw, chess, domino,
  mahjong, music, zodiac, barcode, gradient, volume.
- *Emoji* -- emoji\_faces, emoji\_animals.
- *Specialized* -- cards (playing cards), dna (nucleotide encoding), weather,
  binary.

Each dictionary has a `common` flag (default: `true`). Only `common`
dictionaries are eligible for random selection during encoding. Dictionaries
marked `common = false` (such as `music`, which does not render consistently
across platforms) are available for explicit use but excluded from the random
pool.

Dictionaries are loaded from the built-in registry via
`DictionaryRegistry::load_default()`. Users can also define custom dictionaries
in `~/.config/base-d/dictionaries.toml`, which are merged into the registry at
load time.

=== Encoding modes

Each dictionary operates in one of three modes:

- *Radix* -- true base conversion treating data as a large number. Works with
  any dictionary size.
- *Chunked* -- fixed-size bit groups, compatible with RFC 4648 standards
  (base64, base32, etc.). Supports padding characters.
- *ByteRange* -- direct 1:1 byte-to-codepoint mapping using a contiguous
  Unicode range. Zero encoding overhead.

The mode is determined by the dictionary configuration, not by the caller.

== Title encoding

The commit title is produced by hashing the staged diff:

+ The staged diff (output of `git diff --staged`) is captured as raw bytes.
+ A hash algorithm is chosen at random from the full set: MD5, SHA-224,
  SHA-256, SHA-384, SHA-512, SHA3-224, SHA3-256, SHA3-384, SHA3-512,
  Keccak-224, Keccak-256, Keccak-384, Keccak-512, Blake2b, Blake2s, Blake3,
  CRC-16, CRC-32, CRC-32C, CRC-64, xxHash32, xxHash64, XXH3-64, XXH3-128,
  Ascon, or K12.
+ The hash is computed over the diff bytes.
+ A dictionary is chosen at random from the common pool.
+ The hash bytes are encoded through the dictionary.

The result is a fingerprint of the diff -- not human text. Two identical diffs
will produce different titles because the hash algorithm and dictionary are
re-rolled each time. The title exists so that `mx log` can identify which
commit produced which diff, not for human consumption.

#note[The title is a hash of the _diff_, not of the commit message. It
fingerprints what changed, not what the author said about it.]

== Body encoding

The commit body is produced by compressing and encoding the author's message:

+ The human-readable commit message is captured as UTF-8 bytes.
+ A compression algorithm is chosen at random: LZMA, Zstd, Brotli, Gzip, LZ4,
  or Snappy.
+ The message bytes are compressed.
+ A second dictionary is chosen at random from the common pool (independently
  of the title dictionary).
+ The compressed bytes are encoded through the dictionary.

The result is a compressed, encoded representation of the original message.
Decoding reverses the process: look up the dictionary from the footer, decode
back to compressed bytes, then decompress to recover the original UTF-8 text.

== Footer format

The footer is a single line at the end of the commit message, formatted as:

```
[hash_algo:title_dict|compress_algo:body_dict]
```

For example:

```
[sha384:base62|lzma:uuencode]
```

This tells the decoder:

- The title was produced by hashing with SHA-384 and encoding through the
  `base62` dictionary.
- The body was produced by compressing with LZMA and encoding through the
  `uuencode` dictionary.

The decoder (`mx log`) reads this footer, loads the named dictionaries from the
registry, and reverses the encoding. If the footer is missing or malformed, the
commit is treated as a plain (un-encoded) message and displayed as-is.

=== Footer validation

Not every line that matches the `[a:b|c:d]` shape is a real footer. The decoder
validates that the compression algorithm slot names a known algorithm (LZMA,
Zstd, Brotli, Gzip, LZ4, or Snappy) before treating the line as a footer. This
prevents user-authored text like `[link|here]` or markdown bracket notation from
being mistaken for encoding metadata.

== Dejavu markers

When both the title dictionary and the body dictionary happen to be the same
(by pure chance -- both are selected independently at random), the footer
includes a *dejavu marker*: the word `whoa.` appended on the line after the
footer tag.

```
[sha384:base62|lzma:base62]
whoa.
```

This is an easter egg. It has no functional significance. The encoding and
decoding work identically whether dejavu occurs or not. It simply marks the
coincidence that two independent random draws landed on the same dictionary.

When `mx commit --show-encoded` is used, dejavu commits display an extra line:

```
Dejavu: true (both used base62)
```

== Encoding safety

Some dictionary and algorithm combinations produce encoded output containing
NUL bytes or control characters that would break git's command-line argument
handling. The encoder validates all output and retries with a freshly rolled
dictionary if unsafe characters are detected, up to 5 attempts. Failed attempts
are logged to stderr with the dictionary that produced the problem.

If all 5 attempts produce unsafe output (statistically unlikely given the
dictionary pool size), the commit fails with an error listing every dictionary
combination that was tried.

== Decoding

`mx log` reverses the encoding:

+ It runs `git log` and parses each commit into title, body, and lines.
+ It scans the body for the last footer-shaped line -- a line matching
  `[hash:dict|compress:dict]` where the compression slot names a known
  algorithm.
+ It splits the body into the encoded payload (everything above the footer) and
  trailing content (everything below the footer, including any dejavu marker).
+ It looks up the body dictionary from the footer, decodes the payload back to
  compressed bytes, then decompresses to recover the original message.
+ Non-encoded commits (those without a recognizable footer) pass through
  unchanged.

The footer-scan uses a "last wins" heuristic: if multiple footer-shaped lines
appear in the message (e.g., a user amended extra text that quotes a prior
footer), the last one is used. This covers the common case where the real
footer is near the bottom and any trailing content (dejavu marker,
user-appended notes) appears after it.

For full usage of the decoded log, see #link("log.html")[log].

== The base-d crate

Base-d is an independent crate published on
#link("https://crates.io/crates/base-d")[crates.io]. mx depends on `base-d`
version 3 and uses its `prelude` module for the core encoding API:

- `DictionaryRegistry::load_default()` -- loads all built-in dictionaries.
- `hash_encode(data, registry)` -- hashes data with a random algorithm and
  encodes through a random dictionary. Returns the encoded string, hash
  algorithm name, and dictionary name.
- `compress_encode(data, registry)` -- compresses data with a random algorithm
  and encodes through a random dictionary. Returns the encoded string,
  compression algorithm name, and dictionary name.
- `decode(encoded, dictionary)` -- reverses the encoding for a known
  dictionary.
- `decompress(data, algorithm)` -- reverses the compression.
- `detect_dictionary(encoded)` -- auto-detects which dictionary was used (used
  as a fallback for old commits that lack dictionary names in their footer).

The crate supports SIMD acceleration (AVX2/SSSE3 on x86\_64, NEON on aarch64),
streaming encoding/decoding for large files, custom user dictionaries, and
word-based encoding modes. mx uses only the character-based encoding path.

== Dry-run and encode-only

Two modes let you inspect encoding without creating a commit:

```bash
# Preview what a real commit would produce
mx commit "your message" --dry-run

# Encode arbitrary title/body text (no git state required)
mx commit --encode-only --title "refactor store" --body "split backends"
```

Dry-run runs the full encoding pipeline and validates the output, but skips all
git mutations. Encode-only takes explicit title and body text, encodes them, and
prints the result. Both are useful for testing dictionary behavior or debugging
encoding issues.

For the full commit flag reference, see #link("commit.html")[commit].
