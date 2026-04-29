# Deployment

![services](services.png)

## Overview
The `deployment` directory packages a Docker Compose stack that wires together the Config Server, Eureka, Gateway, Keycloak, Kafka, and service containers with their supporting PostgreSQL instances. Use it when you need the full microservices suite running locally.

## Prerequisites
- Docker
- The `ostock/*` images available locally or pulled from a registry (`config-server`, `eureka-server`, `gateway`, `organization-service`, `licensing-service`).

## Run The Stack
From this repository execute:

```sh
docker compose up
```

This command starts the PostgreSQL containers, waits for the Config Server health check to pass, and then launches the dependent services.

The Eureka, Organization Service, and Licensing Service containers run with the `docker` profile enabled, so they load the network-aware configuration served by the Config Server. The Gateway also runs with the `docker` profile enabled, and its deployment-specific port, Eureka URL, and routes are set directly in `docker-compose.yml`.

Keycloak runs in development mode at `http://localhost:8082` with the bootstrap admin account `admin` / `admin`. Other containers on the Compose network can reach it at `http://keycloak:8080`.

Kafka runs as a single-node broker for local development. It is available to the Organization and Licensing service containers at `kafka:9092`. Host tools can connect at `localhost:29092`.

To start only Keycloak and its PostgreSQL database, use the standalone Compose file:

```sh
docker compose -f docker-compose.keycloak.yml up
```

The standalone file reuses the same `deployment_keycloak_data` Docker volume as the full stack, so realms, clients, users, and client secrets are shared between both run modes.

To start only Kafka, use the standalone Compose file:

```sh
docker compose -f docker-compose.kafka.yml up
```

The standalone Kafka broker uses the same local endpoints as the full stack: `kafka:9092` for containers on its Compose network and `localhost:29092` for host tools.

The gateway is exposed at `http://localhost:8072`. Example gateway URLs:

```text
http://localhost:8072/organization-service/v1/organization/{organizationId}
http://localhost:8072/licensing-service/v1/organization/{organizationId}/license/{licenseId}
```

## Tear Down

```sh
docker compose down
```

## Troubleshooting
- If a service exits immediately, inspect its logs with `docker compose logs <service>`.
- Seeing Eureka retry `http://localhost:8761/eureka` usually means the docker profile is not active. Rebuild the images and confirm `spring.profiles.active=docker` is present on the affected containers.
