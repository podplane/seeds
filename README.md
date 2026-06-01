# Podplane Seeds

This repository contains Netsy snapshot templates used to seed new Podplane
cluster state.

A Podplane seed is a Netsy `.netsy` snapshot used to initialize a new cluster
with platform components already present. Currently there are two options:

- Recommended
- Minimal

The snapshot files are committed in this repository so Git history and tags
provide a public audit log. For each tagged release, a manifest is published
containing the SHA512SUM of each seed file. That manifest is included in the
published SHA512SUM file, which is signed into a Sigstore bundle.

## Versioning

Tags use:

```text
v<components-version>-<seed-revision>
```

Examples for components repo `v1.2.3` and `v1.2.4` versions:

```text
v1.2.3-1
v1.2.3-2
v1.2.4-1
```

- `1.2.3` maps to the Podplane Components release.
- `-1` represents the first seed release for that Components version.

## Development manifest

The checked-in [`manifests/seeds.json`](./manifests/seeds.json) file is a development manifest. It points at local `.netsy` files with paths relative to the manifest directory, matching the way other Podplane dependency manifests support local development.

## Release assets

For tag `v1.2.3-1`, automation publishes:

```text
seeds_1.2.3-1.json
seeds_1.2.3-1_checksums.txt
seeds_1.2.3-1_checksums.txt.bundle
```

The manifest shape is:

```json
{
  "seeds": {
    "version": "1.2.3-1",
    "components": "1.2.3",
    "snapshots": {
      "recommended": {
        "url": "https://raw.githubusercontent.com/podplane/seeds/v1.2.3-1/recommended.netsy",
        "digest": "sha512:...",
        "size": 123
      }
    }
  }
}
```

## Development

```sh
make setup
make precommit
VERSION=1.2.3-1 make manifests
```

For Podplane CLI development, point `podplane deps download --seeds` at
`manifests/seeds.json` once the local `.netsy` files are ready, and it will copy them into the Podplane cache for use on next cluster creation.
