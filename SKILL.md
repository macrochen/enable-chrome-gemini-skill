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

### 第五步：Alfred 工作流（可选，推荐）

Alfred 工作流是最佳方案，每次启动前自动修改配置。

1. 创建 `run.sh`（内容同 wrapper 脚本）
2. **用 Python plistlib 生成 `info.plist`**（避免 XML 转义问题）
3. 关键词设为 `cg`，用 `cg check` 检查状态
4. 打包：`zip -r Chrome-Gemini.alfredworkflow info.plist`
5. 双击 `.alfredworkflow` 文件安装

**关键：必须用 `plistlib` 生成 plist，不能手写 XML。**

```python
import plistlib

with open('run.sh', 'r') as f:
    script_content = f.read()

plist = {
    'bundleid': 'com.macrochen.chrome-gemini',
    'name': 'Chrome Gemini',
    'objects': [
        {
            'config': {'argumenttype': 1, 'keyword': 'cg', 'text': 'Chrome Gemini', 'withspace': True},
            'type': 'alfred.workflow.input.keyword',
            'uid': 'DEADBEEF-0001-0001-0001-000000000001',
            'version': 1
        },
        {
            'config': {
                'script': script_content,   # 脚本内嵌
                'scriptfile': '',            # 留空
                'scriptargtype': 1,
                'type': 0,                   # bash
                'concurrently': False,
                'escaping': 0
            },
            'type': 'alfred.workflow.action.script',
            'uid': 'DEADBEEF-0001-0001-0001-000000000002',
            'version': 2
        }
    ],
    'connections': {
        'DEADBEEF-0001-0001-0001-000000000001': [
            {'destinationuid': 'DEADBEEF-0001-0001-0001-000000000002', 'modifiers': 0, 'modifiersubtext': '', 'vitoclose': False}
        ],
        'DEADBEEF-0001-0001-0001-000000000002': []
    },
    'uidata': {
        'DEADBEEF-0001-0001-0001-000000000001': {'xpos': 100, 'ypos': 200},
        'DEADBEEF-0001-0001-0001-000000000002': {'xpos': 350, 'ypos': 200}
    },
    'userconfigurationconfig': [],
    'variables': {},
    'version': '1.0.0',
    'description': 'Chrome Gemini 启动器',
    'readme': '用法: cg → 启动, cg check → 检查状态',
    'disabled': False,
    'webaddress': '',
    'category': 'Tools',
    'createdby': 'macrochen'
}

with open('info.plist', 'wb') as f:
    plistlib.dump(plist, f, sort_keys=True)
```

然后打包：`zip -r Chrome-Gemini.alfredworkflow info.plist`（不需要 run.sh）。

### 第六步：故障恢复

从备份恢复：

```bash
ls "$LOCAL_STATE".backup.*  # 找到备份
cp "$LOCAL_STATE".backup.YYYYMMDD_HHMMSS "$LOCAL_STATE"
```

## Alfred 工作流集成

Chrome 每次启动会重置 `variations_safe_seed_*` 字段，需要启动前修改。Alfred 工作流是最佳方案。

### plist 生成方式（Alfred 5）

**必须用 Python `plistlib` 生成 plist**，不能手写 XML。

常见错误：
- 手写 XML plist：`>`, `&`, `"` 等字符需要手动转义，极易出错
- `scriptfile` 外部脚本：Alfred 安装 `.alfredworkflow` 时不打包外部文件，脚本会变成默认模板

正确方案：用 `plistlib.dump()` 生成 plist，脚本内嵌到 `config.script` 字段，`scriptfile` 留空。

### 关键字段

- keyword trigger 类型: `alfred.workflow.input.keyword`
- script action 类型: `alfred.workflow.action.script`
- bash 脚本 `type`: 0，AppleScript `type`: 6
- `scriptargtype`: 1 = argv，2 = {query}
- connections 中用 `vitoclose`（不是 `vitowards`）
- 必须有 `userconfigurationconfig` 空数组
- 必须有 `variables` 空 dict

### 打包

```bash
cd workflow_dir
zip -r ~/Desktop/Chrome-Gemini.alfredworkflow info.plist
```

## 常见陷阱

- 必须完全退出 Chrome（⌘Q），不能只是关闭窗口
- VPN 不影响 Local State 修改，但影响 Gemini 功能的实际可用性
- Chrome 更新后可能重置 `glic.launcher_enabled`，需要重新修改
- Chrome 启动时会重置 `variations_safe_seed_*` 和 `variations_country` 字段，用 Alfred 工作流在启动前修改可解决
- `browser.variations_country` 和 `variations_country` 是两个独立字段，都需要改
- `variations_permanent_consistency_country` 是数组格式 `['版本号', 'us']`
