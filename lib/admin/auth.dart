part of kopiers;

Future<void> _showApiSettings(BuildContext context) async {
  final controller = TextEditingController(text: ApiClient.baseUrl);
  String? validationError;
  final savedUrl = await showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.dns_outlined),
            SizedBox(width: 12),
            Expanded(child: Text('Pengaturan Host Server API')),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih preset koneksi atau masukkan alamat API server:',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => setDialogState(
                        () => controller.text = 'http://127.0.0.1:3000/api',
                      ),
                      icon: const Icon(Icons.usb),
                      label: const Text('USB / PC'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setDialogState(
                        () => controller.text = 'http://192.168.1.10:3000/api',
                      ),
                      icon: const Icon(Icons.wifi),
                      label: const Text('Wi-Fi PC'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setDialogState(
                        () => controller.text = 'http://10.0.2.2:3000/api',
                      ),
                      icon: const Icon(Icons.phone_android),
                      label: const Text('Emulator'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'Base API URL',
                    hintText: 'http://192.168.1.10:3000/api',
                    prefixIcon: const Icon(Icons.link),
                    errorText: validationError,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Untuk Wi-Fi, ganti 192.168.1.10 dengan IP komputer yang menjalankan API. '
                  'USB perlu adb reverse tcp:3000 tcp:3000.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => setDialogState(
              () => controller.text = ApiClient.defaultBaseUrl,
            ),
            child: const Text('Default'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              try {
                Navigator.pop(
                  dialogContext,
                  ApiClient.normalizeBaseUrl(controller.text),
                );
              } on FormatException catch (error) {
                setDialogState(() => validationError = error.message);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  if (savedUrl == null || !context.mounted) return;
  await ApiClient.instance.setBaseUrl(savedUrl);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Alamat API disimpan: ${ApiClient.baseUrl}')),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onSignedIn});
  final ValueChanged<Map<String, dynamic>> onSignedIn;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _registerPassword = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        await ApiClient.instance.post('/auth/register', {
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
          'password': _registerPassword.text,
        });
        _identifier.text = _phone.text.trim();
        _password.text = _registerPassword.text;
        _register = false;
      }
      final result = await ApiClient.instance.post('/auth/login', {
        'identifier': _identifier.text.trim(),
        'password': _password.text,
      });
      await ApiClient.instance.saveToken(result['token'] as String);
      widget.onSignedIn(Map<String, dynamic>.from(result['user'] as Map));
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi' : null;

  @override
  
Widget build(BuildContext context) => Scaffold(
  body: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LOGO KOPIERS DI TENGAH, DI LUAR ROW
                  Center(
                    child: Image.asset(
                      'assets/images/logo_kopiers_putih.png',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    _register
                        ? 'Daftar Kopiers'
                        : 'Selamat datang di Kopiers',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          color: coffee,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _register
                        ? 'Buat akun untuk mengumpulkan poin dan menikmati promo.'
                        : 'Silahkan masuk jika sudah punya akun.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),

                  // Tombol pengaturan server dipindahkan ke bawah logo.
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Pengaturan Host Server API',
                      onPressed: () => _showApiSettings(context),
                      icon: const Icon(Icons.dns_outlined),
                    ),
                  ),

                  if (_register) ...[
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor telepon',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (opsional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _registerPassword,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kata sandi (min. 8 karakter)',
                      ),
                      validator: (value) =>
                          value == null || value.length < 8
                              ? 'Minimal 8 karakter'
                              : null,
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _identifier,
                      decoration: const InputDecoration(
                        labelText: 'Nomor telepon atau email',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kata sandi',
                      ),
                      validator: _required,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _register ? 'Daftar dan masuk' : 'Masuk',
                          ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _register = !_register;
                              _error = null;
                            }),
                    child: Text(
                      _register
                          ? 'Sudah punya akun? Masuk'
                          : 'Belum punya akun? Daftar',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
}
