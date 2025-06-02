const API_URL = env.API_URL;

export const cryptoNotSupported = `
  <div class="wrapper">
    <div class="content">
      <h1>Example Decidim participant integration</h1>
      <p>
        Your browser must support the
        <a href="https://developer.mozilla.org/en-US/docs/Web/API/Crypto"
          target="_blank">Web Crypto API</a> in order to use this example
        application.
      </p>
    </div>
  </div>
`;

export const cryptoSubtleNotSupported = `
  <div class="wrapper">
    <div class="content">
      <h1>Example Decidim participant integration</h1>
      <p>
        Your browser must support the
        <a href="https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto"
          target="_blank">SubtleCrypto API</a> in order to use this example
        application.
      </p>
      <p>
        Note that in some browsers this is available only in secure
        contexts. You need to serve this application in a secure context or
        modify your browser settings to allow this API also under insecure
        contexts.
      </p>
    </div>
  </div>
`;

export const index = `
  <div class="wrapper">
    <div class="content">
      <h1>Example Decidim participant integration</h1>
      <p>
        This is a simple example application to demonstrate the participant sign
        in to the Decidim API. Please read through the README documentation to
        prepare your Decidim instance for this integration.
      </p>
      <h2>Important!</h2>
      <p>
        <strong>This example is for demonstration purposes only and should
        only be used in development environment.</strong> The way the
        integration is implemented requires both, the utilizing application
        (i.e. this application) and the OAuth serving application (i.e.
        Decidim) to be behind HTTPS secured connections. Without HTTPS, the
        integration is subject to man-in-the-middle attacks and can cause
        serious security issues and user account hijacking.
      </p>
    </div>
    <div class="divider"></div>
    <div class="content">
      <h2>Test the API</h2>
      <p>
        Press the button below in order to start the authentication process
        with the configured Decidim instance. You will be redirected to
        perform the authentication and token authorization at Decidim.
      </p>
      <button type="button" class="btn" data-action="signIn">Start the sign in process</button>
    </div>
  </div>
`;

export const signedIn = (user, token) => {
  const username = (user.nickname || "").substring(1);
  const baseUrl = API_URL.substring(0, API_URL.indexOf("/api"));
  const profileUrl = `${baseUrl}/profiles/${username}`;
  const scopes = token.scope.split(" ");

  const capabilities = [];
  if (scopes.includes("profile")) {
    capabilities.push("Can read profile information about the user.");
  }
  if (scopes.includes("user")) {
    capabilities.push("Can represent the user through the API.");
  }
  if (scopes.includes("api:read")) {
    capabilities.push("Can read data through the API.");
  }
  if (scopes.includes("api:write")) {
    capabilities.push("Can write data through the API.");
  }

  const createdAt = new Date(token["created_at"] * 1000);
  const expiresAt = new Date((token["created_at"] + token["expires_in"]) * 1000);

  return `
    <div class="wrapper">
      <div class="content">
        <h1>You are now signed in at Decidim</h1>
        <p>Your user details at Decidim are listed below:</p>
        <ul>
          <li><strong>Name:</strong> ${user.name}</li>
          <li><strong>Nickname:</strong> <a href="${profileUrl}" target="_blank">${user.nickname}</a></li>
        </ul>
        <p>Your token details:</p>
        <ul>
          <li><strong>Created at:</strong> ${createdAt.toString()}</li>
          <li><strong>Expires at:</strong> ${expiresAt.toString()}</li>
        </ul>
        <p>Capabilities associated with the token:</p>
        <ul>${capabilities.map((cap) => `<li>${cap}</li>`).join("")}</ul>
      </div>
      <div class="divider"></div>
      <div class="content">
        <button type="button" class="btn" data-action="restart">Restart</button>
      </div>
    </div>
  `;
};

export const signInError = (message) => {
  return `
    <div class="wrapper">
      <div class="content">
        <h1>Sign in error</h1>
        <p>${message}</p>
        <button type="button" class="btn" data-action="restart">Restart</button>
      </div>
    </div>
  `;
};
