# enable-chrome-gemini-skill

在 macOS 上开启 Google Chrome 的 Gemini (Glic) 功能。提供“一行命令启动”和“永久激活”两种方案，支持环境自检与备份恢复。

## Installation

This is a skill for [Gemini CLI](https://github.com/google/gemini-cli).

To install this skill:

1. Clone this repository.
2. Run the install command:

```bash
gemini skills install ./enable-chrome-gemini-skill
```

## Documentation

# Enable Chrome Gemini Skill

## 方案取舍建议

1. **临时/首选方案** (Launch Temp)：不修改任何文件，通过命令行参数启动。适合初次测试或不想动系统文件的用户。
2. **永久激活方案** (Permanent)：修改 `Local State` 配置文件。适合希望每次正常打开 Chrome 都能看到 Gemini 的用户。

## 工作流

### 第一步：环境与状态检查
- 运行 `scripts/check_status.sh` 查看当前是否已激活。
- 运行 `scripts/check_env.sh` 检查 VPN (必须美国) 和系统语言。

### 第二步：优先执行“单行命令”试用
告知用户最安全的方法是运行：
`scripts/launch_temp.sh`
（这相当于运行 `open -n -a "Google Chrome" --args --variations-override-country=us`）

### 第三步：(可选) 执行永久修改
如果用户需要永久生效：
- 运行 `scripts/activate.sh`。

### 第四步：故障恢复
- 如果永久修改后出现问题，运行 `scripts/restore.sh`。

## 资源清单
- `scripts/launch_temp.sh`: **(推荐)** 无损临时启动。
- `scripts/check_status.sh`: 检查配置状态。
- `scripts/check_env.sh`: 环境诊断。
- `scripts/activate.sh`: 永久修改。
- `scripts/restore.sh`: 恢复备份。
