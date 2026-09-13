# 故障排查 / Troubleshooting

| 现象 | 建议检查 | What to check |
| --- | --- | --- |
| ADB 未就绪 | 设置中选择官方 Platform-Tools 的 adb.exe，验证保存；路径指向文件而非文件夹 | Select the official adb executable, not its directory |
| 没有设备 | USB 数据线、USB 调试、设备授权；Windows 厂商 USB 驱动 | Data cable, USB debugging, device authorization, OEM USB driver |
| unauthorized | 解锁设备并接受 RSA 授权提示 | Unlock and accept the RSA authorization prompt |
| offline | 数据线/网络、当前地址与端口、无线调试是否仍开启 | Cable/network, current endpoint and wireless debugging state |
| 配对成功但无法连接 | 配对端口与连接端口不同；返回无线调试主页面查看连接端口 | Use the connection port from the main Wireless debugging screen |
| 端口不可达 | 当前地址、端口、同网段路由、访客网络隔离、防火墙 | Current endpoint, routing, guest isolation and firewall |
| 端口可达但设备不可用 | 端口可能不是 ADB；也可能未配对、未授权或设备离线 | The service may not be ADB; pairing or authorization may be missing |
| 安装失败 | 单 APK、Android 版本、签名一致性和设备空间 | Single APK, Android compatibility, signing identity and free space |
| Windows 无法启动程序 | 完整解压 ZIP，保留 DLL 和 data；检查系统架构 | Extract the entire ZIP including DLLs and data; check system architecture |

端口检查不能确定具体根因，也不使用 ping 作为设备是否可连接的结论。ICMP 和 TCP 可能受到不同的网络规则影响。

The diagnostic tool checks one explicitly supplied TCP endpoint. It does not infer a firewall or route failure merely from a timeout, and it does not treat ping as proof of ADB connectivity.

官方参考 / References:

- [Android Debug Bridge](https://developer.android.com/tools/adb)
- [SDK Platform-Tools](https://developer.android.com/tools/releases/platform-tools)
- [Run apps on a hardware device](https://developer.android.com/studio/run/device)
- [Flutter Windows distribution](https://docs.flutter.dev/platform-integration/windows/building)
