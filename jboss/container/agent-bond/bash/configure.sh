#!/bin/sh
# Configure module
set -e

SCRIPT_DIR=$(dirname $0)
ARTIFACTS_DIR=${SCRIPT_DIR}/artifacts

mv /tmp/artifacts/agent-bond-agent-*.jar ${ARTIFACTS_DIR}/opt/jboss/container/agent-bond

chown -R jboss:root ${ARTIFACTS_DIR}
chmod 444 ${ARTIFACTS_DIR}/opt/jboss/container/agent-bond/agent-bond-agent-*.jar
chmod 755 ${ARTIFACTS_DIR}/opt/jboss/container/agent-bond/agent-bond-opts
chmod 775 ${ARTIFACTS_DIR}/opt/jboss/container/agent-bond/etc
chmod 775 ${ARTIFACTS_DIR}/opt/jboss/container/agent-bond/etc/jmx-exporter-config.yaml

pushd ${ARTIFACTS_DIR}
cp -pr * /
popd

ln -s /opt/jboss/container/agent-bond/agent-bond-agent-*.jar /opt/jboss/container/agent-bond/agent-bond-agent.jar
chown -h jboss:root /opt/jboss/container/agent-bond/agent-bond-agent.jar
