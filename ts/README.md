# @slipway-systems/sdk

TypeScript client for the [Slipway](https://slipway.systems) API, for browsers and Node 20 or later. ESM only.

```bash
npm install @slipway-systems/sdk
```

```ts
import { createClient } from "@slipway-systems/sdk";

const client = createClient({ baseUrl: "https://slipway.example.com", token: process.env.SLIPWAY_TOKEN });
const me = await client.identity.whoAmI({});
console.log(me.user?.email);
```

The client has a property per API service (`identity`, `run`, `deploy` and so on). Message types and service descriptors
are exported from the package too, built with [protobuf-es](https://github.com/bufbuild/protobuf-es) v2 and
[connect-es](https://github.com/connectrpc/connect-es). Failed calls throw a `ConnectError`.

TypeScript projects need `"DOM"` in `lib`, Node ones too, because connect-es's types use `HeadersInit`.

In a browser, a server on another origin has to allow yours, and a long-lived token should not be shipped to the page.

## Versions

Versions match the Slipway server's. `latest` is the newest stable release; release candidates are under `next`, and
patches to older release lines under `release-X.Y`.

Licence: Apache-2.0.
