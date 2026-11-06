part of kopiers;

Future<void> _editAdminProfile(
  BuildContext context,
  Map<String, dynamic> user,
  ValueChanged<Map<String, dynamic>> onUpdated,
) async {
  final name = await _askText(
    context,
    'Nama Admin',
    initial: user['name']?.toString(),
  );
  if (name == null || !context.mounted) return;

  final phone = await _askText(
    context,
    'Nomor telepon',
    initial: user['phone']?.toString(),
  );
  if (phone == null || !context.mounted) return;

  final email = await _askText(
    context,
    'Email (kosongkan untuk menghapus)',
    initial: user['email']?.toString(),
    required: false,
  );
  if (email == null || !context.mounted) return;

  await _runAction(context, () async {
    final result = await ApiClient.instance.patch('/auth/me', {
      'name': name.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
    });

    if (!context.mounted) return;

    final updatedUser = result['user'];
    if (updatedUser is Map) {
      onUpdated(Map<String, dynamic>.from(updatedUser));
    }

    await _message(context, 'Profil Admin berhasil diperbarui.');
  });
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.user,
    required this.onSignOut,
    required this.onUserUpdated,
  });

  final Map<String, dynamic> user;
  final Future<void> Function() onSignOut;
  final ValueChanged<Map<String, dynamic>> onUserUpdated;

  static const Color _red = Color(0xFFE50914);
  static const Color _darkRed = Color(0xFF9F0008);
  static const Color _cream = Color(0xFFFFF5F1);

  String get _name => user['name']?.toString().trim().isNotEmpty == true
      ? user['name'].toString()
      : 'Admin Kopiers';

  String get _email => user['email']?.toString() ?? '';
  String get _phone => user['phone']?.toString() ?? '';
  String get _initials {
    final parts = _name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: const Icon(
          Icons.logout_rounded,
          color: _red,
          size: 32,
        ),
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Kamu akan keluar dari dashboard Admin Kopiers. '
          'Pastikan pekerjaanmu sudah selesai.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await onSignOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _pagePadding(
      LayoutBuilder(
        builder: (context, constraints) {

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_red, _darkRed],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _red.withValues(alpha: 0.20),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ADMINISTRATOR',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.17),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Admin Kopiers',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit profil',
                              onPressed: () => _editAdminProfile(
                                context,
                                user,
                                onUserUpdated,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.16),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Divider(color: Colors.white30, height: 1),
                        const SizedBox(height: 14),
                        const Row(
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: Colors.white,
                              size: 17,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Akun administrator aktif',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.check_circle,
                              color: Color(0xFFB9F6CA),
                              size: 17,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _sectionTitle(
                        'Informasi Akun',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _editAdminProfile(
                        context,
                        user,
                        onUserUpdated,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Ubah'),
                      style: TextButton.styleFrom(
                        foregroundColor: _red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFE1DC)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.035),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _infoTile(
                        icon: Icons.person_outline_rounded,
                        label: 'Nama lengkap',
                        value: _name,
                      ),
                      _infoDivider(),
                      _infoTile(
                        icon: Icons.email_outlined,
                        label: 'Alamat email',
                        value: _email.isEmpty ? 'Belum diatur' : _email,
                      ),
                      _infoDivider(),
                      _infoTile(
                        icon: Icons.phone_outlined,
                        label: 'Nomor telepon',
                        value: _phone.isEmpty ? 'Belum diatur' : _phone,
                      ),
                      _infoDivider(),
                      _infoTile(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Hak akses',
                        value: 'Administrator',
                        valueColor: _red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Tentang Aplikasi'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: const Color(0xFFFFE1DC)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _red,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.local_cafe_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kopiers CRM',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Customer Relationship Management',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Pengelolaan pelanggan, transaksi, '
                              'loyalitas, dan promosi Kopiers.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Akun & Keamanan'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: const Color(0xFFFFE1DC)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: _menuIcon(Icons.edit_outlined),
                        title: const Text(
                          'Edit Profil',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: const Text(
                          'Perbarui nama, email, dan nomor telepon',
                          style: TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                        ),
                        onTap: () => _editAdminProfile(
                          context,
                          user,
                          onUserUpdated,
                        ),
                      ),
                      const Divider(height: 1, indent: 65),
                      ListTile(
                        leading: _menuIcon(Icons.lock_outline_rounded),
                        title: const Text(
                          'Keamanan Akun',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: const Text(
                          'Jaga kerahasiaan informasi login',
                          style: TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(
                          Icons.shield_outlined,
                          color: Colors.green,
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Fitur pengaturan keamanan belum tersedia.',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmSignOut(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'Keluar dari Akun',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: const BorderSide(color: Color(0xFFFFB8B1)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        children: [
          _menuIcon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoDivider() => const Divider(
        height: 1,
        indent: 68,
        endIndent: 15,
      );

  Widget _menuIcon(IconData icon) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: _red, size: 20),
    );
  }
}
