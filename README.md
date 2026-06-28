# appstoreagent-watchdog

English follows Chinese.

## 中文

`appstoreagent-watchdog` 是一个 macOS 用户级守护脚本，用来绕过某些 macOS 27 环境中 `appstoreagent` 长时间占用高 CPU 的问题。

它不会修改系统文件，也不是系统级修复。它只会定期检查名为 `appstoreagent` 的进程；当该进程 CPU 占用达到配置阈值时，先发送 `TERM`，等待几秒后如果仍未退出且 PID 仍对应 `appstoreagent`，才发送 `KILL`。

### 文件

- `appstoreagent-watchdog.sh`: 单次检查脚本
- `install-appstoreagent-watchdog.sh`: 安装用户级 LaunchAgent，定时执行检查
- `uninstall-appstoreagent-watchdog.sh`: 卸载 LaunchAgent 和已复制的脚本

### 安装

```sh
git clone https://github.com/1510207073/appstoreagent-watchdog.git
cd appstoreagent-watchdog
./install-appstoreagent-watchdog.sh 80 60
```

参数含义：

- `80`: CPU 阈值，单位是百分比
- `60`: 检查间隔，单位是秒，最小为 10 秒

安装后会创建：

- 脚本：`~/.local/bin/appstoreagent-watchdog.sh`
- LaunchAgent：`~/Library/LaunchAgents/com.local.appstoreagent-watchdog.plist`
- 日志：`~/Library/Logs/appstoreagent-watchdog.log`

### 手动运行一次

```sh
./appstoreagent-watchdog.sh
```

### Dry run

只记录日志，不实际 kill：

```sh
APPSTOREAGENT_DRY_RUN=1 APPSTOREAGENT_CPU_THRESHOLD=80 ./appstoreagent-watchdog.sh
```

### 配置

可以通过环境变量覆盖默认值：

```sh
APPSTOREAGENT_CPU_THRESHOLD=120 ./appstoreagent-watchdog.sh
APPSTOREAGENT_TERM_WAIT_SECONDS=3 ./appstoreagent-watchdog.sh
APPSTOREAGENT_LOG_FILE=/tmp/appstoreagent-watchdog.log ./appstoreagent-watchdog.sh
```

安装为 LaunchAgent 时，推荐直接通过安装脚本参数调整：

```sh
./install-appstoreagent-watchdog.sh 120 60
```

### 卸载

```sh
./uninstall-appstoreagent-watchdog.sh
```

卸载脚本会移除 LaunchAgent 和复制到 `~/.local/bin` 的脚本，但会保留日志。

### 注意事项

如果 App Store 正在下载或更新应用，结束 `appstoreagent` 可能会中断当前操作。建议把阈值设得偏高，例如 `80`、`100` 或 `120`，避免处理短暂的正常 CPU 峰值。

## English

`appstoreagent-watchdog` is a small macOS user-level watchdog script for working around cases where `appstoreagent` keeps consuming high CPU on some macOS 27 systems.

It does not modify system files and is not an OS-level fix. It periodically checks for a process named `appstoreagent`; when the reported CPU usage reaches the configured threshold, it sends `TERM` first, waits briefly, and sends `KILL` only if the PID still exists and still appears to be `appstoreagent`.

### Files

- `appstoreagent-watchdog.sh`: one-shot watchdog check
- `install-appstoreagent-watchdog.sh`: installs a user-level LaunchAgent for periodic checks
- `uninstall-appstoreagent-watchdog.sh`: removes the LaunchAgent and installed script

### Install

```sh
git clone https://github.com/1510207073/appstoreagent-watchdog.git
cd appstoreagent-watchdog
./install-appstoreagent-watchdog.sh 80 60
```

Arguments:

- `80`: CPU threshold in percent
- `60`: check interval in seconds, minimum `10`

The installer creates:

- Script: `~/.local/bin/appstoreagent-watchdog.sh`
- LaunchAgent: `~/Library/LaunchAgents/com.local.appstoreagent-watchdog.plist`
- Log file: `~/Library/Logs/appstoreagent-watchdog.log`

### Run Once

```sh
./appstoreagent-watchdog.sh
```

### Dry Run

Log what would happen without killing the process:

```sh
APPSTOREAGENT_DRY_RUN=1 APPSTOREAGENT_CPU_THRESHOLD=80 ./appstoreagent-watchdog.sh
```

### Configuration

Override defaults with environment variables:

```sh
APPSTOREAGENT_CPU_THRESHOLD=120 ./appstoreagent-watchdog.sh
APPSTOREAGENT_TERM_WAIT_SECONDS=3 ./appstoreagent-watchdog.sh
APPSTOREAGENT_LOG_FILE=/tmp/appstoreagent-watchdog.log ./appstoreagent-watchdog.sh
```

When installed as a LaunchAgent, use the installer arguments:

```sh
./install-appstoreagent-watchdog.sh 120 60
```

### Uninstall

```sh
./uninstall-appstoreagent-watchdog.sh
```

The uninstaller removes the LaunchAgent and the copied script under `~/.local/bin`, but leaves log files in place.

### Notes

If the App Store is downloading or updating apps, killing `appstoreagent` may interrupt the current operation. Prefer a relatively high threshold such as `80`, `100`, or `120` to avoid reacting to short normal CPU spikes.

