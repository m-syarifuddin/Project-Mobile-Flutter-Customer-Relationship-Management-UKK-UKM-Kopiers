part of kopiers;

// ==========================================

// ADMIN NAVIGATION

// ==========================================

const _adminTitles = [

  'Dashboard',

  'Pelanggan',

  'Segmentasi',

  'Keluhan',

  'Lainnya',

];

const _adminIcons = [

  Icons.space_dashboard_outlined,

  Icons.people_outline,

  Icons.donut_small_outlined,

  Icons.support_agent_outlined,

  Icons.more_horiz,

];

// ==========================================

// ADMIN SHELL

// ==========================================

class AdminShell extends StatefulWidget {

  const AdminShell({

    super.key,

    required this.user,

    required this.onSignOut,

    required this.onUserUpdated,

  });

  final Map<String, dynamic> user;

  final Future<void> Function() onSignOut;

  final ValueChanged<Map<String, dynamic>> onUserUpdated;

  @override

  State<AdminShell> createState() => _AdminShellState();

}

class _AdminShellState extends State<AdminShell> {

  int _index = 0;

  String _section = 'Dashboard';

  void _select(String section) {

    if (!mounted) return;

    setState(() {

      _section = section;

      switch (section) {

        case 'Dashboard':

          _index = 0;

          break;

        case 'Pelanggan':

          _index = 1;

          break;

        case 'Segmentasi':

          _index = 2;

          break;

        case 'Keluhan':

          _index = 3;

          break;

        default:

          _index = 4;

          break;

      }

    });

    debugPrint('Admin membuka menu: $section');

  }

  Widget _page() {

    switch (_section) {

      case 'Dashboard':

        return const DashboardPage();

      case 'Pelanggan':

        return const CustomersPage();

      case 'Segmentasi':

        return const SegmentsPage();

      case 'Keluhan':

        return const ComplaintsPage();

      case 'Loyalitas':

        return const LoyaltyPage();

      case 'Promo':

        return const CampaignsPage();

      case 'Transaksi':

        return const TransactionsPage();

      case 'Produk':

        return const ProductsPage();
      case 'Pengaturan & Profil':

        return ProfilePage(

          user: widget.user,

          onSignOut: widget.onSignOut,

          onUserUpdated: widget.onUserUpdated,

        );

      case 'Lainnya':

      default:

        return MorePage(onSelect: _select);

    }

  }

  @override

  Widget build(BuildContext context) {

    return LayoutBuilder(

      builder: (context, constraints) {

        final wide = constraints.maxWidth >= 900;

        return Scaffold(

          appBar: AppBar(

            title: Text(_section),

            actions: [

              Padding(

                padding: const EdgeInsets.only(right: 18),

                child: Center(

                  child: Text(

                    widget.user['name']?.toString() ?? 'Admin',

                    style: const TextStyle(

                      fontWeight: FontWeight.w600,

                    ),

                  ),

                ),

              ),

            ],

          ),

          body: Row(

            children: [

              if (wide)

                NavigationRail(

                  selectedIndex: _index,

                  onDestinationSelected: (index) {

                    _select(_adminTitles[index]);

                  },

                  labelType: NavigationRailLabelType.all,

                  destinations: List.generate(

                    _adminTitles.length,

                    (index) => NavigationRailDestination(

                      icon: Icon(_adminIcons[index]),

                      selectedIcon: Icon(_adminIcons[index]),

                      label: Text(_adminTitles[index]),

                    ),

                  ),

                ),

              Expanded(child: _page()),

            ],

          ),

          bottomNavigationBar: wide

              ? null

              : NavigationBar(

                  selectedIndex: _index,

                  onDestinationSelected: (index) {

                    _select(_adminTitles[index]);

                  },

                  labelBehavior:

                      NavigationDestinationLabelBehavior.alwaysHide,

                  destinations: List.generate(

                    _adminTitles.length,

                    (index) => NavigationDestination(

                      icon: Icon(_adminIcons[index], size: 25),

                      selectedIcon: Icon(_adminIcons[index], size: 28),

                      label: _adminTitles[index],

                    ),

                  ),

                ),

        );

      },

    );

  }

}

// ==========================================

// MENU LAINNYA

// ==========================================

class MorePage extends StatelessWidget {

  const MorePage({

    super.key,

    required this.onSelect,

  });

  final ValueChanged<String> onSelect;

  @override

  Widget build(BuildContext context) {

    return ListView(

      padding: const EdgeInsets.all(20),

      children: [

        const Text(

          'Operasional CRM',

          style: TextStyle(

            fontSize: 22,

            fontWeight: FontWeight.bold,

          ),

        ),

        const SizedBox(height: 12),

        _MoreTile(

          icon: Icons.point_of_sale_outlined,

          title: 'Transaksi & Kasir',

          onTap: () => onSelect('Transaksi'),

        ),
        _MoreTile(

          icon: Icons.local_cafe_outlined,

          title: 'Produk & Menu',

          onTap: () => onSelect('Produk'),

        ),

        _MoreTile(

          icon: Icons.card_giftcard,

          title: 'Loyalitas & Reward',

          onTap: () => onSelect('Loyalitas'),

        ),

        _MoreTile(

          icon: Icons.campaign_outlined,

          title: 'Promo',

          onTap: () => onSelect('Promo'),

        ),

        _MoreTile(

          icon: Icons.person_outline,

          title: 'Pengaturan & Profil',

          onTap: () => onSelect('Pengaturan & Profil'),

        ),

      ],

    );

  }

}

class _MoreTile extends StatelessWidget {

  const _MoreTile({

    required this.icon,

    required this.title,

    required this.onTap,

  });

  final IconData icon;

  final String title;

  final VoidCallback onTap;

  @override

  Widget build(BuildContext context) {

    return Card(

      child: ListTile(

        leading: Icon(icon, color: coffee),

        title: Text(title),

        trailing: const Icon(Icons.chevron_right),

        onTap: onTap,

      ),

    );

  }

}