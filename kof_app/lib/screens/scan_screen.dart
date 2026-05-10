import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../demo/demo_data.dart';
import '../demo/demo_mode.dart';
import '../utils/haptics.dart';
import '../l10n/l10n.dart';
import '../models/table_session.dart';
import '../providers/session_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'menu_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null) return;
    _processQr(rawValue);
  }

  Future<void> _processQr(String rawValue) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    _controller.stop();

    try {
      final uri = Uri.tryParse(rawValue);
      if (uri == null || !uri.hasScheme) {
        throw Exception(context.l10n.scanInvalidQr);
      }

      final tableLabel = uri.queryParameters['table'];
      final tableToken = uri.queryParameters['table_token'];

      if (tableLabel == null ||
          tableLabel.isEmpty ||
          tableToken == null ||
          tableToken.isEmpty) {
        throw Exception(context.l10n.scanNotKofQr);
      }

      final serverUrl = uri.hasPort
          ? '${uri.scheme}://${uri.host}:${uri.port}'
          : '${uri.scheme}://${uri.host}';

      final info = await ApiService(serverUrl).getInfo();

      if (!mounted) return;

      if (info['name'] != 'Kof') {
        throw Exception(context.l10n.scanWrongServer);
      }

      context.read<CartProvider>().clear();
      context.read<SessionProvider>().setSession(
            TableSession(
              serverUrl: serverUrl,
              tableLabel: tableLabel,
              tableToken: tableToken,
              shopName: info['shop_name'] as String? ?? context.l10n.appName,
            ),
          );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      _controller.start();
    }
  }

  void _startDemoSession({String tableLabel = '3'}) {
    context.read<CartProvider>().clear();
    context.read<SessionProvider>().setSession(
          TableSession(
            serverUrl: DemoData.kServerUrl,
            tableLabel: tableLabel,
            tableToken: 'demo-token',
            shopName: DemoData.shop1.name,
          ),
        );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MenuScreen()),
    );
  }

  Widget _buildDemoBody() {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.demoModeTitle)),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.qr_code_2,
                size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              l10n.demoScanHeading,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.demoScanSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () {
                Haptics.light();
                _startDemoSession(tableLabel: '3');
              },
              icon: const Icon(Icons.table_restaurant),
              label: Text('${DemoData.shop1.name} — ${l10n.tableLabel('3')}'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Haptics.light();
                _startDemoSession(tableLabel: '7');
              },
              icon: const Icon(Icons.table_restaurant),
              label: Text('${DemoData.shop1.name} — ${l10n.tableLabel('7')}'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDemoMode) return _buildDemoBody();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          _buildOverlay(context),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Text(
            l10n.scanTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              l10n.scanSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          Center(child: _buildScanFrame()),
          const Spacer(),
          Center(child: _buildStatusArea(context)),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildScanFrame() {
    const size = 240.0;
    const corner = 24.0;
    const strokeWidth = 4.0;
    const color = Colors.white;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _FramePainter(
                corner: corner, strokeWidth: strokeWidth, color: color),
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusArea(BuildContext context) {
    final l10n = context.l10n;

    if (_isProcessing) {
      return Text(
        l10n.scanConnecting,
        style: const TextStyle(color: Colors.white70),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _errorMessage = null),
              child: Text(l10n.scanTryAgain,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return TextButton(
      onPressed: () => _showManualEntryDialog(context),
      child: Text(
        l10n.scanEnterManually,
        style: const TextStyle(color: Colors.white54),
      ),
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    final l10n = context.l10n;
    final serverCtrl = TextEditingController(text: 'http://');
    final tableCtrl = TextEditingController();
    final tokenCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.scanManualDialogTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: serverCtrl,
                decoration: InputDecoration(
                  labelText: l10n.scanManualServerLabel,
                  hintText: l10n.scanManualServerHint,
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tableCtrl,
                decoration: InputDecoration(
                  labelText: l10n.scanManualTableLabel,
                  hintText: l10n.scanManualTableHint,
                ),
                autocorrect: false,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenCtrl,
                decoration: InputDecoration(
                  labelText: l10n.scanManualTokenLabel,
                  hintText: l10n.scanManualTokenHint,
                ),
                autocorrect: false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final server = serverCtrl.text.trim();
              final table = tableCtrl.text.trim();
              final token = tokenCtrl.text.trim();
              if (server.isEmpty || table.isEmpty || token.isEmpty) return;
              _processQr('$server/?table=$table&table_token=$token');
            },
            child: Text(l10n.scanConnect),
          ),
        ],
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  final double corner;
  final double strokeWidth;
  final Color color;

  const _FramePainter({
    required this.corner,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final c = corner;

    canvas.drawLine(Offset(0, c), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(c, 0), paint);
    canvas.drawLine(Offset(w - c, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, c), paint);
    canvas.drawLine(Offset(0, h - c), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(c, h), paint);
    canvas.drawLine(Offset(w - c, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h - c), Offset(w, h), paint);
  }

  @override
  bool shouldRepaint(_FramePainter old) => false;
}
