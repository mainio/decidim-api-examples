import * as templates from "./templates";

import "./index.css";

const API_URL = env.API_URL;
const JWT_AUD = env.JWT_AUD;

const signIn = async () => {
  window.location.assign("/auth/sign-in");
};

const clearSearchParams = () => {
  const [url] = window.location.href.split("?", 1);
  window.history.replaceState(null, null, url);
};

const validateToken = (token) => {
  if (token === null || typeof token !== "object") {
    return null;
  }

  if (!Number.isInteger(token["created_at"]) || !Number.isInteger(token["expires_in"])) {
    return null;
  }

  const expiry = token["created_at"] + token["expires_in"];
  if (expiry <= Math.round(Date.now() / 1000)) {
    return null;
  }

  return token;
};

const parseToken = (rawToken) => {
  if (typeof rawToken !== "string") {
    return null;
  }

  try {
    return JSON.parse(atob(rawToken));
  } catch (err) {
    console.error(err);
    return null;
  }
};

const getToken = () => {
  const params = new URLSearchParams(window.location.search);

  if (params.has("token")) {
    const rawToken = params.get("token");
    clearSearchParams();

    try {
      const token = parseToken(rawToken);
      if (!validateToken(token)) {
        return null;
      }

      sessionStorage.setItem("token", rawToken);

      return token;
    } catch (err) {
      console.error(err);
      return null;
    }
  }

  return validateToken(parseToken(sessionStorage.getItem("token")));
};

const apiRequest = async (token, query, variables = {}) => {
  const response = await fetch(API_URL, {
    method: "POST",
    headers: {
      "Authorization": `${token["token_type"]} ${token["access_token"]}`,
      "Content-Type": "application/json",
      "X-Jwt-Aud": JWT_AUD
    },
    body: JSON.stringify({ query, variables })
  });

  if (!response.ok) {
    return null;
  }

  const json = await response.json();
  if (Array.isArray(json.errors)) {
    for (const err of json.errors) {
      console.error(err.message);
    }
  }
  return json.data ?? null;
};

const initApp = async () => {
  const params = new URLSearchParams(window.location.search);
  const tokenCallback = params.has("token");

  const appContainer = document.getElementById("app");

  if (!window.crypto) {
    appContainer.innerHTML = templates.cryptoNotSupported;
  } else if (!window.crypto.subtle) {
    appContainer.innerHTML = templates.cryptoSubtleNotSupported;
  } else {
    const token = getToken();

    if (token) {
      const data = await apiRequest(token, "{ session { user { id name nickname } } }")
      if (data && data.session) {
        appContainer.innerHTML = templates.signedIn(data.session.user, token);
      } else {
        appContainer.innerHTML = templates.signInError(
          `
            A token exists but it either <strong>has expired</strong> or
            <strong>is not recognized as a sign in token by Decidim</strong>
            giving information about the signed in user. Please try again and if
            you still get this message, please check that you have configured
            Decidim correctly.
          `
        );
      }
    } else if (tokenCallback) {
      appContainer.innerHTML = templates.signInError("Invalid token returned.");
    } else {
      appContainer.innerHTML = templates.index;
    }
  }

  for (const el of document.querySelectorAll("button[data-action]")) {
    el.addEventListener("click", (ev) => {
      ev.preventDefault();

      if (el.dataset.action === "signIn") {
        signIn();
      } else if (el.dataset.action === "restart") {
        clearSearchParams();
        sessionStorage.clear();
        initApp();
      }
    });
  };
};

initApp();
