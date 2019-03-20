echo "Verifying DC/OS Enterprise CLI"
dcos package install --yes dcos-enterprise-cli
echo "Creating Required Permissions"
dcos security org service-accounts keypair mke-priv.pem mke-pub.pem
dcos security org service-accounts create -p mke-pub.pem -d 'MKE service account' kubernetes
dcos security secrets create-sa-secret mke-priv.pem kubernetes kubernetes/sa
dcos security org users grant kubernetes dcos:mesos:master:reservation:role:kubernetes-role create
dcos security org users grant kubernetes dcos:mesos:master:framework:role:kubernetes-role create
dcos security org users grant kubernetes dcos:mesos:master:task:user:nobody create
echo "Deploying Mesosphere Kubernetes Engine"
cat > ./mke-options.json << 'EOF'
{
  "service": {
    "service_account": "kubernetes",
    "service_account_secret": "kubernetes/sa"
  },
  "mesosphere_kubernetes_engine": {
    "resources": {
      "cpus": 0.5,
      "mem": 1024
    },
    "verbose": false
  }
}
EOF
dcos package install --yes kubernetes --options=./mke-options.json
watch dcos kubernetes manager plan status deploy --name=kubernetes
