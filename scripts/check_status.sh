#!/bin/bash

FILE="$HOME/Library/Application Support/Google/Chrome/Local State"

echo "🔍 正在检查 Chrome Gemini 配置状态..."

if [ ! -f "$FILE" ]; then
    echo "❌ 错误：找不到 Chrome 配置文件 (Local State)。"
    exit 1
fi

python3 -c "
import json
d = json.load(open('$FILE'))
glic = d.get('glic', {})
checks = {
    'glic.launcher_enabled': glic.get('launcher_enabled', False),
    'glic.multi_instance_enabled_by_tier': glic.get('multi_instance_enabled_by_tier', False),
    'browser.variations_country': d.get('browser', {}).get('variations_country') == 'us',
    'variations_country': d.get('variations_country') == 'us',
    'safe_seed_permanent': d.get('variations_safe_seed_permanent_consistency_country') == 'us',
    'safe_seed_session': d.get('variations_safe_seed_session_consistency_country') == 'us',
}
print('-----------------------------------')
all_ok = True
for k, v in checks.items():
    status = '✅' if v else '❌'
    print(f'{status} {k}: {v}')
    if not v:
        all_ok = False
print('-----------------------------------')
if all_ok:
    print('✨ 结论：Gemini 已完全激活')
else:
    print('💡 结论：部分字段未设置，需要运行激活脚本')
"
