part of kopiers;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) => _AdminDataPage(
    key: ValueKey(_refreshKey),

    load: () => ApiClient.instance.get('/dashboard'),

    builder: (context, data) {
      final customers = Map<String, dynamic>.from(data['customers'] as Map);

      final sales = Map<String, dynamic>.from(data['sales'] as Map);

      final segments = customers;

      final rfm = Map<String, dynamic>.from(data['rfm'] as Map);

      final rfmSegments = Map<String, dynamic>.from(rfm['segments'] as Map);

      final complaints = Map<String, dynamic>.from(data['complaints'] as Map);

      final activity = List<Map<String, dynamic>>.from(
        (data['activity'] as List).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

      final customerGrowth = List<Map<String, dynamic>>.from(
        (data['customer_growth'] as List).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

      return _pagePadding(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFF7F1010)],

                  begin: Alignment.topLeft,

                  end: Alignment.bottomRight,
                ),

                borderRadius: BorderRadius.circular(20),

                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB71C1C).withValues(alpha: 0.18),

                    blurRadius: 18,

                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: Row(
                children: [
                  Container(
                    width: 54,

                    height: 54,

                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),

                      borderRadius: BorderRadius.circular(16),

                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),

                    child: const Icon(
                      Icons.analytics_rounded,

                      color: Colors.white,

                      size: 29,
                    ),
                  ),

                  const SizedBox(width: 16),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Ringkasan Bisnis',

                          style: TextStyle(
                            color: Colors.white,

                            fontSize: 20,

                            fontWeight: FontWeight.w800,

                            letterSpacing: -0.4,
                          ),
                        ),

                        SizedBox(height: 6),

                        Text(
                          'Pantau performa penjualan Kopiers',

                          style: TextStyle(
                            color: Color(0xFFF8DADA),

                            fontSize: 12,

                            height: 1.4,
                          ),
                        ),

                        SizedBox(height: 10),

                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,

                              size: 14,

                              color: Colors.white70,
                            ),

                            SizedBox(width: 6),

                            Text(
                              'Aktivitas 30 hari terakhir',

                              style: TextStyle(
                                color: Colors.white,

                                fontSize: 11,

                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    child: IconButton(
                      tooltip: 'Refresh data',
                      onPressed: () {
                        setState(() {
                          _refreshKey++;
                        });
                      },
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            LayoutBuilder(
              builder: (context, box) {
                final columns = box.maxWidth > 720 ? 4 : 2;

                final width = (box.maxWidth - (columns - 1) * 10) / columns;

                return Wrap(
                  spacing: 10,

                  runSpacing: 10,

                  children: [
                    SizedBox(
                      width: width,

                      child: _stat(
                        'Pelanggan terdaftar',

                        '${customers['total'] ?? 0}',

                        Icons.people,

                        coffee,
                      ),
                    ),

                    SizedBox(
                      width: width,

                      child: _stat(
                        'Pelanggan aktif',

                        '${segments['active'] ?? 0}',

                        Icons.trending_up,

                        Colors.green,
                      ),
                    ),

                    SizedBox(
                      width: width,

                      child: _stat(
                        'Pelanggan loyal',

                        '${segments['loyal'] ?? 0}',

                        Icons.favorite_outline,

                        Colors.deepOrange,
                      ),
                    ),

                    SizedBox(
                      width: width,

                      child: _stat(
                        'Nilai transaksi tinggi',

                        '${segments['high_value'] ?? 0}',

                        Icons.diamond_outlined,

                        Colors.purple,
                      ),
                    ),

                    SizedBox(
                      width: width,

                      child: _stat(
                        'Tidak aktif',

                        '${segments['inactive'] ?? 0}',

                        Icons.person_off_outlined,

                        Colors.blueGrey,
                      ),
                    ),

                    SizedBox(
                      width: width,

                      child: _stat(
                        'Transaksi 30 hari',

                        '${sales['transaction_count'] ?? 0}',

                        Icons.receipt_long,

                        Colors.indigo,
                      ),
                    ),

                    SizedBox(
                      width: width,

                      child: _stat(
                        'Penjualan 30 hari',

                        _adminMoney(sales['total_sales']),

                        Icons.payments_outlined,

                        Colors.teal,
                      ),
                    ),

                    SizedBox(
                      width: width,

                      child: _stat(
                        'Keluhan terbuka',

                        '${complaints['open_count'] ?? 0}',

                        Icons.support_agent,

                        Colors.red,
                      ),
                    ),

                    SizedBox(
                      width: width,

                      child: _stat(
                        'Poin beredar',

                        '${data['loyalty']['points_outstanding'] ?? 0}',

                        Icons.stars_outlined,

                        Colors.amber.shade800,
                      ),
                    ),

                    SizedBox(
                      width: width,

                      child: _stat(
                        'Reward aktif',

                        '${data['programs']['active_rewards'] ?? 0}',

                        Icons.card_giftcard_outlined,

                        Colors.deepPurple,
                      ),
                    ),

                    SizedBox(
                      width: width,

                      child: _stat(
                        'Voucher tersedia',

                        '${data['programs']['available_vouchers'] ?? 0}',

                        Icons.confirmation_number_outlined,

                        Colors.blue,
                      ),
                    ),

                    SizedBox(
                      width: width,

                      child: _stat(
                        'Voucher digunakan',

                        '${data['programs']['redeemed_vouchers'] ?? 0}',

                        Icons.local_activity_outlined,

                        Colors.teal,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 18),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.donut_large_rounded, color: coffee),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Segmentasi RFM',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Text(
                          '${rfm['window_days']} hari',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Frequency dan Monetary memakai kuintil cohort.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, box) {
                        final columns = box.maxWidth > 720 ? 4 : 2;
                        final width =
                            (box.maxWidth - (columns - 1) * 8) / columns;
                        const labels = <String, String>{
                          'champions': 'Champions',
                          'loyal_customers': 'Pelanggan loyal',
                          'potential_loyalists': 'Potensial loyal',
                          'new_customers': 'Pelanggan baru',
                          'need_attention': 'Perlu perhatian',
                          'at_risk': 'Berisiko',
                          'cant_lose_them': 'Jangan sampai hilang',
                          'hibernating': 'Hibernating',
                          'regular': 'Reguler',
                          'no_purchase': 'Belum bertransaksi',
                        };

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: labels.entries.map((entry) {
                            return Container(
                              width: width,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: coffee.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: coffee.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${rfmSegments[entry.key] ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Aktivitas harian',

                        style: TextStyle(
                          fontWeight: FontWeight.bold,

                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _DailyMetricChart(
                        title: 'Pelanggan baru per hari',

                        items: customerGrowth,

                        valueKey: 'customer_count',

                        color: const Color.fromARGB(255, 57, 0, 150),

                        formatValue: (value) => value.toInt().toString(),

                        unit: 'pelanggan',
                      ),

                      const SizedBox(height: 16),

                      _DailyMetricChart(
                        title: 'Penjualan per hari',

                        items: activity,

                        valueKey: 'sales',

                        color: coffee,

                        formatValue: _adminCompactMoney,

                        unit: 'penjualan',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.campaign, color: coffee),

                  title: const Text('Promo sedang berjalan'),

                  trailing: Text('${data['campaigns']['active_count'] ?? 0}'),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _DailyMetricChart extends StatelessWidget {
  const _DailyMetricChart({
    required this.title,

    required this.items,

    required this.valueKey,

    required this.color,

    required this.formatValue,

    required this.unit,
  });

  final String title;

  final List<Map<String, dynamic>> items;

  final String valueKey;

  final Color color;

  final String Function(double value) formatValue;

  final String unit;

  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<double>(1, (max, item) {
      final value = (item[valueKey] as num).toDouble();

      return value > max ? value : max;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),

        const SizedBox(height: 8),

        if (items.isEmpty)
          Text('Belum ada $unit pada periode ini.')
        else
          SizedBox(
            height: 140,

            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,

              child: SizedBox(
                width: items.length * 68,

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: items.map((item) {
                    final value = (item[valueKey] as num).toDouble();

                    return SizedBox(
                      width: 68,

                      child: Tooltip(
                        message:
                            '${_adminDate(item['date'])}: ${formatValue(value)} $unit',

                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),

                          child: Column(
                            children: [
                              SizedBox(
                                height: 22,

                                child: FittedBox(
                                  fit: BoxFit.scaleDown,

                                  child: Text(
                                    formatValue(value),

                                    style: const TextStyle(
                                      fontSize: 11,

                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const Spacer(),

                              Container(
                                height: 10 + (value / maxValue * 70),

                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.76),

                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                _adminChartDate(item['date']),

                                style: const TextStyle(
                                  fontSize: 10,

                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _adminCompactMoney(double value) {
  if (value >= 1000000) {
    final amount = value / 1000000;

    return 'Rp${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 1)}jt';
  }

  if (value >= 1000) {
    final amount = value / 1000;

    return 'Rp${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 1)}rb';
  }

  return _adminMoney(value);
}

String _adminChartDate(dynamic value) {
  final date = DateTime.tryParse(value.toString());

  if (date == null) return value.toString();

  return '${date.day}/${date.month}';
}
