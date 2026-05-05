#!/bin/bash
# Chrome Gemini 激活脚本
# 必须在 Chrome 完全退出后运行（⌘Q）

LOCAL_STATE="$HOME/Library/Application Support/Google/Chrome/Local State"

if pgrep -x "Google Chrome" > /dev/null 2>&1; then
    echo "❌ Chrome 正在运行，请先完全退出 Chrome（⌘Q）"
    exit 1
fi

# 备份
BACKUP="$LOCAL_STATE.backup.$(date +%Y%m%d_%H%M%S)"
cp "$LOCAL_STATE" "$BACKUP"
echo "✅ 已备份: $BACKUP"

# 修改配置
python3 -c "
import json
path = '$LOCAL_STATE'
with open(path, 'r') as f:
    data = json.load(f)
if 'glic' not in data:
    data['glic'] = {}
data['glic']['launcher_enabled'] = True
data['glic']['multi_instance_enabled_by_tier'] = True
data['browser']['variations_country'] = 'us'
data['variations_country'] = 'us'
data['variations_safe_seed_permanent_consistency_country'] = 'us'
data['variations_safe_seed_session_consistency_country'] = 'us'
if 'variations_permanent_consistency_country' in data:
    data['variations_permanent_consistency_country'] = [data.get('variations_safe_seed_milestone', ''), 'us']
with open(path, 'w') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print('✅ 配置已更新')
"

echo "💡 重新打开 Chrome 即可使用 Gemini"
