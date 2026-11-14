import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_controller.dart';
import 'domain.dart';

const ink = Color(0xFF173E35);
const green = Color(0xFF16846C);
const muted = Color(0xFF718079);
const canvas = Color(0xFFF5F7F3);
const line = Color(0xFFE5EBE5);
const lime = Color(0xFFDFF6B7);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BozkurtlarApp());
}

class BozkurtlarApp extends StatefulWidget {
  final AppController? controller;
  final bool initialize;
  const BozkurtlarApp({super.key, this.controller, this.initialize = true});
  @override
  State<BozkurtlarApp> createState() => _BozkurtlarAppState();
}

class _BozkurtlarAppState extends State<BozkurtlarApp> {
  late final AppController model = widget.controller ?? AppController();
  @override
  void initState() {
    super.initState();
    if (widget.initialize) {
      unawaited(
        model.initialize().then((_) {
          if (const bool.fromEnvironment('DEMO_START')) {
            return model.startDemo();
          }
        }),
      );
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Bozkurtlar · Su Takibi',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'BozkurtlarSans',
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        primary: green,
        surface: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink, fontSize: 14),
        bodyLarge: TextStyle(color: ink),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w700),
      ),
      dividerColor: line,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: canvas,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ),
    home: Home(model: model),
  );
}

class Home extends StatefulWidget {
  final AppController model;
  const Home({super.key, required this.model});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;
  AppController get m => widget.model;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: m,
    builder: (context, _) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _header(),
              if (m.demo)
                Container(
                  width: double.infinity,
                  color: const Color(0xFFFFF0D5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.science_outlined,
                        size: 16,
                        color: Color(0xFF9C6516),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'DEMO MODU · Tüm değerler örnektir.',
                          style: TextStyle(
                            color: Color(0xFF8A5C1E),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: m.stopDemo,
                        child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Text(
                            'Çık',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (m.message != null)
                Container(
                  color: const Color(0xFFEAF2EE),
                  padding: const EdgeInsets.only(left: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.message!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      IconButton(
                        onPressed: m.dismissMessage,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: switch (tab) {
                  0 => _dashboard(),
                  1 => HistoryPage(model: m),
                  2 => ResearchPage(model: m),
                  _ => SettingsPage(
                    model: m,
                    onConnect: () => _connectSheet(context),
                  ),
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: _navigation(),
      );
    },
  );

  Widget _header() => Container(
    color: canvas,
    padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: line),
              ),
              child: Image.asset('assets/bozkurtlar-logo.png'),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOZKURTLAR',
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 2.3,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'DENEYAP · YEŞİL DÖNÜŞÜM',
                    style: TextStyle(
                      fontSize: 8.5,
                      letterSpacing: 1.4,
                      color: muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Sistem uyarıları',
              onPressed: _alerts,
              icon: Badge(
                isLabelVisible:
                    m.latest?.telemetry.critical == true && !m.stale,
                smallSize: 7,
                child: const Icon(Icons.notifications_none_rounded, color: ink),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _navigation() {
    const items = [
      (Icons.dashboard_outlined, 'İzleme'),
      (Icons.bar_chart_rounded, 'Kayıtlar'),
      (Icons.auto_stories_outlined, 'Bilim'),
      (Icons.tune_rounded, 'Ayarlar'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: line)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Row(
                children: List.generate(
                  4,
                  (i) => Expanded(
                    child: Semantics(
                      selected: tab == i,
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => tab = i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 54,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: tab == i ? lime : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  items[i].$1,
                                  color: tab == i ? ink : muted,
                                  size: 23,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                items[i].$2,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: tab == i
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: tab == i ? ink : muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dashboard() {
    final t = m.latest?.telemetry;
    final s = m.effectiveSettings;
    final percent = t == null ? null : s.percent(t.raw);
    final liters = t == null ? null : s.liters(t.onMs);
    final current = m.demo || (m.connected && !m.stale);
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 26),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Her damlanın bir geleceği var.',
                            style: TextStyle(fontSize: 11, color: muted),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Suya yön ver.',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: lime,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.eco_outlined,
                        color: ink,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: line),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: current ? green : muted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m.demo
                              ? 'Simülasyon cihazı'
                              : m.connected
                              ? (m.stale
                                    ? 'Veri güncel değil'
                                    : 'Deneyap Kart 1A bağlı')
                              : m.connecting
                              ? 'Bağlanıyor…'
                              : 'Deneyap Kart 1A · Bağlı değil',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _connectSheet(context),
                        child: Row(
                          children: [
                            Icon(
                              m.connected
                                  ? Icons.bluetooth_connected
                                  : Icons.bluetooth,
                              size: 17,
                              color: green,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              m.connected ? 'Cihaz' : 'Bağlan',
                              style: const TextStyle(
                                fontSize: 11,
                                color: green,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final level = _levelCard(t, percent, current);
                    final metrics = Column(
                      children: [
                        _volumeCard(liters),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _metric(
                                Icons.timer_outlined,
                                'Pompa komutu',
                                t == null ? '—' : durationText(t.onMs),
                                'Açık kaldığı süre',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _metric(
                                Icons.repeat_rounded,
                                'Başlatma',
                                t == null ? '—' : '${t.starts}',
                                'Açma komutu sayısı',
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                    if (constraints.maxWidth > 720) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: level),
                          const SizedBox(width: 16),
                          Expanded(child: metrics),
                        ],
                      );
                    }
                    return Column(
                      children: [level, const SizedBox(height: 14), metrics],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Seviyenin yolculuğu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => tab = 1),
                      child: const Text(
                        'Kayıtlara git →',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'HAM SENSÖR DEĞERİ',
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 1,
                                color: muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            m.samples.isEmpty
                                ? 'Veri bekleniyor'
                                : 'Son ${math.min(m.samples.length, 120)} kayıt',
                            style: const TextStyle(fontSize: 10, color: muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 135,
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: LevelChart(
                            m.samples.length > 120
                                ? m.samples.sublist(m.samples.length - 120)
                                : m.samples,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            m.samples.isEmpty
                                ? '—'
                                : clockText(
                                    m.samples.length > 120
                                        ? m
                                              .samples[m.samples.length - 120]
                                              .receivedAt
                                        : m.samples.first.receivedAt,
                                  ),
                            style: const TextStyle(fontSize: 10, color: muted),
                          ),
                          Row(
                            children: [
                              Container(width: 14, height: 2, color: green),
                              const SizedBox(width: 5),
                              const Text(
                                'Ölçüm',
                                style: TextStyle(fontSize: 9, color: muted),
                              ),
                              const SizedBox(width: 14),
                              Container(
                                width: 14,
                                height: 2,
                                color: const Color(0xFFE8AE65),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Açma eşiği',
                                style: TextStyle(fontSize: 9, color: muted),
                              ),
                            ],
                          ),
                          Text(
                            m.samples.isEmpty
                                ? '—'
                                : clockText(m.samples.last.receivedAt),
                            style: const TextStyle(fontSize: 10, color: muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => setState(() => tab = 2),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF0E5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.menu_book_outlined, color: green, size: 26),
                        SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bilimin izinde, doğanın yanında.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ağaç gelişimi ve suyun yeniden kullanımı',
                                style: TextStyle(fontSize: 10, color: muted),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: green,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!m.demo && !m.connected)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: m.startDemo,
                        icon: const Icon(Icons.play_circle_outline, size: 18),
                        label: const Text('Demo ile keşfet'),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                const Text(
                  'Bu kart oturumundaki sayaçlar gösterilir. Pompa komutu, fiziksel çalışma doğrulaması değildir.',
                  style: TextStyle(fontSize: 10, height: 1.5, color: muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _levelCard(Telemetry? t, double? percent, bool current) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF194B40), Color(0xFF0F322B)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.water_drop_outlined,
              color: Color(0xFFD2E5D9),
              size: 18,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'SU SEVİYESİ',
                style: TextStyle(
                  color: Color(0xFFD2E5D9),
                  fontSize: 10,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            StatusChip(
              text: !current
                  ? 'Veri bekleniyor'
                  : t?.critical == true
                  ? 'Yüksek seviye'
                  : 'Normal',
              color: !current
                  ? const Color(0xFFB8C8C0)
                  : t?.critical == true
                  ? const Color(0xFFF3D38A)
                  : lime,
              dark: true,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t == null
                        ? '—'
                        : percent != null
                        ? '${percent.round()}%'
                        : '${t.raw}',
                    style: const TextStyle(
                      fontSize: 58,
                      letterSpacing: -2.5,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    percent == null
                        ? 'Ham sensör değeri'
                        : 'Kalibre edilmiş seviye',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFB5CCC0),
                    ),
                  ),
                  if (percent != null && t != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        'Sensör: ${t.raw}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFB5CCC0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 91,
              height: 102,
              child: CustomPaint(
                painter: WaterTank(percent == null ? null : percent / 100),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Container(height: 1, color: Colors.white.withValues(alpha: .12)),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(
              Icons.settings_input_component_outlined,
              size: 15,
              color: Color(0xFFB5CCC0),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                t == null
                    ? 'Pompa komutu bekleniyor'
                    : !current
                    ? 'Son komut · Güncel değil'
                    : !t.armed
                    ? 'Pompa denetimi kilitli'
                    : 'Pompa komutu: ${t.pump ? 'AÇIK' : 'KAPALI'}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              m.latest == null ? '—' : clockText(m.latest!.receivedAt),
              style: const TextStyle(fontSize: 10, color: Color(0xFFB5CCC0)),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _volumeCard(double? liters) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.water_outlined, color: green, size: 21),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Tahmini su aktarımı',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            StatusChip(text: m.demo ? 'DEMO TAHMİNİ' : 'TAHMİN', color: green),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              liters == null
                  ? '—'
                  : liters.toStringAsFixed(1).replaceAll('.', ','),
              style: const TextStyle(
                fontSize: 37,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(width: 6),
            const Text('litre', style: TextStyle(fontSize: 14, color: muted)),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          liters == null
              ? 'Litre hesabı için pompa aktarım hızını ayarlayın.'
              : '${m.demo ? 'Örnek' : 'Girilen'} aktarım hızı × açık komutu süresi',
          style: const TextStyle(fontSize: 10, color: muted, height: 1.4),
        ),
      ],
    ),
  );

  Widget _metric(IconData icon, String label, String value, String hint) =>
      Surface(
        padding: 15,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: green, size: 20),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 10, color: muted)),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(hint, style: const TextStyle(fontSize: 9, color: muted)),
          ],
        ),
      );

  Future<void> _connectSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AnimatedBuilder(
        animation: m,
        builder: (context, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deneyap Kart’a bağlan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kartın Bozkurtlar yazılımını çalıştırdığından ve Bluetooth’un açık olduğundan emin olun.',
                  style: TextStyle(color: muted, height: 1.5, fontSize: 13),
                ),
                const SizedBox(height: 18),
                if (m.connected)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.bluetooth_connected,
                      color: green,
                    ),
                    title: const Text('Deneyap Kart 1A bağlı'),
                    trailing: TextButton(
                      onPressed: m.disconnect,
                      child: const Text('Bağlantıyı kes'),
                    ),
                  ),
                if (m.message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      m.message!,
                      style: const TextStyle(
                        color: Color(0xFFAC642F),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ...m.devices.values.map(
                  (device) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.developer_board, color: green),
                    title: Text(
                      device.name.isEmpty
                          ? 'Bozkurtlar BLE cihazı'
                          : device.name,
                    ),
                    subtitle: Text(
                      device.id,
                      style: const TextStyle(fontSize: 10),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: m.connecting ? null : () => m.connect(device),
                  ),
                ),
                if (m.scanning)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Yakındaki kartlar aranıyor…'),
                      ],
                    ),
                  ),
                if (!m.scanning && m.devices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Henüz cihaz listelenmedi. Tarama 12 saniye sürer.',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: m.scanning || m.connecting ? null : m.scan,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: Text(
                      m.connecting ? 'Bağlanıyor…' : 'Cihazları tara',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      unawaited(m.startDemo());
                    },
                    child: const Text('Cihaz olmadan demo ile keşfet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await m.link.stopScan();
    m.scanning = false;
  }

  void _alerts() {
    final t = m.latest?.telemetry;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sistem uyarıları',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              if (m.demo)
                const ListTile(
                  leading: Icon(Icons.science_outlined),
                  title: Text('Demo verisi görüntüleniyor'),
                  subtitle: Text('Gerçek sensör veya ağaç ölçümü değildir.'),
                ),
              if (m.stale && !m.demo)
                const ListTile(
                  leading: Icon(Icons.bluetooth_disabled, color: muted),
                  title: Text('Güncel ölçüm yok'),
                  subtitle: Text(
                    'Kart bağlantısını ve son ölçüm zamanını kontrol edin.',
                  ),
                ),
              if (t?.critical == true && !m.stale)
                const ListTile(
                  leading: Icon(
                    Icons.water_damage_outlined,
                    color: Colors.orange,
                  ),
                  title: Text('Su seviyesi eşiğin üzerinde'),
                  subtitle: Text(
                    'Bu uyarı su kalitesi veya taşma doğrulaması değildir.',
                  ),
                ),
              if (t != null && !t.armed)
                const ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Pompa denetimi kilitli'),
                  subtitle: Text(
                    'Kart yazılımındaki devre ayarlarını doğrulayın.',
                  ),
                ),
              if (m.decoder.rejected > 0)
                ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: Text(
                    '${m.decoder.rejected} geçersiz veri paketi atlandı',
                  ),
                ),
              const SizedBox(height: 10),
              const Text(
                'Uyarılar uygulama açıkken görüntülenir. Arka plan ve uzaktan alarm hizmeti bu sürümde bulunmaz.',
                style: TextStyle(fontSize: 11, color: muted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Surface extends StatelessWidget {
  final Widget child;
  final double padding;
  const Surface({super.key, required this.child, this.padding = 20});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: line),
      ),
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    ),
  );
}

class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  final bool dark;
  const StatusChip({
    super.key,
    required this.text,
    required this.color,
    this.dark = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: dark ? .13 : .08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 8.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

String clockText(DateTime at) =>
    '${at.toLocal().hour.toString().padLeft(2, '0')}:${at.toLocal().minute.toString().padLeft(2, '0')}';

class WaterTank extends CustomPainter {
  final double? fill;
  WaterTank(this.fill);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 2, size.width - 16, size.height - 5),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = Colors.white.withValues(alpha: .07),
    );
    canvas.save();
    canvas.clipRRect(rect);
    if (fill != null) {
      final y = 5 + (size.height - 10) * (1 - fill!);
      final path = Path()
        ..moveTo(8, y)
        ..cubicTo(
          size.width * .35,
          y - 10,
          size.width * .65,
          y + 10,
          size.width - 8,
          y,
        )
        ..lineTo(size.width - 8, size.height)
        ..lineTo(8, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFBEE997), Color(0xFF62B7A1)],
          ).createShader(Offset.zero & size),
      );
    }
    canvas.restore();
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: .35),
    );
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(
        Offset(size.width - 20, y),
        Offset(size.width - 13, y),
        Paint()
          ..color = Colors.white.withValues(alpha: .4)
          ..strokeWidth = 1.3,
      );
    }
    if (fill == null) {
      final text = TextPainter(
        text: const TextSpan(
          text: '?',
          style: TextStyle(color: Colors.white54, fontSize: 30),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset((size.width - text.width) / 2, 30));
    }
  }

  @override
  bool shouldRepaint(WaterTank oldDelegate) => fill != oldDelegate.fill;
}

class LevelChart extends CustomPainter {
  final List<Sample> samples;
  LevelChart(this.samples);
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;
    for (int i = 0; i < 4; i++) {
      final y = i * size.height / 3;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = line
          ..strokeWidth = 1,
      );
    }
    if (samples.isEmpty) {
      final text = TextPainter(
        text: const TextSpan(
          text: 'Grafik için kartı bağlayın veya demoyu başlatın.',
          style: TextStyle(color: muted, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width - 10);
      text.paint(
        canvas,
        Offset((size.width - text.width) / 2, (size.height - text.height) / 2),
      );
      return;
    }
    final threshold = samples.last.telemetry.thresholdOn;
    final minimum = math
        .max(
          0,
          math.min(
                samples.map((s) => s.telemetry.raw).reduce(math.min),
                threshold,
              ) -
              100,
        )
        .toDouble();
    final maximum =
        math.max(
          samples.map((s) => s.telemetry.raw).reduce(math.max),
          threshold,
        ) +
        100.0;
    final start = samples.first.receivedAt.millisecondsSinceEpoch;
    final span = math.max(
      1,
      samples.last.receivedAt.millisecondsSinceEpoch - start,
    );
    double y(double value) =>
        size.height - (value - minimum) / (maximum - minimum) * size.height;
    final thresholdPaint = Paint()
      ..color = const Color(0xFFE8AE65)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 9) {
      canvas.drawLine(
        Offset(x, y(threshold.toDouble())),
        Offset(math.min(x + 4, size.width), y(threshold.toDouble())),
        thresholdPaint,
      );
    }
    final path = Path();
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      final point = Offset(
        (s.receivedAt.millisecondsSinceEpoch - start) / span * size.width,
        y(s.telemetry.raw.toDouble()),
      );
      final gap =
          i > 0 &&
          (s.receivedAt.difference(samples[i - 1].receivedAt).inSeconds > 20 ||
              s.deviceId != samples[i - 1].deviceId ||
              s.telemetry.boot != samples[i - 1].telemetry.boot);
      if (i == 0 || gap) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
      if (i == samples.length - 1) {
        canvas.drawCircle(
          point,
          5.5,
          Paint()..color = green.withValues(alpha: .12),
        );
        canvas.drawCircle(point, 2.6, Paint()..color = green);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = green
        ..strokeWidth = 2.3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(LevelChart oldDelegate) => true;
}

class HistoryPage extends StatefulWidget {
  final AppController model;
  const HistoryPage({super.key, required this.model});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int range = 1;
  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final cutoff = DateTime.now().subtract(
      Duration(minutes: range == 0 ? 15 : 60),
    );
    final rows = m.samples
        .where((s) => range == 2 || s.receivedAt.isAfter(cutoff))
        .toList();
    final raw = rows.map((s) => s.telemetry.raw).toList();
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageIntro(
                  eyebrow: 'VERİNİN İZİ',
                  title: 'Her ölçüm bir kayıt.',
                  subtitle:
                      'Zaman içindeki değişimi görün, kayıtlarınızı paylaşın.',
                ),
                const SizedBox(height: 22),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('15 dk')),
                    ButtonSegment(value: 1, label: Text('1 saat')),
                    ButtonSegment(value: 2, label: Text('Son kayıtlar')),
                  ],
                  selected: {range},
                  onSelectionChanged: (v) => setState(() => range = v.first),
                ),
                const SizedBox(height: 18),
                Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${rows.length} ölçüm · ${m.demo ? 'Demo' : 'Gerçek kayıt'}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 180,
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: LevelChart(rows),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 22,
                        runSpacing: 12,
                        children: [
                          for (final stat in [
                            (
                              'En düşük',
                              raw.isEmpty ? '—' : '${raw.reduce(math.min)}',
                            ),
                            (
                              'Ortalama',
                              raw.isEmpty
                                  ? '—'
                                  : '${(raw.reduce((a, b) => a + b) / raw.length).round()}',
                            ),
                            (
                              'En yüksek',
                              raw.isEmpty ? '—' : '${raw.reduce(math.max)}',
                            ),
                          ])
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stat.$1,
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  stat.$2,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      const Text(
                        'Değerler ham sensör birimindedir. Uzun bağlantı boşluklarında grafik çizgisi kesilir.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 10,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: m.exportCsv,
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: const Text('CSV paylaş'),
                    ),
                    if (!m.demo)
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ArchivePage(model: m),
                          ),
                        ),
                        icon: const Icon(Icons.inventory_2_outlined, size: 18),
                        label: const Text('Tüm geçmiş'),
                      ),
                    OutlinedButton.icon(
                      onPressed: m.syncing ? null : m.sync,
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: Text(m.syncing ? 'Eşitleniyor…' : 'Arşive eşitle'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  m.demo
                      ? 'Demo CSV’si ayrı etiketlenir; sunucuya gönderilmez.'
                      : 'CSV tüm yerel ölçümleri içerir. Telefonda ${m.storedCount} kayıt var; grafikte en fazla son 3.000 kayıt açılır.',
                  style: const TextStyle(
                    fontSize: 10,
                    color: muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Son ölçümler',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  const Surface(
                    child: Text(
                      'Henüz kayıt yok. İzleme ekranından kartı bağlayın veya demoyu başlatın.',
                      style: TextStyle(color: muted, height: 1.5),
                    ),
                  ),
                ...rows.reversed
                    .take(30)
                    .map(
                      (s) => Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              s.telemetry.pump
                                  ? Icons.water_drop
                                  : Icons.water_drop_outlined,
                              color: green,
                              size: 19,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sensör: ${s.telemetry.raw}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Pompa komutu ${s.telemetry.pump ? 'açık' : 'kapalı'} · ${s.source == 'demo' ? 'Demo' : 'Ölçüm'}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${clockText(s.receivedAt)}:${s.receivedAt.second.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ArchivePage extends StatefulWidget {
  final AppController model;
  const ArchivePage({super.key, required this.model});
  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  final snapshotAt = DateTime.now();
  int page = 0;
  late Future<List<Sample>> rows = _load();
  Future<List<Sample>> _load() => widget.model.store.history(
    limit: 100,
    offset: page * 100,
    until: snapshotAt,
  );
  void _go(int next) => setState(() {
    page = next;
    rows = _load();
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Cihazdaki tüm geçmiş',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    ),
    body: FutureBuilder<List<Sample>>(
      future: rows,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Arşiv okunamadı. Geri dönüp tekrar deneyin.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final samples = snapshot.data!.reversed.toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Gerçek ölçümler · Sayfa ${page + 1}\nEkran açılana kadar kaydedilmiş veriler. Her sayfada en fazla 100 kayıt.',
                style: const TextStyle(color: muted, fontSize: 11, height: 1.6),
              ),
            ),
            Expanded(
              child: samples.isEmpty
                  ? const Center(child: Text('Bu sayfada kayıt yok.'))
                  : ListView.separated(
                      itemCount: samples.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final s = samples[index];
                        final at = s.receivedAt.toLocal();
                        return Material(
                          color: Colors.white,
                          child: ListTile(
                            leading: const Icon(
                              Icons.water_drop_outlined,
                              color: green,
                            ),
                            title: Text(
                              '${s.telemetry.raw} · Pompa komutu ${s.telemetry.pump ? 'açık' : 'kapalı'}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${at.day}.${at.month}.${at.year} ${clockText(at)}:${at.second.toString().padLeft(2, '0')}\nKart oturumu: ${s.telemetry.boot}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: muted,
                              ),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: page == 0 ? null : () => _go(page - 1),
                      child: const Text('Daha yeni'),
                    ),
                    OutlinedButton(
                      onPressed: samples.length < 100
                          ? null
                          : () => _go(page + 1),
                      child: const Text('Daha eski'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class PageIntro extends StatelessWidget {
  final String eyebrow, title, subtitle;
  const PageIntro({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          fontSize: 9,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w800,
          color: green,
        ),
      ),
      const SizedBox(height: 9),
      Text(
        title,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: ink,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: muted, height: 1.6),
      ),
    ],
  );
}

class ResearchPage extends StatelessWidget {
  final AppController model;
  const ResearchPage({super.key, required this.model});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageIntro(
                eyebrow: 'BİLİMSEL DAYANAK',
                title: 'Bilgiyle kök sal.',
                subtitle:
                    'Su kullanımının ağaçlara etkisini yayınlanmış araştırmalardan inceleyin.',
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEDF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: green, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bu bölümdeki değerler bilimsel yayınlara aittir. Kendi ağaçlarımızın büyümesini ölçmez veya aktarılan litreden büyüme yüzdesi hesaplamaz.',
                        style: TextStyle(fontSize: 12, height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...model.research.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Surface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StatusChip(text: 'YAYIN VERİSİ', color: green),
                            const Spacer(),
                            Text(
                              '${r['year']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          r['headline'] as String,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          r['stat'] as String,
                          style: TextStyle(
                            color: r['kind'] == 'risk'
                                ? const Color(0xFFB8783C)
                                : green,
                            fontWeight: FontWeight.w800,
                            fontSize: 38,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          r['metric'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: muted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          r['species'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          r['summary'] as String,
                          style: const TextStyle(fontSize: 12, height: 1.7),
                        ),
                        const SizedBox(height: 14),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 12),
                          dense: true,
                          title: const Text(
                            'Araştırmanın sınırları',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          children: [
                            Text(
                              r['limits'] as String,
                              style: const TextStyle(
                                color: muted,
                                height: 1.6,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 6),
                        Text(
                          r['authors'] as String,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          r['title'] as String,
                          style: const TextStyle(
                            fontSize: 10,
                            color: muted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 9),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(r['url'] as String);
                            try {
                              if (!await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  ) &&
                                  context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Kaynak açılamadı. DOI bağlantısını kopyalayabilirsiniz.',
                                    ),
                                  ),
                                );
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Tarayıcı açılamadı. DOI bağlantısını kopyalayın.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.open_in_new, size: 15),
                          label: const Text(
                            'Bilimsel yayını aç',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: r['url'] as String),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('DOI bağlantısı kopyalandı.'),
                              ),
                            );
                          },
                          child: Text(
                            'DOI: ${r['doi']}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Surface(
                child: Text(
                  'Yeniden kullanım değerlendirmesi, sulamaya uygunluğu doğrulanmış arıtılmış su senaryosu içindir. Bu prototip su kalitesini veya arıtma yeterliliğini ölçmez. Fiziksel gösterim temiz suyla yapılmalıdır.',
                  style: TextStyle(fontSize: 11, color: muted, height: 1.7),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ],
  );
}

class SettingsPage extends StatefulWidget {
  final AppController model;
  final VoidCallback onConnect;
  const SettingsPage({super.key, required this.model, required this.onConnect});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final form = GlobalKey<FormState>();
  late final dry = TextEditingController(
    text: widget.model.settings.dryRaw?.toString() ?? '',
  );
  late final wet = TextEditingController(
    text: widget.model.settings.wetRaw?.toString() ?? '',
  );
  late final flow = TextEditingController(
    text: widget.model.settings.litersPerMinute?.toString() ?? '',
  );
  late final url = TextEditingController(text: widget.model.settings.apiUrl);
  late final token = TextEditingController(
    text: widget.model.settings.apiToken,
  );
  bool saving = false;
  @override
  void dispose() {
    dry.dispose();
    wet.dispose();
    flow.dispose();
    url.dispose();
    token.dispose();
    super.dispose();
  }

  String? rawValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = int.tryParse(value.trim());
    return n == null || n < 0 || n > 4095
        ? '0–4095 arasında tam sayı girin.'
        : null;
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageIntro(
                  eyebrow: 'SİSTEM AYARLARI',
                  title: 'Doğru veri, doğru başlangıç.',
                  subtitle:
                      'Ölçüm ve tahminlerin hangi bilgilere dayandığını belirleyin.',
                ),
                const SizedBox(height: 20),
                Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Deneyap Kart 1A',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Dahili Bluetooth Low Energy · Yakın mesafede takip',
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: widget.onConnect,
                        icon: const Icon(Icons.bluetooth, size: 18),
                        label: const Text('Bluetooth cihazları'),
                      ),
                      const SizedBox(height: 7),
                      TextButton.icon(
                        onPressed: widget.model.demo
                            ? widget.model.stopDemo
                            : widget.model.startDemo,
                        icon: const Icon(Icons.science_outlined, size: 18),
                        label: Text(
                          widget.model.demo
                              ? 'Demodan çık'
                              : 'Demo modunu başlat',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seviye kalibrasyonu',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Boş ve dolu seviyede okunan sensör değerlerini girin. Gösterge bu iki noktaya göre yaklaşık yüzde üretir; tank hacmi yüzdesi değildir.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: dry,
                        keyboardType: TextInputType.number,
                        validator: rawValidator,
                        decoration: const InputDecoration(
                          labelText: 'Boş seviyedeki ham değer',
                          hintText: 'Ölçtüğünüz değeri girin',
                        ),
                      ),
                      const SizedBox(height: 13),
                      TextFormField(
                        controller: wet,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final error = rawValidator(v);
                          if (error != null) return error;
                          if (dry.text.trim().isEmpty !=
                              (v?.trim().isEmpty ?? true)) {
                            return 'Boş ve dolu değerlerini birlikte girin.';
                          }
                          if (v != null &&
                              v.trim().isNotEmpty &&
                              int.tryParse(v) == int.tryParse(dry.text)) {
                            return 'Boş ve dolu değerleri farklı olmalı.';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Dolu seviyedeki ham değer',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pompa aktarım hızı',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Gerçek hortum ve yükseklik düzeninde 1 dakika boyunca çıkan suyu ölçülü kapta toplayın. Bulduğunuz litreyi girin. Ek elektronik sensör gerekmez.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: flow,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final n = double.tryParse(v.replaceAll(',', '.'));
                          return n == null ||
                                  !n.isFinite ||
                                  n <= 0 ||
                                  n > 100000
                              ? 'Geçerli bir pozitif aktarım hızı girin.'
                              : null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Aktarım hızı',
                          suffixText: 'L/dk',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tahmini litre = açık komutu süresi (dk) × aktarım hızı. Ayarı değiştirirseniz oturum tahmini yeniden hesaplanır.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 10,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'İsteğe bağlı sunucu arşivi',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bluetooth takibi sunucu gerektirmez. Gerçek kayıtlar yalnızca “Arşive eşitle” düğmesine bastığınızda belirttiğiniz sunucuya gönderilir.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: url,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Sunucu adresi',
                          hintText: 'https://sunucunuz.example',
                        ),
                      ),
                      const SizedBox(height: 13),
                      TextFormField(
                        controller: token,
                        obscureText: true,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Erişim anahtarı · Bu oturum için',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Erişim anahtarı diske kaydedilmez. Uygulamayı kapattıktan sonra yeniden girmeniz gerekir.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 10,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!form.currentState!.validate()) return;
                            setState(() => saving = true);
                            try {
                              await widget.model.saveSettings(
                                AppSettings(
                                  dryRaw: int.tryParse(dry.text.trim()),
                                  wetRaw: int.tryParse(wet.text.trim()),
                                  litersPerMinute: double.tryParse(
                                    flow.text.trim().replaceAll(',', '.'),
                                  ),
                                  apiUrl: url.text.trim(),
                                  apiToken: token.text.trim(),
                                ),
                              );
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ayarlar kaydedilemedi. Tekrar deneyin.',
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => saving = false);
                            }
                          },
                    icon: const Icon(Icons.check_rounded),
                    label: Text(saving ? 'Kaydediliyor…' : 'Ayarları kaydet'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bu ayarlar telefonun göstergelerini düzenler. Pompa eşikleri ve röle yönü kart yazılımında belirlenir. Sayaçlar kart yeniden başladığında sıfırlanır; önceki kayıtlar telefonda kalır.',
                  style: TextStyle(color: muted, fontSize: 11, height: 1.7),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'BOZKURTLAR  /  DENEYAP\nSU TAKİBİ · v1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.4,
                      height: 1.9,
                      color: muted,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
