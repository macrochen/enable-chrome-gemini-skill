#!/bin/bash
# 恢复备份文件并覆盖当前损坏的文件
if [ -f ~/Library/Application\ Support/Google/Chrome/Local\ State.bak ]; then
    mv ~/Library/Application\ Support/Google/Chrome/Local\ State.bak ~/Library/Application\ Support/Google/Chrome/Local\ State
    echo "已成功恢复备份。"
else
    echo "未发现备份文件，无法恢复。"
fi
