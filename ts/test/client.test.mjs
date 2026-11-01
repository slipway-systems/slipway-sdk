import assert from "node:assert/strict";
import { test } from "node:test";
import { Code, ConnectError, createClient, IdentityService } from "../dist/index.js";

/** A fetch that records the request and answers WhoAmI with one JSON field, or with a Connect error. */
function fakeFetch(status = 200, body = { sessionMethod: "token" }) {
  const calls = [];
  const fetch = async (input, init) => {
    calls.push({ url: String(input), headers: new Headers(init.headers) });
    return new Response(JSON.stringify(body), {
      status,
      headers: { "Content-Type": "application/json" },
    });
  };
  return { calls, fetch };
}

for (const [name, token, want] of [
  ["sends the token", "sk_test", "Bearer sk_test"],
  ["sends no header without a token", undefined, null],
]) {
  test(name, async () => {
    const { calls, fetch } = fakeFetch();
    const client = createClient({ baseUrl: "https://slipway.example.com/", token, fetch });
    // The Connect transport negotiates the binary format by default, so this checks the request and not the decoding.
    await client.identity.whoAmI({}).catch(() => {});
    assert.equal(calls.length, 1);
    assert.equal(calls[0].url, "https://slipway.example.com/slipway.v1.IdentityService/WhoAmI");
    assert.equal(calls[0].headers.get("Authorization"), want);
  });
}

test("a server error is a ConnectError", async () => {
  const { fetch } = fakeFetch(401, { code: "unauthenticated", message: "no" });
  const client = createClient({ baseUrl: "https://slipway.example.com", fetch });
  await assert.rejects(client.identity.whoAmI({}), (err) => {
    assert.ok(err instanceof ConnectError);
    assert.equal(err.code, Code.Unauthenticated);
    return true;
  });
});

test("exports the generated services", () => {
  assert.equal(IdentityService.typeName, "slipway.v1.IdentityService");
});
