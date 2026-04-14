# Deployment

![services](services.png)

## Overview
The `deployment` directory packages a Docker Compose stack that wires together the Config Server, Eureka, and service containers with their supporting PostgreSQL instances. Use it when you need the full microservices suite running locally.

## Prerequisites
- Docker
- The `ostock/*` images available locally or pulled from a registry (`config-server`, `eureka-server`, `organization-service`, `licensing-service`).

## Run The Stack
From this repository execute:

```sh
docker compose up
```

This command starts the two PostgreSQL containers, waits for the Config Server health check to pass, and then launches the dependent services.

The Eureka, Organization Service, and Licensing Service containers run with the `docker` profile enabled, so they load the network-aware configuration served by the Config Server. If you override that locally, keep the profile set to `docker`.

## Tear Down

```sh
docker compose down
```

## Troubleshooting
- If a service exits immediately, inspect its logs with `docker compose logs <service>`.
- Seeing Eureka retry `http://localhost:8761/eureka` usually means the docker profile is not active. Rebuild the images and confirm `spring.profiles.active=docker` is present on the affected containers.
