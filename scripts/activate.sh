#!/bin/bash
# 备份 Local State 文件
cp ~/Library/Application\ Support/Google/Chrome/Local\ State ~/Library/Application\ Support/Google/Chrome/Local\ State.bak

# 修改属性以开启 Gemini
# 1. 开启资格开关
sed -i '' 's/"is_glic_eligible":[[:space:]]*false/"is_glic_eligible":true/g' ~/Library/Application\ Support/Google/Chrome/Local\ State

# 2. 修改国家属性为美国
sed -i '' 's/"variations_country":"cn"/"variations_country":"us"/g' ~/Library/Application\ Support/Google/Chrome/Local\ State

# 3. 强制覆盖地理位置一致性检测
sed -i '' 's/"variations_permanent_consistency_country":[[:space:]]*\[\([^]]*\),[[:space:]]*"[^"]*"\]/"variations_permanent_consistency_country":[\1,"us"]/g' ~/Library/Application\ Support/Google/Chrome/Local\ State

echo "Gemini 激活指令执行完毕。请重新启动 Chrome 观察效果。"
