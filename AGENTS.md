# Podplane Seeds — Agent Guide

This repository contains versioned Podplane seed snapshots: Netsy `.netsy`
snapshot files used to initialize new Podplane clusters with platform
components already present.

## Commands

- `make setup` — verify required tools and install a pre-commit hook when `.git` exists.
- `make check` — check shell scripts and release metadata helpers.
- `make validate` — validate the expected snapshot files when present.
- `VERSION=1.2.3-1 make manifests` — generate `dist/release/seeds_1.2.3-1.json` from the checked-in development manifest.
- `make precommit` — run local checks.
- `make ci` — run checks and snapshot validation.
- `make clean` — remove generated `dist/`.

## Release model

Tags use `v<components-version>-<seed-revision>`, for example `v1.2.3-1`.
The prefix maps to the Podplane Components release, and the suffix is the seed
revision for that Components release.

The `.netsy` files are committed to git. Release automation publishes only the
generated seeds manifest, a sha512 checksums file, and the signed Sigstore
bundle for that checksums file.

## Conventions

- Keep snapshot filenames stable: `recommended.netsy` and `minimal.netsy`.
- Do not commit generated release metadata under `dist/`.
- Prefer changing the snapshot files and tagging a new seed revision over
  rewriting history.
