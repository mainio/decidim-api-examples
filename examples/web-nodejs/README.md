# Decidim Participant Token for web

This is an example traditional web application showing a **confidential** OAuth
client interacting with the Decidim API as an authenticated participant. It is a
low dependency "single page" browser application utilizing a
[Node.js](https://nodejs.org/) backend application handling the authentication
flows without having to allow cross origin requests for the browser on the
Decidim server side in order to allow single page apps to handle the OAuth
authorization flow fully.

This is how the OAuth authorization flow should be implemented for browser
applications. In case you are interested to learn more about implementing the
OAuth authorization flow for **public** clients, such as native web
applications, take a look at the Android application example implementation.

## Preparation

### Install Node.js and project dependencies

Download and install Node.js following the official instructions at:

https://nodejs.org/en/download

Once installed, at the root of this project, run the following command:

```bash
$ npm i
```

### Run the Decidim server

For the application to be able to connect to Decidim, compile the assets and run
the Decidim server:

```bash
$ bundle exec ./bin/shakapacker
$ bundle exec rails s
```

### Configure the OAuth application for Decidim

Within the Decidim's `/system` panel, go to "OAuth applications" and create a
new application with the following details:

- **OAuth Application Name**: Confidential web example
- **Application type**: Confidential
- **Redirect URI**: `http://localhost:8080/auth/callback`
- **Organization**: Example corp
- **Organization URL**: https://www.example.org
- **Organization logo (square)**: (add any image)
- **Available scopes**: `profile`, `user`, `api:read`

### Configure this application

At the root of this project, copy the file named `.env.example` to `.env` and
configure the correct values there. In case you are running Decidim locally on
the same computer with the default configurations, only values you should need
to change are `OAUTH_CLIENT_ID` and `OAUTH_CLIENT_SECRET` which you can get from
the previous step when configuring Decidim.

## Testing the application

After the preparation phase, run the following command at the root of this
project:

```bash
$ npm run dev
```

This will start a simple web server written with Node.js serving both, the
application front-end and the backend handling the communication between this
application and Decidim.

Once the server is running, browse to the address displayed in the console:

http://localhost:8080

Start the authentication process by clicking the button on the application's
initial view. You will be redirected to the Decidim OAuth authorization process
after which the application interacts with the Decidim API as a signed in user
utilizing the authentication token received from the Decidim OAuth authorization
flow.

## Notes about this implementation

This implementation is done for demonstrational purposes and it should not be
utilized as-is for actual production applications. There are several software
libraries that implement the OAuth authorization flow that are widely used,
actively maintained and well tested in actual implementations.

This project implements the whole OAuth authorization flow in order to
demonstrate how the integration works as a whole. It is not meant to be used as
a basis for such implementations but rather to show what should happen during
the OAuth authorization.
