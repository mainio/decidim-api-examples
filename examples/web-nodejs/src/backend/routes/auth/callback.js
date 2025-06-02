const { getRequestUrl } = require("../../utils/http");
const { accessTokenFor } = require("../../utils/oauth");
const { sessionFor } = require("../../utils/session");

module.exports = async (req, res) => {
  res.setHeader("Content-Type", "application/json");

  const redirectUri = getRequestUrl(req);
  redirectUri.pathname = "/auth/callback";

  const token = await accessTokenFor(req, redirectUri);

  const url = new URL(redirectUri.toString().split("?", 1)[0]);
  url.pathname = "/";
  if (token) {
    url.searchParams.set("token", btoa(JSON.stringify(token)));
  } else {
    url.searchParams.set("error", 1);
  }

  res.statusCode = 302;
  res.setHeader("Location", url.toString());
  res.write("Redirecting...");
};
