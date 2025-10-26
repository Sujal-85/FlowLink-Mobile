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

/// Detect if common UPI apps are installed on the device.
/// Returns a map of app code -> available flag.
/// Supported app codes: 'gpay', 'phonepe', 'paytm'.
Future<Map<String, bool>> detectInstalledUpiApps() async {
  Future<bool> can(Uri u) async {
    try {
      return await canLaunchUrl(u);
    } catch (_) {
      return false;
    }
  }

  // Some apps support multiple schemes; check a couple for better reliability
  final gpay = await can(Uri.parse('tez://upi/pay')) || await can(Uri.parse('gpay://upi/pay'));
  final phonepe = await can(Uri.parse('phonepe://upi/pay'));
  final paytm = await can(Uri.parse('paytmmp://pay')) || await can(Uri.parse('paytm://upi/pay'));

  return <String, bool>{
    'gpay': gpay,
    'phonepe': phonepe,
    'paytm': paytm,
  };
}

/// Prefer launching a specific UPI app when possible; falls back to generic UPI deep link.
Future<void> initiateUpiPaymentViaApp(
  BuildContext context, {
  required String upiId,
  required String name,
  required String amount,
  required String app, // 'gpay' | 'phonepe' | 'paytm'
  String note = 'FlowLink Payment',
}) async {
  // Build the common query string
  final vpa = upiId.trim();
  final payeeName = name.trim();
  final parsedAmount = double.tryParse(amount.trim());
  if (vpa.isEmpty || payeeName.isEmpty || parsedAmount == null || parsedAmount <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter a valid name, UPI ID and amount')),
    );
    return;
  }
  final formattedAmount = parsedAmount.toStringAsFixed(2);

  String query(Map<String, String> qp) => Uri(queryParameters: qp).query;
  final qp = {
    'pa': vpa,
    'pn': payeeName,
    'am': formattedAmount,
    'cu': 'INR',
    'tn': note,
  };

  // Candidate URIs for each app
  final candidates = <Uri>[];
  switch (app) {
    case 'gpay':
      candidates.add(Uri.parse('tez://upi/pay?${query(qp)}'));
      candidates.add(Uri.parse('gpay://upi/pay?${query(qp)}'));
      break;
    case 'phonepe':
      candidates.add(Uri.parse('phonepe://upi/pay?${query(qp)}'));
      break;
    case 'paytm':
      // Paytm supports both a generic UPI endpoint and its own scheme
      candidates.add(Uri.parse('paytm://upi/pay?${query(qp)}'));
      candidates.add(Uri.parse('paytmmp://pay?${query(qp)}'));
      break;
    default:
      break;
  }

  // Try candidates first
  for (final uri in candidates) {
    try {
      if (await canLaunchUrl(uri)) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
    } catch (_) {
      // continue to next or fallback
    }
  }

  // Fallback to generic UPI intent (chooser)
  await initiateUpiPayment(context, upiId: upiId, name: name, amount: amount, note: note);
}
