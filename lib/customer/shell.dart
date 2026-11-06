part of kopiers;

const _customerTitles = [
  '',
  '',
  '',
  '',
  '',
  '',
];
const _customerIcons = [
  Icons.home_outlined,
  Icons.receipt_long_outlined,
  Icons.stars_outlined,
  Icons.local_offer_outlined,
  Icons.support_agent_outlined,
  Icons.person_outline,
];

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key, required this.user, required this.onSignOut});
  final Map<String, dynamic> user;
  final Future<void> Function() onSignOut;
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        user: widget.user,
        onOpenPoints: () => setState(() => _index = 2),
      ),
      const TransactionPage(),
      LoyaltyCustomerPage(
        key: ValueKey('loyalty-$_reload'),
        onChanged: () => setState(() => _reload++),
      ),
      const PromoPage(),
      CustomerComplaintsPage(
        key: ValueKey('complaints-$_reload'),
        onChanged: () => setState(() => _reload++),
      ),
      AccountPage(
        key: ValueKey('account-$_reload'),
        user: widget.user,
        onSignOut: widget.onSignOut,
        onChanged: () => setState(() => _reload++),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _customerTitles[_index].isEmpty
              ? 'Beranda'
              : _customerTitles[_index],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: List.generate(
          _customerTitles.length,
          (index) => NavigationDestination(
            icon: Icon(_customerIcons[index]),
            label: _customerTitles[index],
          ),
        ),
      ),
    );
  }
}
