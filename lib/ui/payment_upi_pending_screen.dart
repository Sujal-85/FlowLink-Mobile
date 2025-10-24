import 'dart:async';
import 'package:flutter/material.dart';

class UpiPendingScreen extends StatefulWidget {
  const UpiPendingScreen({super.key, required this.total, required this.itemsCount});
  final double total;
  final int itemsCount;

  @override
  State<UpiPendingScreen> createState() => _UpiPendingScreenState();
}

class _UpiPendingScreenState extends State<UpiPendingScreen> {
  static const int _totalSeconds = 5 * 60; // 5 mins
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _totalSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        t.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _mmss(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remainingSeconds / _totalSeconds;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PAYMENT DETAILS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2)),
            Text('${widget.itemsCount} items. Payable: ₹${widget.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                        strokeWidth: 10,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _mmss(_remainingSeconds),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        const Text('mins remaining', style: TextStyle(color: Colors.black54)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Open your UPI app to approve the payment request before the timer runs out',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(color: Colors.black54),
                  children: [
                    TextSpan(text: 'Note: ', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
                    TextSpan(text: 'Do not hit back button or close this screen until the transaction is complete'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("I've completed the payment"),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel payment', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
