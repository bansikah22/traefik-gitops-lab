# Traefik Academy GitOps Lab

Learning workspace for [GitOps For Reliable Kubernetes](https://academy.traefik.io/courses/gitops-for-reliable-kubernetes).

Prepared from the authenticated written lessons on 2026-11-07. All written lab
components are present for staging and production: Traefik Proxy, cert-manager,
the self-signed issuer, the demo application, HTTP-to-HTTPS redirects,
certificates, and Flux reconciliation instructions.

**This is a historical learning lab, not a production-ready platform.** The
course uses old chart versions. Local rendering is validated, but live deployment
and compatibility with a particular Kubernetes version are not verified.

## Read Later

1. [Course walkthrough and all 17 lesson links](docs/walkthrough.md)
2. [Architecture, tools, and implementation choices](docs/architecture.md)
3. [Compatibility changes and validation evidence](docs/compatibility.md)

The walkthrough is an original companion guide, not a course transcript. Videos
and the quiz remain linked for your own study; no answers, review, or completion
actions have been submitted on your behalf.

## Layout

```text
apps/{base,staging,production}/traefik-demo/
clusters/{staging,production}/
crds/{staging,production}/{traefik-proxy,cert-manager}/
infrastructure/{base,staging,production}/{traefik-proxy,cert-manager}/
sources/helm/
docs/
scripts/validate.sh
```

Both environments share bases but have separate overlay and Flux paths. Flux
will generate `clusters/<environment>/flux-system/` during bootstrap; those files
are deliberately not fabricated before you have a GitHub repository.

## Prepared Versions

| Component | Staging | Production lab |
| --- | --- | --- |
| Traefik Helm chart and CRDs | 10.14.2 | 10.14.1 |
| cert-manager chart and CRDs | v1.7.1 | v1.7.1 |
| Demo image | monachus/traefik-demo, implicit latest | Same |
| Icon color | blue | white |
| HTTP/3 experimental flag | enabled | not enabled |
| Issuer | self-signed | self-signed |

Flux resources use stable APIs. The staging chart pins intentionally differ from
the course's unbounded automatic-upgrade ranges. See the compatibility notes.

## Before Deployment

- Create your empty GitHub repository when ready; no repository was created here.
- Provide two disposable Kubernetes clusters and confirm their contexts.
- Replace `traefik-demo.staging.example.invalid` in the staging app's
	`certificate.yaml` and `ingressroute.yaml` with your staging hostname.
- Replace `traefik-demo.production.example.invalid` in the equivalent production
	files with your production hostname.
- Follow the walkthrough's validation, authentication, and bootstrap steps.

Use a hostname that resolves to the Traefik LoadBalancer address, such as
`traefik-demo.<YOUR_CLUSTER_IP>.sslip.io`. The certificate DNS name and both route
rules must match. Self-signed TLS does not require public ACME validation.

## Validate Locally

From this directory:

```sh
bash scripts/validate.sh
bash scripts/validate.sh --ready
```

The first command checks all seven rendered layers and their relationships. The
second additionally rejects placeholder hostnames. Both need `kubectl`, Ruby,
and internet access to download the pinned CRDs; neither contacts a cluster.
`--ready` is a hostname gate, not proof of runtime readiness or version support.

No tools were installed, Git history created, GitHub repository created, or
Kubernetes/cloud resources changed during this preparation.