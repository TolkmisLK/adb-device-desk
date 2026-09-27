# Wireless discovery

[中文无线发现说明](#中文无线发现说明) · [English](#wireless-discovery)

On the Wireless page, select **Refresh discovery** to query `adb mdns services`. The app separates `_adb-tls-pairing._tcp` from `_adb-tls-connect._tcp` and displays validated host/port pairs. Choosing **Use address** fills only that type's input; it does not issue a pairing or connection command. Pairing still requires the six-digit code and the explicit Pair action. ADB itself may independently reconnect to previously authorized devices according to its own configuration.

Compare the address with the phone's Wireless debugging screen. Service names and addresses are untrusted discovery data, not proof of device identity. An empty list can result from disabled wireless debugging, network isolation or unsupported discovery; manual entry remains available. Legacy `_adb._tcp` services are not treated as modern TLS pairing/connect entries.

The parser ignores malformed rows/endpoints, deduplicates each type/address pair and bounds results to 100 from at most 500 lines. IPv4, bracketed IPv6 and valid hostnames use the existing endpoint validator. Unsupported output is not reported as a successful empty discovery. Results remain in memory, reset when changing ADB executable, and are excluded from saved settings and diagnostic reports. Demo mode uses documentation-only addresses and never invokes ADB.

Validation: local formatting and ten real-process/core smoke checks passed. Local Flutter test startup currently crashes while reading its cached tool snapshot (SIGBUS), before tests execute. New parser/command/widget regressions and actual demo capture are submitted to CI; no discovery with a physical Android device or real multicast network is claimed.

## 中文无线发现说明

在「无线连接」页点击「刷新发现」，应用查询 `adb mdns services`，区分 `_adb-tls-pairing._tcp`（配对）与 `_adb-tls-connect._tcp`（连接），显示通过地址格式检查的主机和端口。选择「使用地址」仅把对应类型的地址填入输入框，**不会**发起配对或连接；配对仍要填写六位码并点击「配对」，连接也要单独操作。ADB 可能根据自身配置重新连接以前授权的设备，这属于 ADB 行为。

发现条目的名称和地址是不可信数据，不能证明设备身份；请与手机「无线调试」页面逐项核对。列表为空可能与手机未开启无线调试、网络隔离或发现能力有关，仍可手动填写。旧式 `_adb._tcp` 不当作现代 TLS 配对或连接服务。

解析器忽略格式错误的行和地址，每种类型/地址组合去重，并从最多 500 行中返回最多 100 项。IPv4、带方括号的 IPv6 和有效主机名使用既有端点校验。无法识别的命令输出不会被当作成功的空列表。发现结果只保存在内存，切换 ADB 程序时清空，不写入设置或诊断报告。演示模式使用文档用途的样例地址，不调用 ADB。完整配对与连接步骤见[中文使用指南](USER-GUIDE.zh-CN.md)。

**本段历史验证状态：** 当时本地格式检查和十个真实进程/核心冒烟检查通过；本地 Flutter 测试工具在执行测试前读取缓存快照时发生 SIGBUS。新解析器、命令和界面回归与演示截图交由 CI 验证。当时未使用真实 Android 设备或实际组播网络验证无线发现。后续证据应查[验证记录](VALIDATION.md)，不能把当时的本地失败或未测状态误读成当前结论。
