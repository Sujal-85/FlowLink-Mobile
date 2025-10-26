import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flowlink_mobile/services/orders_service.dart';
import 'package:flowlink_mobile/services/address_service.dart';

class InvoiceService {
  static Future<Uint8List> generateForOrder(OrderItem order, Address? address) async {
    final doc = pw.Document();

    final titleStyle = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
    final bold = pw.TextStyle(fontWeight: pw.FontWeight.bold);
    final small = pw.TextStyle(fontSize: 10, color: PdfColors.grey700);

    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24)),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('FlowLink', style: titleStyle),
                pw.SizedBox(height: 4),
                pw.Text('Invoice', style: pw.TextStyle(fontSize: 14, color: PdfColors.green800, fontWeight: pw.FontWeight.bold)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Invoice #: ${order.id}', style: bold),
                pw.SizedBox(height: 2),
                pw.Text('Date: $dateStr', style: small),
              ])
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Container(height: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 16),

          // Bill To / Ship To
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Bill To', style: bold),
                  pw.SizedBox(height: 4),
                  if (address != null) ...[
                    pw.Text(address.name),
                    if ((address.mobile).isNotEmpty) pw.Text('Phone: ${address.mobile}', style: small),
                    if ((address.addressLine ?? '').isNotEmpty) pw.Text(address.addressLine!),
                    if ((address.addressLine2 ?? '').isNotEmpty) pw.Text(address.addressLine2!),
                    pw.Text('${address.city}, ${address.state} - ${address.pincode}'),
                  ] else ...[
                    pw.Text('No billing address selected', style: small),
                  ],
                ]),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Ship To', style: bold),
                  pw.SizedBox(height: 4),
                  if (address != null) ...[
                    pw.Text(address.name),
                    if ((address.mobile).isNotEmpty) pw.Text('Phone: ${address.mobile}', style: small),
                    if ((address.addressLine ?? '').isNotEmpty) pw.Text(address.addressLine!),
                    if ((address.addressLine2 ?? '').isNotEmpty) pw.Text(address.addressLine2!),
                    pw.Text('${address.city}, ${address.state} - ${address.pincode}'),
                  ] else ...[
                    pw.Text('No shipping address selected', style: small),
                  ],
                ]),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // Items table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
            columnWidths: {
              0: const pw.FlexColumnWidth(5),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Description', style: bold)),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Qty', style: bold)),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount (INR)', style: bold)),
                ],
              ),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(order.productName)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('1')),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(order.price.toStringAsFixed(2))),
              ]),
            ],
          ),

          pw.SizedBox(height: 8),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 240,
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.8)),
                child: pw.Column(children: [
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Subtotal')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(order.price.toStringAsFixed(2))),
                  ]),
                  pw.Container(height: 1, color: PdfColors.grey300),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Tax (0%)')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('0.00')),
                  ]),
                  pw.Container(height: 1, color: PdfColors.grey300),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total', style: bold)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(order.price.toStringAsFixed(2), style: bold)),
                  ]),
                ]),
              )
            ],
          ),

          pw.SizedBox(height: 24),
          pw.Text('Thank you for shopping with FlowLink!', style: bold),
          pw.SizedBox(height: 4),
          pw.Text('This is a system generated invoice.', style: small),
        ],
      ),
    );

    return doc.save();
  }
}
