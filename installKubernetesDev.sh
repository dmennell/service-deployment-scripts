#!/bin/bash
echo "Verifying DC/OS Enterprise CLI Installed"
dcos package install --yes dcos-enterprise-cli
echo "Creating Permissions Required for Kubernetes Cluster"
dcos security org service-accounts keypair private-key.pem public-key.pem
dcos security org service-accounts create -p public-key.pem -d 'service account' $1
dcos security secrets create-sa-secret private-key.pem $1 $1/sa
dcos security org users grant $1 dcos:mesos:master:framework:role:$1-role create
dcos security org users grant $1 dcos:mesos:master:task:user:root create
dcos security org users grant $1 dcos:mesos:agent:task:user:root create
dcos security org users grant $1 dcos:mesos:master:reservation:role:$1-role create
dcos security org users grant $1 dcos:mesos:master:reservation:principal:$1 delete
dcos security org users grant $1 dcos:mesos:master:volume:role:$1-role create
dcos security org users grant $1 dcos:mesos:master:volume:principal:$1 delete
dcos security org users grant $1 dcos:secrets:default:/$1/* full
dcos security org users grant $1 dcos:secrets:list:default:/$1 read
dcos security org users grant $1 dcos:adminrouter:ops:ca:rw full
dcos security org users grant $1 dcos:adminrouter:ops:ca:ro full
dcos security org users grant $1 dcos:mesos:master:framework:role:slave_public/$1-role create
dcos security org users grant $1 dcos:mesos:master:framework:role:slave_public/$1-role read
dcos security org users grant $1 dcos:mesos:master:reservation:role:slave_public/$1-role create
dcos security org users grant $1 dcos:mesos:master:volume:role:slave_public/$1-role create
dcos security org users grant $1 dcos:mesos:master:framework:role:slave_public read
dcos security org users grant $1 dcos:mesos:agent:framework:role:slave_public read
cat > ./$1.json << 'EOF'
{
  "service": {
    "name": "$1",
    "service_account": "$1",
    "service_account_secret": "$1/sa",
    "virtual_network_name": "dev"
  },
  "kubernetes": {
    "authorization_mode": "AlwaysAllow",
    "high_availability": false,
    "service_cidr": "10.100.0.0/16",
    "dcos_token_authentication": false,
    "control_plane_reserved_resources": {
      "cpus": 1.5,
      "mem": 4096,
      "disk": 10240
    },
    "control_plane_placement": "[[\"hostname\", \"UNIQUE\"]]",
    "control_plane_pre_reserved_role": "*",
    "private_node_count": 1,
    "private_reserved_resources": {
      "kube_cpus": 2,
      "kube_mem": 2048,
      "kube_disk": 10240,
      "system_cpus": 1,
      "system_mem": 1024
    },
    "private_node_placement": "",
    "private_node_pre_reserved_role": "*",
    "proxy": {
      "override_injection": false
    },
    "public_reserved_resources": {
      "kube_cpus": 0.5,
      "kube_mem": 512,
      "kube_disk": 2048,
      "system_cpus": 1,
      "system_mem": 1024
    },
    "public_node_placement": "",
    "public_node_pre_reserved_role": "slave_public",
    "public_node_count": 1
  },
  "calico": {
    "calico_ipv4pool_cidr": "192.168.0.0/16",
    "cni_mtu": 1400,
    "ip_autodetection_method": "interface=(m-dcos|eth0)",
    "ipv4pool_ipip": "Always",
    "felix_ipinipmtu": 1420,
    "felix_ipinipenabled": true,
    "typha": {
      "enabled": false,
      "replicas": 3
    }
  },
  "etcd": {
    "cpus": 0.5,
    "mem": 1024,
    "data_disk": 3072,
    "wal_disk": 512,
    "disk_type": "ROOT",
    "placement": "",
    "pre_reserved_role": "*"
  }
}
EOF
dcos package install --yes kubernetes cluster --options =$1.json
