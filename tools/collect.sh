#!/usr/bin/env bash
set -u # 遇到未定义变量报错，但不使用 set -e 以便让脚本跑完显示所有错误

# 定义路径
WORKDIR="$(cd "$(dirname "$0")/.." && pwd)"
NODE1_OUT="$WORKDIR/node1"
NODE3_OUT="$WORKDIR/node3"

echo "🐧 === 开始收集项目文件 ==="
echo "📂 目标仓库路径: $WORKDIR"

# 1. 准备目录
mkdir -p "$NODE1_OUT/scripts" "$NODE1_OUT/cron" "$NODE1_OUT/storage"
mkdir -p "$NODE3_OUT/logrotate"

# 2. 收集 node1 同步脚本
echo "--------------------------------"
echo "🔍 [1/5]正在查找同步脚本..."
if [ -f "/usr/local/sbin/zzyl_log_sync.sh" ]; then
    cp /usr/local/sbin/zzyl_log_sync.sh "$NODE1_OUT/scripts/"
    echo "✅ 成功: 同步脚本已收集"
else
    echo "❌ 失败: 未找到 /usr/local/sbin/zzyl_log_sync.sh (请确认路径)"
fi

# 3. 收集 Crontab
echo "--------------------------------"
echo "🔍 [2/5] 正在导出 Crontab..."
# 尝试导出，如果为空或失败则提示
if crontab -l > "$NODE1_OUT/cron/crontab.root" 2>/dev/null; then
    # 检查文件是否为空
    if [ -s "$NODE1_OUT/cron/crontab.root" ]; then
        echo "✅ 成功: Crontab 已导出"
    else
        echo "⚠️  警告: Crontab 文件是空的 (你可能还没配定时任务)"
    fi
else
    echo "❌ 失败: 无法读取 Crontab"
fi

# 4. 收集 fstab
echo "--------------------------------"
echo "🔍 [3/5] 正在收集 fstab 变更..."
grep "zzyl_logs" /etc/fstab > "$NODE1_OUT/storage/fstab.zzyl_logs.addition"
if [ -s "$NODE1_OUT/storage/fstab.zzyl_logs.addition" ]; then
    echo "✅ 成功: fstab 配置已收集"
else
    echo "⚠️  警告: fstab 里没找到 'zzyl_logs' 关键字"
fi

# 5. 收集挂载信息 (作为证据)
echo "--------------------------------"
echo "🔍 [4/5] 正在收集磁盘证据..."
lsblk > "$NODE1_OUT/storage/lsblk.txt" && echo "✅ lsblk 收集完毕"
df -hT /mnt/zzyl_logs > "$NODE1_OUT/storage/df_zzyl_logs.txt" && echo "✅ df 收集完毕"

# 6. 收集 node3 配置 (SSH)
echo "--------------------------------"
echo "🔍 [5/5] 正在从 node3 拉取 logrotate 配置..."
if ssh -o BatchMode=yes -o ConnectTimeout=5 root@192.168.88.103 "test -f /etc/logrotate.d/nginx"; then
    scp root@192.168.88.103:/etc/logrotate.d/nginx "$NODE3_OUT/logrotate/"
    echo "✅ 成功: node3 配置文件已抓取"
else
    echo "❌ 失败: 无法连接 node3 或文件不存在 (请检查 SSH 和文件路径)"
fi

echo "--------------------------------"
echo "🎉 采集结束！请检查上方是否有 ❌ 报错"
