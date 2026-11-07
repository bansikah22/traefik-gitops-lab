# Course Walkthrough

This guide explains the prepared files and the commands to run later. All commands
assume your terminal is in `fleet-infra` unless a step says otherwise. Written
exercises have been prepared to their final HTTPS-enabled state; following the
guide deploys that final state, rather than recreating each historical Git commit.

## Course Index

| Order | Course lesson | Preparation |
| --- | --- | --- |
| 1 | [A message from your instructor](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/lessons/33468795-a-message-from-your-instructor) | Video for your review |
| 2 | [GitOps is Configuration Management](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/lessons/34429436-gitops-is-configuration-management) | Video for your review |
| 3 | [Templating Manifests With Kustomize](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/lessons/34429575-templating-manifests-with-kustomize) | Video for your review |
| 4 | [How Flux Operates](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/lessons/34429585-how-flux-operates) | Video for your review |
| 5 | [Our Objectives](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/lessons/34429595-our-objectives) | Video for your review |
| 6 | [Set up your working directory](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/texts/33468952-set-up-your-working-directory) | Complete layout |
| 7 | [Base: Traefik Proxy](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/texts/33468981-base-traefik-proxy) | Base, source, CRDs |
| 8 | [Staging: Traefik Proxy](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/texts/33470053-staging-traefik-proxy) | Staging overlay |
| 9 | [Bootstrap Staging](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/texts/33470086-bootstrap-staging) | Flux instructions; execution deferred |
| 10 | [Managing Flux](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/texts/33470100-managing-flux) | Commands below |
| 11 | [Deploy the Application](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/texts/33470177-deploy-the-application) | Demo base and staging |
| 12 | [Deploy Cert Manager](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/texts/33470241-deploy-cert-manager) | Chart, CRDs, self-signed issuer |
| 13 | [Secure the Application](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/texts/33470256-secure-the-application) | Middleware, certificate, HTTPS routes |
| 14 | [Deploy to Production](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/texts/33470294-deploy-to-production) | Full production overlays |
| 15 | [Pop quiz!](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/quizzes/36645520-pop-quiz) | Complete yourself |
| 16 | [Leave a Review](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/multimedia/36645548-leave-a-review) | Optional personal action |
| 17 | [Share Your Success!](https://academy.traefik.io/courses/take/gitops-for-reliable-kubernetes/texts/36645560-share-your-success) | Personal action after testing |

## 1. Prerequisites

Use two disposable clusters, one staging and one production lab. The course
assumes they already exist; it does not prescribe a cluster provisioning recipe
in the written setup exercises. Do not point these manifests at your existing
homelab or an actual production cluster.

Have Git, kubectl, Kustomize, Helm, the Flux CLI, Ruby for the local checker,
GitHub authentication, and a way to reach the clusters' Traefik Services.
`kubectl kustomize` can replace standalone `kustomize build` throughout this guide.

On macOS, if needed and after reviewing the tool choices, install tools yourself:

```sh
brew install git kubectl kustomize helm fluxcd/tap/flux
```

Ruby is already available on many Macs; if `ruby --version` fails, install Ruby
using your normal toolchain or Homebrew. Nothing was installed during preparation.

Check client versions and your available contexts:

```sh
git --version
kubectl version --client
kustomize version
helm version --short
flux --version
ruby --version
kubectl config get-contexts
```

Check [compatibility notes](compatibility.md) before selecting cluster versions.
The historical charts are not supported production components in 2026. A local
Kubernetes installation may require load-balancer support or port-forwarding.
Avoid a preinstalled conflicting Traefik instance; K3s normally installs its own.

## 2. Understand the Bases and Overlays

The layout already exists. To reproduce the initial directory exercise elsewhere,
the course starts with:

```sh
mkdir fleet-infra
cd fleet-infra
mkdir -p {apps,infrastructure}/{base,production,staging}
mkdir -p {clusters,crds}/{production,staging}
mkdir -p sources/helm
```

Do not run that inside this prepared directory; it would create a nested lab.
Compare the shared bases with their overlays. A base is reusable input, not a
complete environment to apply directly: the app base intentionally lacks hostname
rules and certificate DNS names until an overlay supplies them.

## 3. Review Traefik Proxy

The base installs the namespace and HelmRelease. The staging overlay generates a
ConfigMap from Helm values and patches in chart `10.14.2`. Production pins
`10.14.1`. CRD versions match each environment's chart.

```sh
kubectl kustomize infrastructure/staging/traefik-proxy
kubectl kustomize infrastructure/production/traefik-proxy
```

Look for a hashed `traefik-values-...` ConfigMap and the same name in the
HelmRelease's `valuesFrom`. This is why the base has custom Kustomize name-reference
configuration. Changing values creates a new ConfigMap name; the HelmRelease then
points at the new configuration. This does not guarantee every Helm change causes
a Deployment rollout; the chart and resulting workload determine that.

## 4. Set Hostnames and Validate

Replace the placeholders in both environments' app certificate and IngressRoute
files. Each environment has one certificate DNS name and two matching host rules.
Use an address reachable from your browser, not the instructor's private IPs.

If the LoadBalancer address is assigned only after bootstrap, you can initially
deploy the placeholders, discover the address, then update and push the hostnames;
the placeholder routes simply will not serve your intended URL. For a ready-to-use
first deployment, establish the lab address ahead of time.

```sh
bash scripts/validate.sh
bash scripts/validate.sh --ready
```

The checker intentionally accepts placeholders in its default mode and rejects
them in `--ready` mode. Neither mode deploys anything or proves runtime readiness.

## 5. Create Your GitHub Repository and Initial Commit

Create an empty GitHub repository without generated initial files. Replace the
account and repository names below. Do not push to the instructor's example repo.

```sh
git init -b main
git add README.md .gitignore apps clusters crds infrastructure sources docs scripts
git diff --cached
git commit -m "Prepare Traefik Academy GitOps lab"
git remote add origin git@github.com:YOUR_ACCOUNT/YOUR_REPOSITORY.git
git push -u origin main
```

Review staged files for secrets before committing. These commands have not been
run. Use the HTTPS remote form instead if that matches your GitHub setup.

## 6. Bootstrap Staging

This step changes GitHub and the selected Kubernetes cluster. Use your own account,
the bare repository name, and a token allowed to manage that repository's deploy
key. Follow the current [Flux GitHub bootstrap authentication documentation](https://fluxcd.io/flux/installation/bootstrap/github/).
Fine-grained token permissions differ from classic PAT scopes.

On macOS, copy the token privately and assign it without typing it into history:

```sh
export GITHUB_USER="YOUR_ACCOUNT"
export GITHUB_REPO="YOUR_REPOSITORY"
export GITHUB_TOKEN="$(pbpaste)"
```

Do not print the token, put it in Git, or send it to an assistant. Clear the
clipboard after use through your normal local workflow. The corrected `$(pbpaste)`
syntax differs from the malformed shell example in the course.

```sh
kubectl config use-context YOUR_STAGING_CONTEXT
kubectl config current-context
flux check --pre
flux bootstrap github \
  --personal \
  --owner="$GITHUB_USER" \
  --repository="$GITHUB_REPO" \
  --branch=main \
  --path=clusters/staging
git pull --ff-only
unset GITHUB_TOKEN
```

For an organization-owned repository, consult Flux's documentation instead of
using `--personal`. Stop if `flux check --pre` fails. Bootstrap writes its
`flux-system` manifests to Git; pull those changes before your next commit.

The final-state repository deploys all staging layers during bootstrap, not just
Traefik. Sources and CRDs come first, then infrastructure, then applications.

## 7. Manage Flux and Check Staging

```sh
kubectl config current-context
flux check
flux get kustomizations
flux get sources git
flux get sources chart -A
flux get helmreleases -A
kubectl get pods -n flux-system
kubectl get pods -n traefik-system -l app.kubernetes.io/name=traefik
kubectl get pods -n cert-manager
kubectl get clusterissuer self-signed
kubectl get certificate -n traefik-demo
kubectl rollout status deployment/traefik-demo -n traefik-demo
kubectl get service -n traefik-system
```

Expect sources, crds, infrastructure, apps, and flux-system reconciliations to be
ready; both HelmReleases and the certificate should be ready too. An initial
dependency error may be transient while controllers start. Investigate errors
that persist; do not mark success just because pods exist.

After a Git change, request reconciliation rather than waiting for the interval:

```sh
flux reconcile source git flux-system
flux reconcile kustomization flux-system
flux reconcile kustomization infrastructure
flux reconcile kustomization apps
```

Reconcile `flux-system` to discover newly added cluster-level reconciliation
resources. Existing layers can then be reconciled independently.

## 8. Review the Demo Application

The Service exposes port 80 and targets container port 8080. The staging Deployment
adds `ICON_COLOR=blue`. The base intentionally leaves `replicas` unset.

For the optional scaling exercise, after confirming the staging context:

```sh
kubectl scale deployment/traefik-demo --replicas=3 -n traefik-demo
```

Refresh the app repeatedly to observe pod colors. Since Git does not own a replica
count, this exercise should not be reset simply by Flux reconciliation. Restore
the original lab scale later with the same command using `--replicas=1`.

## 9. Review Certificates and HTTPS

Cert-manager installs from Jetstack and creates the `self-signed` ClusterIssuer.
The app Certificate requests a hostname-specific certificate stored in
`traefik-demo-crt`. HTTPS references that Secret; HTTP uses the shared permanent
redirect Middleware in `traefik-system`.

```sh
kubectl describe certificate traefik-demo -n traefik-demo
kubectl get ingressroutes -n traefik-demo
kubectl get middleware -n traefik-system
curl -I http://YOUR_STAGING_HOSTNAME
curl -k https://YOUR_STAGING_HOSTNAME
```

Expect an HTTP redirect to HTTPS and a blue-icon application response. The
certificate is self-signed, so browsers warn about trust. `curl -k` bypasses trust
checking only for this disposable lab; it is not a production TLS solution.

For a local cluster without external access, port-forward the Traefik Service:

```sh
kubectl port-forward -n traefik-system service/traefik-proxy 8080:80 8443:443
```

In a separate terminal, send the configured hostname with SNI and Host routing:

```sh
curl -k --resolve YOUR_STAGING_HOSTNAME:8443:127.0.0.1 https://YOUR_STAGING_HOSTNAME:8443/
```

An HTTP redirect normally targets HTTPS port 443, not the forwarded 8443. Verify
the redirect header separately and use the explicit HTTPS URL above for the app.
Port-forwarding is an additional local convenience, not a course-prescribed step.

## 10. Bootstrap the Production Lab

Production omits experimental HTTP/3, uses `maxUnavailable: 0`, pins the older
tested Traefik chart, and changes the demo icon to white. It still uses self-signed
TLS because this is a simulation, not real production security.

If you changed hostnames after the initial commit, validate, commit, and push them
before bootstrap. Reassign `GITHUB_TOKEN` privately, then:

```sh
kubectl config use-context YOUR_PRODUCTION_LAB_CONTEXT
kubectl config current-context
flux check --pre
flux bootstrap github \
  --personal \
  --owner="$GITHUB_USER" \
  --repository="$GITHUB_REPO" \
  --branch=main \
  --path=clusters/production
git pull --ff-only
unset GITHUB_TOKEN
```

Repeat the staging checks against this context and production hostname. Expect
white icons, a matching certificate, and healthy layer reconciliations. The same
repository feeds both clusters, but each cluster watches its own path.

## 11. Practice Changes and Promotion

1. Change a staging overlay and run the local validator.
2. Review the diff, commit, and push; reconcile staging.
3. Verify the rendered revision and actual application behavior.
4. Apply the approved change to production's overlay. For chart changes, update
   that environment's CRD references as well.
5. Validate, commit, push, and verify production.

To reverse a configuration change, use `git revert <COMMIT_SHA>`, then push and
reconcile. Inspect the revert before applying it to both clusters. Git rollback
does not undo database changes or recover application data.

## 12. Troubleshoot and Clean Up

```sh
flux logs --level=error
kubectl get events -A --sort-by=.metadata.creationTimestamp
kubectl describe helmrelease traefik-proxy -n traefik-system
kubectl describe helmrelease cert-manager -n cert-manager
kubectl describe certificate traefik-demo -n traefik-demo
```

Missing CRDs: check the crds reconciliation and its remote downloads. Helm chart
fetch errors: check sources, chart version, and network access. A webhook failure:
check cert-manager readiness. A 404: check the request Host header, rule hostname,
Service selector, and port. A certificate warning is expected with this issuer.

Cleanup is safest by deleting only the disposable lab clusters using the tool
that created them. Do not run generic namespace-deletion commands against another
cluster. Stop port-forward processes and remove/revoke lab deploy keys or tokens
when no longer needed. Delete the GitHub repo only if you no longer want the notes.

With `prune: true`, removing a resource from Git can delete it from the cluster;
removing managed CRDs may also remove their custom resources. Suspend reconciliation
before dismantling a shared environment, and review ownership and deletion policy.
`flux uninstall` alone does not mean every managed application has been removed.

Finish the videos and quiz yourself, then optionally review/share the course once
you have personally checked the lab. No course progress was changed in preparation.