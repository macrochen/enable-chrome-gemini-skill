#!/bin/bash
echo "🚀 正在通过临时参数启动 Google Chrome (US Mode)..."
echo "提示：请确保您已经通过 Command + Q 彻底退出了 Chrome。"

open -n -a "Google Chrome" --args --variations-override-country=us

echo "✅ 指令已发送。如果右上角或侧边栏没有出现 Gemini，请检查您的 VPN 是否已切换至美国节点。"
