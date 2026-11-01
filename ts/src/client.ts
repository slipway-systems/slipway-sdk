import type { Interceptor, Transport } from "@connectrpc/connect";
import { createConnectTransport } from "@connectrpc/connect-web";
import { createServices, type Services } from "./services.js";

export interface ClientOptions {
  /** The server's URL, such as `https://slipway.example.com`. */
  baseUrl: string;
  /** A personal access token or a service-account token. Without one, no credentials are sent. */
  token?: string;
  /** Replaces the global `fetch`. */
  fetch?: typeof globalThis.fetch;
  /** Run after the one that sets the token. */
  interceptors?: Interceptor[];
}

/** A client per API service, and the transport they share for use with `createClient` from `@connectrpc/connect`. */
export type SlipwayClient = Services & { transport: Transport };

/**
 * Creates a client for every API service.
 *
 *     const client = createClient({ baseUrl: "https://slipway.example.com", token });
 *     const me = await client.identity.whoAmI({});
 */
export function createClient(options: ClientOptions): SlipwayClient {
  const { baseUrl, token, fetch, interceptors = [] } = options;
  const bearer: Interceptor = (next) => (req) => {
    if (token) req.header.set("Authorization", `Bearer ${token}`);
    return next(req);
  };
  const transport = createConnectTransport({
    baseUrl,
    interceptors: [bearer, ...interceptors],
    // Called through a wrapper so that a browser's fetch keeps its required `this`.
    fetch: fetch ?? ((input, init) => globalThis.fetch(input, init)),
  });
  return { ...createServices(transport), transport };
}
