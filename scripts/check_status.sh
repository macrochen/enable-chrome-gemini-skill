#!/bin/bash

FILE="$HOME/Library/Application Support/Google/Chrome/Local State"

echo "🔍 正在检查 Chrome 配置文件状态..."

if [ ! -f "$FILE" ]; then
    echo "❌ 错误：找不到 Chrome 配置文件 (Local State)。"
    exit 1
fi

# 检查 is_glic_eligible
IS_ELIGIBLE=$(grep -o '"is_glic_eligible":[[:space:]]*true' "$FILE")
# 检查 variations_country
COUNTRY=$(grep -o '"variations_country":"us"' "$FILE")
# 检查一致性国家设置
PERMANENT_COUNTRY=$(grep -o '"variations_permanent_consistency_country":\[[^]]*"us"\]' "$FILE")

echo "-----------------------------------"
if [ ! -z "$IS_ELIGIBLE" ]; then
    echo "✅ Gemini 资格开关 (is_glic_eligible): 已开启"
else
    echo "❌ Gemini 资格开关 (is_glic_eligible): 未开启"
fi

if [ ! -z "$COUNTRY" ]; then
    echo "✅ 浏览器国家属性 (variations_country): 已设为 US"
else
    echo "❌ 浏览器国家属性 (variations_country): 当前非 US"
fi

if [ ! -z "$PERMANENT_COUNTRY" ]; then
    echo "✅ 地理位置一致性 (permanent_consistency): 已锁定为 US"
else
    echo "❌ 地理位置一致性 (permanent_consistency): 未锁定"
fi
echo "-----------------------------------"

if [ ! -z "$IS_ELIGIBLE" ] && [ ! -z "$COUNTRY" ] && [ ! -z "$PERMANENT_COUNTRY" ]; then
    echo "✨ 结论：您的 Chrome 设置已经是激活状态，无需重复修改！"
else
    echo "💡 结论：您的 Chrome 尚未完全开启 Gemini，可以执行激活脚本。"
fi
