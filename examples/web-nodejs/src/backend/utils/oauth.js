const crypto = require("node:crypto").webcrypto;
const { randomString } = require("./string");
const { getRequestUrl, postRequest } = require("./http");
const { sessionFor } = require("./session");

const authUrl = process.env["OAUTH_AUTH_URL"];
const tokenUrl = process.env["OAUTH_TOKEN_URL"];
const clientId = process.env["OAUTH_CLIENT_ID"];
const clientSecret = process.env["OAUTH_CLIENT_SECRET"];

const createOauthState = () => {
  // https://datatracker.ietf.org/doc/html/rfc6749#appendix-A.5
  const chars = Array.from(
    {length: 1 + 0x7E - 0x20},
    (_, i) => String.fromCharCode(0x20 + i)
  );

  // According to RFC 6749, there is no specified maximum limit for the state
  // string, so we use a 36 character string which produces a 48 character
  // string when base64 encoded. This should give enough uniqueness among the
  // different authentication requests, as this is only used to verify the
  // authorization response is originating from the same user session.
  return randomString(chars, 36);
};

const createOauthVerifier = () => {
  // https://datatracker.ietf.org/doc/html/rfc7636#section-4.1
  const ranges = [
    [0x30, 0x39], // 0-9
    [0x41, 0x5A], // A-Z
    [0x61, 0x7A] // a-z
  ];
  const chars = [].concat(
    ...ranges.map(
      ([start, end] = range) => Array.from(
        {length: 1 + end - start},
        (_, i) => String.fromCharCode(start + i)
      )
    ),
    // others
    ["-", ".", "_", "~"]
  );

  // According to RFC 7636, the verifier length needs to be between 43-128
  // characters which equates to 32-96 characters when Base64 encoded.
  return randomString(chars, 96);
};

const digestMessage = async (message) => {
  // https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/digest
  const data = (new TextEncoder()).encode(message);
  return await crypto.subtle.digest("SHA-256", data);
};

const urlsafeBase64 = (hash) => {
  // Note: This is not supported by browsers but works in Node.js. For browser
  // implementation, please use another method for the conversion.
  return Buffer.from(hash).toString("base64url");
};

const authorizeUrlFor = async (req, redirectUri) => {
  const state = urlsafeBase64(createOauthState());
  const verifier = createOauthVerifier();
  const challenge = urlsafeBase64(await digestMessage(verifier));

  const sessionStorage = sessionFor(req);
  sessionStorage.setItem("oauth-state", state);
  sessionStorage.setItem("oauth-verifier", verifier);

  const authUri = new URL(authUrl);
  authUri.searchParams.append("response_type", "code");
  authUri.searchParams.append("client_id", clientId);
  authUri.searchParams.append("redirect_uri", redirectUri);
  authUri.searchParams.append("scope", "profile user api:read");
  authUri.searchParams.append("state", state);
  authUri.searchParams.append("code_challenge", challenge);
  authUri.searchParams.append("code_challenge_method", "S256");

  return authUri.toString();
};

const accessTokenFor = async (req, redirectUri) => {
  const reqUrl = getRequestUrl(req);
  const reqParams = new URLSearchParams(reqUrl.search);

  const sessionStorage = sessionFor(req);
  const storedState = sessionStorage.getItem("oauth-state");
  const storedVerifier = sessionStorage.getItem("oauth-verifier");
  sessionStorage.removeItem("oauth-state");
  sessionStorage.removeItem("oauth-verifier");

  if (reqParams.get("state") !== storedState) {
    console.info("OAUTH ERROR: Invalid state returned.");
    return null;
  }

  const formData = new FormData();
  formData.append("grant_type", "authorization_code");
  formData.append("code", reqParams.get("code"));
  formData.append("redirect_uri", redirectUri);
  formData.append("client_id", clientId);
  formData.append("client_secret", clientSecret);
  formData.append("code_verifier", storedVerifier);

  const response = await postRequest({ url: tokenUrl, data: formData });
  if (typeof response !== "object") {
    return null;
  }

  return response;
};

module.exports = {
  authorizeUrlFor,
  accessTokenFor
};
