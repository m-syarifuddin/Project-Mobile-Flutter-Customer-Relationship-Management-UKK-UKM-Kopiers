import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kopiers/services/member_card_printer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds a printable member card PDF', () async {
    final pdf = await MemberCardPrinter.buildPdf(
      customerId: '42',
      memberName: 'Pelanggan Kopiers',
      tier: 'BRONZE',
      points: 15,
      purchaseCount: 12,
    );

    expect(utf8.decode(pdf.take(4).toList()), '%PDF');
    expect(pdf.length, greaterThan(1000));
  });

  test('rejects a missing member ID', () async {
    await expectLater(
      MemberCardPrinter.buildPdf(
        customerId: ' ',
        memberName: 'Pelanggan Kopiers',
        tier: 'BRONZE',
        points: 0,
        purchaseCount: 0,
      ),
      throwsArgumentError,
    );
  });
}
