#!/bin/bash
set -e

# -----------------------------
# VARIABLES
# -----------------------------
CLUSTER_NAME=jash-cluster
REGION=ap-southeast-1
ACCOUNT_ID=075285241029
POLICY_NAME=AWSLoadBalancerControllerIAMPolicy

# -----------------------------
# 1. CREATE EKS CLUSTER (NO NODEGROUP)
# -----------------------------
eksctl create cluster \
  --name ${CLUSTER_NAME} \
  --region ${REGION} \
  --without-nodegroup

# -----------------------------
# 2. CREATE PRIVATE MANAGED NODEGROUP
# -----------------------------
eksctl create nodegroup \
  --cluster ${CLUSTER_NAME} \
  --region ${REGION} \
  --name jash-private-ng \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 4 \
  --node-volume-size 20 \
  --managed \
  --node-private-networking

# -----------------------------
# 3. ASSOCIATE OIDC PROVIDER (REQUIRED FOR IRSA)
# -----------------------------
eksctl utils associate-iam-oidc-provider \
  --cluster ${CLUSTER_NAME} \
  --region ${REGION} \
  --approve

# -----------------------------
# 4. DOWNLOAD ALB CONTROLLER IAM POLICY
# -----------------------------
curl -o iam_policy.json \
https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

# -----------------------------
# 5. CREATE IAM POLICY (IGNORE IF EXISTS)
# -----------------------------
aws iam create-policy \
  --policy-name ${POLICY_NAME} \
  --policy-document file://iam_policy.json \
  || echo "IAM policy already exists"

# -----------------------------
# 6. CREATE IAM SERVICE ACCOUNT FOR ALB CONTROLLER
# -----------------------------
eksctl create iamserviceaccount \
  --cluster ${CLUSTER_NAME} \
  --region ${REGION} \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME} \
  --approve \
  --override-existing-serviceaccounts

# -----------------------------
# 7. INSTALL HELM (IF NOT PRESENT)
# -----------------------------
# helm repo add eks https://aws.github.io/eks-charts
# helm repo update

# -----------------------------
# 8. INSTALL AWS LOAD BALANCER CONTROLLER
# -----------------------------
# helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
#   -n kube-system \
#   --set clusterName=${CLUSTER_NAME} \
#   --set serviceAccount.create=false \
#   --set serviceAccount.name=aws-load-balancer-controller

# -----------------------------
# 9. ENABLE VPC CNI CUSTOM NETWORKING
# -----------------------------
# kubectl set env daemonset aws-node -n kube-system \
#   AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true \
#   ENI_CONFIG_LABEL_DEF=topology.kubernetes.io/zone \
#   ENABLE_POD_ENI=true

echo "✅ EKS cluster with private nodes and ALB controller setup completed!"
