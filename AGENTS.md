# Deployment Agent Notes

This folder owns the local Docker Compose deployment. Treat
`docker-compose.yml` as the full-stack entry point and
`docker-compose.local.yml` as local infrastructure for IDE-launched services.

## North Star

- Prefer minimal diffs that keep end-to-end deployment simple and reproducible.
- Before adding scripts, sleeps, wrappers, or custom glue, try Compose features,
  Spring profile/configuration, owning-service image metadata, and the existing
  health-check/dependency patterns.
- Keep changes diagnosable with `docker compose config`, `docker compose ps`,
  and service logs.
- Keep examples and validation commands runnable from this directory; do not
  document parent-directory helper script commands here.

## Compose Boundaries

- Keep service names stable; containers depend on Compose DNS names such as
  `config-service`, `eurekaserver`, `organization_db`, `licensing_db`,
  `keycloak_db`, and `keycloak`.
- Inside Compose, use service URLs such as `http://keycloak:8080`; use
  `localhost` only for host-side clients such as Bruno, browsers, or IDE apps.
- Service containers should run with `spring.profiles.active=docker`. A
  container reaching `localhost` for Config Server, Eureka, databases, Kafka,
  Redis, or Keycloak usually means Docker-profile wiring is missing.
- Publish ports only for developer host access. Use health checks plus
  `depends_on` conditions for startup order, not arbitrary sleeps.
- Keep network membership scoped to need: `config`, `eureka`, `kafka`, `redis`,
  `organization`, `licensing`, `keycloak`, and `observability`.

## Images And State

- Full-stack service images live under `ostock/*`: `config-server:1.0.0-SNAPSHOT`,
  `eureka-server:1.0.0-SNAPSHOT`, `gateway:0.0.1-SNAPSHOT`,
  `organization-service:0.0.1-SNAPSHOT`, and
  `licensing-service:0.0.1-SNAPSHOT`.
- PostgreSQL init SQL lives in `compose/organization/` and `compose/licensing/`;
  Docker runs it only when the database volume is first created.
- The full and local stacks intentionally share `deployment_keycloak_data`,
  `deployment_kafka_broker_data`, and `deployment_elasticsearch_data`; preserve
  that unless changing shared local state is the task.
- Keep checked-in credentials obviously local-development only. Be explicit
  about data loss before suggesting volume removal.

## Observability

- Full-stack services send OTLP traces to `otel-collector:4317`, then Jaeger.
  Local IDE-launched services send OTLP directly to Jaeger on `localhost:4317`
  or `localhost:4318`.
- Full-stack Spring services log through Fluent Bit to Logstash. The local
  infrastructure stack has no Fluent Bit; host apps should send logs to
  `localhost:5000` only when indexed logs are needed.
- Prometheus scrapes metrics; keep metrics separate from tracing and logging.

## Bruno

- `bruno/` is host-side, so requests use host-published URLs:
  `localhost:8072`, `8082`, `8080`, `8081`, `8071`, and `8070`.
- Keep requests grouped by runtime boundary: `keycloak`, `gateway`, `licensing`,
  `organization`, `config`, and `eureka`.
- Prefer variables/environments for repeated URLs, credentials, and bearer
  tokens. Do not check in long-lived JWTs.
- Keep shared auth refresh logic in `bruno/opencollection.yml` under
  `request.scripts`; protected requests should use `token: "{{admin_token}}"`.
- Use request-level `runtime.scripts` only for per-request response handling.

## Validation

```sh
docker compose config
docker compose -f docker-compose.local.yml config
docker compose -f docker-compose.local.yml up
docker compose up
docker compose ps -a
docker compose logs <service>
docker compose down
```
