#!/usr/bin/env bash
set -euo pipefail

ready=false
case "${1:-}" in
    "") ;;
    --ready) ready=true ;;
    *) printf '%s\n' 'Usage: bash scripts/validate.sh [--ready]' >&2; exit 2 ;;
esac
if [[ "$#" -gt 1 ]]; then
    printf '%s\n' 'Usage: bash scripts/validate.sh [--ready]' >&2
    exit 2
fi

for tool in kubectl ruby; do
    command -v "$tool" >/dev/null 2>&1 || {
        printf 'Required local command not found: %s\n' "$tool" >&2
        exit 1
    }
done

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

for relative in sources crds/staging crds/production infrastructure/staging infrastructure/production apps/staging apps/production; do
    filename="${relative//\//-}.yaml"
    kubectl kustomize "$root/$relative" > "$scratch/$filename"
    printf 'BUILD PASS %s\n' "$relative"
done

ruby - "$root" "$scratch" "$ready" <<'RUBY'
require 'yaml'

root, scratch, ready = ARGV
def documents(path)
  YAML.load_stream(File.read(path)).compact
end
def verify(condition, message)
  abort("FAIL: #{message}") unless condition
end
def resource(items, kind, name)
  found = items.find { |item| item['kind'] == kind && item.dig('metadata', 'name') == name }
  verify(found, "missing #{kind}/#{name}")
  found
end

sources = documents(File.join(scratch, 'sources.yaml'))
%w[traefik-proxy jetstack].each { |name| resource(sources, 'HelmRepository', name) }

%w[staging production].each do |environment|
  infrastructure = documents(File.join(scratch, "infrastructure-#{environment}.yaml"))
  apps = documents(File.join(scratch, "apps-#{environment}.yaml"))
  crds = documents(File.join(scratch, "crds-#{environment}.yaml"))
  verify(crds.length == 15 && crds.all? { |item| item['kind'] == 'CustomResourceDefinition' }, "#{environment}: expected 15 CRDs")

  traefik = resource(infrastructure, 'HelmRelease', 'traefik-proxy')
  expected_version = environment == 'staging' ? '10.14.2' : '10.14.1'
  verify(traefik.dig('spec', 'chart', 'spec', 'version') == expected_version, "#{environment}: Traefik chart pin")
  config_name = traefik.dig('spec', 'valuesFrom', 0, 'name')
  verify(config_name.start_with?('traefik-values-'), "#{environment}: ConfigMap hash missing")
  config = resource(infrastructure, 'ConfigMap', config_name)
  verify(config.dig('metadata', 'namespace') == traefik.dig('metadata', 'namespace'), "#{environment}: ConfigMap namespace")
  cert_manager = resource(infrastructure, 'HelmRelease', 'cert-manager')
  verify(cert_manager.dig('spec', 'chart', 'spec', 'version') == 'v1.7.1', "#{environment}: cert-manager chart pin")
  verify(cert_manager.dig('metadata', 'namespace') == 'cert-manager', "#{environment}: cert-manager HelmRelease namespace")
  issuer = resource(infrastructure, 'ClusterIssuer', 'self-signed')
  verify(issuer.dig('spec', 'selfSigned') == {}, "#{environment}: self-signed issuer")
  verify(!issuer['metadata'].key?('namespace'), "#{environment}: ClusterIssuer must be cluster-scoped")
  middleware = resource(infrastructure, 'Middleware', 'redirect-scheme-permanent')
  verify(middleware.dig('spec', 'redirectScheme', 'scheme') == 'https', "#{environment}: HTTPS redirect")

  deployment = resource(apps, 'Deployment', 'traefik-demo')
  verify(!deployment['spec'].key?('replicas'), "#{environment}: replicas must remain unmanaged")
  container = deployment.dig('spec', 'template', 'spec', 'containers').find { |item| item['name'] == 'traefik-demo' }
  color = container['env'].find { |item| item['name'] == 'ICON_COLOR' }['value']
  verify(color == (environment == 'staging' ? 'blue' : 'white'), "#{environment}: icon color")
  certificate = resource(apps, 'Certificate', 'traefik-demo')
  host = certificate.dig('spec', 'dnsNames', 0)
  verify(certificate.dig('spec', 'issuerRef', 'name') == 'self-signed', "#{environment}: certificate issuer")
  %w[http https].each do |protocol|
    route = resource(apps, 'IngressRoute', "traefik-demo-#{protocol}")
    verify(route.dig('spec', 'routes', 0, 'match') == "Host(`#{host}`)", "#{environment}: route/certificate hostname mismatch")
    verify(route.dig('spec', 'routes', 0, 'services', 0, 'port') == 80, "#{environment}: route service port")
    if protocol == 'https'
      verify(route.dig('spec', 'tls', 'secretName') == certificate.dig('spec', 'secretName'), "#{environment}: TLS secret mismatch")
    else
      verify(route.dig('spec', 'routes', 0, 'middlewares', 0, 'namespace') == 'traefik-system', "#{environment}: middleware namespace")
    end
  end
  verify(!host.end_with?('.invalid'), "#{environment}: replace placeholder hostname before deployment") if ready == 'true'

  %w[sources crds infrastructure apps].each do |name|
    reconciliation = documents(File.join(root, 'clusters', environment, "#{name}.yaml")).first
    verify(reconciliation['apiVersion'] == 'kustomize.toolkit.fluxcd.io/v1', "#{environment}/#{name}: Flux API version")
    path = name == 'sources' ? './sources' : "./#{name}/#{environment}"
    verify(reconciliation.dig('spec', 'path') == path, "#{environment}/#{name}: source path")
    dependencies = (reconciliation.dig('spec', 'dependsOn') || []).map { |item| item['name'] }
    expected_dependencies = name == 'apps' ? ['infrastructure'] : name == 'infrastructure' ? %w[sources crds] : []
    verify(dependencies == expected_dependencies, "#{environment}/#{name}: dependencies")
  end
  puts "STRUCTURE PASS #{environment}"
end
RUBY

printf '%s\n' 'Validation passed. No cluster was contacted or modified.'
printf '%s\n' 'Remote CRD files were fetched; live readiness and historical-version compatibility are not verified.'