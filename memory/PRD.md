# PRD — Camunda 8.9 SM on OpenShift (air-gapped, ArgoCD)

## Problem statement
Turn the repo `Camunda_8_9_1_Buro/camund-cd-cont` into production-ready, ArgoCD-
deployable Helm charts for Camunda Platform 8.9, external Keycloak, and a Vault
agent. Every component must carry: trusted-ca mount, OpenShift serving-cert service
annotation, illumio/sfm/laas labels+annotations, keytool initContainers, dedicated
ServiceAccount, and a Vault sidecar (fetch secrets from HashiCorp Vault, update the
app secret, rolling restart). External Postgres + Elasticsearch with creds from Vault.
HAProxy as the single entry point for all exposed services (web, REST, gRPC,
monitoring, stats). Values.yaml must be literal (no Go-template rendering). Keep
charts simple/airgap-friendly. Provide documentation.

## Architecture
- 3 ArgoCD apps (namespace `ns`), sync waves: vault-agent(0) → keycloak(1) → platform(2).
- Vault sidecar image (`vault-sidecar`) in `fetch` (bootstrap Job) and `sidecar` modes; no Vault webhook injector.
- External PG + ES; creds in K8s Secrets seeded/rotated from Vault.
- HAProxy (in vault-agent chart) routes by path/port to all services; values-driven backends; optional OpenShift Route.

## Done (2026-06-19)
- `config/camunda-keycloak/x0/values.yaml` — rewritten, literal, validated (helm template, 9 docs, 0 `{{}}`).
- `config/camunda-platform/x0/values.yaml` — full 3385→4159-line file with cross-cutting injected via ruamel + YAML anchors; external PG/ES + OIDC external keycloak; validated (34 docs, 0 `{{}}`). Bundled ES subchart removed.
- `charts/camunda-vault-agent/values.yaml` + flat `config/.../values.yaml`; 5 Vault targets; HAProxy template rewritten values-driven + Route; validated (27 docs, 0 `{{}}`, lint pass).
- Keycloak chart: route-public/route-mgmt templates + trusted-ca CM template added.
- `deploy.yaml` (3 apps + waves), `.gitlab-ci.yml` image list, `README.md`, `docs/PORTS.md`, `docs/haproxy.cfg`.

## Vault paths → secrets
- keycloak: `AP/secret/dev/x0/camunda_keycloak`(admin) + `AP/database/creds/keycloak` → camunda-keycloak-secret
- identity: `AP/database/creds/identity` → camunda-identity-db-secret
- web-modeler: `AP/database/creds/web-modeler` → camunda-web-modeler-db-secret
- orchestration/optimize: `AP/secret/dev/x0/elasticsearch` → camunda-orchestration-es-secret / camunda-optimize-es-secret

## Backlog / next
- DONE (2026-06-19): keycloak-config-cli realm import re-enabled (realm `camunda-platform` + `camunda-identity` client; secret from Vault `camunda-keycloak-clients-secret`).
- DONE (2026-06-19): HAProxy TLS termination enabled (`:443`, reencrypt Route, HTTP→HTTPS redirect).
- P2: Static Vault DB roles for identity/web-modeler if usernames must rotate.
- P2: Connectors/Console Vault sidecars if OIDC client secrets are externalised.
- All deliverables are in `/app/work/camund-cd-cont` — push via "Save to GitHub".
