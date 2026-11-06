part of kopiers;

class CustomerComplaintsPage extends StatelessWidget {
  const CustomerComplaintsPage({super.key, required this.onChanged});

  final VoidCallback onChanged;

  static const Color _red = Color(0xFFE50914);
  static const Color _cream = Color(0xFFFFF6F2);

  @override
  Widget build(BuildContext context) => _CustomerDataPage(
        load: () => ApiClient.instance.get('/complaints'),
        builder: (context, data) {
          final complaints = List<Map<String, dynamic>>.from(
            (data['data'] as List).map(
              (item) => Map<String, dynamic>.from(item as Map),
            ),
          );

          final waiting = complaints.where((e) => e['status'] == 'waiting').length;
          final processing =
              complaints.where((e) => e['status'] == 'in_progress').length;
          final resolved =
              complaints.where((e) => e['status'] == 'resolved').length;

          return _page(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE50914), Color(0xFF9F0008)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _red.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pusat Bantuan Kopiers',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 7),
                              const Text(
                                'Kami Siap Membantu!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                'Sampaikan kendalamu, tim Kopiers siap membantu menyelesaikannya.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () =>
                                    _createComplaint(context, onChanged),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: _red,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Buat Keluhan',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Ringkasan Keluhan',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _complaintStat(
                        icon: Icons.schedule_rounded,
                        title: 'Menunggu',
                        value: waiting,
                        color: const Color(0xFFE59A20),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _complaintStat(
                        icon: Icons.sync_rounded,
                        title: 'Diproses',
                        value: processing,
                        color: const Color(0xFF3685D8),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _complaintStat(
                        icon: Icons.check_circle_outline,
                        title: 'Selesai',
                        value: resolved,
                        color: const Color(0xFF279B65),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Riwayat Keluhan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pantau perkembangan laporanmu',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${complaints.length} Laporan',
                        style: const TextStyle(
                          color: _red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (complaints.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFFDFDA)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: _cream,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mark_chat_unread_outlined,
                            size: 42,
                            color: _red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum Ada Keluhan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Semua berjalan lancar? Senang mendengarnya! Jika membutuhkan bantuan, tim Kopiers siap membantu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _createComplaint(context, onChanged),
                          icon: const Icon(Icons.add),
                          label: const Text('Kirim Keluhan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _red,
                            side: const BorderSide(color: _red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ...complaints.asMap().entries.map((entry) {
                  final index = entry.key;
                  final complaint = entry.value;
                  final status = complaint['status']?.toString();
                  final category =
                      complaint['category']?.toString() ?? 'Keluhan';

                  return TweenAnimationBuilder<double>(
                    key: ValueKey(complaint['id'] ?? index),
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400 + (index * 100)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 18 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: const Color(0xFFFFE2DE)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.035),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 7,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          leading: Container(
                            width: 43,
                            height: 43,
                            decoration: BoxDecoration(
                              color: _cream,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.support_agent_rounded,
                              color: _red,
                            ),
                          ),
                          title: Text(
                            category,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Row(
                              children: [
                                _complaintStatusBadge(status),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _date(complaint['created_at']),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _cream,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Deskripsi Keluhan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    complaint['description']?.toString() ?? '-',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (complaint['image_url'] is String) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Lampiran Foto',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              _complaintImage(
                                complaint['image_url'] as String,
                              ),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _complaintHistory(context, complaint),
                                icon: const Icon(
                                  Icons.history_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Lihat Riwayat Penanganan',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _red,
                                  side: const BorderSide(
                                    color: Color(0xFFFFC9C3),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
}

Widget _complaintStat({
  required IconData icon,
  required String title,
  required int value,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: color.withValues(alpha: 0.18)),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 23),
        const SizedBox(height: 7),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget _complaintStatusBadge(String? status) {
  final Color color;
  final IconData icon;

  switch (status) {
    case 'waiting':
      color = const Color(0xFFE59A20);
      icon = Icons.schedule_rounded;
      break;
    case 'in_progress':
      color = const Color(0xFF3685D8);
      icon = Icons.sync_rounded;
      break;
    case 'resolved':
      color = const Color(0xFF279B65);
      icon = Icons.check_circle_outline;
      break;
    default:
      color = Colors.grey;
      icon = Icons.info_outline;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(
          _complaintStatus(status),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}

String _complaintStatus(String? status) => switch (status) {
      'waiting' => 'Menunggu',
      'in_progress' => 'Diproses',
      'resolved' => 'Selesai',
      _ => status ?? '-',
    };

Widget _complaintImage(String imagePath) => FutureBuilder<dynamic>(
      future: ApiClient.instance.getBytes(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(color: Color(0xFFE50914)),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Lampiran gambar tidak dapat dimuat.'),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              snapshot.data,
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );

Future<void> _editProfile(
  BuildContext context,
  Map<String, dynamic> customer,
  VoidCallback onChanged,
) async {
  final name = await _ask(context, 'Nama', hint: customer['name']?.toString());
  if (name == null || !context.mounted) return;

  final phone = await _ask(
    context,
    'Nomor telepon',
    hint: customer['phone']?.toString(),
  );
  if (phone == null || !context.mounted) return;

  final email = await _ask(
    context,
    'Email (kosongkan untuk menghapus)',
    hint: customer['email']?.toString(),
    required: false,
  );
  if (email == null || !context.mounted) return;

  await _action(context, () async {
    await ApiClient.instance.patch('/customers/me', {
      'name': name,
      'phone': phone,
      'email': email,
    });
    if (!context.mounted) return;
    await _toast(context, 'Profil berhasil diperbarui.');
    onChanged();
  });
}

Future<void> _createComplaint(
  BuildContext context,
  VoidCallback onChanged,
) async {
  final selectedCategory = await showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('Kategori keluhan'),
      children: [
        for (final category in const [
          'Produk',
          'Transaksi',
          'Pelayanan',
          'Kebersihan',
          'Lainnya',
        ])
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, category),
            child: Text(category),
          ),
      ],
    ),
  );
  if (selectedCategory == null || !context.mounted) return;

  final category = selectedCategory == 'Lainnya'
      ? await _ask(context, 'Kategori keluhan lainnya')
      : selectedCategory;
  if (category == null || !context.mounted) return;

  final description = await _ask(
    context,
    'Ceritakan keluhanmu',
    hint: 'Jelaskan masalah dengan detail (min. 10 karakter)',
    multiline: true,
  );
  if (description == null || !context.mounted) return;

  if (description.length < 10) {
    await _toast(context, 'Deskripsi minimal 10 karakter.', error: true);
    return;
  }

  final attachImage = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Lampirkan foto?'),
      content: const Text(
        'Foto membantu tim Kopiers memahami keluhan. Lampiran bersifat opsional.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Lewati'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, true),
          icon: const Icon(Icons.image_outlined),
          label: const Text('Pilih foto'),
        ),
      ],
    ),
  );
  if (attachImage == null || !context.mounted) return;

  String? imageUrl;
  if (attachImage) {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1600,
      );
      if (image == null || !context.mounted) return;

      final name = image.name.toLowerCase();
      final contentType = name.endsWith('.png')
          ? 'image/png'
          : name.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';

      final uploaded = await ApiClient.instance.uploadComplaintImage(
        await image.readAsBytes(),
        contentType,
      );
      imageUrl = uploaded['image_url'] as String;
    } catch (error) {
      if (context.mounted) {
        await _toast(context, error.toString(), error: true);
      }
      return;
    }
  }

  if (!context.mounted) return;

  final complaint = <String, dynamic>{
    'category': category,
    'description': description,
  };
  if (imageUrl != null) complaint['image_url'] = imageUrl;

  await _action(context, () async {
    await ApiClient.instance.post('/complaints', complaint);
    if (!context.mounted) return;
    await _toast(context, 'Keluhan berhasil dikirim.');
    onChanged();
  });
}

Future<void> _complaintHistory(
  BuildContext context,
  Map<String, dynamic> complaint,
) async {
  await _action(context, () async {
    final result = await ApiClient.instance.get(
      '/complaints/${complaint['id']}',
    );
    if (!context.mounted) return;

    final history = List<Map<String, dynamic>>.from(
      (result['history'] as List).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Riwayat penanganan'),
        content: SizedBox(
          width: 360,
          child: history.isEmpty
              ? const Text('Belum ada pembaruan.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: history
                      .map(
                        (entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _complaintStatus(entry['status']?.toString()),
                          ),
                          subtitle: Text(
                            '${entry['response'] ?? ''}\n'
                            '${entry['changed_by'] ?? ''} · '
                            '${_date(entry['created_at'])}',
                          ),
                          isThreeLine: true,
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  });
}
