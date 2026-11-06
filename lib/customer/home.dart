part of kopiers;

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.user, required this.onOpenPoints});

  final Map<String, dynamic> user;

  final VoidCallback onOpenPoints;

  static const Color coffee = Color(0xFF4B241C);

  static const Color red = Color(0xFFB92525);

  static const Color cream = Color(0xFFFFF8F0);

  static const Color muted = Color(0xFF8B7B73);

  @override
  Widget build(BuildContext context) {
    return _CustomerDataPage(
      load: () async {
        final results = await Future.wait([
          ApiClient.instance.get('/customers/me'),

          ApiClient.instance.get('/campaigns'),

          ApiClient.instance.get('/products'),
        ]);

        return {
          'customer': results[0]['customer'],

          'campaigns': results[1]['data'],

          'products': results[2]['data'],
        };
      },

      builder: (context, data) {
        final customer = Map<String, dynamic>.from(data['customer'] as Map);

        final campaigns = List<Map<String, dynamic>>.from(
          (data['campaigns'] as List).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );

        final products = List<Map<String, dynamic>>.from(
          (data['products'] as List).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );

        final name =
            customer['name']?.toString() ??
            user['name']?.toString() ??
            'Sobat Kopiers';

        return _page(
          Container(
            color: cream,

            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // HEADER LOGO KOPIERS
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/logo_kopiers.png',
                        width: 180,
                        height: 55,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your daily coffee partner',
                        style: TextStyle(
                          fontSize: 11,
                          color: muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // HERO CUSTOMER
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(22),

                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [red, Color(0xFF791B1B)],

                        begin: Alignment.topLeft,

                        end: Alignment.bottomRight,
                      ),

                      borderRadius: BorderRadius.circular(26),

                      boxShadow: [
                        BoxShadow(
                          color: red.withValues(alpha: 0.20),

                          blurRadius: 20,

                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),

                    child: Stack(
                      children: [
                        Positioned(
                          right: -15,

                          top: -15,

                          child: Icon(
                            Icons.coffee_rounded,

                            size: 125,

                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Text(
                              'PART OF KOPIERS',

                              style: TextStyle(
                                color: Color(0xFFFFD9B8),

                                fontSize: 11,

                                fontWeight: FontWeight.bold,

                                letterSpacing: 2,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Hai, $name 👋',

                              maxLines: 1,

                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                color: Colors.white,

                                fontSize: 24,

                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 7),

                            const Text(
                              'Nikmati harimu dengan kopi favoritmu.',

                              style: TextStyle(
                                color: Color(0xFFFFE8DC),

                                fontSize: 13,

                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 23),

                            Container(
                              padding: const EdgeInsets.all(14),

                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.13),

                                borderRadius: BorderRadius.circular(18),

                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),

                              child: Row(
                                children: [
                                  Container(
                                    width: 46,

                                    height: 46,

                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD66B),

                                      borderRadius: BorderRadius.circular(14),
                                    ),

                                    child: const Icon(
                                      Icons.stars_rounded,

                                      color: coffee,

                                      size: 29,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        const Text(
                                          'Poin kamu',

                                          style: TextStyle(
                                            color: Color(0xFFFFE8DC),

                                            fontSize: 12,
                                          ),
                                        ),

                                        Text(
                                          '${customer['points_balance'] ?? 0} poin',

                                          style: const TextStyle(
                                            color: Colors.white,

                                            fontSize: 21,

                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  FilledButton(
                                    onPressed: onOpenPoints,

                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white,

                                      foregroundColor: red,
                                    ),

                                    child: const Text(
                                      'Tukar',

                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
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

                  const SizedBox(height: 18),

                  // DIGITAL LOYALTY CARD
                  _LoyaltyCard(name: name, customer: customer),

                  const SizedBox(height: 28),

                  // JUDUL MENU
                  _heading(
                    Icons.local_cafe_rounded,

                    'Menu Kopiers',

                    'Temukan minuman favoritmu.',
                  ),

                  const SizedBox(height: 16),

                  if (products.isEmpty)
                    _empty(
                      Icons.coffee_outlined,

                      'Menu belum tersedia',

                      'Nantikan menu favoritmu di sini.',
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 650 ? 3 : 2;

                        return GridView.builder(
                          shrinkWrap: true,

                          physics: const NeverScrollableScrollPhysics(),

                          itemCount: products.length,

                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,

                                crossAxisSpacing: 12,

                                mainAxisSpacing: 12,

                                mainAxisExtent: 258,
                              ),

                          itemBuilder: (context, index) {
                            return _AnimatedMenuCard(
                              key: ValueKey(products[index]['id'] ?? index),

                              product: products[index],

                              index: index,
                            );
                          },
                        );
                      },
                    ),

                  const SizedBox(height: 30),

                  // JUDUL PROMO
                  _heading(
                    Icons.local_offer_rounded,

                    'Promo untukmu',

                    'Penawaran menarik dari Kopiers.',
                  ),

                  const SizedBox(height: 16),

                  if (campaigns.isEmpty)
                    _empty(
                      Icons.sell_outlined,

                      'Belum ada promo',

                      'Pantau terus promo terbaru Kopiers.',
                    )
                  else
                    SizedBox(
                      height: 160,

                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,

                        itemCount: campaigns.length,

                        separatorBuilder: (_, __) => const SizedBox(width: 12),

                        itemBuilder: (context, index) {
                          return _PromoCard(
                            campaign: campaigns[index],

                            index: index,
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 26),

                  // FOOTER
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(19),

                    decoration: BoxDecoration(
                      color: coffee,

                      borderRadius: BorderRadius.circular(22),
                    ),

                    child: const Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,

                          color: Color(0xFFFFD66B),

                          size: 27,
                        ),

                        SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                'Brew your happiness.',

                                style: TextStyle(
                                  color: Colors.white,

                                  fontSize: 15,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 5),

                              Text(
                                'Satu tegukan, banyak cerita.',

                                style: TextStyle(
                                  color: Color(0xFFE9DBCA),

                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _heading(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 44,

          height: 44,

          decoration: BoxDecoration(
            color: const Color(0xFFF1DFD0),

            borderRadius: BorderRadius.circular(14),
          ),

          child: Icon(icon, color: coffee, size: 24),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: const TextStyle(
                  fontSize: 19,

                  fontWeight: FontWeight.w900,

                  color: coffee,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,

                style: const TextStyle(fontSize: 11, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _empty(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: const Color(0xFFF0E4DB)),
      ),

      child: Column(
        children: [
          Icon(icon, color: coffee, size: 42),

          const SizedBox(height: 10),

          Text(
            title,

            style: const TextStyle(color: coffee, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,

            textAlign: TextAlign.center,

            style: const TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ======================================================

// ======================================================
// DIGITAL LOYALTY CARD
// ======================================================

class _LoyaltyCard extends StatelessWidget {
  const _LoyaltyCard({required this.name, required this.customer});
  final String name;
  final Map<String, dynamic> customer;

  @override
  Widget build(BuildContext context) {
    final points = int.tryParse('${customer['points_balance'] ?? 0}') ?? 0;
    final transactionCount =
        int.tryParse('${customer['transaction_count'] ?? 0}') ?? 0;
    final rawId = customer['id'] ?? customer['customer_id'];
    final memberId = rawId == null
        ? 'KOP-MEMBER'
        : 'KOP-${rawId.toString().padLeft(6, '0')}';
    final calculatedTier = transactionCount >= 20
        ? 'platinum'
        : transactionCount >= 10
        ? 'gold'
        : transactionCount >= 5
        ? 'silver'
        : transactionCount >= 1
        ? 'bronze'
        : 'none';
    final tierKey =
        customer['loyalty_tier']?.toString().toLowerCase() ?? calculatedTier;
    final tier = switch (tierKey) {
      'platinum' => 'Platinum',
      'gold' => 'Gold',
      'silver' => 'Silver',
      'bronze' => 'Bronze',
      _ => 'Belum Loyal',
    };
    final previous = switch (tierKey) {
      'platinum' => 20,
      'gold' => 10,
      'silver' => 5,
      'bronze' => 1,
      _ => 0,
    };
    final next = switch (tierKey) {
      'platinum' => 20,
      'gold' => 20,
      'silver' => 10,
      'bronze' => 5,
      _ => 1,
    };
    final progress = tierKey == 'platinum'
        ? 1.0
        : ((transactionCount - previous) / (next - previous))
              .clamp(0.0, 1.0)
              .toDouble();
    final remaining = (next - transactionCount).clamp(0, next);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD20B16), Color(0xFF850B12), Color(0xFF5E080D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFD5B4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: coffee.withValues(alpha: 0.20),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                bottom: -24,
                child: Icon(
                  Icons.coffee_rounded,
                  size: 145,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'kopiers',
                              style: TextStyle(
                                color: Color(0xFFFFF4E6),
                                fontSize: 37,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.8,
                                fontFamily: 'Georgia',
                              ),
                            ),
                            SizedBox(height: 7),
                            Text(
                              'D I G I T A L   L O Y A L T Y   C A R D',
                              style: TextStyle(
                                color: Color(0xD9FFFFFF),
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFE69A), Color(0xFFE5A82A)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFF6C250B),
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              tierKey == 'none' ? tier : '$tier Member',
                              style: const TextStyle(
                                color: Color(0xFF6C250B),
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 27),
                  Text(
                    'NAMA MEMBER',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 17),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MEMBER ID',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              memberId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'TOTAL POIN',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 10,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                points.toString(),
                                style: const TextStyle(
                                  color: Color(0xFFFFE4B2),
                                  fontSize: 30,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 2),
                                child: Text(
                                  'pts',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0E0D2)),
            boxShadow: [
              BoxShadow(
                color: coffee.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Progress loyalty kamu',
                      style: TextStyle(
                        color: coffee,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    tierKey == 'platinum'
                        ? 'Level tertinggi!'
                        : '$remaining transaksi lagi',
                    style: const TextStyle(
                      color: coffee,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  backgroundColor: const Color(0xFFF0E8E2),
                  valueColor: const AlwaysStoppedAnimation<Color>(coffee),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _LoyaltyTierLabel(
                    label: 'Bronze',
                    active: tierKey == 'bronze',
                    color: const Color(0xFF9B5B2A),
                  ),
                  _LoyaltyTierLabel(
                    label: 'Silver',
                    active: tierKey == 'silver',
                    color: const Color(0xFF8C969F),
                  ),
                  _LoyaltyTierLabel(
                    label: 'Gold',
                    active: tierKey == 'gold',
                    color: const Color(0xFFD99A13),
                  ),
                  _LoyaltyTierLabel(
                    label: 'Platinum',
                    active: tierKey == 'platinum',
                    color: const Color(0xFF697786),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tier dihitung dari transaksi selesai: Bronze 1+, Silver 5+, Gold 10+, Platinum 20+.',
                style: TextStyle(
                  color: coffee.withValues(alpha: 0.9),
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoyaltyTierLabel extends StatelessWidget {
  const _LoyaltyTierLabel({
    required this.label,
    required this.active,
    required this.color,
  });
  final String label;
  final bool active;
  final Color color;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: active ? 1 : 0.55,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.workspace_premium_rounded, size: 15, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: active ? color : coffee,
            fontSize: 9,
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// KARTU MENU DENGAN ANIMASI

// ======================================================

class _AnimatedMenuCard extends StatefulWidget {
  const _AnimatedMenuCard({
    super.key,

    required this.product,

    required this.index,
  });

  final Map<String, dynamic> product;

  final int index;

  @override
  State<_AnimatedMenuCard> createState() => _AnimatedMenuCardState();
}

class _AnimatedMenuCardState extends State<_AnimatedMenuCard> {
  bool _pressed = false;

  static const Color coffee = Color(0xFF4B241C);

  static const Color red = Color(0xFFB92525);

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final name = product['name']?.toString() ?? 'Menu Kopiers';

    final description =
        product['description']?.toString() ?? 'Kopi pilihan Kopiers.';

    final price = _money(product['price']);

    return TweenAnimationBuilder<double>(
      key: ValueKey('animation-${product['id'] ?? widget.index}'),

      tween: Tween<double>(begin: 0, end: 1),

      duration: Duration(milliseconds: 350 + (widget.index.clamp(0, 8) * 60)),

      curve: Curves.easeOutCubic,

      builder: (context, value, child) {
        return Opacity(
          opacity: value,

          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),

            child: Transform.scale(scale: 0.94 + (0.06 * value), child: child),
          ),
        );
      },

      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,

        duration: const Duration(milliseconds: 140),

        curve: Curves.easeOut,

        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),

          onTapUp: (_) => setState(() => _pressed = false),

          onTapCancel: () => setState(() => _pressed = false),

          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(22),

              border: Border.all(color: const Color(0xFFF1E7DF)),

              boxShadow: [
                BoxShadow(
                  color: coffee.withValues(alpha: 0.07),

                  blurRadius: 12,

                  offset: const Offset(0, 5),
                ),
              ],
            ),

            clipBehavior: Clip.antiAlias,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Expanded(
                  flex: 5,

                  child: Stack(
                    fit: StackFit.expand,

                    children: [
                      _MenuProductImage(
                        imageUrl: product['image_url']?.toString(),
                      ),

                      Positioned(
                        top: 9,

                        left: 9,

                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,

                            vertical: 6,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),

                            borderRadius: BorderRadius.circular(9),
                          ),

                          child: const Row(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              Icon(Icons.coffee_rounded, color: red, size: 12),

                              SizedBox(width: 4),

                              Text(
                                'KOPIERS',

                                style: TextStyle(
                                  fontSize: 8,

                                  color: coffee,

                                  fontWeight: FontWeight.w900,

                                  letterSpacing: 0.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  flex: 4,

                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          name,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            color: coffee,

                            fontWeight: FontWeight.w800,

                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Expanded(
                          child: Text(
                            description,

                            maxLines: 2,

                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              color: Color(0xFF8B7B73),

                              fontSize: 10,

                              height: 1.3,
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                price,

                                maxLines: 1,

                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  color: red,

                                  fontWeight: FontWeight.w900,

                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}

// ======================================================

// FOTO PRODUK

// ======================================================

class _MenuProductImage extends StatefulWidget {
  const _MenuProductImage({this.imageUrl});

  final String? imageUrl;

  @override
  State<_MenuProductImage> createState() => _MenuProductImageState();
}

class _MenuProductImageState extends State<_MenuProductImage> {
  late Future<dynamic>? _imageFuture;

  @override
  void initState() {
    super.initState();

    _loadImage();
  }

  @override
  void didUpdateWidget(covariant _MenuProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  void _loadImage() {
    final url = widget.imageUrl;

    _imageFuture = url == null || url.isEmpty
        ? null
        : ApiClient.instance.getBytes(url);
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,

      height: double.infinity,

      color: const Color(0xFFF2E4D6),

      alignment: Alignment.center,

      child: const Icon(
        Icons.local_cafe_rounded,

        color: Color(0xFF8B6553),

        size: 46,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_imageFuture == null) {
      return _placeholder();
    }

    return FutureBuilder<dynamic>(
      future: _imageFuture,

      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return _placeholder();
        }

        return Image.memory(
          snapshot.data!,

          width: double.infinity,

          height: double.infinity,

          fit: BoxFit.cover,

          errorBuilder: (_, __, ___) => _placeholder(),
        );
      },
    );
  }
}

// ======================================================

// BANNER PROMO

// ======================================================

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.campaign, required this.index});

  final Map<String, dynamic> campaign;

  final int index;

  @override
  Widget build(BuildContext context) {
    const coffee = Color(0xFF4B241C);

    const red = Color(0xFFB92525);

    final name = campaign['name']?.toString() ?? 'Promo Kopiers';

    final description =
        campaign['description']?.toString() ??
        'Nikmati penawaran spesial dari Kopiers.';

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),

      duration: Duration(milliseconds: 400 + (index.clamp(0, 8) * 80)),

      curve: Curves.easeOutCubic,

      builder: (context, value, child) {
        return Opacity(
          opacity: value,

          child: Transform.translate(
            offset: Offset(16 * (1 - value), 0),

            child: child,
          ),
        );
      },

      child: Container(
        width: 285,

        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: index.isEven
                ? [coffee, const Color(0xFF754532)]
                : [red, const Color(0xFF7E1B1B)],

            begin: Alignment.topLeft,

            end: Alignment.bottomRight,
          ),

          borderRadius: BorderRadius.circular(22),

          boxShadow: [
            BoxShadow(
              color: coffee.withValues(alpha: 0.10),

              blurRadius: 12,

              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: Stack(
          children: [
            Positioned(
              right: -8,

              bottom: -16,

              child: Icon(
                Icons.local_offer_rounded,

                size: 90,

                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.local_offer_rounded,

                      color: Color(0xFFFFD66B),

                      size: 17,
                    ),

                    SizedBox(width: 7),

                    Text(
                      'SPECIAL OFFER',

                      style: TextStyle(
                        color: Color(0xFFFFDDBB),

                        fontSize: 10,

                        fontWeight: FontWeight.bold,

                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  name,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 17,

                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 5),

                Expanded(
                  child: Text(
                    description,

                    maxLines: 2,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: Color(0xFFFFE8DC),

                      fontSize: 11,

                      height: 1.4,
                    ),
                  ),
                ),

                Text(
                  'Berakhir ${_date(campaign['ends_at'])}',

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Color(0xFFFFD66B),

                    fontSize: 10,

                    fontWeight: FontWeight.w700,
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
