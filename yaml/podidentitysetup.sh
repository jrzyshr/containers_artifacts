
# set up Azure User Managed Identity
IDENTITY_RESOURCE_GROUP = teamResources
IDENTITY_NAME = tripInsightsPodID

az identity create --resource-group ${IDENTITY_RESOURCE_GROUP} --name ${IDENTITY_NAME}

export IDENTITY_CLIENT_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query clientId -otsv)"
export IDENTITY_RESOURCE_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query id -otsv)"

# Assign "VMC" priviledges to the user managed identity
NODE_GROUP=$(az aks show -g myResourceGroup -n myAKSCluster --query nodeResourceGroup -o tsv)
NODES_RESOURCE_ID=$(az group show -n $NODE_GROUP -o tsv --query "id")
az role assignment create --role "Virtual Machine Contributor" --assignee "$IDENTITY_CLIENT_ID" --scope $NODES_RESOURCE_ID

# Add the user managed identity to the AKS cluster
export POD_IDENTITY_NAME="trips-pod-identity"
export POD_IDENTITY_NAMESPACE="api"
az aks pod-identity add --resource-group ${IDENTITY_RESOURCE_GROUP} --cluster-name tripinsightssec3 --namespace ${POD_IDENTITY_NAMESPACE}  --name ${POD_IDENTITY_NAME} --identity-resource-id ${IDENTITY_RESOURCE_ID}

# After this, you need to pass the user managed ID's info into the YAML file of your pod so that it can use it.


az aks nodepool add \
    --resource-group teamResources \
    --cluster-name tripinsightssec3 \
    --os-type Windows \
    --name winNodePool \
    --node-vm-size Standard_D4s_v3 \
    --kubernetes-version 1.20.5 \
    --aks-custom-headers WindowsContainerRuntime=containerd \
    --node-count 1 \
    --node-taints os=windows:NoSchedule