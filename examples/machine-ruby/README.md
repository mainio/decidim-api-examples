# Decidim machine-to-machine integration

This application is an example of a machine-to-machine integration with Decidim
utilizing the assigned API credentials for interacting with the Decidim API. The
application is only designed to demonstrate what should happen during the API
user authentication flow and how the machine integration should interact with
the API.

## Preparation

This guide assumes you already have Ruby installed if you are normally
developing Decidim applications.

### Install the dependencies

At the root of this repository, run the following command:

```bash
$ bundle install
```

### Configure the API user for Decidim

Within the Decidim's `/system` panel, go to "API credentials" and create a new
API user with the following details:

- **Organization**: (select the target organization)
- **Name**: Machine-to-machine example

Copy the API key and API secret for the newly created user as you will need them
in the next step.

### Configure this application

At the root of this project, copy the file named `.env.example` to `.env` and
configure the correct values there. In case you are running Decidim locally on
the same computer with the default configurations, only values you should need
to change are `API_KEY` and `API_SECRET` which you can get from the previous
step when configuring Decidim.

## Testing the application

After the configuration is completed, run the following command to run the
example application:

```bash
$ bundle exec ./bin/automate
```

## Notes about this implementation

This implementation is done for demonstrational purposes and it should not be
utilized as-is for actual production applications. The API user authentication
flow is fairly simple to implement in any language and there is nothing special
related to interacting with these HTTP endpoints.

This project implements the whole API authentication flow in order to
demonstrate how the integration works as a whole. It is not meant to be used as
a basis for such implementations but rather to show what should happen during
the API authentication for machine-to-machine applications.
