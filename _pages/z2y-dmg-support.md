---
layout: single
title: "Z2Y DMG Plus Support"
permalink: /support/z2y-dmg/
author_profile: false
toc: true
toc_label: "Support / 支持"
---

# Z2Y DMG Plus Support

Z2Y DMG Plus is a macOS utility for packaging apps, files, and folders into DMG disk images. It supports the classic drag-to-Applications layout and a one-click installer layout.

Z2Y DMG Plus 是一款 macOS DMG 打包工具，可将 App、文件或文件夹制作成磁盘映像，并支持经典拖拽安装和一键安装两种模式。

## Contact / 联系支持

For help, email [petterobam@gmail.com](mailto:petterobam@gmail.com). Please include your macOS version, Z2Y DMG Plus version, the selected packaging mode, and the exact error message.

如需帮助，请发送邮件至 [petterobam@gmail.com](mailto:petterobam@gmail.com)。请在邮件中注明 macOS 版本、Z2Y DMG Plus 版本、所选打包模式和完整错误信息。

You can also [report an issue on GitHub](https://github.com/zero2you4tech/Z2Y-DMG/issues). Do not include passwords, signing certificates, private keys, or other sensitive information.

你也可以通过 [GitHub 提交问题](https://github.com/zero2you4tech/Z2Y-DMG/issues)。请勿提交密码、签名证书、私钥或其他敏感信息。

## Before reporting an issue / 提交问题前

Please provide:

- The source item type: app, file, or folder.
- The packaging mode: Classic or One-click Installer.
- Whether the source app launches normally before packaging.
- The destination folder and available disk space.
- The complete build log or a screenshot of the error.

请提供以下信息：

- 源内容类型：App、文件或文件夹。
- 打包模式：经典模式或一键安装模式。
- 源 App 在打包前能否正常启动。
- 输出目录和可用磁盘空间。
- 完整构建日志或错误截图。

## Troubleshooting / 常见问题

### The source cannot be opened / 无法打开源内容

Confirm that the source still exists and that Z2Y DMG Plus has permission to access its folder. If the source is in Downloads, Desktop, or an external drive, macOS may ask for folder access.

请确认源内容仍然存在，并允许 Z2Y DMG Plus 访问其所在目录。如果源内容位于“下载”“桌面”或外接磁盘，macOS 可能会请求文件夹访问权限。

### DMG creation fails / DMG 创建失败

Choose a writable local output folder, make sure there is enough free space, and avoid writing over a mounted DMG. Retry with a short file name if the source name contains unusual path characters.

请选择可写的本地输出目录，确认磁盘空间充足，并避免覆盖当前已挂载的 DMG。如果源名称包含特殊路径字符，可改用较短的名称后重试。

### The packaged app will not open / 打包后的 App 无法打开

Verify that the original app launches and has a valid code signature. Z2Y DMG Plus preserves the source content but cannot repair an invalid or incomplete app signature.

请先确认原始 App 可以启动且代码签名有效。Z2Y DMG Plus 会保留源内容，但无法修复无效或不完整的 App 签名。

### One-click installation does not finish / 一键安装未完成

Keep the DMG mounted until installation finishes. Confirm that the destination Applications folder is writable, then retry. If macOS displays a security prompt, review the app publisher before allowing it to open.

请保持 DMG 挂载，直到安装完成。确认目标“应用程序”目录可写后重试。如果 macOS 显示安全提示，请先核对 App 发布者再选择打开。

## Response time / 响应时间

Support requests are normally reviewed within three business days.

支持请求通常会在三个工作日内处理。
