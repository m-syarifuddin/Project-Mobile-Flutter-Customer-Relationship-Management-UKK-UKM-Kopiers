part of kopiers;

class _CustomerDataPage extends StatefulWidget {
  const _CustomerDataPage({required this.load, required this.builder});
  final Future<dynamic> Function() load;
  final Widget Function(BuildContext context, dynamic data) builder;
  @override
  State<_CustomerDataPage> createState() => _CustomerDataPageState();
}

class _CustomerDataPageState extends State<_CustomerDataPage> {
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
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 100),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 42,
                      color: coffee,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
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

Widget _page(Widget child) => ListView(
  physics: const AlwaysScrollableScrollPhysics(),
  padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
  children: [child],
);

Widget _title(String title, [String? subtitle]) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
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

String _money(dynamic value) {
  final text = ((value as num?)?.toDouble() ?? 0).toStringAsFixed(0);
  final result = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) result.write('.');
    result.write(text[i]);
  }
  return 'Rp ${result.toString()}';
}

String _date(dynamic value) {
  if (value == null) return '-';
  final date = DateTime.tryParse(value.toString());
  if (date == null) return value.toString();
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

Future<void> _toast(
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

Future<String?> _ask(
  BuildContext context,
  String title, {
  String? hint,
  bool multiline = false,
  bool required = true,
}) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: multiline ? 4 : 1,
        decoration: InputDecoration(labelText: hint ?? title),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();
            if (required && value.isEmpty) return;
            Navigator.pop(context, value);
          },
          child: const Text('Kirim'),
        ),
      ],
    ),
  );
}

Future<void> _action(
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
