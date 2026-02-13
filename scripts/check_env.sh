#!/bin/bash

echo "🔍 正在检查您的系统环境..."

# 1. 检查操作系统
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ 错误：此脚本仅支持 macOS 系统。"
    exit 1
else
    echo "✅ 操作系统：macOS"
fi

# 2. 检查系统语言和地区
LANGUAGES=$(defaults read -g AppleLanguages | head -n 2 | tail -n 1 | xargs)
LOCALE=$(defaults read -g AppleLocale)

echo "ℹ️  系统语言：$LANGUAGES"
echo "ℹ️  系统地区：$LOCALE"

if [[ "$LANGUAGES" == *"en"* ]] && [[ "$LOCALE" == *"US"* ]]; then
    echo "✅ 系统语言和地区：符合建议设置 (US/English)"
else
    echo "⚠️  建议：将系统语言设为 English，地区设为 United States 以获得最佳兼容性。"
fi

# 3. 检查网络 IP 位置 (使用 ipapi.co)
echo "🌐 正在检查网络出口位置..."
IP_INFO=$(curl -s https://ipapi.co/json/)
COUNTRY=$(echo "$IP_INFO" | grep '"country_code":' | cut -d '"' -f 4)
CITY=$(echo "$IP_INFO" | grep '"city":' | cut -d '"' -f 4)

if [ "$COUNTRY" == "US" ]; then
    echo "✅ 网络环境：美国 ($CITY)"
else
    echo "❌ 网络环境：当前检测到为 $COUNTRY ($CITY)，建议切换至美国节点。"
fi

# 4. 检查 Chrome 状态
if pgrep -x "Google Chrome" > /dev/null; then
    echo "⚠️  警告：检测到 Google Chrome 正在运行，请在激活前完全退出 (Command + Q)。"
else
    echo "✅ Chrome 状态：已退出"
fi

echo "-----------------------------------"
echo "检查完毕。"
