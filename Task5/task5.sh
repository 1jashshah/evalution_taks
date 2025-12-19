#!/bin/bash
set -e

# =========================================================
# Task-5: Multi-Tenant EKS Setup
# Namespaces + RBAC + NetworkPolicy + Prometheus + Grafana
# =========================================================

CLUSTER_NAME="jash-cluster"
REGION="ap-southeast-1"
ACCOUNT_ID="075285241029"

# ---------------------------------------------------------
# 1. Namespaces
# ---------------------------------------------------------
echo "Creating namespaces..."
kubectl create namespace team-a || true
kubectl create namespace team-b || true

kubectl label namespace team-a kubernetes.io/metadata.name=team-a --overwrite
kubectl label namespace team-b kubernetes.io/metadata.name=team-b --overwrite

# ---------------------------------------------------------
# 2. RBAC (Team-A & Team-B)
# ---------------------------------------------------------
echo "Applying RBAC..."

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: team-a-role
  namespace: team-a
rules:
- apiGroups: [""]
  resources: ["pods","services","configmaps"]
  verbs: ["get","list","watch","create","update","delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: team-a-rolebinding
  namespace: team-a
subjects:
- kind: Group
  name: team-a-group
roleRef:
  kind: Role
  name: team-a-role
  apiGroup: rbac.authorization.k8s.io
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: team-b-role
  namespace: team-b
rules:
- apiGroups: [""]
  resources: ["pods","services","configmaps"]
  verbs: ["get","list","watch","create","update","delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: team-b-rolebinding
  namespace: team-b
subjects:
- kind: Group
  name: team-b-group
roleRef:
  kind: Role
  name: team-b-role
  apiGroup: rbac.authorization.k8s.io
EOF

# ---------------------------------------------------------
# 3. Network Isolation (STRICT)
# ---------------------------------------------------------
echo "Applying NetworkPolicies..."

for ns in team-a team-b; do
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: $ns
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: $ns
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: $ns
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: $ns
EOF
done

# Allow DNS
for ns in team-a team-b; do
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: $ns
spec:
  podSelector: {}
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
EOF
done

# ---------------------------------------------------------
# 4. Prometheus (Per Team)
# ---------------------------------------------------------
echo "Deploying Prometheus per team..."

for ns in team-a team-b; do
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: $ns
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: prometheus
  namespace: $ns
rules:
- apiGroups: [""]
  resources: ["pods","services","endpoints"]
  verbs: ["get","list","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: prometheus
  namespace: $ns
subjects:
- kind: ServiceAccount
  name: prometheus
roleRef:
  kind: Role
  name: prometheus
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: $ns
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: "$ns-pods"
      kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
          - $ns
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: $ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      serviceAccountName: prometheus
      containers:
      - name: prometheus
        image: prom/prometheus
        args:
        - "--config.file=/etc/prometheus/prometheus.yml"
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
      volumes:
      - name: config
        configMap:
          name: prometheus-config
EOF
done

# ---------------------------------------------------------
# 5. Grafana (Per Team)
# ---------------------------------------------------------
echo "Deploying Grafana per team..."

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: team-a
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_USER
          value: team-a
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: team-a-password
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: team-a
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
EOF

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: team-b
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_USER
          value: team-b
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: team-b-password
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: team-b
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
EOF

# ---------------------------------------------------------
# DONE
# ---------------------------------------------------------
echo "✅ Task-5 Multi-Tenant EKS setup completed successfully"
echo "Team-A Grafana: kubectl port-forward -n team-a svc/grafana 3000:3000"
echo "Team-B Grafana: kubectl port-forward -n team-b svc/grafana 3000:3000"