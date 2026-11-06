part of kopiers;

class PromoPage extends StatefulWidget {
  const PromoPage({super.key});

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  late Future<Map<String, dynamic>> _dataFuture;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final results = await Future.wait([
      ApiClient.instance.get('/campaigns'),
      ApiClient.instance.get('/loyalty/vouchers/me'),
    ]);

    final campaignsResponse = results[0];
    final vouchersResponse = results[1];

    if (campaignsResponse is! Map || vouchersResponse is! Map) {
      throw Exception('Format data promo atau voucher tidak valid.');
    }

    return {
      'campaigns': campaignsResponse['data'] ?? [],
      'vouchers': vouchersResponse['data'] ?? [],
    };
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _dataFuture = _loadData();
    });

    try {
      await _dataFuture;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui data: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _showVoucherDetail(
    Map<String, dynamic> originalVoucher,
  ) async {
    final code = originalVoucher['code']?.toString() ?? '';
    if (code.isEmpty) return;

    Map<String, dynamic> voucher = originalVoucher;

    try {
      // Periksa status terbaru sebelum menampilkan QR.
      final response = await ApiClient.instance.get('/loyalty/vouchers/me');
      if (response is! Map || response['data'] is! List) {
        throw Exception('Respons voucher dari server tidak valid.');
      }

      final latestVouchers = _asMapList(response['data']);
      final matches = latestVouchers.where(
        (item) => item['code']?.toString() == code,
      );
      if (matches.isEmpty) {
        throw Exception('Voucher tidak ditemukan pada akun ini.');
      }

      voucher = matches.first;
      if (!mounted) return;
      setState(() => _dataFuture = _loadData());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat memeriksa voucher: $error')),
      );
      return;
    }

    if (!mounted) return;

    final status = voucher['status']?.toString();
    final campaignName = voucher['campaign_name']?.toString() ?? 'Voucher Kopiers';
    final expiresAt = _date(voucher['expires_at']);
    final isAvailable = status == 'available';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFBF8),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.local_cafe_rounded, color: coffee, size: 34),
                ),
                const SizedBox(height: 14),
                Text(
                  campaignName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text('Berlaku sampai $expiresAt', style: TextStyle(color: Colors.brown.shade400)),
                const SizedBox(height: 14),
                _statusChip(status),
                const SizedBox(height: 20),
                if (isAvailable) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: coffee.withValues(alpha: 0.16)),
                      boxShadow: [
                        BoxShadow(color: coffee.withValues(alpha: 0.08), blurRadius: 22, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: QrImageView(
                      data: code,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tunjukkan QR Code ini kepada admin Kopiers untuk memvalidasi voucher.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    code,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        if (!sheetContext.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kode voucher berhasil disalin.')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Salin Kode Voucher'),
                    ),
                  ),
                ] else ...[
                  Icon(
                    status == 'used' ? Icons.verified_rounded : Icons.info_outline_rounded,
                    size: 48,
                    color: status == 'used' ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    status == 'used'
                        ? 'Voucher ini sudah ditukarkan dan QR tidak lagi tersedia.'
                        : 'Voucher berstatus ${_voucherStatus(status)} dan tidak dapat digunakan melalui QR ini.',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Ambil status terbaru lagi setelah detail ditutup.
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError && !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Gagal memuat promo dan voucher.\n${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Coba Lagi')),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final campaigns = _asMapList(data['campaigns']);
        final vouchers = _asMapList(data['vouchers']);
        final availableCount = vouchers.where((v) => v['status'] == 'available').length;
        final usedCount = vouchers.where((v) => v['status'] == 'used').length;

        return RefreshIndicator(
          onRefresh: _refresh,
          color: coffee,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(offset: Offset(0, 22 * (1 - value)), child: child),
                ),
                child: _promoHero(campaigns.length, vouchers.length),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: _sectionHeading('Promo aktif', 'Penawaran spesial untukmu')),
                  IconButton.filledTonal(
                    tooltip: 'Perbarui promo dan voucher',
                    onPressed: _refreshing ? null : _refresh,
                    icon: _refreshing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (campaigns.isEmpty)
                _emptyState(Icons.campaign_outlined, 'Belum ada promo', 'Promo menarik dari Kopiers akan muncul di sini.'),
              ...List.generate(campaigns.length, (index) {
                final item = campaigns[index];
                final conditions = _campaignConditions(item['conditions']);
                final discount = item['discount_percent'];
                return _animatedItem(
                  index: index,
                  child: _campaignCard(item, discount, conditions),
                );
              }),
              const SizedBox(height: 24),
              _sectionHeading('Voucher kamu', 'Ketuk voucher untuk melihat QR Code'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _miniStat('Tersedia', availableCount.toString(), Icons.confirmation_number_rounded, const Color(0xFFE34A42))),
                  const SizedBox(width: 10),
                  Expanded(child: _miniStat('Terpakai', usedCount.toString(), Icons.verified_rounded, const Color(0xFF3B956B))),
                  const SizedBox(width: 10),
                  Expanded(child: _miniStat('Total', vouchers.length.toString(), Icons.wallet_giftcard_rounded, const Color(0xFF9B744B))),
                ],
              ),
              const SizedBox(height: 14),
              if (vouchers.isEmpty)
                _emptyState(Icons.confirmation_number_outlined, 'Belum ada voucher', 'Voucher yang kamu dapatkan akan tampil di sini.'),
              ...List.generate(vouchers.length, (index) {
                final voucher = vouchers[index];
                return _animatedItem(index: index, child: _voucherCard(voucher));
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _promoHero(int campaignCount, int voucherCount) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFE32620), Color(0xFFEF5147)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: const Color(0xFFB71C1C).withValues(alpha: 0.22), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(right: -8, top: -12, child: Icon(Icons.local_cafe_rounded, size: 112, color: Colors.white.withValues(alpha: 0.10))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(30)),
                child: const Text('KOPIERS SPECIAL OFFER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
              ),
              const SizedBox(height: 16),
              const Text('Promo spesial\nbuat kamu!', style: TextStyle(color: Colors.white, fontSize: 27, height: 1.12, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Temukan penawaran dan gunakan voucher favoritmu.', style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 12, height: 1.4)),
              const SizedBox(height: 20),
              Row(
                children: [
                  _heroMetric(Icons.campaign_rounded, campaignCount.toString(), 'Promo'),
                  const SizedBox(width: 22),
                  _heroMetric(Icons.confirmation_number_rounded, voucherCount.toString(), 'Voucher'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 19),
        const SizedBox(width: 7),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
      ],
    );
  }

  Widget _sectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF35231F))),
        const SizedBox(height: 3),
        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.brown.shade400)),
      ],
    );
  }

  Widget _animatedItem({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('promo_item_$index'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + (index.clamp(0, 5) * 90).toInt()),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 18 * (1 - value)), child: child),
      ),
      child: child,
    );
  }

  Widget _campaignCard(Map<String, dynamic> item, dynamic discount, Map<String, dynamic> conditions) {
    final name = item['name']?.toString() ?? 'Promo Kopiers';
    final description = item['description']?.toString() ?? 'Promo khusus dari Kopiers.';
    final campaignType = _campaignType(item['campaign_type']?.toString());
    final start = _date(item['starts_at']);
    final end = _date(item['ends_at']);
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE0DC)),
        boxShadow: [BoxShadow(color: const Color(0xFF6D2520).withValues(alpha: 0.045), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: const Color(0xFFFFE9E6), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.campaign_rounded, color: Color(0xFFD71920)),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF35231F))),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Wrap(
              spacing: 6,
              runSpacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _smallTag(campaignType),
                if (discount != null) _smallTag('Diskon $discount%', red: true),
              ],
            ),
          ),
          children: [
            Align(alignment: Alignment.centerLeft, child: Text(description, style: TextStyle(color: Colors.brown.shade700, height: 1.45, fontSize: 13))),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 16, color: coffee),
                const SizedBox(width: 6),
                Expanded(child: Text('$start – $end', style: TextStyle(fontSize: 11, color: Colors.brown.shade500))),
              ],
            ),
            if (conditions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFF5F0), borderRadius: BorderRadius.circular(13)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Syarat promo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    const SizedBox(height: 5),
                    ...conditions.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text('• ${entry.key}: ${entry.value}', style: const TextStyle(fontSize: 12)),
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _voucherCard(Map<String, dynamic> voucher) {
    final code = voucher['code']?.toString() ?? '';
    final status = voucher['status']?.toString();
    final campaignName = voucher['campaign_name']?.toString() ?? 'Voucher Kopiers';
    final expiresAt = _date(voucher['expires_at']);
    final used = status == 'used';
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE0DC)),
        boxShadow: [BoxShadow(color: Colors.brown.withValues(alpha: 0.035), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: code.isEmpty ? null : () => _showVoucherDetail(voucher),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: used ? const Color(0xFFEAF5EF) : const Color(0xFFFFE9E6), borderRadius: BorderRadius.circular(14)),
                  child: Icon(used ? Icons.verified_rounded : Icons.confirmation_number_rounded, color: used ? Colors.green : const Color(0xFFD71920)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(code.isEmpty ? '-' : code, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: .3)),
                      const SizedBox(height: 4),
                      Text(campaignName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.brown.shade700)),
                      const SizedBox(height: 3),
                      Text('Berlaku sampai $expiresAt', style: TextStyle(fontSize: 10, color: Colors.brown.shade400)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _statusChip(status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: .15)), boxShadow: [BoxShadow(color: color.withValues(alpha: .05), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.brown.shade400)),
        ],
      ),
    );
  }

  Widget _smallTag(String text, {bool red = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: red ? const Color(0xFFFFE6E3) : const Color(0xFFF5EEE8), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: red ? const Color(0xFFC51E25) : Colors.brown.shade600)),
    );
  }

  Widget _statusChip(String? status) {
    final used = status == 'used';
    final expired = status == 'expired';
    final color = used ? const Color(0xFF27845A) : expired ? Colors.grey : const Color(0xFFC62828);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(30)),
      child: Text(_voucherStatus(status), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 25),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFFE5E1))),
      child: Column(
        children: [
          Icon(icon, size: 34, color: const Color(0xFFD94A42)),
          const SizedBox(height: 9),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.brown.shade400)),
        ],
      ),
    );
  }
}

String _voucherStatus(String? status) => switch (status) {
  'available' => 'Tersedia',
  'upcoming' => 'Akan datang',
  'expired' => 'Kedaluwarsa',
  'used' => 'Terpakai',
  _ => status ?? '-',
};

String _campaignType(String? type) => switch (type) {
  'new_customer' => 'Pelanggan baru',
  'loyal' => 'Pelanggan loyal',
  'reengagement' => 'Kembali berbelanja',
  'personalized' => 'Promo personal',
  _ => type ?? 'Promo Kopiers',
};

Map<String, dynamic> _campaignConditions(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      return {};
    }
  }
  return {};
}
