# Compatibility and Verification

Prepared on 2026-11-07 from the authenticated written Traefik Academy lessons.
The course examples reflect an older Kubernetes ecosystem. This workspace keeps
the course's architecture and historical chart versions but makes the following
explicit adjustments. It does not claim that the old applications are supported
on current Kubernetes releases.

## Changes From the Written Examples

| Original example | Prepared workspace | Reason |
| --- | --- | --- |
| HelmRepository `source.toolkit.fluxcd.io/v1beta1` | `v1` | Stable current Flux API |
| HelmRelease `helm.toolkit.fluxcd.io/v2beta1` | `v2` | Stable current Flux API |
| Flux Kustomization `kustomize.toolkit.fluxcd.io/v1beta2` | `v1` | Stable current Flux API |
| Kustomize `bases` | `resources` | Current Kustomize syntax |
| `patchesStrategicMerge` | `patches` with file paths | Current Kustomize syntax; multi-document routes build successfully |
| Staging Traefik `>=10.14.0` | `10.14.2` | Prevent an unrelated current major version from exceeding the old CRDs/values |
| Staging cert-manager `>=v1.7.0` | `v1.7.1` | Keep chart and CRDs aligned instead of selecting latest |
| Traefik published Service `traefik-system/traefik` | `traefik-system/traefik-proxy` | Chart helper uses the `traefik-proxy` release name |
| Instructor's IP-based hostnames | Environment-specific `.example.invalid` placeholders | Require your actual lab hostnames rather than routing to someone else's environment |
| GitHub `/raw/` URLs for Traefik CRDs | Version-pinned raw.githubusercontent.com URLs | Same tagged resources without extra GitHub page redirects |
| Some prose paths omit staging or put the app route under infrastructure | Files use the consistent trees and code-block paths | Correct apparent path typos |
| Implicit directory aggregation in Flux | Explicit aggregate Kustomize files | Make each layer buildable with local tooling |
| Infrastructure applies without health wait | `wait: true` and `timeout: 10m` | Apps wait for healthy infrastructure, reducing webhook startup races |
| cert-manager-wide namespace transformer also affects ClusterIssuer | Explicit namespace on its HelmRelease; no global namespace transformer | Keep the issuer cluster-scoped while HelmRelease remains namespaced |
| `export GITHUB_TOKEN=(pbpaste)` | `export GITHUB_TOKEN="$(pbpaste)"` | Correct Bash/zsh command substitution |

Production Traefik remains `10.14.1` with matching CRDs, production cert-manager
remains `v1.7.1`, and the original demo image and self-signed issuer are retained.
Traefik's `traefik.containo.us/v1alpha1` custom-resource group is intentionally
kept because it matches those historical CRDs. Do not change it independently to
`traefik.io/v1alpha1` without a coordinated Traefik/chart/CRD migration.

## Verification Performed

- All 11 initial course directories were checked.
- All seven environment/source layers built with `kubectl kustomize`.
- Both environments' remote Traefik and cert-manager CRD files downloaded and
  rendered: 15 CRDs per environment.
- The Bash validator passed syntax checking and both structural check sets.
- Checks cover chart pins, hashed ConfigMap references, namespaces, self-signed
  issuer linkage, demo icon colors, omitted replicas, matching HTTP/HTTPS and
  certificate hostnames, TLS Secret names, and Flux paths/dependencies.
- cert-manager Helm chart `v1.7.1` rendered successfully: 43 chart resources.
- The Traefik chart's tagged naming helper confirms the published-Service name
  is `traefik-proxy` for that release name.

## Unverified and Deferred

- The Traefik `10.14.2` chart download timed out from
  `https://traefik.github.io/charts/traefik/traefik-10.14.2.tgz`; no chart-render
  success was claimed. Recheck the network and repository artifact before deployment.
- No live cluster was contacted, bootstrapped, or modified.
- GitHub repository creation, authentication, pushes, and generated Flux bootstrap
  files await your repository and cluster choices.
- Actual Helm reconciliation, controller readiness, issuer/certificate readiness,
  routing, TLS, and load-balancing behavior remain to be tested.
- Kubernetes server-version compatibility, image availability, and image CPU
  architecture support are not established. In particular, check the historical
  demo image on an Apple Silicon local cluster before relying on native arm64.
- Videos were not transcribed or treated as watched. The guide links them for your
  review. Quiz answers, reviews, and sharing actions were not submitted.

## Recheck Before Running

```sh
bash scripts/validate.sh
bash scripts/validate.sh --ready
helm template traefik-proxy traefik \
  --repo https://helm.traefik.io/traefik \
  --version 10.14.2 \
  --namespace traefik-system \
  -f infrastructure/staging/traefik-proxy/values.yaml
helm template traefik-proxy traefik \
  --repo https://helm.traefik.io/traefik \
  --version 10.14.1 \
  --namespace traefik-system \
  -f infrastructure/production/traefik-proxy/values.yaml
helm template cert-manager cert-manager \
  --repo https://charts.jetstack.io \
  --version v1.7.1 \
  --namespace cert-manager
```

Run `flux check --pre` only after selecting the intended lab cluster. This checks
Flux prerequisites, not whether old third-party charts are supported. A clean
Kustomize build checks composition, not cluster-side admission or application health.

If historical charts do not work on your chosen cluster, stop and plan a separate
modernization: upgrade chart versions and their CRDs together, update Traefik
custom-resource API groups and Helm values, verify cert-manager support, and pin
a tested demo image digest. Do not silently upgrade only one piece or downgrade
an existing shared cluster to make a historical exercise work.