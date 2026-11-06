part of kopiers;

class SegmentsPage extends StatelessWidget {
  const SegmentsPage({super.key});

  static const Color _primary = Color(0xFF9F2525);

  String _label(String value) {
    switch (value.toLowerCase()) {
      case 'new':
        return 'Baru';
      case 'active':
        return 'Aktif';
      case 'inactive':
        return 'Tidak Aktif';
      case 'none':
        return 'Belum Loyal';
      case 'bronze':
        return 'Bronze';
      case 'silver':
        return 'Silver';
      case 'gold':
        return 'Gold';
      case 'platinum':
        return 'Platinum';
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'no_purchase':
        return 'Belum Bertransaksi';
      case 'champions':
        return 'Champions';
      case 'loyal_customers':
        return 'Pelanggan Loyal';
      case 'potential_loyalists':
        return 'Potensial Loyal';
      case 'new_customers':
        return 'Pelanggan Baru';
      case 'need_attention':
        return 'Perlu Perhatian';
      case 'at_risk':
        return 'Berisiko';
      case 'cant_lose_them':
        return 'Jangan Sampai Hilang';
      case 'hibernating':
        return 'Tidak Aktif';
      case 'regular':
        return 'Pelanggan Reguler';
      default:
        return value.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _activityColor(String value) {
    switch (value.toLowerCase()) {
      case 'new':
        return const Color(0xFF9463CE);
      case 'active':
        return const Color(0xFF2878D0);
      default:
        return const Color(0xFFE28B35);
    }
  }

  Color _loyaltyColor(String value) {
    switch (value.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFB77945);
      case 'silver':
        return const Color(0xFF89939F);
      case 'gold':
        return const Color(0xFFD49B25);
      case 'platinum':
        return const Color(0xFF7566B5);
      default:
        return const Color(0xFF777777);
    }
  }

  Color _valueColor(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return const Color(0xFF16A36A);
      case 'medium':
        return const Color(0xFF2878D0);
      default:
        return const Color(0xFF89939F);
    }
  }

  Color _rfmColor(String value) {
    switch (value.toLowerCase()) {
      case 'champions':
      case 'loyal_customers':
        return const Color(0xFF16A36A);
      case 'potential_loyalists':
      case 'new_customers':
        return const Color(0xFF2878D0);
      case 'need_attention':
      case 'at_risk':
      case 'cant_lose_them':
        return const Color(0xFFE28B35);
      case 'no_purchase':
      case 'hibernating':
        return const Color(0xFF89939F);
      default:
        return const Color(0xFF7566B5);
    }
  }

  Widget _summarySection(
    BuildContext context,
    String title,
    IconData icon,
    Map<String, dynamic> data,
    Color Function(String) colorBuilder,
  ) {
    final entries = data.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 19, color: _primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${entries.length} kategori',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 88,
          ),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final color = colorBuilder(entry.key);

            return Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: color, size: 19),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _label(entry.key),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.value ?? 0} pelanggan',
                          style: TextStyle(
                            color: color,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _tag(String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        _label(value),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AdminDataPage(
      load: () => ApiClient.instance.get('/segments'),
      builder: (context, data) {
        final rows = List<Map<String, dynamic>>.from(
          (data['data'] as List? ?? []).map(
            (row) => Map<String, dynamic>.from(row as Map),
          ),
        );

        final summary = Map<String, dynamic>.from(
          data['summary'] as Map? ?? {},
        );

        final activity = Map<String, dynamic>.from(
          summary['activity'] as Map? ?? {},
        );

        final loyalty = Map<String, dynamic>.from(
          summary['loyalty'] as Map? ?? {},
        );

        final customerValue = Map<String, dynamic>.from(
          summary['customer_value'] as Map? ?? {},
        );

        final rfm = Map<String, dynamic>.from(summary['rfm'] as Map? ?? {});

        final total = (summary['total'] as num?)?.toInt() ?? rows.length;

        return _pagePadding(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9F2525), Color(0xFF641B1B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.donut_large_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Segmentasi Pelanggan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Analisis aktivitas, loyalitas, nilai pelanggan, '
                      'dan perilaku belanja dengan metode RFM.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_alt_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            '$total pelanggan terdata',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // RINGKASAN AKTIVITAS
              _summarySection(
                context,
                'Segmentasi Aktivitas',
                Icons.bolt_rounded,
                activity,
                _activityColor,
              ),

              const SizedBox(height: 23),

              // RINGKASAN LOYALITAS
              _summarySection(
                context,
                'Kategori Loyalitas',
                Icons.workspace_premium_rounded,
                loyalty,
                _loyaltyColor,
              ),

              const SizedBox(height: 23),

              // RINGKASAN CUSTOMER VALUE
              _summarySection(
                context,
                'Customer Value',
                Icons.stars_rounded,
                customerValue,
                _valueColor,
              ),

              const SizedBox(height: 23),

              _summarySection(
                context,
                'Segmen RFM',
                Icons.insights_rounded,
                rfm,
                _rfmColor,
              ),

              const SizedBox(height: 8),

              Text(
                'Skor RFM 1–5 dihitung relatif di antara pelanggan '
                'yang memiliki transaksi selesai. R = kebaruan '
                'transaksi, F = frekuensi, M = total belanja.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 26),

              // DAFTAR PELANGGAN
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Daftar Pelanggan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${rows.length} pelanggan',
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              Text(
                'Klasifikasi aktivitas, loyalitas, nilai belanja, '
                'dan skor RFM.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),

              const SizedBox(height: 13),

              if (rows.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 42,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada data pelanggan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Data segmentasi akan muncul setelah '
                        'pelanggan tersedia.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...rows.map((row) {
                  final name = row['name']?.toString() ?? '-';
                  final activitySegment =
                      row['activity_segment']?.toString() ??
                      row['segment']?.toString() ??
                      'inactive';
                  final loyaltyTier = row['loyalty_tier']?.toString() ?? 'none';
                  final valueTier = row['customer_value']?.toString() ?? 'low';
                  final rfmSegment =
                      row['rfm_segment']?.toString() ?? 'regular';
                  final rfmScore = row['rfm_score']?.toString() ?? '---';
                  final rfmScores = Map<String, dynamic>.from(
                    row['rfm_scores'] as Map? ?? {},
                  );
                  final recencyDays = (row['recency_days'] as num?)?.toInt();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 11),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 43,
                              height: 43,
                              decoration: BoxDecoration(
                                color: _primary.withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: _primary,
                                size: 23,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${row['transaction_count'] ?? 0} transaksi',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _adminMoney(row['lifetime_value']),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 13),
                        Divider(
                          height: 1,
                          color: Colors.grey.withValues(alpha: 0.13),
                        ),
                        const SizedBox(height: 11),

                        Wrap(
                          spacing: 6,
                          runSpacing: 7,
                          children: [
                            _tag(
                              activitySegment,
                              _activityColor(activitySegment),
                            ),
                            _tag(loyaltyTier, _loyaltyColor(loyaltyTier)),
                            _tag(valueTier, _valueColor(valueTier)),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: _rfmColor(rfmSegment)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.insights_rounded,
                                    size: 15,
                                    color: _rfmColor(rfmSegment),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'RFM $rfmScore',
                                    style: TextStyle(
                                      color: _rfmColor(rfmSegment),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Flexible(
                                    child: Text(
                                      _label(rfmSegment),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: _rfmColor(rfmSegment),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'R ${rfmScores['recency'] ?? '-'}'
                                '${recencyDays == null ? ' (belum ada transaksi)' : ' ($recencyDays hari)'}'
                                '  ·  F ${rfmScores['frequency'] ?? '-'}'
                                '  ·  M ${rfmScores['monetary'] ?? '-'}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Total belanja pelanggan',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _adminMoney(row['lifetime_value']),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 15),

              // PENGATURAN
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _editSegments(context);
                  },
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Atur Aturan Segmentasi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: _primary),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// =====================================================
// PENGATURAN ATURAN SEGMENTASI
// =====================================================

Future<void> _editSegments(BuildContext context) async {
  try {
    final rules = await ApiClient.instance.get('/segments/rules');

    if (!context.mounted) return;

    final currentRules = Map<String, dynamic>.from(
      rules['rules'] as Map? ?? {},
    );

    final active = await _askInt(
      context,
      'Hari untuk kategori aktif',
      initial: (currentRules['active_days'] as num?)?.toInt() ?? 30,
    );

    if (active == null || !context.mounted) return;

    final newDays = await _askInt(
      context,
      'Hari untuk pelanggan baru',
      initial: (currentRules['new_customer_days'] as num?)?.toInt() ?? 30,
    );

    if (newDays == null || !context.mounted) return;

    final loyal = await _askInt(
      context,
      'Minimal jumlah transaksi pelanggan loyal',
      initial: (currentRules['loyal_min_transactions'] as num?)?.toInt() ?? 10,
    );

    if (loyal == null || !context.mounted) return;

    final highValue = await _askInt(
      context,
      'Nilai transaksi tinggi (Rupiah)',
      initial: (currentRules['high_value_amount'] as num?)?.toInt() ?? 500000,
    );

    if (highValue == null || !context.mounted) return;

    await _runAction(context, () async {
      await ApiClient.instance.put('/segments/rules', {
        'active_days': active,
        'new_customer_days': newDays,
        'loyal_min_transactions': loyal,
        'high_value_amount': highValue,
      });

      if (!context.mounted) return;

      await _message(context, 'Aturan segmentasi berhasil diperbarui.');
    });
  } catch (e) {
    if (!context.mounted) return;

    await _message(context, 'Gagal memuat aturan segmentasi: $e');
  }
}
