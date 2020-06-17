#!/bin/sh
set -e

kubeadm init --config /tmp/master-configuration.yml \
  --ignore-preflight-errors=Swap,NumCPU

kubeadm token create ${token}

[ -d $HOME/.kube ] || mkdir -p $HOME/.kube
ln -s /etc/kubernetes/admin.conf $HOME/.kube/config

until nc -z localhost 6443; do
  echo "Waiting for API server to respond on master"
  sleep 5
done

#kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml

# See: https://kubernetes.io/docs/admin/authorization/rbac/
kubectl create clusterrolebinding permissive-binding \
  --clusterrole=cluster-admin \
  --user=admin \
  --user=kubelet \
  --group=system:serviceaccounts
