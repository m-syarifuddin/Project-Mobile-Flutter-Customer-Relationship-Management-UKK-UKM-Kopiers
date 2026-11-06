part of kopiers;

class ComplaintsPage extends StatefulWidget {
  const ComplaintsPage({super.key});

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  String _selectedStatus = 'all';
  DateTimeRange? _dateRange;
  int _reload = 0;

  Map<String, String> get _complaintFilters {
    final filters = <String, String>{};
    if (_selectedStatus != 'all') {
      filters['status'] = _selectedStatus;
    }

    final range = _dateRange;
    if (range != null) {
      filters['from'] = _dateOnly(range.start);
      filters['to'] = _dateOnly(range.end);
    }
    return filters;
  }

  @override
  Widget build(BuildContext context) {
    return _AdminDataPage(
      key: ValueKey(_reload),
      load: () => ApiClient.instance.get(
        '/complaints',
        query: _complaintFilters,
      ),
      builder: (context, data) {
        final complaints = List<Map<String, dynamic>>.from(
          (data['data'] as List? ?? const []).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );

        final waitingCount = complaints
            .where((item) => item['status']?.toString() == 'waiting')
            .length;
        final progressCount = complaints
            .where((item) => item['status']?.toString() == 'in_progress')
            .length;
        final resolvedCount = complaints
            .where((item) => item['status']?.toString() == 'resolved')
            .length;

        return _pagePadding(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildComplaintHeader(complaints.length),
              const SizedBox(height: 18),
              _buildSummaryCards(
                total: complaints.length,
                waiting: waitingCount,
                progress: progressCount,
                resolved: resolvedCount,
              ),
              const SizedBox(height: 22),
              _buildFilterPanel(),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _sectionTitle(
                      'Daftar Keluhan',
                      '${complaints.length} laporan ditemukan',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Muat ulang',
                    onPressed: () => setState(() => _reload++),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (complaints.isEmpty)
                _buildEmptyState()
              else
                ...complaints.map(_buildComplaintCard),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComplaintHeader(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFE53935), Color(0xFFEF6C45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 9),
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
                  'Pusat Keluhan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Pantau laporan pelanggan dan tindak lanjuti setiap masukan.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.4,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Text(
                    '$total laporan pada tampilan ini',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    required int total,
    required int waiting,
    required int progress,
    required int resolved,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final cardWidth = compact
            ? (constraints.maxWidth - 10) / 2
            : (constraints.maxWidth - 30) / 4;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                'Total',
                total,
                Icons.forum_outlined,
                const Color(0xFF455A64),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                'Menunggu',
                waiting,
                Icons.schedule_rounded,
                const Color(0xFFE59A18),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                'Diproses',
                progress,
                Icons.sync_rounded,
                const Color(0xFF2878C8),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                'Selesai',
                resolved,
                Icons.check_circle_outline_rounded,
                const Color(0xFF26966D),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    String label,
    int value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.filter_alt_outlined, size: 18),
              SizedBox(width: 7),
              Text(
                'Filter laporan',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    prefixIcon: const Icon(Icons.flag_outlined, size: 19),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Semua status'),
                    ),
                    DropdownMenuItem(
                      value: 'waiting',
                      child: Text('Menunggu'),
                    ),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('Diproses'),
                    ),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text('Selesai'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedStatus = value;
                      _reload++;
                    });
                  },
                ),
              ),
              OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: Text(
                  _dateRange == null
                      ? 'Pilih tanggal'
                      : '${_dateOnly(_dateRange!.start)} — '
                          '${_dateOnly(_dateRange!.end)}',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_selectedStatus != 'all' || _dateRange != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'all';
                      _dateRange = null;
                      _reload++;
                    });
                  },
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text('Reset'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? 'waiting';
    final color = _complaintStatusColor(status);
    final customerName = item['customer_name']?.toString().trim();
    final customer = (customerName == null || customerName.isEmpty)
        ? 'Pelanggan'
        : customerName;
    final description = item['description']?.toString() ?? '';
    final category = item['category']?.toString() ?? 'Keluhan';
    final imagePath = item['image_url']?.toString();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.chat_bubble_outline_rounded, color: color),
        ),
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '$customer  •  ${_adminDate(item['created_at'])}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _statusPill(status, color),
            const SizedBox(height: 2),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          ],
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 13),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Deskripsi keluhan',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              description.isEmpty ? 'Tidak ada deskripsi.' : description,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          if (imagePath != null && imagePath.isNotEmpty) ...[
            const SizedBox(height: 12),
            _adminComplaintImage(imagePath),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tindakan admin',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 9,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: status == 'in_progress' || status == 'resolved'
                    ? null
                    : () => _updateComplaint(context, item, 'in_progress'),
                icon: const Icon(Icons.sync_rounded, size: 17),
                label: const Text('Proses'),
              ),
              FilledButton.icon(
                onPressed: status == 'resolved'
                    ? null
                    : () => _updateComplaint(context, item, 'resolved'),
                icon: const Icon(Icons.check_rounded, size: 17),
                label: const Text('Selesaikan'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF23865F),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        _status(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: coffee.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_chat_read_outlined,
              color: coffee,
              size: 30,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Belum ada keluhan',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 5),
          Text(
            'Laporan pelanggan akan muncul di halaman ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final today = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year + 5),
      initialDateRange: _dateRange,
    );

    if (range != null && mounted) {
      setState(() {
        _dateRange = range;
        _reload++;
      });
    }
  }
}

Color _complaintStatusColor(String? status) {
  switch (status) {
    case 'waiting':
      return const Color(0xFFD99116);
    case 'in_progress':
      return const Color(0xFF2878C8);
    case 'resolved':
      return const Color(0xFF26966D);
    default:
      return const Color(0xFF64748B);
  }
}

String _dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

Future<void> _updateComplaint(
  BuildContext context,
  Map<String, dynamic> item,
  String status,
) async {
  final response = await _askText(
    context,
    status == 'resolved' ? 'Tanggapan penyelesaian' : 'Catatan penanganan',
    multiline: true,
  );

  if (response == null || !context.mounted) return;

  await _runAction(context, () async {
    await ApiClient.instance.patch('/complaints/${item['id']}/status', {
      'status': status,
      'response': response,
    });

    if (context.mounted) {
      await _message(context, 'Status keluhan diperbarui.');
    }
  });
}

Widget _adminComplaintImage(String imagePath) => FutureBuilder<dynamic>(
  future: ApiClient.instance.getBytes(imagePath),
  builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      );
    }

    if (snapshot.hasError || snapshot.data == null) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('Lampiran gambar tidak dapat dimuat.'),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            snapshot.data,
            height: 190,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  },
);
