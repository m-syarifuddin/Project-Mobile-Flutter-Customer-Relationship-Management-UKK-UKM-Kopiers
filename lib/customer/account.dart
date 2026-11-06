part of kopiers;

class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    required this.user,
    required this.onSignOut,
    required this.onChanged,
  });

  final Map<String, dynamic> user;
  final Future<void> Function() onSignOut;
  final VoidCallback onChanged;

  static const Color _red = Color(0xFFC62828);
  static const Color _darkRed = Color(0xFF8E1717);
  static const Color _cream = Color(0xFFFFF7E8);
  static const Color _ink = Color(0xFF352723);
  static const Color _muted = Color(0xFF8A7B72);
  static const Color _line = Color(0xFFEDE2D5);

  Future<Map<String, dynamic>> _loadAccount() async {
    final results = await Future.wait([
      ApiClient.instance.get('/customers/me'),
      ApiClient.instance.get('/loyalty/points/me'),
    ]);

    final customerResponse = Map<String, dynamic>.from(results[0] as Map);
    final loyaltyResponse = Map<String, dynamic>.from(results[1] as Map);

    final customerData = customerResponse['customer'];
    final customer = customerData is Map
        ? Map<String, dynamic>.from(customerData)
        : customerResponse;

    final loyaltyData = loyaltyResponse['loyalty_card'];
    final loyalty = loyaltyData is Map
        ? Map<String, dynamic>.from(loyaltyData)
        : <String, dynamic>{};

    // Jika endpoint transaksi tersedia, gunakan untuk mengambil statistik.
    // Jika tidak, halaman tetap menggunakan data jumlah pembelian dari loyalty.
    var transactionCount = _toInt(
      loyalty['purchase_count'] ?? loyalty['total_transactions'],
    );

    try {
      final response = await ApiClient.instance.get('/transactions/me');
      final transactionResponse = Map<String, dynamic>.from(response as Map);

      final raw =
          transactionResponse['data'] ??
          transactionResponse['transactions'] ??
          transactionResponse['items'];

      if (raw is List) {
        transactionCount = raw.where((item) {
          if (item is! Map) return false;
          return item['status']?.toString().toLowerCase() == 'completed';
        }).length;
      }
    } catch (_) {
      // Endpoint transaksi belum tersedia atau tidak dapat diakses.
    }

    return {
      'customer': customer,
      'loyalty': loyalty,
      'balance': _toInt(loyaltyResponse['balance']),
      'transaction_count': transactionCount,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _memberNumber(dynamic id) {
    final value = id?.toString().trim() ?? '';

    if (value.isEmpty || value == '-') {
      return 'ID MEMBER BELUM TERSEDIA';
    }

    // Format angka menjadi KOP-000123.
    // Jika ID bukan angka, tampilkan ID asli.
    final number = int.tryParse(value);
    if (number != null) {
      return 'KOP-${number.toString().padLeft(6, '0')}';
    }

    return 'KOP-$value';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadAccount(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _red));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, color: _red, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Data akun belum bisa dimuat',
                    style: TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Periksa koneksi dan endpoint API customer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => onChanged(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Muat ulang'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final customer = Map<String, dynamic>.from(data['customer'] as Map);
        final loyalty = Map<String, dynamic>.from(data['loyalty'] as Map);

        final name = (customer['name'] ?? user['name'] ?? 'Pelanggan Kopiers')
            .toString();

        final email = (customer['email'] ?? user['email'] ?? '').toString();

        final phone = (customer['phone'] ?? '').toString();

        final memberId =
            customer['id'] ?? loyalty['member_id'] ?? loyalty['customer_id'];

        final memberNumber = _memberNumber(memberId);
        final balance = _toInt(data['balance']);
        final transactionCount = _toInt(data['transaction_count']);

        final stamps = _toInt(
          loyalty['purchases_in_cycle'] ??
              loyalty['stamps'] ??
              loyalty['stamp_count'],
        ).clamp(0, 10);

        return Container(
          color: _cream,
          child: SafeArea(
            child: RefreshIndicator(
              color: _red,
              onRefresh: () async {
                onChanged();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                children: [
                  // HEADER
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.coffee_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KOPIERS',
                              style: TextStyle(
                                color: _red,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'Akun pelanggan',
                              style: TextStyle(color: _muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Muat ulang',
                        onPressed: onChanged,
                        icon: const Icon(Icons.refresh_rounded, color: _red),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // GREETING
                  const Text(
                    'Halo, selamat datang!',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nikmati kopi favoritmu dan kumpulkan reward.',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),

                  const SizedBox(height: 22),

                  // MEMBER CARD + QR
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage(
                          'assets/images/background_kartu_member.png',
                        ),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: _red.withValues(alpha: 0.22),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _darkRed.withValues(alpha: 0.62),
                                  _darkRed.withValues(alpha: 0.48),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.coffee_rounded,
                                    color: Colors.white,
                                    size: 27,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'KOPIERS MEMBER',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.verified_rounded,
                                    color: _cream.withValues(alpha: 0.95),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                name.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                memberNumber,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  letterSpacing: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.20),
                                  ),
                                ),
                                child: Text(
                                  'ID PELANGGAN: ${memberId ?? "-"}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'POIN KAMU',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.75,
                                            ),
                                            fontSize: 10,
                                            letterSpacing: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.stars_rounded,
                                              color: _cream,
                                              size: 25,
                                            ),
                                            const SizedBox(width: 7),
                                            Text(
                                              '$balance',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 30,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _cream,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: memberId == null
                                        ? const SizedBox(
                                            width: 82,
                                            height: 82,
                                            child: Icon(
                                              Icons.qr_code_2_rounded,
                                              size: 60,
                                              color: _muted,
                                            ),
                                          )
                                        : QrImageView(
                                            data: 'KOPIERS-MEMBER:$memberId',
                                            version: QrVersions.auto,
                                            size: 82,
                                            backgroundColor: _cream,
                                            errorCorrectionLevel:
                                                QrErrorCorrectLevel.H,
                                          ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tunjukkan kartu member saat bertransaksi.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // STATISTICS
                  const Text(
                    'Ringkasan akun',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _AccountStatCard(
                          icon: Icons.shopping_bag_rounded,
                          label: 'Transaksi selesai',
                          value: '$transactionCount',
                          color: _red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AccountStatCard(
                          icon: Icons.stars_rounded,
                          label: 'Total poin',
                          value: '$balance',
                          color: const Color(0xFFB47A19),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // LOYALTY PROGRESS
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Kartu stamp kopi',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '$stamps/10',
                        style: const TextStyle(
                          color: _red,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Kumpulkan 10 stamp untuk memenuhi satu siklus reward.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _line),
                    ),
                    child: Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 12,
                          children: List.generate(10, (index) {
                            final filled = index < stamps;

                            return Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: filled ? _red : _cream,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: filled ? _red : _line,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                index == 9
                                    ? Icons.card_giftcard_rounded
                                    : Icons.coffee_rounded,
                                color: filled ? Colors.white : _red,
                                size: 23,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: stamps / 10,
                            minHeight: 8,
                            backgroundColor: _cream,
                            color: _red,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          stamps >= 10
                              ? 'Stamp lengkap! Periksa ketersediaan reward.'
                              : 'Tinggal ${10 - stamps} stamp lagi menuju target.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // PROFILE INFORMATION
                  const Text(
                    'Informasi pribadi',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _line),
                    ),
                    child: Column(
                      children: [
                        _AccountInfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Nama lengkap',
                          value: name,
                        ),
                        const Divider(height: 24, color: _line),
                        _AccountInfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: email.isEmpty ? 'Belum diatur' : email,
                        ),
                        const Divider(height: 24, color: _line),
                        _AccountInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Nomor telepon',
                          value: phone.isEmpty ? 'Belum diatur' : phone,
                        ),
                        const Divider(height: 24, color: _line),
                        _AccountInfoRow(
                          icon: Icons.badge_outlined,
                          label: 'ID member',
                          value: memberNumber,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              _showEditOptions(context, customer);
                            },
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Kelola akun'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  // SIGN OUT
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _red,
                        side: BorderSide(color: _red.withValues(alpha: 0.35)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _confirmSignOut(context),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        'Keluar dari akun',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
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

  void _showEditOptions(BuildContext context, Map<String, dynamic> customer) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kelola akun',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Pilih informasi yang ingin kamu perbarui.',
                  style: TextStyle(color: _muted),
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_outline, color: _red),
                  ),
                  title: const Text('Edit profil'),
                  subtitle: const Text('Nama, email, dan nomor telepon'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showEditProfileForm(context, customer);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.lock_outline, color: _red),
                  ),
                  title: const Text('Ganti password'),
                  subtitle: const Text('Perbarui keamanan akun'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showPasswordNotice(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileForm(
    BuildContext context,
    Map<String, dynamic> customer,
  ) {
    // Memakai form edit profil yang sudah ada di project.
    _editProfile(context, customer, onChanged);
  }

  void _showPasswordNotice(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submitPassword() async {
              final currentPassword = currentPasswordController.text.trim();
              final newPassword = newPasswordController.text;
              final confirmPassword = confirmPasswordController.text;

              if (currentPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua kolom password wajib diisi.'),
                  ),
                );
                return;
              }

              if (newPassword.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password baru minimal 8 karakter.'),
                  ),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Konfirmasi password tidak cocok.'),
                  ),
                );
                return;
              }

              if (currentPassword == newPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Password baru harus berbeda dari password lama.',
                    ),
                  ),
                );
                return;
              }

              setDialogState(() => isLoading = true);

              try {
                await ApiClient.instance.post('/auth/change-password', {
                  'current_password': currentPassword,
                  'new_password': newPassword,
                });

                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Password berhasil diubah. Silakan login kembali.',
                    ),
                  ),
                );

                // Keluar karena token lama sudah tidak berlaku.
                onSignOut();
              } catch (e) {
                if (!dialogContext.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal mengubah password: $e')),
                );
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => isLoading = false);
                }
              }
            }

            Widget passwordField({
              required String label,
              required TextEditingController controller,
              required bool obscure,
              required VoidCallback onToggle,
            }) {
              return TextField(
                controller: controller,
                obscureText: obscure,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(color: _muted),
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: _red,
                  ),
                  suffixIcon: IconButton(
                    onPressed: onToggle,
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _muted,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: _cream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              icon: const Icon(Icons.lock_reset_rounded, color: _red, size: 35),
              title: const Text(
                'Ganti password',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      passwordField(
                        label: 'Password lama',
                        controller: currentPasswordController,
                        obscure: obscureCurrent,
                        onToggle: () {
                          setDialogState(
                            () => obscureCurrent = !obscureCurrent,
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      passwordField(
                        label: 'Password baru',
                        controller: newPasswordController,
                        obscure: obscureNew,
                        onToggle: () {
                          setDialogState(() => obscureNew = !obscureNew);
                        },
                      ),
                      const SizedBox(height: 14),
                      passwordField(
                        label: 'Konfirmasi password baru',
                        controller: confirmPasswordController,
                        obscure: obscureConfirm,
                        onToggle: () {
                          setDialogState(
                            () => obscureConfirm = !obscureConfirm,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Gunakan password baru minimal 8 karakter.',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Batal', style: TextStyle(color: _muted)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isLoading ? null : submitPassword,
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Keluar dari akun?',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Kamu bisa login kembali kapan saja.',
            style: TextStyle(color: _muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal', style: TextStyle(color: _muted)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await onSignOut();
    }
  }
}

class _AccountStatCard extends StatelessWidget {
  const _AccountStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE2D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF352723),
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8A7B72), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _AccountInfoRow extends StatelessWidget {
  const _AccountInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E8),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: const Color(0xFFC62828), size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF8A7B72), fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF352723),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
