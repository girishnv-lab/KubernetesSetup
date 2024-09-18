#!/bin/bash

# Display credit
echo "Credit to Roshan Bharti for the ready-made kind configuration."
echo ""
echo ""

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for prerequisites
echo "Checking for prerequisites..."
for cmd in curl git dnf yum; do
    if ! command_exists $cmd; then
        echo "Error: $cmd is not installed. Please install $cmd before running this script."
        exit 1
    fi
done

# cd to /tmp
cd /tmp

# Detect OS and install Docker accordingly
if [ -f /etc/redhat-release ]; then
    # For RHEL-based systems
    echo "Detected RHEL-based system"
    sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
    sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl start docker
    sudo systemctl enable docker

elif [ -f /etc/amazon-linux-release ]; then
    # For Amazon Linux systems (2023 and 2)
    echo "Detected Amazon Linux system"
    sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker

else
    echo "Unsupported OS"
    exit 1
fi

# Installing kind
echo "Installing kind..."
curl -Lo /usr/bin/kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x /usr/bin/kind

# Installing HELM
echo "Installing HELM..."

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Installing kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/bin/kubectl

# Installing Kind cluster
echo "Installing Kind cluster..."
curl -Lo kind-new.yaml https://github.com/girishnv-lab/KubernetesSetup/blob/main/kind-config.yaml
echo "Creating Kind cluster with custom configuration..."
kind create cluster --config kind-new.yaml --retain --image "kindest/node:v1.21.14"

kubectl cluster-info --context kind-kind

# Setting up HELM charts and creating MongoDB namespace with latest Operator. 
echo "Setting up HELM charts"
helm repo add mongodb https://mongodb.github.io/helm-charts

echo "Installing MongDB Kubernetes Operator with latest operator version and creating MongoDB namespace"

helm install enterprise-operator mongodb/enterprise-operator --namespace mongodb --create-namespace

echo "below is your mongodb-enterprise-operator"
kubectl describe deployments mongodb-enterprise-operator -n mongodb

# Set mongodb namespace as default context
kubectl config set-context --current --namespace=mongodb

# Instructions to generate config-map.yaml and secret.yaml
echo "Next steps:"
echo "1. Open OpsManager UI."
echo "2. Navigate to Deployment, Add, and select 'Prepare Kubernetes Configurations'."
echo "3. Select 'Create new API keys' and then 'Generate Key and YAML'."
echo "4. Copy the contents of 'config-map.yaml'."
echo "5. Now, copy the contents of 'secret.yaml'."
echo "6. Make sure the API has Org Owner role and the IP address is added."

# Taking input for config-map.yaml
echo "Please paste the content of 'config-map.yaml' and press enter (new line), then press ctrl+d when done:"
cat > config-map.yaml

# Taking input for secret.yaml
echo "Please paste the content of 'secret.yaml' and press enter (new line), then press ctrl+d when done:"
cat > secret.yaml

# Applying the YAML files
echo "Applying the config-map.yaml and secret.yaml to the mongodb namespace..."
kubectl apply -f config-map.yaml -f secret.yaml -n mongodb

# Final instructions
echo "Successfully configured Kubernetes."
echo "If you would like to deploy a replica set, please modify the file 'mongodb-enterprise-kubernetes/samples/mongodb/minimal/replica-set.yaml'."
echo "Remove all the options from 'podTemplate:'."
echo "Change the credentials from 'my-credentials' to 'organization-secret'."
echo "Once 'replica-set.yaml' is edited, apply it using the following command:"
echo "kubectl apply -f mongodb-enterprise-kubernetes/samples/mongodb/minimal/replica-set.yaml -n mongodb"

echo "Configuration complete."
