#!/usr/bin/env bash
set -Eeuo pipefail

BACKUP_DIR="${BACKUP_DIR:-/var/backups/etcd}"
ETCDCTL_API=3
export ETCDCTL_API

ETCD_ENDPOINT="${ETCD_ENDPOINT:-https://127.0.0.1:2379}"
CA_FILE="${CA_FILE:-/etc/kubernetes/pki/etcd/ca.crt}"
CERT_FILE="${CERT_FILE:-/etc/kubernetes/pki/etcd/healthcheck-client.crt}"
KEY_FILE="${KEY_FILE:-/etc/kubernetes/pki/etcd/healthcheck-client.key}"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/etcd-${TIMESTAMP}.db"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

for file in "$CA_FILE" "$CERT_FILE" "$KEY_FILE"; do
  [[ -r "$file" ]] || {
    echo "ERROR: Cannot read $file" >&2
    exit 1
  }
done

etcdctl \
  --endpoints="$ETCD_ENDPOINT" \
  --cacert="$CA_FILE" \
  --cert="$CERT_FILE" \
  --key="$KEY_FILE" \
  endpoint health

etcdctl \
  --endpoints="$ETCD_ENDPOINT" \
  --cacert="$CA_FILE" \
  --cert="$CERT_FILE" \
  --key="$KEY_FILE" \
  snapshot save "$BACKUP_FILE"

chmod 600 "$BACKUP_FILE"

etcdutl snapshot status "$BACKUP_FILE" --write-out=table

sha256sum "$BACKUP_FILE" > "${BACKUP_FILE}.sha256"

echo "Backup completed: $BACKUP_FILE"
echo "Checksum: ${BACKUP_FILE}.sha256"