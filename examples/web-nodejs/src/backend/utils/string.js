const crypto = require("node:crypto").webcrypto;

const randomString = (chars, length) => {
  const randomArray = new Uint8Array(length);
  crypto.getRandomValues(randomArray);
  return Array.from({length}, (_, i) => chars[randomArray[i] % chars.length]).join("");
};

module.exports = { randomString };
