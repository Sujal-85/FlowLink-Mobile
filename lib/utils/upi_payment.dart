import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// UPI deep-link (intent) payment helper using url_launcher.
///
/// Usage:
// / await initiateUpiPayment(context,
// /   upiId: 'merchant@upi',
// /   name: 'FlowLink Store',
// /   amount: '129.50',
// / );

Future<void> initiateUpiPayment(
  BuildContext context, {
  required String upiId,
  required String name,
  required String amount,
  String note = 'FlowLink Payment',
}) async {
  // 1) Validate inputs and normalize
  final vpa = upiId.trim();
  final payeeName = name.trim();
  final parsedAmount = double.tryParse(amount.trim());

  if (vpa.isEmpty || payeeName.isEmpty || parsedAmount == null || parsedAmount <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter a valid name, UPI ID and amount')),
    );
    return;
  }

  // 2) Format amount to 2 decimals (recommended by UPI apps)
  final formattedAmount = parsedAmount.toStringAsFixed(2);

  // 3) Build a valid UPI deep link
  //    upi://pay?pa=<upi_id>&pn=<name>&am=<amount>&cu=INR&tn=<note>
  final uri = Uri(
    scheme: 'upi',
    host: 'pay',
    queryParameters: <String, String>{
      'pa': vpa,                 // Payee VPA
      'pn': payeeName,           // Payee (merchant) name
      'am': formattedAmount,     // Amount
      'cu': 'INR',               // Currency (Indian Rupee)
      'tn': note,                // Transaction note shown in UPI app
    },
  );

  // 4) Verify that a UPI-capable app is available
  final canOpen = await canLaunchUrl(uri);
  if (!canOpen) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No UPI app found on this device')),
    );
    return;
  }

  // 5) Launch the UPI intent (external application)
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start UPI payment')),
      );
    }
  } catch (_) {
    // 6) Fail-safe: if anything goes wrong, notify the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment initiation failed')),
    );
  }
}
