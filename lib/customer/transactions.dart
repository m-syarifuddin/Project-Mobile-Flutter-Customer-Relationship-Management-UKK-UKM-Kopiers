part of kopiers;

class TransactionPage extends StatelessWidget {
  const TransactionPage({super.key});
  @override
  Widget build(BuildContext context) => _CustomerDataPage(
    load: () => ApiClient.instance.get('/transactions/me'),
    builder: (context, data) {
      final transactions = List<Map<String, dynamic>>.from(
        (data['data'] as List).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
      return _page(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(
              'Riwayat transaksi',
              '${transactions.length} transaksi tercatat',
            ),
            if (transactions.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.receipt_long_outlined, color: coffee),
                  title: Text('Belum ada transaksi.'),
                  subtitle: Text('Transaksi pembelianmu akan tampil di sini.'),
                ),
              ),
            ...transactions.map((transaction) {
              final items = List<Map<String, dynamic>>.from(
                (transaction['items'] as List? ?? []).map(
                  (item) => Map<String, dynamic>.from(item as Map),
                ),
              );
              return Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.receipt_long, color: coffee),
                  title: Text(
                    _money(transaction['total_amount']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${_date(transaction['created_at'])} · ${transaction['status']}',
                  ),
                  children: items.isEmpty
                      ? [
                          const ListTile(
                            title: Text('Detail produk belum tersedia.'),
                          ),
                        ]
                      : items
                            .map(
                              (item) => ListTile(
                                leading: _CustomerProductImage(
                                  imageUrl: item['image_url']?.toString(),
                                ),
                                dense: true,
                                title: Text(
                                  '${item['product']} × ${item['quantity']}',
                                ),
                                trailing: Text(_money(item['line_total'])),
                              ),
                            )
                            .toList(),
                ),
              );
            }),
          ],
        ),
      );
    },
  );
}

class _CustomerProductImage extends StatelessWidget {
  const _CustomerProductImage({this.imageUrl});

  final String? imageUrl;
  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: _size,
      height: _size,
      color: const Color(0xFFF2E4D6),
      alignment: Alignment.center,
      child: const Icon(Icons.local_cafe_outlined, color: coffee, size: 20),
    );
    if (imageUrl == null || imageUrl!.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: placeholder,
      );
    }
    return FutureBuilder(
      future: ApiClient.instance.getBytes(imageUrl!),
      builder: (context, snapshot) {
        final child = snapshot.hasData
            ? Image.memory(
                snapshot.data!,
                width: _size,
                height: _size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => placeholder,
              )
            : placeholder;
        return ClipRRect(borderRadius: BorderRadius.circular(8), child: child);
      },
    );
  }
}
