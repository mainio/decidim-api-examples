const { parseCookies, getRequestProtocol } = require("./http");
const { randomString } = require("./string");

// In-memory session storage for demonstrational purposes. Only works when all
// users are served by the same process.
const sessionStorage = {};
const sessionCookieName = "dpt_session_id";

class Session {
  constructor(id) {
    this.id = id;
    this.values = {};
  }

  setItem(key, value) {
    this.values[key] = value;
  }

  getItem(key) {
    return this.values[key];
  }

  removeItem(key) {
    delete this.values[key];
  }
}

const generateSessionId = () => {
  const ranges = [
    [0x30, 0x39], // 0-9
    [0x41, 0x5A], // A-Z
    [0x61, 0x7A] // a-z
  ];
  const chars = [].concat(
    ...ranges.map(([start, end] = range) => Array.from({length: end - start + 1}, (_, i) => String.fromCharCode(start + i)))
  );

  return randomString(chars, 32);
};

const getSessionId = (req) => {
  let id = req.sessionId;
  if (!id) {
    const cookies = parseCookies(req);
    id = cookies[sessionCookieName];
  }
  if (id && sessionStorage[id]) {
    return id;
  }
  return null;
}

const setSession = (req, res) => {
  const protocol = getRequestProtocol(req);
  const session = sessionFor(req);
  const maxAge = 3600; // 1 hour
  const expires = new Date(Date.now() + maxAge * 1000).toGMTString();
  const path = "/";

  if (protocol === "https") {
    res.setHeader("Set-Cookie", `${sessionCookieName}=${session.id}; Path=${path}; Expires=${expires}; Max-Age=${maxAge}; SameSite=Strict; Secure; HttpOnly`);
  } else {
    res.setHeader("Set-Cookie", `${sessionCookieName}=${session.id}; Path=${path}; Expires=${expires}; Max-Age=${maxAge}; SameSite=Strict; HttpOnly`);
  }
};

const sessionFor = (req) => {
  const id = getSessionId(req);
  if (id) {
    req.sessionId = id;
    return sessionStorage[id];
  }

  const session = new Session(generateSessionId());
  sessionStorage[session.id] = session;
  req.sessionId = session.id;
  return session;
};

const endSession = (id) => {
  return delete sessionStorage[id];
};

module.exports = { setSession, sessionFor, endSession };
