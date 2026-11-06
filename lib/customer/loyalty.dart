part of kopiers;

class LoyaltyCustomerPage extends StatelessWidget {
  const LoyaltyCustomerPage({super.key, required this.onChanged});
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => _CustomerDataPage(
    load: () async {
      final result = await Future.wait([
        ApiClient.instance.get('/loyalty/points/me'),
        ApiClient.instance.get('/loyalty/rewards'),
        ApiClient.instance.get('/loyalty/redemptions/me'),
      ]);
      return {
        'points': result[0],
        'rewards': result[1]['data'],
        'redemptions': result[2]['data'],
      };
    },
    builder: (context, data) {
      final points = Map<String, dynamic>.from(data['points'] as Map);
      final history = List<Map<String, dynamic>>.from(
        ((points['history'] as List?) ?? const []).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
      final rewards = List<Map<String, dynamic>>.from(
        ((data['rewards'] as List?) ?? const []).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
      final redemptions = List<Map<String, dynamic>>.from(
        ((data['redemptions'] as List?) ?? const []).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
      final balance = points['balance'] ?? 0;
      return _page(
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FlipLoyaltyCard(
                balance: balance,
                loyaltyCard: Map<String, dynamic>.from(
                  (points['loyalty_card'] as Map?) ?? const {},
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final card = Map<String, dynamic>.from(
                      (points['loyalty_card'] as Map?) ?? const {},
                    );
                    final customerId = card['member_id'] ?? card['customer_id'];
                    if (customerId == null) {
                      await _toast(
                        context,
                        'ID member tidak tersedia. Coba muat ulang data.',
                        error: true,
                      );
                      return;
                    }
                    try {
                      final tier = card['loyalty_tier']?.toString() ?? 'Member';
                      await MemberCardPrinter.printCard(
                        customerId: customerId.toString(),
                        memberName:
                            card['customer_name']?.toString() ??
                            'Member Kopiers',
                        tier: tier.replaceAll('_', ' ').toUpperCase(),
                        points: balance is num
                            ? balance.toInt()
                            : int.tryParse(balance.toString()) ?? 0,
                        purchaseCount:
                            (card['purchase_count'] as num?)?.toInt() ?? 0,
                      );
                    } catch (error) {
                      await _toast(
                        context,
                        'Gagal mencetak kartu member: $error',
                        error: true,
                      );
                    }
                  },
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('Cetak kartu member'),
                ),
              ),
              const SizedBox(height: 26),
              _LoyaltySectionHeader(
                icon: Icons.card_giftcard_rounded,
                title: 'Tukar reward',
                subtitle: 'Pakai poinmu untuk hadiah spesial',
                count: '${rewards.length} reward',
              ),
              const SizedBox(height: 13),
              if (rewards.isEmpty)
                const _LoyaltyEmptyState(
                  icon: Icons.redeem_rounded,
                  title: 'Belum ada reward tersedia',
                  subtitle: 'Reward baru akan muncul di sini.',
                )
              else
                ...rewards.map(
                  (reward) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LoyaltyRewardCard(
                      reward: reward,
                      onRedeem: () => _redeem(context, reward, onChanged),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _LoyaltySectionHeader(
                icon: Icons.confirmation_number_rounded,
                title: 'Kode klaim reward',
                subtitle: 'Tunjukkan kode kepada admin saat mengambil hadiah',
                count: '${redemptions.length} kode',
              ),
              const SizedBox(height: 13),
              if (redemptions.isEmpty)
                const _LoyaltyEmptyState(
                  icon: Icons.qr_code_2_rounded,
                  title: 'Belum ada kode klaim',
                  subtitle: 'Kode akan tampil setelah kamu menukar reward.',
                )
              else
                ...redemptions.map(
                  (redemption) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LoyaltyRedemptionCard(redemption: redemption),
                  ),
                ),
              const SizedBox(height: 16),
              _LoyaltySectionHeader(
                icon: Icons.history_rounded,
                title: 'Riwayat poin',
                subtitle: 'Pantau perolehan dan penggunaan poinmu',
                count: '${history.length} aktivitas',
              ),
              const SizedBox(height: 13),
              if (history.isEmpty)
                const _LoyaltyEmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'Belum ada riwayat poin',
                  subtitle: 'Aktivitas poinmu akan tercatat di sini.',
                )
              else
                ...history.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LoyaltyHistoryCard(entry: entry),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _FlipLoyaltyCard extends StatefulWidget {
  const _FlipLoyaltyCard({required this.balance, required this.loyaltyCard});
  final dynamic balance;
  final Map<String, dynamic> loyaltyCard;
  @override
  State<_FlipLoyaltyCard> createState() => _FlipLoyaltyCardState();
}

class _FlipLoyaltyCardState extends State<_FlipLoyaltyCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  bool _showBack = false;
  static const Color _red = Color(0xFFE00000);
  static const Color _darkRed = Color(0xFF780000);
  static const Color _coffee = Color(0xFF482B22);
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _rotation = Tween<double>(begin: 0, end: 3.141592653589793).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    setState(() => _showBack = !_showBack);
    if (_showBack) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  int _toInt(dynamic value, [int fallback = 0]) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.loyaltyCard;
    final totalPurchases = _toInt(
      card['purchase_count'] ?? card['completed_transactions'],
    );
    const target = 10;
    final cyclePurchases = totalPurchases > 0 && totalPurchases % target == 0
        ? target
        : totalPurchases % target;
    final progress = (cyclePurchases / target).clamp(0.0, 1.0).toDouble();
    final remaining = _toInt(
      card['purchases_remaining'],
      (target - cyclePurchases).clamp(0, target),
    ).clamp(0, target).toInt();
    final rewardReady =
        card['reward_ready'] == true ||
        (totalPurchases > 0 && totalPurchases % target == 0);
    final rawName = card['customer_name'] ?? card['name'] ?? 'Member Kopiers';
    final memberName = rawName.toString().trim().isEmpty
        ? 'Member Kopiers'
        : rawName.toString();
    final rawId = card['member_id'] ?? card['customer_id'] ?? card['id'];
    final memberId = rawId == null
        ? 'KOP-MEMBER'
        : 'KOP-${rawId.toString().padLeft(6, '0')}';

    // Tier dibaca dari response loyalty_card yang dikirim backend.
    final rawTier =
        card['tier_name'] ??
        card['loyalty_tier'] ??
        card['loyalty_level'] ??
        card['membership_tier'] ??
        card['membership_level'] ??
        card['tier'] ??
        card['level'];
    final tierName = rawTier?.toString().trim().isNotEmpty == true
        ? rawTier.toString().trim()
        : 'Member';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _rotation,
          builder: (context, child) {
            final angle = _rotation.value;
            final showingBack = angle >= 1.5707963267948966;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(angle),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateY(showingBack ? 3.141592653589793 : 0),
                child: showingBack
                    ? _buildBack(
                        memberName: memberName,
                        memberId: memberId,
                        totalPurchases: totalPurchases,
                        cyclePurchases: cyclePurchases,
                        target: target,
                        progress: progress,
                        remaining: remaining,
                        rewardReady: rewardReady,
                      )
                    : _buildFront(
                        memberName: memberName,
                        memberId: memberId,
                        tierName: tierName,
                      ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 17,
                color: _coffee.withValues(alpha: 0.65),
              ),
              const SizedBox(width: 6),
              Text(
                _showBack
                    ? 'Ketuk kartu untuk melihat saldo poin'
                    : 'Ketuk kartu untuk melihat progres reward',
                style: TextStyle(
                  color: _coffee.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFront({
    required String memberName,
    required String memberId,
    required String tierName,
  }) {
    return GestureDetector(
      onTap: _flipCard,
      child: Container(
        key: const ValueKey('loyalty-front'),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 225),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFED1717), _darkRed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFFFFB8A8)),
          boxShadow: [
            BoxShadow(
              color: _red.withValues(alpha: 0.2),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              bottom: -38,
              child: Icon(
                Icons.coffee_rounded,
                size: 155,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.coffee_rounded,
                        color: Color(0xFFFFD66B),
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KOPIERS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'DIGITAL LOYALTY CARD',
                            style: TextStyle(
                              color: Color(0xFFFFD6D6),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD66B).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFFFD66B)
                              .withValues(alpha: 0.75),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.workspace_premium_rounded,
                            color: Color(0xFFFFD66B),
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            tierName.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFFFD66B),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 27),
                Text(
                  memberName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  memberId,
                  style: const TextStyle(
                    color: Color(0xFFFFD6D6),
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFFFD66B),
                      size: 25,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'SALDO POIN',
                      style: TextStyle(
                        color: Color(0xFFFFD6D6),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.balance}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 3),
                      child: Text(
                        'PTS',
                        style: TextStyle(
                          color: Color(0xFFFFD66B),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack({
    required String memberName,
    required String memberId,
    required int totalPurchases,
    required int cyclePurchases,
    required int target,
    required double progress,
    required int remaining,
    required bool rewardReady,
  }) {
    // Kartu stempel: 10 transaksi selesai = 1 kopi gratis.
    final stamps = List.generate(target, (index) {
      final filled = index < cyclePurchases;
      final isRewardStamp = index == target - 1;
      return Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: isRewardStamp
              ? const Color(0xFFFFD66B)
              : filled
              ? const Color(0xFFFFE0D8)
              : Colors.white.withValues(alpha: 0.96),
          shape: BoxShape.circle,
          border: Border.all(
            color: isRewardStamp
                ? const Color(0xFF8A3B22)
                : const Color(0xFFE8B9A8),
            width: isRewardStamp ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isRewardStamp
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      rewardReady
                          ? Icons.coffee_rounded
                          : Icons.card_giftcard_rounded,
                      size: 18,
                      color: const Color(0xFF7B2118),
                    ),
                    const Text(
                      'FREE',
                      style: TextStyle(
                        color: Color(0xFF7B2118),
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                )
              : filled
              ? const Icon(
                  Icons.coffee_rounded,
                  color: Color(0xFFB80000),
                  size: 22,
                )
              : const SizedBox.shrink(),
        ),
      );
    });
    return GestureDetector(
      onTap: _flipCard,
      child: Container(
        key: const ValueKey('loyalty-back'),
        width: double.infinity,
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB40D12), Color(0xFF6F090D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFFFFD66B).withValues(alpha: 0.65),
          ),
          boxShadow: [
            BoxShadow(
              color: _coffee.withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -15,
              child: Icon(
                Icons.coffee_rounded,
                size: 105,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'KUMPULKAN 10 STEMPEL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'DAPATKAN 1 GELAS KOPI GRATIS!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFD66B),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 9,
                    runSpacing: 9,
                    children: stamps,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFFFFD66B),
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '$memberName · $memberId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '$cyclePurchases/$target',
                      style: const TextStyle(
                        color: Color(0xFFFFD66B),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFD66B),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: rewardReady
                        ? const Color(0xFFFFD66B)
                        : Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD66B).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        rewardReady
                            ? Icons.check_circle_rounded
                            : Icons.local_cafe_rounded,
                        color: rewardReady
                            ? const Color(0xFF6F090D)
                            : const Color(0xFFFFD66B),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rewardReady
                              ? 'Mantap! Kamu memenuhi syarat kopi gratis.'
                              : 'Selesaikan $remaining transaksi lagi untuk kopi gratis.',
                          style: TextStyle(
                            color: rewardReady
                                ? const Color(0xFF6F090D)
                                : Colors.white,
                            fontSize: 10,
                            height: 1.35,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
  }
}

class _LoyaltySectionHeader extends StatelessWidget {
  const _LoyaltySectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.count,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String? count;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE00000), Color(0xFFB80000)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 23),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF282323),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF282323).withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count!,
              style: const TextStyle(
                color: Color(0xFFB80000),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LoyaltyRewardCard extends StatelessWidget {
  const _LoyaltyRewardCard({required this.reward, required this.onRedeem});
  final Map<String, dynamic> reward;
  final VoidCallback onRedeem;
  @override
  Widget build(BuildContext context) {
    final stock = reward['stock'];
    final cost = reward['points_cost'] ?? 0;
    final outOfStock = stock is num && stock <= 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFFFD6D6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB80000).withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE0E0), Color(0xFFFFF3F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Color(0xFFB80000),
              size: 30,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward['name']?.toString() ?? '-',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF282323),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFB80000),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$cost poin',
                      style: const TextStyle(
                        color: Color(0xFFB80000),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                if (stock != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    outOfStock ? 'Stok habis' : 'Stok tersedia: $stock',
                    style: TextStyle(
                      color: outOfStock
                          ? Colors.red.shade700
                          : const Color(0xFF77706D),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: outOfStock
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFE00000), Color(0xFFB80000)],
                    ),
              color: outOfStock ? Colors.grey.shade300 : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: FilledButton(
              onPressed: outOfStock ? null : onRedeem,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Tukar',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoyaltyRedemptionCard extends StatelessWidget {
  const _LoyaltyRedemptionCard({required this.redemption});
  final Map<String, dynamic> redemption;
  @override
  Widget build(BuildContext context) {
    final claimed = redemption['status'] == 'claimed';
    final code = redemption['redemption_code'] ?? redemption['code'] ?? '-';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD6D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: claimed
                      ? const Color(0xFFE6F5EA)
                      : const Color(0xFFFFE0E0),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  claimed
                      ? Icons.check_circle_rounded
                      : Icons.confirmation_number_rounded,
                  color: claimed
                      ? Colors.green.shade700
                      : const Color(0xFFB80000),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  redemption['reward_name']?.toString() ?? '-',
                  style: const TextStyle(
                    color: Color(0xFF282323),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: claimed
                      ? const Color(0xFFE6F5EA)
                      : const Color(0xFFFFF0D8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  claimed ? 'Selesai' : 'Belum diklaim',
                  style: TextStyle(
                    color: claimed
                        ? Colors.green.shade800
                        : const Color(0xFF8B5700),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFFFD6D6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KODE KLAIM',
                  style: TextStyle(
                    color: Color(0xFF8A7777),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  code.toString(),
                  style: const TextStyle(
                    color: Color(0xFFB80000),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${claimed ? 'Reward sudah diambil' : 'Tunjukkan kode ini kepada admin'} · ${_date(redemption['redeemed_at'])}',
            style: const TextStyle(color: Color(0xFF77706D), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _LoyaltyHistoryCard extends StatelessWidget {
  const _LoyaltyHistoryCard({required this.entry});
  final Map<String, dynamic> entry;
  @override
  Widget build(BuildContext context) {
    final value = (entry['points'] as num? ?? 0).toInt();
    final positive = value >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1E7E7)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: positive
                  ? const Color(0xFFE6F5EA)
                  : const Color(0xFFFFE8E0),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              positive ? Icons.north_east_rounded : Icons.south_west_rounded,
              color: positive ? Colors.green.shade700 : Colors.deepOrange,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['description']?.toString() ?? 'Perubahan poin',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF282323),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _date(entry['created_at']),
                  style: const TextStyle(
                    color: Color(0xFF8B7B73),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${positive ? '+' : ''}$value',
            style: TextStyle(
              color: positive ? Colors.green.shade700 : Colors.deepOrange,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoyaltyEmptyState extends StatelessWidget {
  const _LoyaltyEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD6D6)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0E0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFFB80000), size: 27),
          ),
          const SizedBox(height: 11),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF282323),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8B7B73), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

Future<void> _redeem(
  BuildContext context,
  Map<String, dynamic> reward,
  VoidCallback onChanged,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Tukar reward?'),
      content: Text(
        'Gunakan ${reward['points_cost']} poin untuk ${reward['name']}?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Tukar poin'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await _action(context, () async {
    final result = await ApiClient.instance.post(
      '/loyalty/rewards/${reward['id']}/redeem',
    );
    if (!context.mounted) return;
    final redemption = Map<String, dynamic>.from(result['redemption'] as Map);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF2E9D58)),
            SizedBox(width: 9),
            Expanded(child: Text('Reward berhasil ditukar')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tunjukkan kode ini kepada admin untuk mengambil ${redemption['reward_name']}.',
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD6D6)),
              ),
              child: SelectableText(
                (redemption['code'] ?? redemption['redemption_code'] ?? '-')
                    .toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB80000),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
    onChanged();
  });
}
