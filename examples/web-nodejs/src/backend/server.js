#!/usr/bin/env node

const http = require("node:http");
const path = require("node:path");
const fs = require("node:fs");
const mime = require("mime-types");
const route = require("./routes");
const { getRequestUrl } = require("./utils/http");
const { setSession } = require("./utils/session");

const basePath = path.join(__dirname, "../..");
const distPath = path.join(basePath, "dist");

const server = http.createServer(async (req, res) => {
  const reqUrl = getRequestUrl(req);
  const reqParams = new URLSearchParams(reqUrl.search);
  let targetPath = reqUrl.pathname;
  if (targetPath === "/") {
    targetPath = "/index.html";
  }

  console.log(`${req.method} ${targetPath}`);
  if (reqParams.size > 0) {
    console.log(`  PARAMS: ${reqParams}`);
  }

  const filePath = `${distPath}${targetPath}`;
  if (fs.existsSync(filePath)) {
    const mimeType = mime.lookup(filePath);
    res.statusCode = 200;
    res.setHeader("Content-Type", mimeType);

    console.log("HTTP 200");
    const readStream = fs.createReadStream(filePath);
    readStream.on("close", () => {
      res.end();
    });
    readStream.pipe(res);
  } else if (targetPath === "/favicon.ico") {
    console.log("HTTP 200 (favicon, empty)");
    res.statusCode = 200;
    res.setHeader("Content-Type", "image/vnd.microsoft.icon");
    res.end();
  } else {
    const handler = route(targetPath);
    if (handler) {
      setSession(req, res);
      await handler(req, res);
      console.log(`HTTP ${res.statusCode}`);
    } else {
      console.log("HTTP 404");
      res.setHeader("Content-Type", "text/plain");
      res.write("404 - Not found")
    }
    res.end();
  }
});

module.exports = server;
