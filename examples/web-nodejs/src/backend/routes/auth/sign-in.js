const { authorizeUrlFor } = require("../../utils/oauth");
const { getRequestUrl } = require("../../utils/http");

module.exports = async (req, res) => {
  const redirectUri = getRequestUrl(req);
  redirectUri.pathname = "/auth/callback";

  const url = await authorizeUrlFor(req, redirectUri);

  res.statusCode = 302;
  res.setHeader("Location", url);
  res.write("Redirecting...");
};
