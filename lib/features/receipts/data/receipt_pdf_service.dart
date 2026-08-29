import 'dart:typed_data';

import 'package:flutter/material.dart' show BuildContext, Color;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:tappay/features/payments/data/payment_models.dart';
import 'package:tappay/core/theme/app_theme.dart';

/// Builds and shares a nicely-formatted PDF receipt for a [TransactionModel].
///
/// Amounts are stored as integer minor units (pesewas/kobo). We reuse the
/// app's [formatAmount] helper from `theme.dart` so the PDF matches exactly
/// what the on-screen receipt shows (e.g. `GHS 35.00`).
class ReceiptPdfService {
  const ReceiptPdfService();

  /// Brand accent used across the document, derived from the app's primary
  /// brand colour so the PDF stays in sync with the app theme.
  static PdfColor get _brand => _toPdf(AppColors.brand);
  static PdfColor get _brandDeep => _toPdf(AppColors.brandDeep);
  static PdfColor get _ink => _toPdf(AppColors.ink);
  static PdfColor get _inkSoft => _toPdf(AppColors.inkSoft);
  static PdfColor get _inkFaint => _toPdf(AppColors.inkFaint);
  static PdfColor get _border => _toPdf(AppColors.border);

  static PdfColor _toPdf(Color c) => PdfColor.fromInt(c.toARGB32());

  /// Maps a transaction status to a badge colour (mirrors [StatusPill]).
  static PdfColor _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return _toPdf(AppColors.success);
      case 'FAILED':
        return _toPdf(AppColors.danger);
      case 'REFUNDED':
        return _inkSoft;
      default:
        return _toPdf(AppColors.warning);
    }
  }

  /// A human-friendly label for the status badge.
  static String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return 'PAID';
      case 'REFUNDED':
        return 'REFUNDED';
      case 'FAILED':
        return 'FAILED';
      case 'PENDING':
      case 'INITIALIZED':
        return 'PENDING';
      default:
        return status.toUpperCase();
    }
  }

  /// Renders the receipt to PDF bytes.
  Future<Uint8List> build(TransactionModel txn) async {
    final doc = pw.Document(
      title: 'TapPay receipt ${txn.reference}',
      author: 'TapPay',
    );

    final generatedAt = DateTime.now();
    final dateFmt = DateFormat.yMMMMd().add_jm();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _header(),
            pw.SizedBox(height: 28),
            _amountBlock(txn),
            pw.SizedBox(height: 24),
            _detailsCard(txn, dateFmt),
            pw.Spacer(),
            _footer(generatedAt, dateFmt),
          ],
        ),
      ),
    );

    return doc.save();
  }

  /// Builds the PDF and opens the platform share / save / print sheet.
  Future<void> shareReceipt(BuildContext context, TransactionModel txn) async {
    final bytes = await build(txn);
    final safeRef = txn.reference.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'tappay-receipt-$safeRef.pdf',
    );
  }

  // --- sections -----------------------------------------------------------

  pw.Widget _header() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 44,
          height: 44,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(colors: [_brand, _brandDeep]),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(
            'TP',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Text(
          'TapPay',
          style: pw.TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        pw.Spacer(),
        pw.Text(
          'Payment Receipt',
          style: pw.TextStyle(color: _inkSoft, fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _amountBlock(TransactionModel txn) {
    final statusColor = _statusColor(txn.status);
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(AppColors.surfaceAlt.toARGB32()),
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'Amount',
            style: pw.TextStyle(color: _inkSoft, fontSize: 11, letterSpacing: 0.4),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            formatAmount(txn.amount, txn.currency),
            style: pw.TextStyle(
              color: _ink,
              fontSize: 34,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColor(statusColor.red, statusColor.green, statusColor.blue, 0.12),
              borderRadius: pw.BorderRadius.circular(999),
            ),
            child: pw.Text(
              _statusLabel(txn.status),
              style: pw.TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _detailsCard(TransactionModel txn, DateFormat dateFmt) {
    final rows = <List<String>>[
      ['Reference', txn.reference],
      ['Transaction ID', txn.id],
      ['Date', dateFmt.format(txn.createdAt)],
      ['Currency', txn.currency],
      if (txn.payerId != null) ['Payer', txn.payerId!],
      ['Payee', txn.payeeId],
      if (txn.description?.isNotEmpty == true) ['Note', txn.description!],
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(16),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: pw.Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            pw.Container(
              decoration: i == rows.length - 1
                  ? null
                  : pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: _border)),
                    ),
              padding: const pw.EdgeInsets.symmetric(vertical: 12),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 120,
                    child: pw.Text(
                      rows[i][0],
                      style: pw.TextStyle(color: _inkSoft, fontSize: 11),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      rows[i][1],
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        color: _ink,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _footer(DateTime generatedAt, DateFormat dateFmt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: _border),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated by TapPay - ${dateFmt.format(generatedAt)}',
          style: pw.TextStyle(color: _inkFaint, fontSize: 9),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'This receipt was verified with the payment provider.',
          style: pw.TextStyle(color: _inkFaint, fontSize: 9),
        ),
      ],
    );
  }
}
