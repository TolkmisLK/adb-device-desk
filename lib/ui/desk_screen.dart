import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../core/adb_service.dart';
import '../core/demo_service.dart';
import '../core/diagnostics.dart';
import '../core/models.dart';
import '../core/settings.dart';
import 'messages.dart';

class DeskScreen extends StatefulWidget {
  const DeskScreen({
    super.key,
    required this.settings,
    required this.demo,
    required this.english,
    required this.onLanguageChanged,
    this.service,
  });
  final Settings settings;
  final bool demo;
  final bool english;
  final ValueChanged<bool> onLanguageChanged;
  final DeviceService? service;
  @override
  State<DeskScreen> createState() => _DeskScreenState();
}

class _DeskScreenState extends State<DeskScreen> {
  late DeviceService service =
      widget.service ??
      (widget.demo
          ? const DemoService()
          : AdbService(executable: widget.settings.adbPath));
  late final path = TextEditingController(text: widget.settings.adbPath);
  final target = TextEditingController();
  final pairingTarget = TextEditingController();
  final pairingCode = TextEditingController();
  final scroll = ScrollController();
  List<AdbDevice> devices = [];
  List<WirelessService> discovered = [];
  bool discoveryRun = false;
  String? selected;
  String? adbVersion;
  String? error;
  String? activity;
  Map<String, String>? deviceInfo;
  DiagnosticReport? report;
  bool busy = false;
  int page = 0;

  String t(String zh, String en) => widget.english ? en : zh;
  AdbDevice? get device {
    for (final value in devices) {
      if (value.serial == selected) return value;
    }
    return null;
  }

  bool get operable => !busy && !widget.demo && device?.ready == true;
  bool get canDisconnect {
    try {
      Endpoint.parse(selected ?? '');
      return !busy && !widget.demo;
    } on DeskException {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(perform(refresh));
    });
  }

  @override
  void dispose() {
    path.dispose();
    target.dispose();
    pairingTarget.dispose();
    pairingCode.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> perform(Future<void> Function() action) async {
    if (busy || !mounted) return;
    setState(() {
      busy = true;
      error = null;
      activity = null;
    });
    try {
      await action();
    } on DeskException catch (e) {
      if (mounted) setState(() => error = e.code);
    } on FileSystemException {
      if (mounted) setState(() => error = 'file_error');
    } on Object {
      if (mounted) setState(() => error = 'unexpected_error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> refresh() async {
    try {
      final version = await service.version();
      final found = await service.devices();
      if (!mounted) return;
      setState(() {
        adbVersion = version;
        devices = found;
        if (!found.any((d) => d.serial == selected)) {
          selected = found.isEmpty ? null : found.first.serial;
        }
        deviceInfo = null;
      });
    } on Object {
      if (mounted) {
        setState(() {
          adbVersion = null;
          devices = [];
          selected = null;
          deviceInfo = null;
        });
      }
      rethrow;
    }
  }

  void done(String zh, String en) {
    if (mounted) setState(() => activity = t(zh, en));
  }

  Future<bool> confirm(String title, String description) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t('取消', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t('继续', 'Continue')),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> install() async {
    final serial = selected!;
    final apk = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'APK', extensions: ['apk']),
      ],
    );
    if (apk == null || !mounted) return;
    if (!await confirm(
      t('安装 APK', 'Install APK'),
      '${apk.name}\n\n${t('将安装到所选设备。若应用已存在，将尝试保留数据并更新应用。', 'Install on the selected device. An existing app will be updated while retaining its data where supported.')}',
    )) {
      return;
    }
    await service.install(serial, apk.path);
    done('应用安装成功。', 'App installed successfully.');
  }

  Future<void> screenshot() async {
    final serial = selected!;
    final location = await getSaveLocation(
      suggestedName: 'screenshot.png',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'PNG', extensions: ['png']),
      ],
    );
    if (location == null) return;
    final bytes = await service.screenshot(serial);
    await File(location.path).writeAsBytes(bytes, flush: true);
    done('截图已保存。', 'Screenshot saved.');
  }

  Future<void> exportLogs() async {
    final serial = selected!;
    if (!await confirm(
      t('导出最近 500 行日志', 'Export the latest 500 log lines'),
      t(
        '设备日志可能包含账号、应用内容和其他个人信息。日志不会自动脱敏或上传，请在分享前检查。',
        'Device logs may contain accounts, app content and personal information. Logs are not automatically redacted or uploaded. Review them before sharing.',
      ),
    )) {
      return;
    }
    final location = await getSaveLocation(
      suggestedName: 'device-logcat.txt',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Text', extensions: ['txt']),
      ],
    );
    if (location == null) return;
    await File(
      location.path,
    ).writeAsString(await service.logs(serial), flush: true);
    done('设备日志已保存。', 'Device logs saved.');
  }

  Future<void> diagnose() async {
    final endpoint = target.text.trim().isEmpty
        ? null
        : Endpoint.parse(target.text);
    final result = await Diagnostics(
      service,
      probe: widget.demo ? (_) async => false : null,
    ).run(endpoint: endpoint, demo: widget.demo);
    if (mounted) setState(() => report = result);
  }

  Future<void> exportReport() async {
    final current = report;
    if (current == null) return;
    final location = await getSaveLocation(
      suggestedName: 'adb-diagnostic-report.json',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (location == null) return;
    await File(location.path).writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(current.toJson())}\n',
      flush: true,
    );
    done('诊断报告已保存。', 'Diagnostic report saved.');
  }

  void navigate(int value) {
    setState(() => page = value);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labels = [
      t('设备', 'Devices'),
      t('无线连接', 'Wireless'),
      t('连接诊断', 'Diagnostics'),
      t('设置', 'Settings'),
    ];
    const icons = [
      Icons.devices_rounded,
      Icons.wifi_rounded,
      Icons.fact_check_outlined,
      Icons.tune_rounded,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 880;
        return Scaffold(
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: page,
                  onDestinationSelected: navigate,
                  destinations: List.generate(
                    4,
                    (i) => NavigationDestination(
                      icon: Icon(icons[i]),
                      label: labels[i],
                    ),
                  ),
                ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  Container(
                    width: 218,
                    color: scheme.surface,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 30, 18, 32),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.usb_rounded,
                                  color: scheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'ADB\nDevice Desk',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (var i = 0; i < labels.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: ListTile(
                              selected: page == i,
                              selectedTileColor: scheme.primaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              leading: Icon(icons[i]),
                              title: Text(labels[i]),
                              onTap: () => navigate(i),
                            ),
                          ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('在本机处理', 'LOCAL WORKSPACE'),
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t(
                                  '设备数据留在你的电脑上。',
                                  'Device data stays on your computer.',
                                ),
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'v0.1.0',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          wide ? 32 : 18,
                          22,
                          wide ? 32 : 18,
                          18,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                wide
                                    ? t('安卓设备工作台', 'Android device workspace')
                                    : 'ADB Device Desk',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (widget.demo)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Chip(
                                  label: Text(t('演示数据', 'DEMO DATA')),
                                ),
                              ),
                            Icon(
                              adbVersion == null
                                  ? Icons.circle_outlined
                                  : Icons.check_circle_rounded,
                              size: 17,
                              color: adbVersion == null
                                  ? scheme.outline
                                  : scheme.primary,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              adbVersion == null
                                  ? t('ADB 未就绪', 'ADB unavailable')
                                  : t('ADB 已就绪', 'ADB ready'),
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (busy)
                        const LinearProgressIndicator(minHeight: 2)
                      else
                        const SizedBox(height: 2),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scroll,
                          padding: EdgeInsets.fromLTRB(
                            wide ? 32 : 18,
                            14,
                            wide ? 32 : 18,
                            32,
                          ),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1120),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (error != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: notice(
                                        message(error!, widget.english),
                                        failure: true,
                                      ),
                                    ),
                                  if (activity != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: notice(activity!),
                                    ),
                                  switch (page) {
                                    0 => devicesPage(),
                                    1 => wirelessPage(),
                                    2 => diagnosticsPage(),
                                    _ => settingsPage(),
                                  },
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget notice(String text, {bool failure = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: failure ? scheme.errorContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(failure ? Icons.error_outline : Icons.info_outline, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget heading(String title, String subtitle, {Widget? action}) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.6,
                ),
              ),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ],
    ),
  );

  Widget panel(String title, Widget child, {String? subtitle}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    ),
  );

  Widget button(
    String label,
    IconData icon,
    Future<void> Function() action, {
    bool enabled = true,
    bool primary = false,
  }) {
    final callback = enabled && !busy ? () => unawaited(perform(action)) : null;
    return primary
        ? FilledButton.icon(
            onPressed: callback,
            icon: Icon(icon, size: 18),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: callback,
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
  }

  Widget devicesPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading(
        t('你的设备', 'Your devices'),
        t(
          '查看连接状态，选择设备后开始操作。',
          'Check connections, select a device, and get to work.',
        ),
        action: button(t('刷新', 'Refresh'), Icons.refresh, refresh),
      ),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          metric(t('已发现', 'Detected'), devices.length, Icons.devices),
          metric(
            t('可操作', 'Ready'),
            devices.where((d) => d.ready).length,
            Icons.check_circle_outline,
          ),
          metric(
            t('待处理', 'Needs attention'),
            devices.where((d) => !d.ready).length,
            Icons.build_circle_outlined,
          ),
        ],
      ),
      const SizedBox(height: 22),
      if (devices.isEmpty)
        panel(
          t('连接第一台设备', 'Connect your first device'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cable_rounded, size: 44),
              const SizedBox(height: 16),
              Text(
                t(
                  '使用 USB 数据线连接设备，开启 USB 调试并接受设备上的授权提示。也可以使用无线连接向导。',
                  'Connect with a USB data cable, enable USB debugging and accept the authorization prompt. You can also use the wireless connection guide.',
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: () => navigate(adbVersion == null ? 3 : 1),
                    child: Text(
                      adbVersion == null
                          ? t('配置 ADB', 'Set up ADB')
                          : t('无线连接', 'Wireless connection'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => navigate(2),
                    child: Text(t('排查连接问题', 'Troubleshoot')),
                  ),
                ],
              ),
            ],
          ),
        )
      else ...[
        Card(
          child: Column(
            children: [
              for (var i = 0; i < devices.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 20, endIndent: 20),
                deviceTile(devices[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        panel(
          t('设备操作', 'Device actions'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (device != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SelectableText(
                    '${device!.title} · ${device!.serial}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              if (device != null && !device!.ready)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: notice(message(device!.state, widget.english)),
                ),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: [
                  button(
                    t('设备信息', 'Device info'),
                    Icons.info_outline,
                    () async {
                      final result = await service.info(selected!);
                      if (mounted) setState(() => deviceInfo = result);
                    },
                    enabled: !busy && device?.ready == true,
                  ),
                  button(
                    t('安装 APK', 'Install APK'),
                    Icons.install_mobile,
                    install,
                    enabled: operable,
                  ),
                  button(
                    t('保存截图', 'Save screenshot'),
                    Icons.screenshot_monitor,
                    screenshot,
                    enabled: operable,
                  ),
                  button(
                    t('导出日志', 'Export logs'),
                    Icons.article_outlined,
                    exportLogs,
                    enabled: operable,
                  ),
                  button(
                    t('断开无线连接', 'Disconnect Wi-Fi'),
                    Icons.link_off,
                    () async {
                      await service.disconnect(selected!);
                      await refresh();
                      done(
                        '已断开所选无线连接。',
                        'Selected wireless connection disconnected.',
                      );
                    },
                    enabled: canDisconnect,
                  ),
                ],
              ),
              if (deviceInfo != null) ...[
                const SizedBox(height: 20),
                const Divider(),
                for (final entry in deviceInfo!.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: SelectableText(
                      '${infoLabel(entry.key)}: ${entry.value}',
                    ),
                  ),
              ],
            ],
          ),
          subtitle: widget.demo
              ? t(
                  '演示模式不会连接或修改真实设备。',
                  'Demo mode does not connect to or modify real devices.',
                )
              : t(
                  '所有操作仅针对当前选中的设备。',
                  'All operations target only the selected device.',
                ),
        ),
      ],
    ],
  );

  String infoLabel(String key) => switch (key) {
    'ro.product.manufacturer' => t('制造商', 'Manufacturer'),
    'ro.product.model' => t('型号', 'Model'),
    'ro.build.version.release' => 'Android',
    _ => 'SDK',
  };

  Widget metric(String label, int count, IconData icon) => SizedBox(
    width: 190,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$count',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );

  Widget deviceTile(AdbDevice value) {
    final scheme = Theme.of(context).colorScheme;
    final chosen = value.serial == selected;
    final status = value.ready
        ? t('已连接', 'Ready')
        : value.state == 'unauthorized'
        ? t('待授权', 'Authorize')
        : value.state == 'offline'
        ? t('离线', 'Offline')
        : value.state;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      selected: chosen,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: .35),
      leading: Icon(
        chosen ? Icons.radio_button_checked : Icons.radio_button_off,
        color: chosen ? scheme.primary : scheme.outline,
      ),
      title: Text(
        value.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(value.serial, overflow: TextOverflow.ellipsis),
      ),
      trailing: Chip(
        avatar: Icon(
          value.ready ? Icons.check_circle : Icons.error_outline,
          size: 16,
        ),
        label: Text(status),
      ),
      onTap: busy
          ? null
          : () => setState(() {
              selected = value.serial;
              deviceInfo = null;
            }),
    );
  }

  Widget wirelessPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading(
        t('无线连接', 'Connect over Wi-Fi'),
        t(
          '电脑和安卓设备需要在可互相访问的局域网中。',
          'Your computer and Android device must be reachable on the same local network.',
        ),
      ),
      panel(
        t('发现无线服务', 'Discover wireless services'),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t(
                '读取 ADB 已发现的配对和连接端口。发现结果不证明设备身份；请与手机屏幕核对。选择只填入地址，不会自动配对或连接。',
                'Read pairing and connection ports discovered by ADB. Discovery does not verify identity; compare with your phone. Selecting an entry only fills the address.',
              ),
            ),
            const SizedBox(height: 12),
            button(t('刷新发现列表', 'Refresh discovery'), Icons.radar, () async {
              setState(() {
                discovered = [];
                discoveryRun = false;
              });
              final found = await service.discoverWireless();
              if (mounted) {
                setState(() {
                  discovered = found;
                  discoveryRun = true;
                });
              }
            }),
            if (discoveryRun && discovered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  t(
                    '没有发现服务。检查手机无线调试、同网段与网络隔离；仍可手动填写下方地址。',
                    'No services found. Check wireless debugging and network isolation, or enter the address manually below.',
                  ),
                ),
              ),
            for (final entry in discovered)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  entry.pairing
                      ? t('配对端口', 'Pairing port')
                      : t('连接端口', 'Connection port'),
                ),
                subtitle: Text('${entry.name}\n${entry.endpoint}'),
                trailing: TextButton(
                  onPressed: busy || widget.demo
                      ? null
                      : () => setState(() {
                          if (entry.pairing) {
                            pairingTarget.text = entry.endpoint.toString();
                            pairingCode.clear();
                          } else {
                            target.text = entry.endpoint.toString();
                            report = null;
                          }
                        }),
                  child: Text(t('填入', 'Use address')),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      panel(
        t('01  配对设备', '01  Pair your device'),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t(
                'Android 11 及以上：开发者选项 → 无线调试 → 使用配对码配对设备。将弹窗中的地址、端口和配对码填在下方。',
                'Android 11+: Developer options > Wireless debugging > Pair device with pairing code. Enter the address, port and code shown in that dialog.',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: pairingTarget,
              enabled: !busy && !widget.demo,
              decoration: InputDecoration(
                labelText: t('配对地址与端口', 'Pairing address and port'),
                hintText: '192.168.1.20:40123',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pairingCode,
              enabled: !busy && !widget.demo,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: t('6 位配对码', 'Six-digit pairing code'),
              ),
            ),
            const SizedBox(height: 6),
            button(
              t('配对', 'Pair device'),
              Icons.phonelink_lock,
              () async {
                final endpoint = Endpoint.parse(pairingTarget.text);
                final code = pairingCode.text.trim();
                pairingCode.clear();
                await service.pair(endpoint, code);
                done(
                  '配对成功。请继续使用无线调试主页面的连接端口连接。',
                  'Paired. Continue with the connection port from the main Wireless debugging screen.',
                );
              },
              enabled: !widget.demo,
              primary: true,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      panel(
        t('02  建立连接', '02  Connect'),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t(
                '返回无线调试主页面，使用“IP 地址和端口”。它通常与配对端口不同，而且可能在重新开启无线调试后改变。',
                'Return to the main Wireless debugging screen and use “IP address & Port”. This usually differs from the pairing port and may change after restarting wireless debugging.',
              ),
            ),
            const SizedBox(height: 20),
            endpointField(),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                button(
                  t('连接设备', 'Connect device'),
                  Icons.wifi,
                  () async {
                    await service.connect(Endpoint.parse(target.text));
                    await refresh();
                    done(
                      'ADB 已确认连接。可前往设备页面查看状态。',
                      'ADB confirmed the connection. Check its state on the Devices page.',
                    );
                  },
                  enabled: !widget.demo,
                  primary: true,
                ),
                TextButton(
                  onPressed: () => navigate(2),
                  child: Text(
                    t('连接失败？运行诊断', 'Trouble connecting? Run diagnostics'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      notice(
        t(
          'Android 10 及更早版本：先通过 USB 连接并授权，手动执行 adb tcpip 5555，再使用设备局域网地址与 5555 端口连接。仅在可信网络启用，使用后关闭网络调试。应用不会自动修改设备的调试模式。',
          'Android 10 and earlier: connect and authorize over USB, manually run adb tcpip 5555, then connect to the device LAN address on port 5555. Enable this only on a trusted network and turn network debugging off afterward. This app does not change device debugging modes automatically.',
        ),
      ),
    ],
  );

  Widget endpointField() => TextField(
    controller: target,
    enabled: !busy,
    onChanged: (_) => setState(() => report = null),
    decoration: InputDecoration(
      labelText: t('连接地址与端口', 'Connection address and port'),
      hintText: '192.168.1.20:37121',
    ),
  );

  Widget diagnosticsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading(
        t('逐项检查，找到下一步', 'Find your next step'),
        t(
          '检查 ADB、设备状态和指定端口。不扫描局域网，也不会自动修改设备设置。',
          'Check ADB, device states and one target port. No LAN scanning or automatic device setting changes.',
        ),
      ),
      panel(
        t('连接检查', 'Connection checks'),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            endpointField(),
            const SizedBox(height: 10),
            Text(
              t(
                '地址可留空，仅检查本机 ADB 与设备列表。',
                'Leave blank to check only local ADB and the device list.',
              ),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                button(
                  t('开始诊断', 'Run diagnostics'),
                  Icons.fact_check_outlined,
                  diagnose,
                  primary: true,
                ),
                button(
                  t('导出报告', 'Export report'),
                  Icons.download_outlined,
                  exportReport,
                  enabled: report != null,
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      if (report == null)
        notice(
          t(
            '运行后将逐项显示检查结果与处理建议。报告不包含设备标识、目标地址、配对码或原始日志。',
            'Run diagnostics to see checks and next steps. Reports omit device identifiers, target addresses, pairing codes and raw logs.',
          ),
        )
      else
        panel(
          t('诊断结果', 'Diagnostic results'),
          Column(
            children: [
              for (final check in report!.checks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        switch (check.status) {
                          CheckStatus.pass => Icons.check_circle_outline,
                          CheckStatus.fail => Icons.cancel_outlined,
                          CheckStatus.warning => Icons.info_outline,
                          CheckStatus.skipped => Icons.remove_circle_outline,
                        },
                        color: check.status == CheckStatus.fail
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          message(check.code, widget.english),
                          style: const TextStyle(height: 1.6),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          subtitle:
              '${t('检查时间', 'Checked at')}: ${report!.createdAt.toLocal().toString().split('.').first}',
        ),
    ],
  );

  Widget settingsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading(
        t('设置', 'Settings'),
        t('配置本机工具和界面语言。', 'Configure local tools and the interface language.'),
      ),
      panel(
        t('ADB 工具位置', 'ADB executable'),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t(
                '已安装 Platform-Tools 并配置 PATH 时，保留 adb 即可。否则选择 adb.exe 的完整路径。',
                'Keep adb if Platform-Tools is installed and on PATH. Otherwise select the full path to adb.exe.',
              ),
            ),
            const SizedBox(height: 14),
            const SelectableText(
              'https://developer.android.com/tools/releases/platform-tools',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: path,
              enabled: !busy && !widget.demo,
              decoration: InputDecoration(
                labelText: t('可执行文件', 'Executable'),
                hintText: r'C:\platform-tools\adb.exe',
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                button(t('选择文件', 'Choose file'), Icons.folder_open, () async {
                  final file = await openFile(
                    acceptedTypeGroups: Platform.isWindows
                        ? const [
                            XTypeGroup(label: 'ADB', extensions: ['exe']),
                          ]
                        : const [],
                  );
                  if (file != null) path.text = file.path;
                }, enabled: !widget.demo),
                button(
                  t('验证并保存', 'Verify and save'),
                  Icons.check,
                  () async {
                    final value = path.text.trim();
                    if (value.isEmpty) {
                      throw const DeskException('adb_unavailable');
                    }
                    final candidate = AdbService(executable: value);
                    await candidate.version();
                    await Settings(
                      adbPath: value,
                      english: widget.english,
                    ).save();
                    service = candidate;
                    if (mounted) {
                      setState(() {
                        report = null;
                        discovered = [];
                        discoveryRun = false;
                      });
                    }
                    await refresh();
                    done('设置已保存，ADB 可用。', 'Settings saved. ADB is available.');
                  },
                  enabled: !widget.demo,
                  primary: true,
                ),
              ],
            ),
            if (adbVersion != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SelectableText(
                  adbVersion!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      panel(
        t('语言', 'Language'),
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('中文')),
              ButtonSegment(value: true, label: Text('English')),
            ],
            selected: {widget.english},
            onSelectionChanged: busy
                ? null
                : (values) {
                    unawaited(
                      perform(() async {
                        final english = values.first;
                        if (!widget.demo) {
                          final current = service is AdbService
                              ? (service as AdbService).executable
                              : widget.settings.adbPath;
                          await Settings(
                            adbPath: current,
                            english: english,
                          ).save();
                        }
                        widget.onLanguageChanged(english);
                      }),
                    );
                  },
          ),
        ),
      ),
      const SizedBox(height: 20),
      notice(
        t(
          '仅保存 ADB 路径与语言偏好。配对码不保存，诊断报告与设备日志由你选择是否导出。应用不包含遥测或云端上传。',
          'Only the ADB path and language preference are saved. Pairing codes are not stored. You choose when to export reports or logs. No telemetry or cloud uploads are included.',
        ),
      ),
    ],
  );
}
