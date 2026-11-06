part of kopiers;

class _AdminDataPage extends StatefulWidget {
  const _AdminDataPage({super.key, required this.load, required this.builder});
  final Future<dynamic> Function() load;
  final Widget Function(BuildContext context, dynamic data) builder;
  @override
  State<_AdminDataPage> createState() => _AdminDataPageState();
}

class _AdminDataPageState extends State<_AdminDataPage> {
  late Future<dynamic> _future = widget.load();
  void _refresh() => setState(() => _future = widget.load());
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async => _refresh(),
    child: FutureBuilder<dynamic>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ListView(
            children: [
              const SizedBox(height: 100),
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 40,
                      color: coffee,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _refresh,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return widget.builder(context, snapshot.data);
      },
    ),
  );
}

Widget _pagePadding(Widget child) => ListView(
  physics: const AlwaysScrollableScrollPhysics(),
  padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
  children: [child],
);

Widget _sectionTitle(String title, [String? subtitle]) => Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    ],
  ),
);

Widget _stat(String label, String value, IconData icon, Color color) => Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 16),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    ),
  ),
);

String _adminMoney(dynamic value) {
  final number = (value as num?)?.toDouble() ?? 0;
  final parts = number.toStringAsFixed(0).split('');
  final formatted = StringBuffer();
  for (var i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) formatted.write('.');
    formatted.write(parts[i]);
  }
  return 'Rp ${formatted.toString()}';
}

String _adminDate(dynamic value) {
  if (value == null) return '-';
  final date = DateTime.tryParse(value.toString());
  if (date == null) return value.toString();
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _status(String? value) => switch (value) {
  'waiting' => 'Menunggu',
  'in_progress' => 'Diproses',
  'resolved' => 'Selesai',
  'active' => 'Aktif',
  'inactive' => 'Tidak aktif',
  'new' => 'Baru',
  'loyal' => 'Loyal',
  'high_value' => 'Nilai tinggi',
  _ => value ?? '-',
};

Future<void> _message(
  BuildContext context,
  String text, {
  bool error = false,
}) async {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: error ? Colors.red.shade700 : coffee,
    ),
  );
}

Future<String?> _askText(
  BuildContext context,
  String title, {
  String? initial,
  String? helper,
  TextInputType keyboardType = TextInputType.text,
  bool required = true,
  bool multiline = false,
}) async {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: multiline ? TextInputType.multiline : keyboardType,
        maxLines: multiline ? 4 : 1,
        decoration: InputDecoration(labelText: helper ?? title),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();
            if (required && value.isEmpty) return;
            Navigator.pop(dialogContext, value);
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

Future<int?> _askInt(BuildContext context, String title, {int? initial}) async {
  final result = await _askText(
    context,
    title,
    initial: initial?.toString(),
    keyboardType: TextInputType.number,
  );
  return result == null ? null : int.tryParse(result);
}

Future<void> _runAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await action();
  } catch (error) {
    if (messenger?.mounted ?? false) {
      messenger!.showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}
