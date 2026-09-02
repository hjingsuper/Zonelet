# Zonelet

小而美的 macOS 菜单栏世界时钟。

[English](#english)

官网：<https://hjingsuper.github.io/Zonelet/> · [下载最新版本](https://github.com/hjingsuper/Zonelet/releases/latest)

正式版本提供适用于 Apple Silicon（M 系列芯片）的 DMG 安装镜像。

## 功能

- 添加任意地区时间；首次启动默认只有 UTC
- 默认简体中文，也可切换 English
- 可一键统一全部地区时间格式，也可单独设置每个地区，并实时预览
- 多个地区时间之间自动显示分隔符
- 所有已启用地区时间集中在一个稳定的菜单栏项目中显示
- 单独控制菜单栏显示、重命名和排序
- 跨日时显示 `+1` 或 `-1`
- 可选择是否开机自启；默认开启，启动时只驻留菜单栏、不弹出主界面
- 登录项注册失败时可重新检测，并提示确认应用安装位置
- 自动在后台下载更新，安装完成后重新启动
- 地区时间换算完全离线；仅检查更新时连接 GitHub Releases
- 没有额外启动图标、账号、分析、日历、天气或同步

点击菜单栏中的 Zonelet 时间即可打开管理界面，也可以再次启动 Zonelet。

## 安装与首次打开

1. 下载并双击 `Zonelet-Apple-Silicon.dmg`。
2. 将 Zonelet 拖入右侧的“应用程序”文件夹。
3. 在“应用程序”中打开 Zonelet；应用默认只显示 UTC，并驻留菜单栏。

Zonelet 是免费开源项目，目前没有 Apple Developer 证书。首次打开时如果
提示“Apple 无法验证 Zonelet”，请确认安装包来自本仓库的 GitHub Releases，
再前往“系统设置 → 隐私与安全性”，找到被阻止的 Zonelet 并点击“仍要打开”。

从 v1.12 开始，应用使用正式且唯一的 `com.hjingsuper.Zonelet` 标识，并自动
迁移旧版的地区时间、格式和开机自启设置。这可绕开部分 macOS 26 设备中
Control Center 错误保留旧菜单栏阻止状态的问题。如果菜单栏仍未显示，请在
“系统设置 → 菜单栏 → 允许在菜单栏显示”中确认 Zonelet 已开启。

## 运行

需要 macOS 14 或更高版本以及 Xcode Command Line Tools。

```sh
./script/build_and_run.sh
```

运行测试：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

创建带背景和“拖入应用程序”布局的 DMG，需要 Python 3.10+：

```sh
python3 -m pip install dmgbuild==1.6.7
./script/build_and_run.sh --package
./script/package_dmg.sh dist/Zonelet.app Zonelet-Apple-Silicon.dmg
```

## 发布

推送新的 `v*` 标签会自动测试、打包 Apple Silicon DMG、生成 SHA-256
校验文件并发布 GitHub Release。没有 Apple 证书时使用固定的开源项目签名，
用户仍需按上面的步骤在“隐私与安全性”中允许首次打开。

未来如果有 Apple Developer 证书，可以在仓库的
**Settings → Secrets and variables → Actions** 中配置：

- `MACOS_CERTIFICATE_BASE64`：Developer ID Application `.p12` 文件的 Base64 内容
- `MACOS_CERTIFICATE_PASSWORD`：导出 `.p12` 时设置的密码
- `APPLE_ID`：Apple Developer 账户邮箱
- `APPLE_TEAM_ID`：开发者团队 ID
- `APPLE_APP_PASSWORD`：为公证创建的 App 专用密码
- `SPARKLE_ED_PRIVATE_KEY`：Sparkle EdDSA 私钥；使用 Sparkle 的
  `generate_keys --account Zonelet -x <文件>` 导出后，将文件内容保存为 Secret

配置完整时，GitHub Actions 会自动导入证书、启用 Hardened Runtime、
签名应用、提交 Apple 公证并装订公证票据；未配置时仍会正常发布临时签名版本。

配置 `SPARKLE_ED_PRIVATE_KEY` 后，流程还会生成签名的 `appcast.xml`；应用
定期检查该文件，并在后台下载、安装更新后重新启动。

## English

Zonelet is a tiny macOS menu bar world clock. Each clock has its own date and
time format, visible clocks are clearly separated, and new installs start with
UTC only. Time-zone conversion stays offline; only update checks access GitHub
Releases. There are no accounts, analytics, or tracking.

## License

Zonelet is open source under the [MIT License](LICENSE).

Project home: <https://github.com/hjingsuper/Zonelet>

本软件为免费开源项目，仅供交流学习与个人使用。请遵守相关法律法规与开源协议，勿用于任何商业或非法用途。

The website is deployed from `docs/` with GitHub Pages. Every push builds a
downloadable Actions artifact; pushing a version tag such as `v1.9` creates a
GitHub Release with an Apple Silicon DMG and SHA-256 checksum.
