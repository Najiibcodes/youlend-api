#!/bin/bash

echo -e "\n[BOOTSTRAPPING CLUSTER]\n"

# Check if the kind cluster already exists
if kind get clusters | grep -q "kind"; then
  echo "Cluster 'kind' already exists. Skipping creation..."
else
  kind create cluster --wait 5m --config kind.yml
fi

# Fails on errors
set -o errexit

##############################################
# Download helm repositories
##############################################
echo -e "\n[·] Downloading helm repositories..."

# Check if a helm repository exists and add it if it doesn't
function add_helm_repo() {
  local repo_name=$1
  local repo_url=$2
  if helm repo list | grep -q "$repo_name"; then
    echo "$repo_name repository already exists. Skipping..."
  else
    echo "Adding $repo_name repository..."
    helm repo add $repo_name $repo_url
  fi
}

# Core repos
add_helm_repo jetstack https://charts.jetstack.io
add_helm_repo traefik https://traefik.github.io/charts
add_helm_repo prometheus-community https://prometheus-community.github.io/helm-charts
add_helm_repo grafana https://grafana.github.io/helm-charts


helm repo update

##############################################
# Install core helm charts
##############################################

echo -e "\n[·] Installing core helm charts..."

# Function to check if a helm release exists
function helm_release_exists() {
    local release=$1
    local namespace=${2:-default}
    helm status $release -n $namespace >/dev/null 2>&1
    return $?
}

# Install cert-manager if not exists
if ! helm_release_exists cert-manager cert-manager; then
    echo "Installing cert-manager..."
    helm upgrade --install \
        cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --values ./kubernetes/controllers/cert-manager/values.yaml \
        --wait
else
    echo "cert-manager already installed, skipping..."
fi

# Install Traefik if not exists
if ! helm_release_exists traefik default; then
    echo "Installing Traefik..."
    helm upgrade --install \
        traefik traefik/traefik \
        --values ./kubernetes/controllers/traefik/values.yaml \
        --wait
else
    echo "traefik already installed, skipping..."
fi

# # Install Prometheus if not exists
# if ! helm_release_exists prometheus monitoring; then
#     echo "Installing Prometheus..."
#     helm upgrade --install \
#         prometheus prometheus-community/prometheus \
#         --namespace monitoring \
#         --create-namespace \
#         --wait
# else
#     echo "prometheus already installed, skipping..."
# fi

# # Install Grafana if not exists
# if ! helm_release_exists grafana monitoring; then
#     echo "Installing Grafana..."
#     helm upgrade --install \
#         grafana grafana/grafana \
#         --namespace monitoring \
#         --create-namespace \
#         --wait
# else
#     echo "grafana already installed, skipping..."
# fi

##############################################
# Install custom configuration and apps
##############################################
echo -e "\n[·] Installing custom configs and apps..."

## Using Helm to install the loan-system application

helm install loan-system ./kubernetes/loan-chart
echo "Loan system installed"

# kubectl apply -k ./kubernetes/loan-app
kubectl apply -k ./kubernetes/configs
kubectl apply -k ./kubernetes/apps

##############################################
# Extract Certificates and Trust in Keychain (macOS)
##############################################
echo -e "\n[·] Extracting and trusting certificates..."

# if kubectl get secret cert-whoami &> /dev/null; then
#   kubectl get secret cert-whoami -o jsonpath='{.data.tls\.crt}' | base64 --decode > whoami.crt
# else
#   echo "Error: secret 'cert-whoami' not found"
#   exit 1
# fi

# echo -e "\n[·] Adding certificates to Keychain Access..."
# sudo security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain-db whoami.crt

##############################################
# Display core access details
##############################################
echo -e "\n› Core components setup done!"
echo -e "\n[💻] Loan System application running on: https://loan-system.127.0.0.1.nip.io:8080"
echo -e "[💻] Traefik dashboard accessible at: https://traefik.127.0.0.1.nip.io/dashboard/"


echo -e "\n› All components have been deployed successfully!"