# Slipway SDKs

Go and TypeScript clients for the [Slipway](https://slipway.systems) API.

| Language | Install | Docs |
|---|---|---|
| Go | `go get github.com/slipway-systems/slipway-sdk/go` | [go/README.md](go/README.md) |
| TypeScript | `npm install @slipway-systems/sdk` | [ts/README.md](ts/README.md) |

`proto/` holds the protobuf definitions they are generated from.

## Versions

The SDKs are versioned in lockstep with the server: SDK `X.Y.Z` is generated from the protos of Slipway `X.Y.Z`. Go tags
are `go/vX.Y.Z`, and the npm package is `X.Y.Z`. There is no compatibility promise before 1.0 beyond the checks of
`buf breaking`.

On npm, `latest` is the newest stable release. A release candidate is published under `next`, and a patch to an older
release line under `release-X.Y`, so neither reaches a plain `npm install`.

## Contributing

This repository is written by Slipway's release process: each release replaces its contents, so a change made here is
lost at the next one. Please open an issue instead.

## Licence

Everything in this repository, including `proto/` and the generated code, is under the [Apache License 2.0](LICENSE).
The Slipway server has its own licence, which does not apply to anything here.
