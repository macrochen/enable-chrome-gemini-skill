---
name: enable-chrome-gemini-skill
description: 在 macOS 上开启 Google Chrome 的 Gemini (Glic) 功能。提供"一行命令启动"和"永久激活"两种方案，支持环境自检与备份恢复。
---

# Enable Chrome Gemini Skill

## 关键发现（2026-04 验证）

仅修改 `variations_country` 不够。Glic (Gemini in Chrome) 激活需要同时修改 Local State 中的多个字段：

- `glic.launcher_enabled` → True（这是最关键的开关）
- `variations_safe_seed_permanent_consistency_country` → us
- `variations_safe_seed_session_consistency_country` → us
- `browser.variations_country` → us

## 方案取舍建议

1. **临时/首选方案** (Launch Temp)：不修改任何文件，通过命令行参数启动。适合初次测试或不想动系统文件的用户。
2. **永久激活方案** (Permanent)：修改 `Local State` 配置文件。适合希望每次正常打开 Chrome 都能看到 Gemini 的用户。

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
data['variations_safe_seed_permanent_consistency_country'] = 'us'
data['variations_safe_seed_session_consistency_country'] = 'us'

with open(path, 'w') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
```

重新打开 Chrome 即可。

### 第四步：故障恢复

从备份恢复：

```bash
ls "$LOCAL_STATE".backup.*  # 找到备份
cp "$LOCAL_STATE".backup.YYYYMMDD_HHMMSS "$LOCAL_STATE"
```

## 常见陷阱

- 必须完全退出 Chrome（⌘Q），不能只是关闭窗口
- VPN 不影响 Local State 修改，但影响 Gemini 功能的实际可用性
- Chrome 更新后可能重置 `glic.launcher_enabled`，需要重新修改
