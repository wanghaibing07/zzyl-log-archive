#!/usr/bin/env bash
set -euo pipefail

BASE="/mnt/zzyl_logs"
DST_NODE2="${BASE}/node2_ruoyi"
DST_NODE3="${BASE}/node3_nginx"

mkdir -p "$DST_NODE2" "$DST_NODE3"

TODAY_DASH=$(date +%F)        # 2026-01-17
TODAY_COMPACT=$(date +%Y%m%d) # 20260117

RSYNC="/usr/bin/rsync"
SSH_OPTS="-o BatchMode=yes -o StrictHostKeyChecking=accept-new"

# node2: /home/ruoyi/logs/ 下的 sys-*.YYYY-MM-DD.log
# 需求：同步昨天及以前 => 排除今天
$RSYNC -avz --delete --delete-delay -e "ssh $SSH_OPTS" \
  --exclude="sys-*.${TODAY_DASH}.log" \
  --include="sys-*.log" \
  --exclude="*" \
  root@192.168.88.102:/home/ruoyi/logs/  "$DST_NODE2/"

# node3: /var/log/nginx/ 下的 access.log-YYYYMMDD / error.log-YYYYMMDD
# 需求：同步昨天及以前 => 排除今天
$RSYNC -avz --delete --delete-delay -e "ssh $SSH_OPTS" \
  --exclude="*-${TODAY_COMPACT}" \
  --include="access.log-*" \
  --include="error.log-*" \
  --exclude="*" \
  root@192.168.88.103:/var/log/nginx/ "$DST_NODE3/"

