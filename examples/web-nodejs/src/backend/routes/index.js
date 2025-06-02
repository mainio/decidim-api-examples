const routes = {
  "/auth/sign-in": require("./auth/sign-in"),
  "/auth/callback": require("./auth/callback"),
};

module.exports = (path) => routes[path];
