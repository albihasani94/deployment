# Container Deployment Preferences

Optimize for the simplest end-to-end container design, not only the smallest local Compose change.

This directory is the local Docker Compose deployment for the microservices suite. Treat `docker-compose.yml` as the full-stack integration entry point and `docker-compose.keycloak.yml` as the standalone Keycloak entry point.

Before adding custom container glue, check whether the same outcome can be achieved with:
- existing Docker Compose features
- Spring profile or application configuration
- service image build configuration in the owning service directory
- the current network, health check, and dependency patterns

Prefer the option with the least long-term operational complexity, as long as it remains clear, reproducible, and easy to diagnose.

## Compose Guidelines

Keep service names stable. Other containers address services by Compose DNS names such as `config-service`, `eurekaserver`, `organization_db`, `licensing_db`, `keycloak_db`, and `keycloak`.

Use container-to-container URLs inside the stack, not host URLs. For example, services on the Compose network should reach Keycloak at `http://keycloak:8080`, not `http://localhost:8082`.

Expose host ports only when a developer needs to access the service directly from the host. Avoid adding extra published ports for container-only communication.

When adding dependencies between services, prefer Compose health checks for infrastructure readiness and `depends_on` conditions for startup order. Do not rely on arbitrary sleeps or retry wrapper scripts unless the service itself cannot report readiness.

Keep network membership intentional. Attach each service only to the networks it needs:
- `config` for Config Server access
- `eureka` for service discovery and Gateway routing
- `organization` for Organization Service database access
- `licensing` for Licensing Service database access
- `keycloak` for Keycloak and its database

## Image Guidelines

The full stack expects local or registry images under the `ostock/*` namespace. If a Compose image tag changes, update the owning service build configuration or document how the image is produced.

Build service images from their owning service directories instead of adding build contexts to this deployment Compose file by default. The repository-level `build-service-images.sh` script is the current convenience path for rebuilding the Maven-built service images.

Keep image names aligned with the service build metadata:
- `ostock/config-server:1.0.0-SNAPSHOT`
- `ostock/eureka-server:0.0.1-SNAPSHOT`
- `ostock/gateway:0.0.1-SNAPSHOT`
- `ostock/organization-service:0.0.1-SNAPSHOT`
- `ostock/licensing-service:0.0.1-SNAPSHOT`

## Configuration Guidelines

The service containers should run with `spring.profiles.active=docker` unless there is a deliberate reason to test another profile. Seeing a service try to contact `localhost` for Config Server, Eureka, databases, or Keycloak usually means the Docker profile or network-specific configuration is missing.

Prefer environment variables in Compose for deployment wiring and profile selection. Prefer Spring configuration files in the owning service/config-server project for reusable application behavior.

Keep secrets in this local deployment obviously development-only. The checked-in Keycloak and PostgreSQL credentials are for local use; do not make them look production-safe.

## Data Guidelines

The Organization and Licensing PostgreSQL containers initialize from `compose/organization/` and `compose/licensing/`. Keep SQL files deterministic and safe to rerun only in the context Docker's init directory supports: they run when the database data directory is first created.

The Keycloak standalone and full-stack Compose files intentionally share the `deployment_keycloak_data` Docker volume. Preserve that unless changing the shared-local-state behavior is the goal.

Before suggesting destructive cleanup commands such as removing volumes, be explicit about which data will be lost.

## Bruno Guidelines

The `bruno/` collection is a host-side API client for the local Compose deployment. Unlike container configuration, Bruno requests should use host-published URLs such as `http://localhost:8072`, `http://localhost:8082`, `http://localhost:8080`, `http://localhost:8081`, `http://localhost:8071`, and `http://localhost:8070`.

Keep requests grouped by the runtime boundary they exercise:
- `keycloak` for token and realm discovery calls
- `gateway` for end-to-end calls through Spring Cloud Gateway
- `licensing` and `organization` for direct service diagnostics
- `config` and `eureka` for platform service checks

When adding or changing requests, prefer reusable Bruno variables or environments for repeated base URLs, credentials, and bearer tokens. Do not add new long-lived copied JWTs unless the request is deliberately capturing a short-lived local example.

Keep checked-in credentials obviously local-development only. The Keycloak users, client secret, and database credentials in this deployment are not production secrets.

For validation, start the smallest Compose stack that exposes the target service, get a fresh token from the Bruno `keycloak` requests when authentication is required, then run the relevant request through Bruno or repeat the same URL with `curl`.

## Validation

For Compose-only changes, prefer lightweight validation first:

```sh
docker compose config
docker compose -f docker-compose.keycloak.yml config
```

When runtime validation is needed, start the smallest relevant stack:

```sh
docker compose -f docker-compose.keycloak.yml up
docker compose up
```

Useful checks while the stack is running:

```sh
docker compose ps -a
docker compose logs <service>
docker compose down
```

If service image changes are involved, rebuild the relevant service image from the owning service directory, or use the repository-level image build script when the full stack needs fresh images.
