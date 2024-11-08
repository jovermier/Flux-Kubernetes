#!/bin/bash

# Ensure that a version number is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <version> <ipv6 true|false> (leave the prepended 'v' off the version number)"
  exit 1
fi

set -e

VERSION=$1
IPV6_ENABLED=$2

# Get the directory of the script to ensure the output path is relative to the script's location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set the output path for the manifest file
OUTPUT_FILE="${SCRIPT_DIR}/../raw/cilium-v${VERSION}.yaml"
rm -rf OUTPUT_FILE 2>/dev/null | true

helm repo add cilium https://helm.cilium.io/ 1>/dev/null
helm repo update 1>/dev/null

# Run the helm template command and output to the specified file
helm template cilium cilium/cilium \
  --version "v${VERSION}" \
  --namespace kube-system \
  --set operator.replicas=2 \
  --set rolloutCiliumPods=true \
  --set operator.rollOutPods=true \
  --set ipv4.enabled=true \
  --set ipv6.enabled="$IPV6_ENABLED" \
  --set ipam.mode=kubernetes \
  --set externalIPs.enabled=true \
  --set nodePort.enabled=true \
  --set hostPort.enabled=true \
  --set bpf.masquerade=true \
  --set kubeProxyReplacement=true \
  --set securityContext.capabilities.ciliumAgent='{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}' \
  --set securityContext.capabilities.cleanCiliumState='{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}' \
  --set cgroup.autoMount.enabled=false \
  --set cgroup.hostRoot=/sys/fs/cgroup \
  --set k8sServiceHost=localhost \
  --set k8sServicePort=7445 > "$OUTPUT_FILE"

# Notify the user of the output file location
echo "Cilium manifest generated for v$VERSION at: $OUTPUT_FILE"