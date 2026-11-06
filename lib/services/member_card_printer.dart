import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MemberCardPrinter {
  static Future<void> printCard({
    required String customerId,
    required String memberName,
    required String tier,
    required int points,
    required int purchaseCount,
  }) async {
    if (customerId.trim().isEmpty) {
      throw ArgumentError.value(customerId, 'customerId', 'Tidak boleh kosong');
    }

    await Printing.layoutPdf(
      onLayout: (_) => buildPdf(
        customerId: customerId,
        memberName: memberName,
        tier: tier,
        points: points,
        purchaseCount: purchaseCount,
      ),
      name: 'Kartu-Member-KOP-${customerId.padLeft(6, '0')}.pdf',
    );
  }

  @visibleForTesting
  static Future<Uint8List> buildPdf({
    required String customerId,
    required String memberName,
    required String tier,
    required int points,
    required int purchaseCount,
  }) async {
    if (customerId.trim().isEmpty) {
      throw ArgumentError.value(customerId, 'customerId', 'Tidak boleh kosong');
    }

    final document = pw.Document();
    final font = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();
    final backgroundBytes = (await rootBundle.load(
      'assets/images/background_kartu_member.png',
    )).buffer.asUint8List();
    final background = pw.MemoryImage(backgroundBytes);
    final memberNumber = 'KOP-${customerId.padLeft(6, '0')}';
    final normalizedTier = tier.trim().replaceAll('_', ' ').toUpperCase();
    final tierLabel = normalizedTier.isEmpty || normalizedTier == 'NONE'
        ? 'MEMBER'
        : '$normalizedTier MEMBER';
    final progress = purchaseCount % 10 == 0 && purchaseCount > 0
        ? 10
        : purchaseCount % 10;

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => pw.Center(
          child: pw.Container(
            width: 85.6 * PdfPageFormat.mm,
            height: 54 * PdfPageFormat.mm,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
              borderRadius: pw.BorderRadius.circular(3 * PdfPageFormat.mm),
            ),
            child: pw.ClipRRect(
              horizontalRadius: 3 * PdfPageFormat.mm,
              verticalRadius: 3 * PdfPageFormat.mm,
              child: pw.Stack(
                fit: pw.StackFit.expand,
                children: [
                  pw.Image(background, fit: pw.BoxFit.cover),
                  pw.Positioned(
                    left: 3 * PdfPageFormat.mm,
                    right: 3 * PdfPageFormat.mm,
                    bottom: 3 * PdfPageFormat.mm,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 3 * PdfPageFormat.mm,
                        vertical: 2 * PdfPageFormat.mm,
                      ),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor(0.25, 0, 0, 0.88),
                        borderRadius: pw.BorderRadius.circular(
                          2 * PdfPageFormat.mm,
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              mainAxisSize: pw.MainAxisSize.min,
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  memberName,
                                  maxLines: 1,
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 10,
                                    color: PdfColors.white,
                                  ),
                                ),
                                pw.SizedBox(height: 1 * PdfPageFormat.mm),
                                pw.Text(
                                  '$memberNumber  |  $tierLabel',
                                  maxLines: 1,
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 6,
                                    color: PdfColors.white,
                                  ),
                                ),
                                pw.SizedBox(height: 1 * PdfPageFormat.mm),
                                pw.Text(
                                  '$points poin  |  Stempel $progress/10',
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: 6,
                                    color: PdfColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 2 * PdfPageFormat.mm),
                          pw.Container(
                            width: 15 * PdfPageFormat.mm,
                            height: 15 * PdfPageFormat.mm,
                            padding: const pw.EdgeInsets.all(
                              1 * PdfPageFormat.mm,
                            ),
                            color: PdfColors.white,
                            child: pw.BarcodeWidget(
                              barcode: pw.Barcode.qrCode(),
                              data: 'KOPIERS-MEMBER:$customerId',
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
        ),
      ),
    );

    return document.save();
  }
}
