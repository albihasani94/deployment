# Deployment

![services](services.png)

## Overview
The `deployment` directory packages a Docker Compose stack that wires together the Config Server, Eureka, and service containers with their supporting PostgreSQL instance. Use it when you need the full microservices suite running locally.

## Prerequisites
- Docker
- The `ostock/*` images built locally or pulled from a registry (`config-server`, `eureka-server`, `organization-service`, `licensing-service`).

## Run The Stack
From this repository execute:

```sh
docker compose up
```

This command rebuilds any stale images, starts the shared databases, waits for the Config Server readiness gate, and then launches the dependent services.

Each Spring Boot container runs with `spring.profiles.active=docker`, so it loads the network-aware configuration served by the Config Server. If you override environment variables locally, be sure to preserve the uppercase profile key so Spring picks it up.

## Tear Down

```sh
docker compose down
```

## Troubleshooting
- If a service exits immediately, inspect its logs with `docker compose -f deployment/docker-compose.yml logs <service>`.
- Seeing Eureka retry `http://localhost:8761/eureka` usually means the docker profile is not active. Rebuild the images (for example, `./build-docker-images.sh`) and confirm `spring.profiles.active=docker` is present on the affected containers.
