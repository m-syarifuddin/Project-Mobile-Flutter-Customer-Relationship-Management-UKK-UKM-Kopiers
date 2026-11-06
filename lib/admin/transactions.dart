

part of kopiers;

class TransactionsPage extends StatefulWidget {

  const TransactionsPage({super.key});

  @override

  State<TransactionsPage> createState() => _TransactionsPageState();

}

class _TransactionsPageState extends State<TransactionsPage> {

  int _reload = 0;

  Widget _gradientIcon(IconData icon) {

    return Container(

      padding: const EdgeInsets.all(12),

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

            color: coffee.withValues(alpha: 0.18),

            blurRadius: 7,

            offset: const Offset(0, 3),

          ),

        ],

      ),

      child: Icon(

        icon,

        color: Colors.white,

        size: 25,

      ),

    );

  }

  Widget _createTransactionButton() {

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

        onPressed: _createTransaction,

        tooltip: 'Catat transaksi',

        padding: const EdgeInsets.all(12),

        icon: const Icon(

          Icons.add_shopping_cart_rounded,

          color: Colors.white,

          size: 25,

        ),

      ),

    );

  }

  @override

  Widget build(BuildContext context) => _AdminDataPage(

        key: ValueKey('transactions-$_reload'),

        load: () => ApiClient.instance.get(

          '/transactions',

          query: {'page': '1', 'limit': '100'},

        ),

        builder: (context, data) {

          final transactions = List<Map<String, dynamic>>.from(

            (data['data'] as List).map(

              (item) => Map<String, dynamic>.from(item as Map),

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

                        'Transaksi & kasir',

                        '${transactions.length} transaksi terbaru',

                      ),

                    ),

                    _createTransactionButton(),

                  ],

                ),

                const SizedBox(height: 14),

                // Ringkasan transaksi

                Container(

                  width: double.infinity,

                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(

                    gradient: const LinearGradient(

                      colors: [

                        Color(0xFFE00404),

                        Color(0xFFB80000),

                      ],

                      begin: Alignment.topLeft,

                      end: Alignment.bottomRight,

                    ),

                    borderRadius: BorderRadius.circular(20),

                    boxShadow: [

                      BoxShadow(

                        color: coffee.withValues(alpha: 0.16),

                        blurRadius: 10,

                        offset: const Offset(0, 4),

                      ),

                    ],

                  ),

                  child: Row(

                    children: [

                      Container(

                        padding: const EdgeInsets.all(13),

                        decoration: BoxDecoration(

                          color: Colors.white.withValues(alpha: 0.18),

                          borderRadius: BorderRadius.circular(15),

                        ),

                        child: const Icon(

                          Icons.point_of_sale_rounded,

                          color: Colors.white,

                          size: 30,

                        ),

                      ),

                      const SizedBox(width: 14),

                      Expanded(

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            const Text(

                              'Kasir Kopiers',

                              style: TextStyle(

                                color: Colors.white,

                                fontWeight: FontWeight.bold,

                                fontSize: 18,

                              ),

                            ),

                            const SizedBox(height: 5),

                            Text(

                              '${transactions.length} transaksi tercatat',

                              style: const TextStyle(

                                color: Colors.white70,

                                fontSize: 13,

                              ),

                            ),

                          ],

                        ),

                      ),

                      const Icon(

                        Icons.receipt_long_rounded,

                        color: Colors.white,

                        size: 28,

                      ),

                    ],

                  ),

                ),

                const SizedBox(height: 16),

                if (transactions.isEmpty)

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

                        _gradientIcon(Icons.receipt_long_rounded),

                        const SizedBox(height: 14),

                        const Text(

                          'Belum ada transaksi',

                          style: TextStyle(

                            fontWeight: FontWeight.bold,

                            fontSize: 16,

                          ),

                        ),

                        const SizedBox(height: 6),

                        Text(

                          'Catat transaksi pertama untuk mulai '

                          'mencatat penjualan Kopiers.',

                          textAlign: TextAlign.center,

                          style: TextStyle(

                            color: Colors.grey.shade600,

                          ),

                        ),

                        const SizedBox(height: 16),

                        FilledButton.icon(

                          onPressed: _createTransaction,

                          icon: const Icon(

                            Icons.add_shopping_cart_rounded,

                            color: Colors.white,

                          ),

                          label: const Text('Catat transaksi'),

                        ),

                      ],

                    ),

                  ),

                ...transactions.map((transaction) {

                  final status =

                      transaction['status']?.toString() ?? '-';

                  final isCompleted = [

                    'completed',

                    'paid',

                    'success',

                  ].contains(status.toLowerCase());

                  return Card(

                    clipBehavior: Clip.antiAlias,

                    child: ListTile(

                      contentPadding: const EdgeInsets.symmetric(

                        horizontal: 14,

                        vertical: 8,

                      ),

                      leading: _gradientIcon(

                        Icons.receipt_long_rounded,

                      ),

                      title: Text(

                        transaction['customer_name']?.toString() ??

                            'Customer',

                        style: const TextStyle(

                          fontWeight: FontWeight.bold,

                          fontSize: 15,

                        ),

                      ),

                      subtitle: Padding(

                        padding: const EdgeInsets.only(top: 7),

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            Row(

                              children: [

                                Icon(

                                  Icons.calendar_today_rounded,

                                  size: 13,

                                  color: Colors.grey.shade600,

                                ),

                                const SizedBox(width: 5),

                                Expanded(

                                  child: Text(

                                    _adminDate(transaction['created_at']),

                                    style: TextStyle(

                                      color: Colors.grey.shade600,

                                      fontSize: 12,

                                    ),

                                  ),

                                ),

                              ],

                            ),

                            const SizedBox(height: 6),

                            Container(

                              padding: const EdgeInsets.symmetric(

                                horizontal: 9,

                                vertical: 4,

                              ),

                              decoration: BoxDecoration(

                                color: isCompleted

                                    ? const Color(0xFFE5F7EC)

                                    : softRed,

                                borderRadius: BorderRadius.circular(8),

                              ),

                              child: Text(

                                status,

                                style: TextStyle(

                                  color: isCompleted

                                      ? const Color(0xFF197344)

                                      : darkCoffee,

                                  fontWeight: FontWeight.w600,

                                  fontSize: 11,

                                ),

                              ),

                            ),

                          ],

                        ),

                      ),

                      trailing: Text(

                        _adminMoney(transaction['total_amount']),

                        style: const TextStyle(

                          color: coffee,

                          fontWeight: FontWeight.bold,

                          fontSize: 13,

                        ),

                      ),

                    ),

                  );

                }),

              ],

            ),

          );

        },

      );

  Future<void> _createTransaction() async {

    await _runAction(context, () async {

      final data = await Future.wait([

        ApiClient.instance.get(

          '/customers',

          query: {

            'status': 'active',

            'page': '1',

            'limit': '100',

          },

        ),

        ApiClient.instance.get('/products'),

      ]);

      if (!mounted) return;

      final customers = List<Map<String, dynamic>>.from(

        (data[0]['data'] as List).map(

          (item) => Map<String, dynamic>.from(item as Map),

        ),

      );

      final products = List<Map<String, dynamic>>.from(

        (data[1]['data'] as List).map(

          (item) => Map<String, dynamic>.from(item as Map),

        ),

      );

      if (customers.isEmpty || products.isEmpty) {

        await _message(

          context,

          'Tambahkan minimal satu customer dan satu produk '

          'sebelum mencatat transaksi.',

          error: true,

        );

        return;

      }

      await showDialog<void>(

        context: context,

        builder: (dialogContext) => _SaleDialog(

          customers: customers,

          products: products,

          onSubmit: (customerId, items, voucherCode) async {

            final messenger = ScaffoldMessenger.maybeOf(context);

            final response = await ApiClient.instance.post(

              '/transactions',

              {

                'customer_id': customerId,

                'items': items,

                if (voucherCode.isNotEmpty)

                  'voucher_code': voucherCode,

              },

            );

            if (!mounted || !dialogContext.mounted) return;

            Navigator.pop(dialogContext);

            setState(() => _reload++);

            messenger?.showSnackBar(

              SnackBar(

                content: Text(

                  'Transaksi ${_adminMoney(response['total_amount'])} '

                  'dicatat; ${response['points_earned']} poin diberikan.',

                ),

                backgroundColor: coffee,

                behavior: SnackBarBehavior.floating,

              ),

            );

          },

        ),

      );

    });

  }

}

class _SaleDialog extends StatefulWidget {

  const _SaleDialog({

    required this.customers,

    required this.products,

    required this.onSubmit,

  });

  final List<Map<String, dynamic>> customers;

  final List<Map<String, dynamic>> products;

  final Future<void> Function(

    int customerId,

    List<Map<String, int>> items,

    String voucherCode,

  ) onSubmit;

  @override

  State<_SaleDialog> createState() => _SaleDialogState();

}

class _SaleDialogState extends State<_SaleDialog> {

  int? _customerId;

  int? _productId;

  int _quantity = 1;

  String _voucherCode = '';

  final TextEditingController _voucherController = TextEditingController();

  final List<Map<String, int>> _items = [];

  bool _saving = false;

  Widget _dialogIcon(IconData icon) {

    return Container(

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(

        gradient: const LinearGradient(

          colors: [

            Color(0xFFE00404),

            Color(0xFFB80000),

          ],

        ),

        borderRadius: BorderRadius.circular(12),

      ),

      child: Icon(

        icon,

        color: Colors.white,

        size: 24,

      ),

    );

  }

  Future<void> _scanVoucher() async {

    if (_customerId == null) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Pilih pelanggan terlebih dahulu.')),

      );

      return;

    }

    final code = await showDialog<String>(

      context: context,

      builder: (_) => const _VoucherQrScannerDialog(),

    );

    if (code == null || code.trim().isEmpty || !mounted) return;

    try {

      final result = await ApiClient.instance.validateVoucher(code.trim());

      if (!mounted) return;

      final voucher = result['voucher'] is Map

          ? Map<String, dynamic>.from(result['voucher'] as Map)

          : <String, dynamic>{};

      final voucherCustomerId =

          int.tryParse('${voucher['customer_id'] ?? ''}');

      if (result['valid'] != true) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text(result['message']?.toString() ??

                'Voucher tidak valid atau sudah digunakan.'),

            backgroundColor: Colors.red,

          ),

        );

        return;

      }

      if (voucherCustomerId != null && voucherCustomerId != _customerId) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(

            content: Text('Voucher bukan milik pelanggan yang dipilih.'),

            backgroundColor: Colors.red,

          ),

        );

        return;

      }

      setState(() {

        _voucherCode = code.trim();

        _voucherController.text = code.trim();

      });

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text('Voucher berhasil divalidasi.'),

          backgroundColor: Colors.green,

        ),

      );

    } catch (error) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('Gagal memvalidasi voucher: $error'),

          backgroundColor: Colors.red,

        ),

      );

    }

  }

  Future<void> _scanMember() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _MemberQrScannerDialog(),
    );

    if (code == null || code.trim().isEmpty || !mounted) return;

    // QR dari aplikasi Customer menggunakan format:
    // KOPIERS-MEMBER:<customers.id>
    const prefix = 'KOPIERS-MEMBER:';
    final scannedCode = code.trim();

    if (!scannedCode.toUpperCase().startsWith(prefix)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR tidak valid. Gunakan QR Member Kopiers.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final scannedId = scannedCode.substring(prefix.length).trim();

    if (scannedId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID pelanggan pada QR tidak ditemukan.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Cocokkan ID dari QR dengan primary key customers.id.
    Map<String, dynamic>? matchedCustomer;

    for (final customer in widget.customers) {
      final customerId = customer['id']?.toString().trim();

      if (customerId == scannedId) {
        matchedCustomer = customer;
        break;
      }
    }

    if (!mounted) return;

    if (matchedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pelanggan dengan ID $scannedId tidak ditemukan. '
            'Pastikan QR menggunakan customers.id dan pelanggan '
            'termasuk dalam daftar pelanggan aktif.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final customerId = int.tryParse(
      matchedCustomer['id']?.toString() ?? '',
    );

    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID pelanggan tidak valid pada data Admin.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _customerId = customerId;
      _voucherCode = '';
      _voucherController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pelanggan ${matchedCustomer['name'] ?? 'Kopiers'} '
          'berhasil dipilih.',
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void dispose() {

    _voucherController.dispose();

    super.dispose();

  }

  @override

  Widget build(BuildContext context) => AlertDialog(

        backgroundColor: Colors.white,

        surfaceTintColor: Colors.transparent,

        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(24),

        ),

        title: Row(

          children: [

            _dialogIcon(Icons.point_of_sale_rounded),

            const SizedBox(width: 12),

            const Expanded(

              child: Text(

                'Catat transaksi',

                style: TextStyle(

                  fontWeight: FontWeight.bold,

                  fontSize: 19,

                ),

              ),

            ),

          ],

        ),

        content: SizedBox(

          width: 460,

          child: SingleChildScrollView(

            child: Column(

              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                const Text(

                  'Pilih pelanggan dan produk yang dibeli.',

                  style: TextStyle(fontSize: 13),

                ),

                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _customerId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Pilih customer',
                          prefixIcon: Icon(
                            Icons.person_rounded,
                            color: coffee,
                          ),
                        ),
                        items: widget.customers.map((customer) {
                          return DropdownMenuItem<int>(
                            value: (customer['id'] as num).toInt(),
                            child: Text(
                              '${customer['name']} · ${customer['phone']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _saving
                            ? null
                            : (value) {
                                setState(() {
                                  _customerId = value;
                                  _voucherCode = '';
                                  _voucherController.clear();
                                });
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _scanMember,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text('Scan Member'),
                        style: FilledButton.styleFrom(
                          backgroundColor: coffee,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<int>(

                  initialValue: _productId,

                  isExpanded: true,

                  decoration: const InputDecoration(

                    labelText: 'Pilih produk',

                    prefixIcon: Icon(

                      Icons.local_cafe_rounded,

                      color: coffee,

                    ),

                  ),

                  items: widget.products.map((product) {

                    return DropdownMenuItem<int>(

                      value: (product['id'] as num).toInt(),

                      child: Text(

                        '${product['name']} · '

                        '${_adminMoney(product['price'])}',

                        overflow: TextOverflow.ellipsis,

                      ),

                    );

                  }).toList(),

                  onChanged: _saving

                      ? null

                      : (value) {

                          setState(() => _productId = value);

                        },

                ),

                const SizedBox(height: 12),

                Row(

                  children: [

                    Expanded(

                      child: TextFormField(

                        key: const ValueKey('transaction-quantity'),

                        initialValue: '1',

                        keyboardType: TextInputType.number,

                        decoration: const InputDecoration(

                          labelText: 'Jumlah',

                          prefixIcon: Icon(

                            Icons.numbers_rounded,

                            color: coffee,

                          ),

                        ),

                        onChanged: (value) {

                          _quantity = int.tryParse(value) ?? 1;

                        },

                      ),

                    ),

                    const SizedBox(width: 10),

                    FilledButton.icon(

                      onPressed: _saving

                          ? null

                          : () {

                              if (_productId == null || _quantity < 1) {

                                return;

                              }

                              setState(() {

                                final existing = _items.indexWhere(

                                  (item) =>

                                      item['product_id'] == _productId,

                                );

                                if (existing >= 0) {

                                  _items[existing]['quantity'] =

                                      _items[existing]['quantity']! +

                                          _quantity;

                                } else {

                                  _items.add({

                                    'product_id': _productId!,

                                    'quantity': _quantity,

                                  });

                                }

                                _quantity = 1;

                              });

                            },

                      icon: const Icon(

                        Icons.add_rounded,

                        color: Colors.white,

                      ),

                      label: const Text('Tambah'),

                    ),

                  ],

                ),

                const SizedBox(height: 16),

                if (_items.isNotEmpty) ...[

                  const Text(

                    'Item pesanan',

                    style: TextStyle(

                      fontWeight: FontWeight.bold,

                      fontSize: 15,

                    ),

                  ),

                  const SizedBox(height: 8),

                ],

                ..._items.map((item) {

                  final product = widget.products.firstWhere(

                    (product) =>

                        (product['id'] as num).toInt() ==

                        item['product_id'],

                  );

                  final price =

                      (product['price'] as num?)?.toDouble() ?? 0;

                  final quantity = item['quantity'] ?? 0;

                  final subtotal = price * quantity;

                  return Container(

                    margin: const EdgeInsets.only(bottom: 8),

                    padding: const EdgeInsets.symmetric(

                      horizontal: 10,

                      vertical: 6,

                    ),

                    decoration: BoxDecoration(

                      color: cream,

                      borderRadius: BorderRadius.circular(12),

                      border: Border.all(color: borderColor),

                    ),

                    child: Row(

                      children: [

                        Container(

                          padding: const EdgeInsets.all(8),

                          decoration: BoxDecoration(

                            color: softRed,

                            borderRadius: BorderRadius.circular(10),

                          ),

                          child: const Icon(

                            Icons.local_cafe_rounded,

                            color: coffee,

                            size: 20,

                          ),

                        ),

                        const SizedBox(width: 10),

                        Expanded(

                          child: Column(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              Text(

                                '${product['name']} × $quantity',

                                style: const TextStyle(

                                  fontWeight: FontWeight.w600,

                                ),

                              ),

                              const SizedBox(height: 3),

                              Text(

                                _adminMoney(subtotal),

                                style: const TextStyle(

                                  color: coffee,

                                  fontSize: 12,

                                  fontWeight: FontWeight.bold,

                                ),

                              ),

                            ],

                          ),

                        ),

                        IconButton(

                          tooltip: 'Hapus item',

                          onPressed: _saving

                              ? null

                              : () {

                                  setState(() => _items.remove(item));

                                },

                          icon: const Icon(

                            Icons.close_rounded,

                            color: coffee,

                          ),

                        ),

                      ],

                    ),

                  );

                }),

                const SizedBox(height: 8),

                Row(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Expanded(

                      child: TextField(

                        controller: _voucherController,

                        enabled: !_saving,

                        textCapitalization: TextCapitalization.characters,

                        decoration: const InputDecoration(

                          labelText: 'Kode voucher (opsional)',

                          prefixIcon: Icon(

                            Icons.confirmation_number_rounded,

                            color: coffee,

                          ),

                        ),

                        onChanged: (value) => _voucherCode = value.trim(),

                      ),

                    ),

                    const SizedBox(width: 8),

                    SizedBox(

                      height: 56,

                      child: FilledButton.icon(

                        onPressed: _saving ? null : _scanVoucher,

                        icon: const Icon(Icons.qr_code_scanner),

                        label: const Text('Scan'),

                        style: FilledButton.styleFrom(

                          backgroundColor: coffee,

                          foregroundColor: Colors.white,

                        ),

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 12),

                if (_items.isNotEmpty)

                  Container(

                    width: double.infinity,

                    padding: const EdgeInsets.all(13),

                    decoration: BoxDecoration(

                      gradient: const LinearGradient(

                        colors: [

                          Color(0xFFFFE0E0),

                          Color(0xFFFFF5F5),

                        ],

                      ),

                      borderRadius: BorderRadius.circular(14),

                      border: Border.all(color: borderColor),

                    ),

                    child: Row(

                      children: [

                        const Icon(

                          Icons.shopping_bag_rounded,

                          color: coffee,

                        ),

                        const SizedBox(width: 10),

                        Expanded(

                          child: Text(

                            '${_items.length} jenis item ditambahkan',

                            style: const TextStyle(

                              color: darkCoffee,

                              fontWeight: FontWeight.w600,

                            ),

                          ),

                        ),

                      ],

                    ),

                  ),

              ],

            ),

          ),

        ),

        actions: [

          TextButton(

            onPressed: _saving

                ? null

                : () => Navigator.pop(context),

            child: const Text('Batal'),

          ),

          FilledButton.icon(

            onPressed: _saving ||

                    _customerId == null ||

                    _items.isEmpty

                ? null

                : () async {

                    final messenger =

                        ScaffoldMessenger.maybeOf(context);

                    setState(() => _saving = true);

                    try {

                      await widget.onSubmit(

                        _customerId!,

                        List<Map<String, int>>.from(

                          _items.map(

                            (item) => Map<String, int>.from(item),

                          ),

                        ),

                        _voucherCode,

                      );

                    } catch (error) {

                      if (messenger?.mounted ?? false) {

                        messenger!.showSnackBar(

                          SnackBar(

                            content: Text(error.toString()),

                            backgroundColor: Colors.red.shade700,

                            behavior: SnackBarBehavior.floating,

                          ),

                        );

                      }

                    } finally {

                      if (mounted) {

                        setState(() => _saving = false);

                      }

                    }

                  },

            icon: _saving

                ? const SizedBox(

                    width: 18,

                    height: 18,

                    child: CircularProgressIndicator(

                      strokeWidth: 2,

                      color: Colors.white,

                    ),

                  )

                : const Icon(

                    Icons.check_circle_rounded,

                    color: Colors.white,

                  ),

            label: Text(

              _saving ? 'Menyimpan...' : 'Simpan transaksi',

            ),

          ),

        ],

      );

}

// Scanner QR yang dipanggil langsung dari form transaksi admin.

class _VoucherQrScannerDialog extends StatefulWidget {

  const _VoucherQrScannerDialog();

  @override

  State<_VoucherQrScannerDialog> createState() =>

      _VoucherQrScannerDialogState();

}

class _VoucherQrScannerDialogState

    extends State<_VoucherQrScannerDialog> {

  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {

    if (_handled) return;

    for (final barcode in capture.barcodes) {

      final code = barcode.rawValue?.trim();

      if (code != null && code.isNotEmpty) {

        _handled = true;

        Navigator.of(context).pop(code);

        return;

      }

    }

  }

  @override

  Widget build(BuildContext context) {

    return AlertDialog(

      title: const Row(

        children: [

          Icon(Icons.qr_code_scanner, color: coffee),

          SizedBox(width: 10),

          Text('Scan Voucher'),

        ],

      ),

      content: SizedBox(

        width: 350,

        height: 350,

        child: Column(

          children: [

            const Text(

              'Arahkan kamera ke QR Code voucher pelanggan.',

              textAlign: TextAlign.center,

            ),

            const SizedBox(height: 14),

            Expanded(

              child: ClipRRect(

                borderRadius: BorderRadius.circular(16),

                child: MobileScanner(onDetect: _onDetect),

              ),

            ),

          ],

        ),

      ),

      actions: [

        TextButton(

          onPressed: () => Navigator.of(context).pop(),

          child: const Text('Batal'),

        ),

      ],

    );

  }

}

/// Scanner QR Member untuk memilih pelanggan pada form transaksi.
class _MemberQrScannerDialog extends StatefulWidget {
  const _MemberQrScannerDialog();

  @override
  State<_MemberQrScannerDialog> createState() =>
      _MemberQrScannerDialogState();
}

class _MemberQrScannerDialogState extends State<_MemberQrScannerDialog> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code != null && code.isNotEmpty) {
        _handled = true;
        Navigator.of(context).pop(code);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.qr_code_scanner_rounded, color: coffee),
          SizedBox(width: 10),
          Text('Scan QR Member'),
        ],
      ),
      content: SizedBox(
        width: 350,
        height: 350,
        child: Column(
          children: [
            const Text(
              'Arahkan kamera ke QR Member pada kartu pelanggan Kopiers.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(onDetect: _onDetect),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
