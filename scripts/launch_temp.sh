#!/bin/bash
echo "🚀 正在通过临时参数启动 Google Chrome (US Mode)..."
echo "提示：请确保您已经通过 Command + Q 彻底退出了 Chrome。"

if open -n -a "Google Chrome" --args --variations-override-country=us 2>/dev/null; then
  echo "✅ 已通过应用名启动 Chrome。"
elif [ -d "/Applications/Google Chrome.app" ] && open -n -a "/Applications/Google Chrome.app" --args --variations-override-country=us; then
  echo "✅ 已通过应用路径启动 Chrome。"
else
  echo "❌ 未找到 Google Chrome.app，请确认 Chrome 已安装在 /Applications。"
  exit 1
fi

echo "✅ 指令已发送。如果右上角或侧边栏没有出现 Gemini，请检查您的 VPN 是否已切换至美国节点。"
