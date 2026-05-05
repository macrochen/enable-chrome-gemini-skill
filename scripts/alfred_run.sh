#!/usr/bin/env bash
set -euo pipefail

LOCAL_STATE="$HOME/Library/Application Support/Google/Chrome/Local State"

# 仅检查模式
if [ "${1:-}" = "check" ]; then
    python3 -c "
import json
d = json.load(open('$LOCAL_STATE'))
glic = d.get('glic', {})
ok = glic.get('launcher_enabled') and d.get('variations_country') == 'us'
print('OK: Gemini 已激活' if ok else 'ERR: Gemini 未激活')
print('browser.variations_country:', d.get('browser', {}).get('variations_country', 'N/A'))
print('variations_country:', d.get('variations_country', 'N/A'))
print('safe_seed_permanent:', d.get('variations_safe_seed_permanent_consistency_country', 'N/A'))
print('safe_seed_session:', d.get('variations_safe_seed_session_consistency_country', 'N/A'))
"
    exit 0
fi

# 如果 Chrome 正在运行，先退出
if pgrep -x "Google Chrome" > /dev/null 2>&1; then
    osascript -e 'quit app "Google Chrome"'
    sleep 2
    if pgrep -x "Google Chrome" > /dev/null 2>&1; then
        killall "Google Chrome" 2>/dev/null || true
        sleep 1
    fi
fi

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
"

# 启动 Chrome
open -a "Google Chrome"
echo "OK: Chrome with Gemini 已启动"
