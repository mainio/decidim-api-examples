const http = require("node:http");

const getRequestProtocol = (req) => {
  return typeof req.socket.getPeerCertificate === "function" ? "https" : "http";
};

const getRequestUrl = (req) => {
  return new URL(req.url || "", `${getRequestProtocol(req)}://${req.headers.host}`);
};

const parseCookies = (req) => {
  const jar = {};
  const cookie = req.headers.cookie;
  if (!cookie) {
    return jar;
  }

  for (const kv of cookie.split(";")) {
    const [key, val] = kv.split("=");
    if (!key) {
      continue;
    }
    if (!val) {
      continue;
    }

    jar[key.trim()] = val.trim();
  }
  return jar;
};

const getContentType = (res) => {
  const type = (res.headers["content-type"] ?? "").split(";", 1)[0];
  if (type.length < 1) {
    return "text/plain";
  }
  return type;
};

const postRequest = async ({ url, data }) => {
  return new Promise((resolve, reject) => {
    const uri = new URL(url);
    const postData = new URLSearchParams(data).toString();
    const options = {
      hostname: uri.hostname,
      port: uri.port,
      path: uri.pathname,
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Content-Length": Buffer.byteLength(postData)
      }
    };
    const request = http.request(options, (res) => {
      let responseData = "";

      // A chunk of data has been received.
      res.on("data", (chunk) => {
        responseData += chunk;
      });

      // The whole response has been received.
      res.on("end", () => {
        if (getContentType(res) === "application/json") {
          resolve(JSON.parse(responseData));
        } else {
          resolve(responseData);
        }
      });
    });

    request.on("error", reject);

    request.write(postData);
    request.end();
  });
};

module.exports = { getRequestProtocol, getRequestUrl, postRequest, parseCookies };
