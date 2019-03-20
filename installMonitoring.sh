echo -e "\033[0;32mVerifying DC/OS Enterprise CLI Installed\033[0m"
dcos package install --yes dcos-enterprise-cli
echo -e "\033[0;32mCreating Permissions for DC/OS Monitoring Service\033[0m"
dcos security org service-accounts keypair dcos-monitoring-private-key.pem dcos-monitoring-public-key.pem
dcos security org service-accounts create -p dcos-monitoring-public-key.pem -d "dcos-monitoring service account" dcos-monitoring-principal
dcos security secrets create-sa-secret --strict dcos-monitoring-private-key.pem dcos-monitoring-principal dcos-monitoring/service-private-key
dcos security org users grant dcos-monitoring-principal dcos:adminrouter:ops:ca:rw full
dcos security org users grant dcos-monitoring-principal dcos:adminrouter:ops:ca:ro full
dcos security org users grant dcos-monitoring-principal dcos:mesos:agent:framework:role:slave_public read
dcos security org users grant dcos-monitoring-principal dcos:mesos:master:framework:role:dcos-monitoring-role create
dcos security org users grant dcos-monitoring-principal dcos:mesos:master:framework:role:slave_public read
dcos security org users grant dcos-monitoring-principal dcos:mesos:master:framework:role:slave_public/dcos-monitoring-role read
dcos security org users grant dcos-monitoring-principal dcos:mesos:master:framework:role:slave_public/dcos-monitoring-role create
dcos security org users grant dcos-monitoring-principal dcos:mesos:master:reservation:principal:dcos-monitoring-principal delete
dcos security org users grant dcos-monitoring-principal dcos:mesos:master:reservation:role:dcos-monitoring-role create
dcos security org users grant dcos-monitoring-principal dcos:mesos:master:reservation:role:slave_public/dcos-monitoring-role create
dcos security org users grant dcos-monitoring-principal dcos:mesos:master:task:user:nobody create
dcos security org users grant dcos-monitoring-principal dcos:mesos:master:volume:principal:dcos-monitoring-principal delete
dcos security org users grant dcos-monitoring-principal dcos:mesos:master:volume:role:dcos-monitoring-role create
dcos security org users grant dcos-monitoring-principal dcos:mesos:master:volume:role:slave_public/dcos-monitoring-role create
dcos security org users grant dcos-monitoring-principal dcos:secrets:default:/dcos-monitoring/\* full
dcos security org users grant dcos-monitoring-principal dcos:secrets:list:default:/dcos-monitoring read
echo -e "\033[0;32mDeploying DC/OS Monitoring Service\033[0m"
cat > dcos-monitoring.json << 'EOF'
{
  "service": {
    "name": "dcos-monitoring",
    "user": "nobody",
    "service_account": "dcos-monitoring-principal",
    "service_account_secret": "dcos-monitoring/service-private-key",
    "log_level": "INFO"
  },
  "prometheus": {
    "cpus": 2,
    "mem": 4096,
    "volume": {
      "type": "ROOT",
      "size": 25000,
      "profile": ""
    },
    "interval": 30,
    "timeout": 25,
    "dcos_metrics_node_port": 61091,
    "storage_tsdb_retention": "15d",
    "admin_router_proxy": {
      "enabled": true,
      "url": ""
    },
    "alert_rules_repository": {
      "url": "",
      "path": "",
      "reference_name": "",
      "credentials": {
        "username": "",
        "password": "",
        "deploy_key": ""
      }
    }
  },
  "grafana": {
    "cpus": 2,
    "mem": 4096,
    "data_volume": {
      "type": "ROOT",
      "size": 512,
      "profile": ""
    },
    "ui_port": 3000,
    "admin_router_proxy": true,
    "public": false,
    "admin_credentials": {
      "username": "",
      "password": ""
    },
    "placement_constraints": "",
    "default_dashboards": true,
    "dashboard_config_repository": {
      "url": "",
      "path": "",
      "reference_name": "",
      "credentials": {
        "username": "",
        "password": "",
        "deploy_key": ""
      }
    }
  },
  "alertmanager": {
    "cpus": 1,
    "mem": 1024,
    "data_volume": {
      "type": "ROOT",
      "size": 512,
      "profile": ""
    },
    "secrets": {
      "slack_api_url": ""
    },
    "config_repository": {
      "url": "",
      "path": "",
      "credentials": {
        "username": "",
        "password": "",
        "deploy_key": ""
      }
    }
  }
}
EOF
dcos package install --yes beta-dcos-monitoring --options=dcos-monitoring.json
watch dcos beta-dcos-monitoring plan show deploy
