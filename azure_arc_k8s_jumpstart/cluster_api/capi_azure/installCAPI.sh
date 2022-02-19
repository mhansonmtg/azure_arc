#!/bin/bash
exec >installCAPI.log
exec 2>&1

sudo apt-get update

# Set deployment GitHub repository environment variables
export githubAccount="microsoft"
export githubBranch="main"
export templateBaseUrl="https://raw.githubusercontent.com/${githubAccount}/azure_arc/${githubBranch}/azure_arc_k8s_jumpstart/cluster_api/capi_azure/" # Do not change!

# Set deployment environment variables
export CLUSTERCTL_VERSION="1.1.1" # Do not change!
export CAPI_PROVIDER="azure" # Do not change!
export CAPI_PROVIDER_VERSION="1.1.1" # Do not change!
export AZURE_ENVIRONMENT="AzurePublicCloud" # Do not change!
export KUBERNETES_VERSION="1.22.6" # Do not change!
export CONTROL_PLANE_MACHINE_COUNT="<Control Plane node count>"
export WORKER_MACHINE_COUNT="<Workers node count>" 
export AZURE_LOCATION="<Azure region>" # Name of the Azure datacenter location. For example: "eastus"
export AZURE_ARC_CLUSTER_RESOURCE_NAME="<Azure Arc-enabled Kubernetes cluster resource name>" # Name of the Azure Arc-enabled Kubernetes cluster resource name as it will shown in the Azure portal
export CAPI_WORKLOAD_CLUSTER_NAME=$(echo "${AZURE_ARC_CLUSTER_RESOURCE_NAME,,}") # Converting to lowercase case variable > Name of the CAPI workload cluster. Must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
export AZURE_RESOURCE_GROUP="<Azure resource group name>"
export AZURE_SUBSCRIPTION_ID="<Azure subscription id>"
export AZURE_TENANT_ID="<Azure tenant id>"
export AZURE_CLIENT_ID="<Azure SPN application client id>"
export AZURE_CLIENT_SECRET="<Azure SPN application client secret>"
export AZURE_CONTROL_PLANE_MACHINE_TYPE="<Control Plane node Azure VM type>" # For example: "Standard_D4s_v4"
export AZURE_NODE_MACHINE_TYPE="<Worker node Azure VM type>" # For example: "Standard_D8s_v4"

# Base64 encode the variables - Do not change!
export AZURE_SUBSCRIPTION_ID_B64="$(echo -n "$AZURE_SUBSCRIPTION_ID" | base64 | tr -d '\n')"
export AZURE_TENANT_ID_B64="$(echo -n "$AZURE_TENANT_ID" | base64 | tr -d '\n')"
export AZURE_CLIENT_ID_B64="$(echo -n "$AZURE_CLIENT_ID" | base64 | tr -d '\n')"
export AZURE_CLIENT_SECRET_B64="$(echo -n "$AZURE_CLIENT_SECRET" | base64 | tr -d '\n')"

# Settings needed for AzureClusterIdentity used by the AzureCluster
export AZURE_CLUSTER_IDENTITY_SECRET_NAME="cluster-identity-secret"
export CLUSTER_IDENTITY_NAME="cluster-identity"
export AZURE_CLUSTER_IDENTITY_SECRET_NAMESPACE="default"

# Installing Azure CLI & Azure Arc extensions
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

sudo -u $USER az extension add --name connectedk8s
sudo -u $USER az extension add --name k8s-configuration
sudo -u $USER az extension add --name k8s-extension

echo "Log in to Azure"
sudo -u $USER az login --service-principal --username $SPN_CLIENT_ID --password $SPN_CLIENT_SECRET --tenant $SPN_TENANT_ID
az -v
echo ""

# Creating deployment Azure resource group
az group create --name $AZURE_RESOURCE_GROUP --location $AZURE_LOCATION

# Installing snap
sudo apt install snapd

# Installing Docker
sudo snap install docker
sudo groupadd docker
sudo usermod -aG docker $USER

# Installing kubectl
sudo snap install kubectl --classic

# Installing kustomize
sudo snap install kustomize

# Registering Azure Arc providers
echo "Registering Azure Arc providers"
az config set extension.use_dynamic_install=yes_without_prompt

az provider register --namespace Microsoft.Kubernetes --wait
az provider register --namespace Microsoft.KubernetesConfiguration --wait
az provider register --namespace Microsoft.ExtendedLocation --wait

az provider show -n Microsoft.Kubernetes -o table
az provider show -n Microsoft.KubernetesConfiguration -o table
az provider show -n Microsoft.ExtendedLocation -o table

# Installing clusterctl
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v${CLUSTERCTL_VERSION}/clusterctl-linux-amd64 -o clusterctl
sudo chmod +x ./clusterctl
sudo mv ./clusterctl /usr/local/bin/clusterctl
clusterctl version

# Installing Helm 3
echo ""
sudo snap install helm --classic

# Create a secret to include the password of the Service Principal identity created in Azure
# This secret will be referenced by the AzureClusterIdentity used by the AzureCluster
kubectl create secret generic "${AZURE_CLUSTER_IDENTITY_SECRET_NAME}" --from-literal=clientSecret="${AZURE_CLIENT_SECRET}"

# Converting the kind cluster to a Cluster API management cluster
echo "Transforming the Kubernetes cluster to a management cluster with the Cluster API Azure Provider (CAPZ)..."
clusterctl init --infrastructure=azure:v${CAPI_PROVIDER_VERSION}
echo "Making sure cluster is ready..."
echo ""
kubectl wait --for=condition=Available --timeout=60s --all deployments -A >/dev/null
echo ""

# Deploy CAPI Workload cluster
echo "Deploying Kubernetes workload cluster"
echo ""
clusterctl generate cluster $CAPI_WORKLOAD_CLUSTER_NAME \
  --kubernetes-version v$KUBERNETES_VERSION \
  --control-plane-machine-count=$CONTROL_PLANE_MACHINE_COUNT \
  --worker-machine-count=$WORKER_MACHINE_COUNT \
  > $CAPI_WORKLOAD_CLUSTER_NAME.yaml

# Creating CAPI Workload cluster yaml manifest
echo "Deploying Kubernetes workload cluster"
echo ""
sudo curl -o capz_kustomize/patches/AzureCluster.yaml --create-dirs ${templateBaseUrl}artifacts/capz_kustomize/patches/AzureCluster.yaml
sudo curl -o capz_kustomize/patches/Cluster.yaml ${templateBaseUrl}artifacts/capz_kustomize/patches/Cluster.yaml
sudo curl -o capz_kustomize/patches/KubeadmControlPlane.yaml ${templateBaseUrl}artifacts/capz_kustomize/patches/KubeadmControlPlane.yaml
sudo curl -o capz_kustomize/kustomization.yaml ${templateBaseUrl}artifacts/capz_kustomize/kustomization.yaml
kubectl kustomize capz_kustomize/ > jumpstart.yaml
clusterctl generate yaml --from jumpstart.yaml > template.yaml

# Deploying CAPI Workload cluster
echo ""
sudo kubectl apply -f template.yaml

echo ""
until sudo kubectl get cluster --all-namespaces | grep -q "Provisioned"; do echo "Waiting for Kubernetes control plane to be in Provisioned phase..." && sleep 20 ; done
echo ""
sudo kubectl get cluster --all-namespaces

echo ""
until sudo kubectl get kubeadmcontrolplane --all-namespaces | grep -q "true"; do echo "Waiting for control plane to initialize. This may take a few minutes..." && sleep 20 ; done
echo ""
sudo kubectl get kubeadmcontrolplane --all-namespaces
clusterctl get kubeconfig $CLUSTER_NAME > $CLUSTER_NAME.kubeconfig
echo ""
sudo kubectl --kubeconfig=./$CLUSTER_NAME.kubeconfig apply -f https://raw.githubusercontent.com/kubernetes-sigs/cluster-api-provider-azure/main/templates/addons/calico.yaml

echo ""
CLUSTER_TOTAL_MACHINE_COUNT=`expr $CONTROL_PLANE_MACHINE_COUNT + $WORKER_MACHINE_COUNT`
export CLUSTER_TOTAL_MACHINE_COUNT="$(echo $CLUSTER_TOTAL_MACHINE_COUNT)"
until [[ $(sudo kubectl --kubeconfig=./$CLUSTER_NAME.kubeconfig get nodes | grep -c -w "Ready") == $CLUSTER_TOTAL_MACHINE_COUNT ]]; do echo "Waiting all nodes to be in Ready state. This may take a few minutes..." && sleep 30 ; done 2> /dev/null
echo ""
sudo kubectl --kubeconfig=./$CLUSTER_NAME.kubeconfig label node -l '!node-role.kubernetes.io/master' node-role.kubernetes.io/worker=worker
echo ""
sudo kubectl --kubeconfig=./$CLUSTER_NAME.kubeconfig get nodes -o wide | expand | awk 'length($0) > length(longest) { longest = $0 } { lines[NR] = $0 } END { gsub(/./, "=", longest); print "/=" longest "=\\"; n = length(longest); for(i = 1; i <= NR; ++i) { printf("| %s %*s\n", lines[i], n - length(lines[i]) + 1, "|"); } print "\\=" longest "=/" }'














echo "Onboarding the cluster as an Azure Arc enabled Kubernetes cluster"
az login --service-principal --username $AZURE_CLIENT_ID --password $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
echo ""

rm -rf ~/.azure/AzureArcCharts

echo "Checking if you have up-to-date Azure Arc AZ CLI 'connectedk8s' extension..."
az extension show --name "connectedk8s" &> extension_output
if cat extension_output | grep -q "not installed"; then
az extension add --name "connectedk8s"
rm extension_output
else
az extension update --name "connectedk8s"
rm extension_output
fi
echo ""

echo "Checking if you have up-to-date Azure Arc AZ CLI 'k8s-configuration' extension..."
az extension show --name "k8s-configuration" &> extension_output
if cat extension_output | grep -q "not installed"; then
az extension add --name "k8s-configuration"
rm extension_output
else
az extension update --name "k8s-configuration"
rm extension_output
fi
echo ""

az connectedk8s connect --name $CAPI_WORKLOAD_CLUSTER_NAME --resource-group $CAPI_WORKLOAD_CLUSTER_NAME --location $AZURE_LOCATION --kube-config $CAPI_WORKLOAD_CLUSTER_NAME.kubeconfig
