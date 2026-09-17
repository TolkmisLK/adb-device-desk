// Stable codes are shared by diagnostics, safe errors and exported reports.
String message(String code, bool english) {
  final value = _messages[code];
  return value == null
      ? (english ? 'The operation could not be completed.' : '未能完成操作。')
      : value[english ? 1 : 0];
}

const _messages = <String, List<String>>{
  'adb_available': ['ADB 已就绪', 'ADB is available'],
  'discovery_unavailable': [
    '当前 ADB 未返回无线发现列表。请更新官方 Platform-Tools，或手动填写手机显示的地址与端口。',
    'ADB did not return a wireless discovery list. Update official Platform-Tools or enter the address and port shown on your phone.',
  ],
  'adb_unavailable': [
    '无法启动 ADB。请在设置中选择官方 Platform-Tools 里的 adb.exe，并确认文件可运行。',
    'Cannot start ADB. Select adb.exe from the official Platform-Tools in Settings and check that it is executable.',
  ],
  'server_responding': ['本机 ADB 服务响应正常', 'Local ADB server is responding'],
  'server_not_checked': [
    'ADB 不可用，尚未检查设备',
    'Device check skipped because ADB is unavailable',
  ],
  'no_devices': [
    '尚未发现设备。USB 连接请开启 USB 调试；无线连接请先配对，再使用连接端口。',
    'No devices found. Enable USB debugging for USB, or pair first and use the connection port for Wi-Fi.',
  ],
  'device_ready': ['已发现可以操作的设备', 'A device is ready for operations'],
  'unauthorized': [
    '设备等待授权：解锁设备，接受 USB 调试授权弹窗。',
    'Authorization required: unlock the device and accept the USB debugging prompt.',
  ],
  'offline': [
    '设备处于离线状态。检查线缆或网络，并确认无线调试仍开启、地址和端口未变化。',
    'Device is offline. Check the cable or network and verify that wireless debugging, address and port are still current.',
  ],
  'no_permissions': [
    '当前用户无权访问 USB 设备。检查系统 USB 权限或驱动。',
    'USB access denied. Check operating-system USB permissions or drivers.',
  ],
  'recovery': [
    '设备处于恢复模式，常规操作不可用。',
    'Device is in recovery mode. Normal operations are unavailable.',
  ],
  'sideload': [
    '设备处于 sideload 模式，常规操作不可用。',
    'Device is in sideload mode. Normal operations are unavailable.',
  ],
  'bootloader': ['设备处于引导加载模式。', 'Device is in bootloader mode.'],
  'rescue': ['设备处于救援模式。', 'Device is in rescue mode.'],
  'host': [
    '设备返回 host 状态，常规操作不可用。',
    'Device reported host state. Normal operations are unavailable.',
  ],
  'port_reachable': ['目标 TCP 端口可连接', 'Target TCP port is reachable'],
  'port_unreachable': [
    '目标 TCP 端口无法连接。请核对当前地址与端口、同一局域网、访客网络隔离和防火墙；这些是可能原因，尚未定位具体原因。',
    'Target TCP port is unreachable. Check the current address and port, shared LAN, guest-network isolation and firewall. These are possible causes, not a confirmed diagnosis.',
  ],
  'port_is_not_authorization': [
    '端口检查只验证 TCP 连通性，不能确认它是 ADB 服务，也不能证明已配对或授权。',
    'A TCP check cannot confirm that the service is ADB or that pairing and authorization succeeded.',
  ],
  'port_not_checked': [
    '未填写目标地址，已跳过网络端口检查。',
    'No target supplied; network port check skipped.',
  ],
  'invalid_endpoint': [
    '请输入地址和端口，例如 192.168.1.20:37121 或 [2001:db8::1]:37121。端口范围为 1–65535。',
    'Enter host:port, e.g. 192.168.1.20:37121 or [2001:db8::1]:37121. Port must be 1–65535.',
  ],
  'invalid_pairing_code': [
    '配对码必须为设备上显示的 6 位数字。',
    'Enter the six-digit pairing code shown on the device.',
  ],
  'connect_failed': [
    'ADB 未确认连接成功。请使用无线调试主页面的连接端口，不要使用配对端口；然后运行连接诊断。',
    'ADB did not confirm a connection. Use the connection port on the main Wireless debugging screen, not the pairing port, then run diagnostics.',
  ],
  'pair_failed': [
    '配对未成功。重新打开设备上的“使用配对码配对设备”，核对配对端口和新配对码。',
    'Pairing failed. Reopen “Pair device with pairing code” and check the pairing port and fresh code.',
  ],
  'command_timeout': [
    '操作超时，已停止本次 ADB 客户端命令。检查设备和网络后再试。',
    'Operation timed out; this ADB client command was stopped. Check the device and network before retrying.',
  ],
  'output_limit': [
    '输出超过 24 MiB 上限，已停止读取。',
    'Output exceeded the 24 MiB limit; reading was stopped.',
  ],
  'command_failed': [
    'ADB 命令失败。请刷新设备状态、确认授权，必要时运行连接诊断。',
    'ADB command failed. Refresh devices, check authorization, and run diagnostics if needed.',
  ],
  'device_missing': [
    '目标设备已断开。请刷新设备列表并重新选择。',
    'The selected device disconnected. Refresh and select it again.',
  ],
  'invalid_device': ['请选择有效设备。', 'Select a valid device.'],
  'invalid_apk': ['请选择可读取的 .apk 文件。', 'Select a readable .apk file.'],
  'install_failed': [
    '安装失败。检查 APK 是否兼容、签名是否匹配以及设备空间是否充足。',
    'Installation failed. Check APK compatibility, signing identity and available device storage.',
  ],
  'invalid_screenshot': [
    '设备未返回有效的 PNG 截图，未保存文件。',
    'The device did not return a PNG screenshot; no file was saved.',
  ],
  'demo_only': [
    '当前为演示模式，设备操作已禁用。',
    'Device operations are disabled in demo mode.',
  ],
  'file_error': [
    '文件读写失败。请检查文件权限和剩余磁盘空间。',
    'File access failed. Check permissions and available disk space.',
  ],
  'unexpected_error': [
    '操作未完成。请刷新后重试。',
    'Operation did not complete. Refresh and try again.',
  ],
};
