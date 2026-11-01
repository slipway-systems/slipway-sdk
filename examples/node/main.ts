// Calls WhoAmI on the server at SLIPWAY_URL with the token in SLIPWAY_TOKEN.
import { createClient } from "@slipway-systems/sdk";

const client = createClient({
  baseUrl: process.env.SLIPWAY_URL ?? "",
  token: process.env.SLIPWAY_TOKEN,
});
const me = await client.identity.whoAmI({});
console.log(`user=${me.user?.email} method=${me.sessionMethod}`);
