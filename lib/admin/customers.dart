part of kopiers;

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  String _search = '';
  String _accountStatus = 'all';
  String _segment = 'all';
  int _reload = 0;

  Future<dynamic> _load() => ApiClient.instance.get(
    '/customers',
    query: {
      'search': _search,
      'status': _accountStatus,
      if (_segment != 'all') 'segment': _segment,
      'page': '1',
      'limit': '100',
    },
  );

  void _refresh() => setState(() => _reload++);

  Future<void> _addCustomer() async {
    final name = await _askText(context, 'Nama pelanggan');
    if (name == null || !mounted) return;

    final phone = await _askText(context, 'Nomor telepon');
    if (phone == null || !mounted) return;

    final email = await _askText(context, 'Email (opsional)', required: false);
    if (email == null || !mounted) return;

    final password = await _askText(
      context,
      'Kata sandi awal (min. 8 karakter)',
    );
    if (password == null || !mounted) return;

    await _runAction(context, () async {
      await ApiClient.instance.post('/customers', {
        'name': name,
        'phone': phone,
        if (email.isNotEmpty) 'email': email,
        'password': password,
      });

      if (!mounted) return;
      _refresh();
      await _message(context, 'Pelanggan berhasil ditambahkan.');
    });
  }

  Future<void> _showCustomer(Map<String, dynamic> customer) async {
    final id = customer['id'];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: FutureBuilder<dynamic>(
            future: ApiClient.instance.get('/customers/$id'),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Gagal memuat detail pelanggan:\n${snapshot.error}',
                  ),
                );
              }

              final response = snapshot.data;
              if (response is! Map || response['customer'] is! Map) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Data pelanggan tidak tersedia.'),
                );
              }

              final details = Map<String, dynamic>.from(
                response['customer'] as Map,
              );
              final transactions = response['transactions'] as List? ?? [];

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: coffee,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            details['name']?.toString() ?? 'Pelanggan',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: coffee,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _customerInfo(
                      Icons.phone_rounded,
                      details['phone']?.toString() ?? '-',
                    ),
                    _customerInfo(
                      Icons.email_rounded,
                      details['email']?.toString() ?? 'Tanpa email',
                    ),
                    _customerInfo(
                      Icons.calendar_month_rounded,
                      'Bergabung ${_adminDate(details['joined_at'])}',
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _customerStat(
                            Icons.receipt_long_rounded,
                            'Transaksi',
                            '${details['transaction_count'] ?? 0}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _customerStat(
                            Icons.stars_rounded,
                            'Poin',
                            '${details['points_balance'] ?? 0}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _customerInfo(
                      Icons.payments_rounded,
                      'Total belanja: ${_adminMoney(details['lifetime_value'])}',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _runAction(context, () async {
                          await MemberCardPrinter.printCard(
                            customerId: details['id'].toString(),
                            memberName:
                                details['name']?.toString() ?? 'Pelanggan',
                            tier: details['loyalty_tier']?.toString() ?? 'none',
                            points:
                                (details['points_balance'] as num?)?.toInt() ??
                                0,
                            purchaseCount:
                                (details['transaction_count'] as num?)
                                    ?.toInt() ??
                                0,
                          );
                        }),
                        icon: const Icon(Icons.print_rounded),
                        label: const Text('Cetak kartu member'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Riwayat transaksi',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (transactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Belum ada transaksi.'),
                      ),
                    ...transactions.map((transaction) {
                      final item = Map<String, dynamic>.from(
                        transaction as Map,
                      );

                      return Card(
                        color: cream,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: coffee,
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            _adminMoney(item['total_amount']),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${_adminDate(item['created_at'])} · ${item['status'] ?? '-'}',
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _customerInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: coffee, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _customerStat(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softRed,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: coffee, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: coffee,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addCustomerButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE00404), Color(0xFFB80000)],
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
        onPressed: _addCustomer,
        tooltip: 'Tambah pelanggan',
        padding: const EdgeInsets.all(12),
        icon: const Icon(
          Icons.person_add_alt_1_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required double width,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _AdminDataPage(
    key: ValueKey('customers-$_reload-$_search-$_accountStatus-$_segment'),
    load: _load,
    builder: (context, data) {
      final rows = List<Map<String, dynamic>>.from(
        (data['data'] as List).map(
          (row) => Map<String, dynamic>.from(row as Map),
        ),
      );

      return _pagePadding(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _sectionTitle(
                    'Pelanggan',
                    '${rows.length} pelanggan ditemukan',
                  ),
                ),
                _addCustomerButton(),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama, nomor, atau email',
                prefixIcon: const Icon(Icons.search_rounded, color: coffee),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _search = value);
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _filterDropdown(
                  label: 'Status akun',
                  value: _accountStatus,
                  width: 180,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Semua status')),
                    DropdownMenuItem(value: 'active', child: Text('Aktif')),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Nonaktif'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _accountStatus = value ?? 'all';
                    });
                  },
                ),
                _filterDropdown(
                  label: 'Segmen',
                  value: _segment,
                  width: 210,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Semua segmen')),
                    DropdownMenuItem(value: 'new', child: Text('Baru')),
                    DropdownMenuItem(value: 'active', child: Text('Aktif')),
                    DropdownMenuItem(value: 'loyal', child: Text('Loyal')),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Tidak aktif'),
                    ),
                    DropdownMenuItem(
                      value: 'high_value',
                      child: Text('Nilai tinggi'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _segment = value ?? 'all';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: softRed,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.group_add_rounded,
                        color: coffee,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Pelanggan belum tersedia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tambahkan pelanggan pertama untuk mulai '
                      'mengelola data pelanggan Kopiers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _addCustomer,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Tambah pelanggan'),
                    ),
                  ],
                ),
              ),
            ...rows.map((row) {
              final isActive =
                  row['is_active'] == true || row['is_active'] == 1;
              final name = row['name']?.toString() ?? '-';
              final initial = name.trim().isNotEmpty
                  ? name.trim()[0].toUpperCase()
                  : '?';

              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  onTap: () => _showCustomer(row),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isActive
                            ? const [Color(0xFFE00404), Color(0xFFB80000)]
                            : const [Color(0xFFFFE0E0), Color(0xFFFFF5F5)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: isActive
                        ? Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Text(
                            initial,
                            style: const TextStyle(
                              color: coffee,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${row['phone'] ?? '-'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFE5F7EC)
                                    : softRed,
                                borderRadius: BorderRadius.circular(8),
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
                            Text(
                              '${row['transaction_count'] ?? 0} transaksi',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _adminMoney(row['lifetime_value']),
                              style: const TextStyle(
                                color: coffee,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Aksi pelanggan',
                    icon: const Icon(Icons.more_vert_rounded, color: coffee),
                    onSelected: (value) async {
                      if (value == 'toggle') {
                        await _runAction(context, () async {
                          await ApiClient.instance.patch(
                            '/customers/${row['id']}/status',
                            {'is_active': !isActive},
                          );
                          _refresh();
                        });
                      } else if (value == 'edit') {
                        final nameValue = await _askText(
                          context,
                          'Ubah nama',
                          initial: row['name']?.toString(),
                        );
                        if (nameValue == null || !context.mounted) {
                          return;
                        }

                        final phoneValue = await _askText(
                          context,
                          'Ubah nomor telepon',
                          initial: row['phone']?.toString(),
                        );
                        if (phoneValue == null || !context.mounted) {
                          return;
                        }

                        await _runAction(context, () async {
                          await ApiClient.instance.patch(
                            '/customers/${row['id']}',
                            {'name': nameValue, 'phone': phoneValue},
                          );
                          _refresh();
                        });
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, color: coffee, size: 20),
                            SizedBox(width: 10),
                            Text('Ubah profil'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              isActive
                                  ? Icons.person_off_rounded
                                  : Icons.person_rounded,
                              color: isActive ? darkCoffee : coffee,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );
    },
  );
}
