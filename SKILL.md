---
name: enable-chrome-gemini-skill
description: 在 macOS 上开启 Google Chrome 的 Gemini (Glic) 功能。提供"一行命令启动"和"永久激活"两种方案，支持环境自检与备份恢复。
---

# Enable Chrome Gemini Skill

## 关键发现（2026-05 验证）

仅修改 `browser.variations_country` 不够。Glic (Gemini in Chrome) 激活需要同时修改 Local State 中的多个字段：

- `glic.launcher_enabled` → True（最关键的开关）
- `glic.multi_instance_enabled_by_tier` → True
- `browser.variations_country` → us
- `variations_country` → us（与 browser.variations_country 是两个独立字段）
- `variations_safe_seed_permanent_consistency_country` → us
- `variations_safe_seed_session_consistency_country` → us
- `variations_permanent_consistency_country` → `['版本号', 'us']`（数组格式）

Chrome 每次启动会重置 `variations_safe_seed_*` 和 `variations_country` 字段为 `cn`，"永久激活"并不可靠。用 wrapper 脚本在启动前自动修改配置是最稳方案。

## 方案取舍建议

1. **临时/首选方案** (Launch Temp)：不修改任何文件，通过命令行参数启动。适合初次测试或不想动系统文件的用户。
2. **永久激活方案** (Permanent)：修改 `Local State` 配置文件。适合希望每次正常打开 Chrome 都能看到 Gemini 的用户。
3. **推荐方案** (Wrapper)：Chrome 每次启动都会重置 safe seed 字段，"永久激活"并不可靠。用 wrapper 脚本在启动前自动修改配置是最稳方案。可包装为 Alfred 工作流（关键词 `cg`）。

## 工作流

### 第一步：环境与状态检查

检查 Chrome 版本、当前进程和 Local State 配置：

```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version
ps aux | grep -i "Google Chrome" | grep -v grep | head -5
python3 -c "import json; d=json.load(open('$HOME/Library/Application Support/Google/Chrome/Local State')); print('glic:', d.get('glic',{})); print('country:', d.get('browser',{}).get('variations_country','N/A'))"
```

### 第二步：临时启动（推荐先试）

关闭所有 Chrome 窗口后执行：

```bash
open -n -a "Google Chrome" --args --variations-override-country=us --enable-features=Glic
```

### 第三步：永久激活

如果临时方案生效且需要永久生效，修改 Local State：

```bash
# 路径
LOCAL_STATE="$HOME/Library/Application Support/Google/Chrome/Local State"

# 备份
cp "$LOCAL_STATE" "$LOCAL_STATE.backup.$(date +%Y%m%d_%H%M%S)"
```

用 Python 修改（必须关闭 Chrome 后执行）：

```python
import json, os
path = os.path.expanduser("~/Library/Application Support/Google/Chrome/Local State")
with open(path, 'r') as f:
    data = json.load(f)

# 关键字段修改
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
```

重新打开 Chrome 即可。

### 第四步：Wrapper 脚本（推荐）

Chrome 每次启动重置 safe seed 字段，创建 wrapper 脚本 `~/bin/chrome-gemini`：

```bash
#!/usr/bin/env bash
set -euo pipefail
LOCAL_STATE="$HOME/Library/Application Support/Google/Chrome/Local State"

if [ "${1:-}" = "check" ]; then
    python3 -c "
import json
d = json.load(open('$LOCAL_STATE'))
glic = d.get('glic', {})
ok = glic.get('launcher_enabled') and d.get('browser',{}).get('variations_country') == 'us'
print('✅ Gemini 已激活' if ok else '❌ Gemini 未激活')
"
    exit 0
fi

# 关闭 Chrome
if pgrep -x "Google Chrome" > /dev/null 2>&1; then
    osascript -e 'quit app "Google Chrome"'
    sleep 2
    pgrep -x "Google Chrome" > /dev/null 2>&1 && killall "Google Chrome" 2>/dev/null || true
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
open -a "Google Chrome"
```

`chmod +x ~/bin/chrome-gemini`，确保 `~/bin` 在 PATH 中。

### 第五步：Alfred 工作流（可选）

将 wrapper 脚本包装为 Alfred 工作流：

1. 创建 `run.sh`（内容同 wrapper 脚本）
2. `info.plist` 中 Script Action 使用 `scriptfile=run.sh`、`type=0`（外部脚本），**不要内嵌脚本到 plist XML**（`>`、`&` 等字符的 XML 转义会出问题）
3. 关键词设为 `cg`，用 `cg check` 检查状态
4. 打包：`zip -r Chrome-Gemini.alfredworkflow info.plist run.sh`
5. 双击 `.alfredworkflow` 文件安装

### 第六步：故障恢复

从备份恢复：

```bash
ls "$LOCAL_STATE".backup.*  # 找到备份
cp "$LOCAL_STATE".backup.YYYYMMDD_HHMMSS "$LOCAL_STATE"
```

## Alfred 工作流集成

Chrome 每次启动会重置 `variations_safe_seed_*` 字段，需要启动前修改。Alfred 工作流是最佳方案。

### plist 格式要求（Alfred 5）

创建 `info.plist` + 外部 `run.sh`，打包为 `.alfredworkflow`（即 zip）。

关键字段：
- keyword trigger 类型: `alfred.workflow.input.keyword`（不是 `alfred.workflow.trigger.keyword`）
- script action 类型: `alfred.workflow.action.script`
- bash 脚本 `type`: 0，AppleScript `type`: 6
- `scriptargtype`: 1 = argv，2 = {query}
- connections 中用 `vitoclose`（不是 `vitowards`）
- 必须有 `userconfigurationconfig` 空数组
- 必须有 `variables` 空 dict

### XML 转义陷阱

脚本中的 `>`, `&`, `"` 等字符在 plist XML 中需要转义。最简单的方案：**用外部脚本文件**（`scriptfile` 字段），不要内联脚本。

### 打包

```bash
cd workflow_dir
zip -r ~/Desktop/Chrome-Gemini.alfredworkflow info.plist run.sh
```

## 常见陷阱

- 必须完全退出 Chrome（⌘Q），不能只是关闭窗口
- VPN 不影响 Local State 修改，但影响 Gemini 功能的实际可用性
- Chrome 更新后可能重置 `glic.launcher_enabled`，需要重新修改
- Chrome 启动时会重置 `variations_safe_seed_*` 和 `variations_country` 字段，用 Alfred 工作流在启动前修改可解决
- `browser.variations_country` 和 `variations_country` 是两个独立字段，都需要改
- `variations_permanent_consistency_country` 是数组格式 `['版本号', 'us']`
