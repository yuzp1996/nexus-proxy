# nexus-proxy

[![Build Status](https://travis-ci.org/travelaudience/nexus-proxy.svg?branch=master)](https://travis-ci.org/travelaudience/nexus-proxy)
[![Docker Repository on Quay](https://quay.io/repository/travelaudience/docker-nexus-proxy/status "Docker Repository on Quay")](https://quay.io/repository/travelaudience/docker-nexus-proxy)

A proxy for Nexus Repository Manager that allows for optional authentication against external identity providers.

Read [the design document](docs/design.md) for a more detailed explanation of why and how.

## Before proceeding

**ATTENTION**: This software does not manage or enforce authorization. It's
therefore required that users, roles and permissions are to be configured
through Nexus administrative UI before start using Nexus.

**ATTENTION**: If GCP IAM authentication is enabled, every user account
**must be created** with their organization email address as the username.
A password needs to be set but it will only be important if GCP IAM
authentication is disabled. **Also** it is necessary to grant the
"_Organization Viewer_" role [**at organization-level**](https://cloud.google.com/iam/docs/resource-hierarchy-access-control)
(i.e., in the "_IAM & Admin_" section of the organization in the GCP UI) to
every user.

**ATTENTION:**: If GCP IAM authentication is enabled, it is necessary to
[enable the Nexus "_Rut Auth_" capability](https://help.sonatype.com/display/NXRM3/Security#Security-AuthenticationviaRemoteUserToken).
Otherwise, authentication succeeds but Nexus can't initiate user sessions.

**ATTENTION**: The Nexus-specific credentials mentioned above are valid for
one year **and** for as long as the user is a member of the GCP organization.

**ATTENTION**: If the `ENFORCE_HTTPS` flag is set to `true` it is assumed that
one has configured `nexus-proxy` or any load-balancers in front of it to serve
HTTPS on host `NEXUS_HTTP_HOST` and port `443` with a valid TLS certificate.

**ATTENTION:**: Setting the `JWT_REQUIRES_MEMBERSHIP_VERIFICATION` environment variable to `false` inherently makes `nexus-proxy` less secure.
In this scenario, a user containing a valid JWT token will be able to make requests using CLI tools like Maven or Docker without having to go through the OAuth2 consent screen.
For example, if a user leaves the organization while keeping a valid JWT token, and this environment variable is set to `false`, they will still be able to make requests to Nexus.

## Introduction

While deploying Nexus Repository Manager on GKE, we identified a couple issues:

1. GCLB backend health-checks weren't working when reaching Nexus directly.
1. Couldn't expose Docker private registry with the same set-up used to
expose the other artifact repositories.

We also knew beforehand that we would need to authenticate Nexus against
[Google Cloud Identity & Access Management](https://cloud.google.com/iam/).

While the aforementioned issues were easily fixed with [Nginx](https://nginx.org/en/),
the authentication part proved much more complicated. For all of those reasons,
we decided to implement our own proxy software that would deliver everything we
needed.

Also, authentication is disabled by default so it can be used in simpler scenarios.

**When GCP IAM authentication is enabled**, every user attempting to access Nexus
is asked to authenticate against GCP with their GCP organization credentials.
If authentication succeeds, an encrypted token will be generated by the proxy
and sent to the client ,e.g. browser, so it knows how to authenticate itself.
After being logged-in, and only when authentication is enabled, the user must
request Nexus-specific credentials for using with tools like Maven,
Gradle, sbt, Python (pip) and Docker.

## Pre-requisites

For building the project:

* JDK 8.

For basic proxying:

* A domain name configured with an `A` and a `CNAME` records pointing to the proxy.
  * For local testing one may create two entries on `/etc/hosts` pointing to `127.0.0.1`.
* A running and properly configured instance of Nexus.
  * One may use the default `8081` port for the HTTP connector and `5003` for the Docker registry, for example.

For opt-in authentication against Google Cloud IAM:

* All of the above.
* A GCP organization.
* A GCP project with the _Cloud Resources Manager_ API enabled.
* A set of credentials of type _OAuth Client ID_ obtained from _GCP > API Manager > Credentials_.
* Proper configuration of the resulting client's "_Redirect URL_".

## Generating the Keystore

A Java keystore is needed in order for the proxy to sign user tokens (JWT).
Here's how to generate the keystore:

```bash
$ keytool -genkey \
          -keystore keystore.jceks \
          -storetype jceks \
          -keyalg RSA \
          -keysize 2048 \
          -alias RS256 \
          -sigalg SHA256withRSA \
          -dname "CN=,OU=,O=,L=,ST=,C=" \
          -validity 3651
```

One will be prompted for two passwords. One must make sure the passwords match.

Also, one is free to change the value of the `dname`, `keystore` and `validity` parameters.

## Building the code

The following command will build the project and generate a runnable jar:

```bash
$ ./gradlew build
```

## Running the proxy

The following command will run the proxy on port `8080` with no authentication
and pointing to a local Nexus instance:

```bash
$ ALLOWED_USER_AGENTS_ON_ROOT_REGEX="GoogleHC" \
  BIND_PORT="8080" \
  NEXUS_DOCKER_HOST="containers.example.com" \
  NEXUS_HTTP_HOST="nexus.example.com" \
  NEXUS_RUT_HEADER="X-Forwarded-User" \
  TLS_ENABLED="false" \
  UPSTREAM_DOCKER_PORT="5000" \
  UPSTREAM_HTTP_PORT="8081" \
  UPSTREAM_HOST="localhost" \
  java -jar ./build/libs/nexus-proxy-2.3.0.jar
```

## Running the proxy with GCP IAM authentication enabled

The following command will run the proxy on port `8080` with GCP IAM
authentication enabled and pointing to a local Nexus instance:

```bash
$ ALLOWED_USER_AGENTS_ON_ROOT_REGEX="GoogleHC" \
  AUTH_CACHE_TTL="60000" \
  BIND_PORT="8080" \
  CLOUD_IAM_AUTH_ENABLED="true" \
  CLIENT_ID="my-client-id" \
  CLIENT_SECRET="my-client-secret" \
  KEYSTORE_PATH="./.secrets/keystore.jceks" \
  KEYSTORE_PASS="my-keystore-password" \
  NEXUS_DOCKER_HOST="containers.example.com" \
  NEXUS_HTTP_HOST="nexus.example.com" \
  NEXUS_RUT_HEADER="X-Forwarded-User" \
  ORGANIZATION_ID="123412341234" \
  REDIRECT_URL="https://nexus.example.com/oauth/callback" \
  SESSION_TTL="1440000" \
  TLS_ENABLED="false" \
  UPSTREAM_DOCKER_PORT="5000" \
  UPSTREAM_HTTP_PORT="8081" \
  UPSTREAM_HOST="localhost" \
  java -jar ./build/libs/nexus-proxy-2.3.0.jar
```

## Environment Variables

| Name                                | Description |
|-------------------------------------|-------------|
| `ALLOWED_USER_AGENTS_ON_ROOT_REGEX` | A regex against which to match the `User-Agent` of requests to `GET /` so that they can be answered with `200 OK`. |
| `AUTH_CACHE_TTL`                    | The amount of time (in _milliseconds_) during which to cache the fact that a given user is authorized to make requests. |
| `BIND_HOST`                         | The interface on which to listen for incoming requests. Defaults to `0.0.0.0`. |
| `BIND_PORT`                         | The port on which to listen for incoming requests. |
| `CLIENT_ID`                         | The application's client ID in _GCP / API Manager / Credentials_. |
| `CLIENT_SECRET`                     | The abovementioned application's client secret. |
| `CLOUD_IAM_AUTH_ENABLED`            | Whether to enable authentication against Google Cloud IAM. |
| `ENFORCE_HTTPS`                     | Whether to enforce access by HTTPS only. If set to `true` Nexus will only be accessible via HTTPS. |
| `JAVA_TOOL_OPTIONS`                 | JVM options to provide, for example `-XX:MaxDirectMemorySize=1024M`. |
| `JWT_REQUIRES_MEMBERSHIP_VERIFICATION` | Whether users presenting valid JWT tokens must still be verified for membership within the organization. |
| `KEYSTORE_PATH`                     | The path to the keystore containing the key with which to sign JWTs. |
| `KEYSTORE_PASS`                     | The password of the abovementioned keystore. |
| `LOG_LEVEL`                         | The desired log level (i.e., `trace`, `debug`, `info`, `warn` or `error`). Defaults to `info`. |
| `NEXUS_DOCKER_HOST`                 | The host used to access the Nexus Docker registry. |
| `NEXUS_HTTP_HOST`                   | The host used to access the Nexus UI and Maven repositories. |
| `NEXUS_RUT_HEADER`                  | The name of the header which will convey auth info to Nexus. |
| `ORGANIZATION_ID`                   | The ID of the organization against which to validate users' membership. |
| `REDIRECT_URL`                      | The URL where to redirect users after the OAuth2 consent screen. |
| `SESSION_TTL`                       | The TTL (in _milliseconds_) of a user's session. |
| `TLS_CERT_PK12_PATH`                | The path to the PK12 file to use when enabling TLS. |
| `TLS_CERT_PK12_PASS`                | The password of the PK12 file to use when enabling TLS. |
| `TLS_ENABLED`                       | Whether to enable TLS. |
| `UPSTREAM_DOCKER_PORT`              | The port where the proxied Nexus Docker registry listens. |
| `UPSTREAM_HTTP_PORT`                | The port where the proxied Nexus instance listens. |
| `UPSTREAM_HOST`                     | The host where the proxied Nexus instance listens. |
