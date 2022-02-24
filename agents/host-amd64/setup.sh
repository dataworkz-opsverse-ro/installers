#!/bin/bash

SERVICE_NAME=opsverse-agent
SERVICE_FILE=/etc/systemd/system/${SERVICE_NAME}.service

# Parse CLI args
while [[ $# -gt 0 ]]; do
  case $1 in
    -m|--metrics-host)
      METRICS_HOST="$2"
      shift # past argument
      shift # past value
      ;;
    -l|--logs-host)
      LOGS_HOST="$2"
      shift # past argument
      shift # past value
      ;;
    -t|--traces-collector-host)
      TRACES_HOST="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--password)
      PASS="$2"
      shift # past argument
      shift # past value
      ;;
    --help)
      HELP=true
      shift # past argument
      ;;
    *)
      echo "Unknown parameter passed: $1"
      exit 1 ;;
  esac
done

# Show help, if necessary, and exit
if [ "$HELP" = true ] || [ -z $METRICS_HOST ] || [ -z $LOGS_HOST ] || [ -z $TRACES_HOST ] || [ -z $PASS ] ; then
  echo "Installs the OpsVerse Agent on your machine"
  echo ""
  echo "Usage: sudo installer -- [OPTIONS]" 
  echo ""
  echo "Arguments:"
  echo "  -m, --metrics-host             Your Prometheus-compatible metrics host"
  echo "  -l, --logs-host                Your Loki host"
  echo "  -t, --traces-collector-host    Your traces collector host"
  echo "  -p, --password                 Your ObserveNow instance auth password"
  echo ""
  echo "Example:"
  echo "  sudo installer -- -m metrics-foobar.mysubdomain.com \\"
  echo "           -l logs-foobar.mysubdomain.com \\"
  echo "           -t traces-collector-foobar.mysubdomain.com \\"
  echo "           -p somepass" 

  exit 0
fi


# move executable and config to appropriate directories
mkdir -p /usr/local/bin/ /etc/opsverse
cp -f ./agent-v0.13.1-linux-amd64 /usr/local/bin/opsverse-telemetry-agent
cp -f ./agent-config.yaml /etc/opsverse/
chmod +x /usr/local/bin/opsverse-telemetry-agent

# Replace variables in agent config file
HOSTNAME=$(hostname)
B64PASS=$(echo -n "devopsnow:${PASS}" | base64)
sed -i "s/__METRICS_HOST__/${METRICS_HOST}/g" /etc/opsverse/agent-config.yaml
sed -i "s/__LOGS_HOST__/${LOGS_HOST}/g" /etc/opsverse/agent-config.yaml
sed -i "s/__TRACES_HOST__/${TRACES_COLLECTOR_HOST}/g" /etc/opsverse/agent-config.yaml
sed -i "s/__PASSWORD__/${PASS}/g" /etc/opsverse/agent-config.yaml
sed -i "s/__HOST__/${HOSTNAME}/g" /etc/opsverse/agent-config.yaml

# Setup the SystemD service file
if [ -f ${SERVICE_FILE} ]; then
  systemctl stop ${SERVICE_NAME}.service
  systemctl disable ${SERVICE_NAME}.service
  cp -f ./${SERVICE_NAME}.service ${SERVICE_FILE}
else
  cp -f ./${SERVICE_NAME}.service ${SERVICE_FILE}
fi
 
systemctl enable ${SERVICE_NAME}.service
systemctl start ${SERVICE_NAME}.service
