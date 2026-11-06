
part of kopiers;

class LoyaltyPage extends StatefulWidget {
  const LoyaltyPage({super.key});

  @override
  State<LoyaltyPage> createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends State<LoyaltyPage> {
  int _reload = 0;

  Future<void> _addReward(BuildContext context) async {
    final name = await _askText(context, 'Nama reward');
    if (name == null || !context.mounted) return;

    final description = await _askText(
      context,
      'Deskripsi reward (opsional)',
      required: false,
    );
    if (description == null || !context.mounted) return;

    final points = await _askInt(context, 'Biaya poin');
    if (points == null || !context.mounted) return;

    final stock = await _askInt(
      context,
      'Stok (0 = habis)',
      initial: 10,
    );
    if (stock == null || !context.mounted) return;

    await _runAction(context, () async {
      await ApiClient.instance.post('/loyalty/rewards', {
        'name': name,
        if (description.isNotEmpty) 'description': description,
        'points_cost': points,
        'stock': stock,
      });

      if (!context.mounted) return;

      setState(() => _reload++);
      await _message(context, 'Reward berhasil ditambahkan.');
    });
  }

  Widget _gradientIcon(
    IconData icon, {
    double size = 24,
    double padding = 11,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE00404),
            Color(0xFFB80000),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: coffee.withValues(alpha: 0.16),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size,
      ),
    );
  }

  Widget _addRewardButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE00404),
            Color(0xFFB80000),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: coffee.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => _addReward(context),
        tooltip: 'Tambah reward',
        padding: const EdgeInsets.all(12),
        icon: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 25,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Card(
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _AdminDataPage(
        key: ValueKey(_reload),
        load: () async {
          final results = await Future.wait([
            ApiClient.instance.get('/loyalty/rewards'),
            ApiClient.instance.get('/loyalty/settings'),
            ApiClient.instance.get('/loyalty/redemptions'),
          ]);

          return {
            'rewards': results[0]['data'],
            'rules': results[1]['rules'],
            'redemptions': results[2]['data'],
          };
        },
        builder: (context, data) {
          final rewards = List<Map<String, dynamic>>.from(
            (data['rewards'] as List).map(
              (row) => Map<String, dynamic>.from(row as Map),
            ),
          );

          final redemptions = List<Map<String, dynamic>>.from(
            (data['redemptions'] as List).map(
              (row) => Map<String, dynamic>.from(row as Map),
            ),
          );

          final rules = Map<String, dynamic>.from(
            data['rules'] as Map,
          );

          final pointsPerTenThousand =
              (rules['points_per_10000'] as num?)?.toInt() ?? 0;

          return _pagePadding(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(
                  'Loyalitas & reward',
                  'Kelola katalog reward dan aturan poin transaksi',
                ),
                const SizedBox(height: 8),

                // Pengaturan poin
                _sectionCard(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final value = await _askInt(
                        context,
                        'Poin per Rp10.000',
                        initial: pointsPerTenThousand,
                      );

                      if (value == null || !context.mounted) return;

                      await _runAction(context, () async {
                        await ApiClient.instance.put(
                          '/loyalty/settings',
                          {
                            'points_per_10000': value,
                          },
                        );

                        if (!context.mounted) return;
                        setState(() => _reload++);
                        await _message(
                          context,
                          'Aturan poin berhasil diperbarui.',
                        );
                      });
                    },
                    child: Row(
                      children: [
                        _gradientIcon(Icons.stars_rounded),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Aturan poin transaksi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$pointsPerTenThousand poin per Rp10.000',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.edit_rounded,
                          color: coffee,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Katalog reward
                Row(
                  children: [
                    Expanded(
                      child: _sectionTitle('Katalog reward'),
                    ),
                    _addRewardButton(context),
                  ],
                ),
                const SizedBox(height: 6),

                if (rewards.isEmpty)
                  _sectionCard(
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          _gradientIcon(
                            Icons.card_giftcard_rounded,
                            size: 34,
                            padding: 17,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada reward',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Tambahkan reward untuk pelanggan Kopiers.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: () => _addReward(context),
                            icon: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                            ),
                            label: const Text('Tambah reward'),
                          ),
                        ],
                      ),
                    ),
                  ),

                ...rewards.map((reward) {
                  final isActive =
                      reward['is_active'] == true ||
                      reward['is_active'] == 1;

                  final points =
                      (reward['points_cost'] as num?)?.toInt() ?? 0;

                  final stock =
                      (reward['stock'] as num?)?.toInt();

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          _gradientIcon(
                            Icons.card_giftcard_rounded,
                            size: 27,
                            padding: 12,
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reward['name']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 7,
                                  runSpacing: 5,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: softRed,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$points poin',
                                        style: const TextStyle(
                                          color: darkCoffee,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      stock == null
                                          ? 'Stok tak terbatas'
                                          : 'Stok $stock',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFFE5F7EC)
                                        : softRed,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(
                                    isActive ? 'Aktif' : 'Nonaktif',
                                    style: TextStyle(
                                      color: isActive
                                          ? const Color(0xFF197344)
                                          : darkCoffee,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Aksi reward',
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: coffee,
                            ),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await _editReward(context, reward);
                              } else if (value == 'toggle') {
                                await _runAction(context, () async {
                                  await ApiClient.instance.patch(
                                    '/loyalty/rewards/${reward['id']}',
                                    {'is_active': !isActive},
                                  );

                                  if (!context.mounted) return;
                                  setState(() => _reload++);
                                });
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_rounded,
                                      color: coffee,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text('Edit reward'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      isActive
                                          ? Icons.toggle_off_rounded
                                          : Icons.toggle_on_rounded,
                                      color: coffee,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      isActive
                                          ? 'Nonaktifkan'
                                          : 'Aktifkan',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 18),

                // Penukaran reward
                _sectionTitle(
                  'Penukaran customer',
                  'Periksa kode klaim dan tandai setelah reward diserahkan',
                ),
                const SizedBox(height: 6),

                if (redemptions.isEmpty)
                  _sectionCard(
                    child: Row(
                      children: [
                        _gradientIcon(
                          Icons.redeem_rounded,
                          size: 27,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Belum ada customer yang menukar reward.',
                          ),
                        ),
                      ],
                    ),
                  ),

                ...redemptions.map((redemption) {
                  final isClaimed = redemption['status'] == 'claimed';
                  final statusText = isClaimed
                      ? 'Selesai'
                      : 'Menunggu diambil';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isClaimed
                                      ? const Color(0xFFE5F7EC)
                                      : softRed,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isClaimed
                                      ? Icons.check_circle_rounded
                                      : Icons.card_giftcard_rounded,
                                  color: isClaimed
                                      ? const Color(0xFF197344)
                                      : coffee,
                                  size: 25,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      redemption['customer_name']
                                              ?.toString() ??
                                          '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      redemption['customer_phone']
                                              ?.toString() ??
                                          '-',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      redemption['reward_name']
                                              ?.toString() ??
                                          '-',
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isClaimed
                                      ? const Color(0xFFE5F7EC)
                                      : softRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: isClaimed
                                        ? const Color(0xFF197344)
                                        : darkCoffee,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cream,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kode penukaran',
                                  style: TextStyle(
                                    color: darkCoffee,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  redemption['redemption_code']
                                          ?.toString() ??
                                      '-',
                                  style: const TextStyle(
                                    color: coffee,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${_adminDate(redemption['redeemed_at'])}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (!isClaimed)
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                icon: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.white,
                                ),
                                label: const Text('Tandai selesai'),
                                onPressed: () {
                                  _runAction(context, () async {
                                    await ApiClient.instance.patch(
                                      '/loyalty/redemptions/${redemption['id']}/claim',
                                    );

                                    if (!context.mounted) return;
                                    setState(() => _reload++);
                                  });
                                },
                              ),
                            )
                          else
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Chip(
                                avatar: Icon(
                                  Icons.done_all_rounded,
                                  color: Color(0xFF197344),
                                ),
                                label: Text('Selesai'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Penyesuaian poin pelanggan
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _adjustPoints(context),
                    icon: const Icon(
                      Icons.add_card_rounded,
                      color: coffee,
                    ),
                    label: const Text('Sesuaikan poin pelanggan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: coffee,
                      side: const BorderSide(color: coffee),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

  Future<void> _editReward(
    BuildContext context,
    Map<String, dynamic> reward,
  ) async {
    final name = await _askText(
      context,
      'Nama reward',
      initial: reward['name']?.toString(),
    );
    if (name == null || !context.mounted) return;

    final description = await _askText(
      context,
      'Deskripsi reward',
      initial: reward['description']?.toString(),
      required: false,
    );
    if (description == null || !context.mounted) return;

    final points = await _askInt(
      context,
      'Biaya poin',
      initial: (reward['points_cost'] as num?)?.toInt() ?? 0,
    );
    if (points == null || !context.mounted) return;

    final stock = await _askInt(
      context,
      'Stok (0 = habis)',
      initial: (reward['stock'] as num?)?.toInt() ?? 0,
    );
    if (stock == null || !context.mounted) return;

    await _runAction(context, () async {
      await ApiClient.instance.patch(
        '/loyalty/rewards/${reward['id']}',
        {
          'name': name,
          'description': description.isEmpty ? null : description,
          'points_cost': points,
          'stock': stock,
        },
      );

      if (!context.mounted) return;
      setState(() => _reload++);
      await _message(context, 'Reward berhasil diperbarui.');
    });
  }

  Future<void> _adjustPoints(BuildContext context) async {
    final customerId = await _askInt(context, 'ID pelanggan');
    if (customerId == null || !context.mounted) return;

    final points = await _askInt(
      context,
      'Jumlah poin (+/-)',
    );
    if (points == null || !context.mounted) return;

    final description = await _askText(
      context,
      'Alasan penyesuaian',
    );
    if (description == null || !context.mounted) return;

    await _runAction(context, () async {
      await ApiClient.instance.post(
        '/loyalty/points/$customerId/adjustment',
        {
          'points': points,
          'description': description,
        },
      );

      if (context.mounted) {
        await _message(context, 'Poin berhasil disesuaikan.');
      }
    });
  }
}
