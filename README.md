# Zonelet

小而美、完全离线的 macOS 菜单栏世界时钟。

[English](#english)

官网：<https://hjingsuper.github.io/Zonelet/> · [下载最新版本](https://github.com/hjingsuper/Zonelet/releases/latest)

## 功能

- 添加任意系统时区；首次启动默认只有 UTC
- 默认简体中文，也可切换 English
- 可一键统一全部时区格式，也可单独设置每个时区，并实时预览
- 多个时区之间自动显示分隔符
- 单独控制菜单栏显示、重命名和排序
- 跨日时显示 `+1` 或 `-1`
- 没有额外启动图标、账号、联网、分析、日历、天气或同步

点击菜单栏中的任意时区即可打开管理界面，也可以再次启动 Zonelet。

## 运行

需要 macOS 14 或更高版本以及 Xcode Command Line Tools。

```sh
./script/build_and_run.sh
```

运行测试：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

## English

Zonelet is a tiny, fully offline macOS menu bar world clock. Each clock has its
own date and time format, visible clocks are clearly separated, and new installs
start with UTC only. There are no accounts, analytics, or network access.

## License

Zonelet is open source under the [MIT License](LICENSE).

Project home: <https://github.com/hjingsuper/Zonelet>

The website is deployed from `docs/` with GitHub Pages. Every push builds a
downloadable Actions artifact; pushing a version tag such as `v1.6` creates a
GitHub Release with the packaged macOS app and SHA-256 checksum.
