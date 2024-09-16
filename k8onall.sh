#!/bin/bash

# Display credit
echo "Credit to Roshan Bharti for the ready-made kind configuration."
echo ""
echo ""

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "This script installs Docker and other tools on RHEL and Amazon Linux only."

# Check for prerequisites
echo "Checking for prerequisites..."
for cmd in curl git dnf yum; do
    if ! command_exists $cmd; then
        echo "Error: $cmd is not installed. Please install $cmd before running this script."
        exit 1
    fi
done

# Detect OS and install Docker accordingly
if [ -f /etc/redhat-release ]; then
    if grep -q "Red Hat" /etc/redhat-release; then
        echo "Detected RHEL-based system"

        # Removing old Docker packages if any
        echo "Removing old Docker packages if any..."
        sudo yum remove -y docker \
            docker-client \
            docker-client-latest \
            docker-common \
            docker-latest \
            docker-latest-logrotate \
            docker-logrotate \
            docker-engine

        # Setting up Docker repository for RHEL
        echo "Setting up Docker repository for RHEL..."
        sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

        # Installing Docker
        echo "Installing Docker Engine..."
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Starting and enabling Docker
        echo "Starting and enabling Docker..."
        sudo systemctl start docker
        sudo systemctl enable docker

    elif [ -f /etc/amazon-linux-release ] || [ -f /etc/system-release ]; then
        if grep -q "Amazon Linux 2023" /etc/amazon-linux-release || grep -q "Amazon Linux 2023" /etc/system-release; then
            echo "Detected Amazon Linux 2023"

            # Removing old Docker packages if any
            echo "Removing old Docker packages if any..."
            sudo yum remove -y docker \
                docker-client \
                docker-client-latest \
                docker-common \
                docker-latest \
                docker-latest-logrotate \
                docker-logrotate \
                docker-engine

            # Installing Docker for Amazon Linux 2023
            echo "Installing Docker Engine for Amazon Linux 2023..."
            sudo amazon-linux-extras install -y docker

            # Starting and enabling Docker
            echo "Starting and enabling Docker..."
            sudo systemctl start docker
            sudo systemctl enable docker

        elif grep -q "Amazon Linux 2" /etc/amazon-linux-release || grep -q "Amazon Linux 2" /etc/system-release; then
            echo "Detected Amazon Linux 2"

            # Removing old Docker packages if any
            echo "Removing old Docker packages if any..."
            sudo yum remove -y docker \
                docker-client \
                docker-client-latest \
                docker-common \
                docker-latest \
                docker-latest-logrotate \
                docker-logrotate \
                docker-engine

            # Installing Docker for Amazon Linux 2
            echo "Installing Docker Engine for Amazon Linux 2..."
            sudo amazon-linux-extras install -y docker

            # Starting and enabling Docker
            echo "Starting and enabling Docker..."
            sudo systemctl start docker
            sudo systemctl enable docker

        else
            echo "Unsupported Amazon Linux system"
            exit 1
        fi
    else
        echo "Unsupported RHEL-based system"
        exit 1
    fi
else
    echo "Unsupported OS"
    exit 1
fi

# Installing kind
echo "Installing kind..."
curl -Lo /usr/bin/kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x /usr/bin/kind

# Installing kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/bin/kubectl

# Installing Kind cluster
echo "Installing Kind cluster..."
curl -Lo kind-updated.yaml https://raw.githubusercontent.com/bhartiroshan/OpsManager/master/kind-config.yaml
echo "Creating Kind cluster with custom configuration..."
kind create cluster --config kind-updated.yaml --retain --image "kindest/node:v1.21.14"

kubectl cluster-info --context kind-kind

# Cloning MongoDB enterprise repository
echo "Cloning MongoDB enterprise repository..."
git clone https://github.com/mongodb/mongodb-enterprise-kubernetes.git

# Creating MongoDB namespace
echo "Creating MongoDB namespace..."
kubectl create namespace mongodb

# Set mongodb namespace as default context
kubectl config set-context --current --namespace=mongodb

# Creating MongoDB Enterprise Operator
echo "Creating MongoDB Enterprise Operator..."
kubectl apply -f mongodb-enterprise-kubernetes/crds.yaml
kubectl apply -f mongodb-enterprise-kubernetes/mongodb-enterprise.yaml

echo "Cluster will be ready in 2-3 minutes."

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