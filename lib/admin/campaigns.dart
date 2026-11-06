part of kopiers;
class CampaignsPage extends StatefulWidget {
  const CampaignsPage({super.key});
  @override
  State<CampaignsPage> createState() => _CampaignsPageState();
}
const Map<String, Map<String, String>> campaignSegments = {
  'activity': {
    'new': 'Pelanggan baru',
    'active': 'Pelanggan aktif',
    'inactive': 'Pelanggan tidak aktif',
  },
  'loyalty': {
    'none': 'Belum memiliki loyalitas',
    'bronze': 'Bronze',
    'silver': 'Silver',
    'gold': 'Gold',
    'platinum': 'Platinum',
  },
  'customer_value': {
    'low': 'Customer Value Low',
    'medium': 'Customer Value Medium',
    'high': 'Customer Value High',
  },
};

String campaignTypeForSegment(String dimension, String segment) {
  if (dimension == 'activity') {
    if (segment == 'new') return 'new_customer';
    if (segment == 'inactive') return 'reengagement';
    return 'personalized';
  }
  if (dimension == 'loyalty') return 'loyal';
  return 'personalized';
}

String _campaignConditionsText(dynamic value) {
  if (value is String && value.isNotEmpty) {
    try {
      value = jsonDecode(value);
    } on FormatException {
      return '';
    }
  }
  if (value is Map) {
    return (value['min_purchase'] ?? '').toString();
  }
  return '';
}
class _CampaignsPageState extends State<CampaignsPage> {
  int _reload = 0;
  @override
  Widget build(BuildContext context) => _AdminDataPage(
    key: ValueKey(_reload),
    load: () => ApiClient.instance.get('/campaigns'),
    builder: (context, data) {
      final campaigns = List<Map<String, dynamic>>.from(
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
                    'Promo',
                    'Promo yang ditargetkan berdasarkan segmen',
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [coffee, darkCoffee],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: coffee.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _createCampaign,
                    tooltip: 'Buat Promo',
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
            if (campaigns.isEmpty)
              const Text('Belum ada promo. Buat promo pertama.'),
            ...campaigns.map(
              (campaign) => Card(
                child: ExpansionTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [coffee, darkCoffee],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  title: Text(campaign['name']?.toString() ?? '-'),
                  subtitle: Text(
                    '${campaign['campaign_type']} · ${_adminDate(campaign['starts_at'])}—${_adminDate(campaign['ends_at'])}',
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        campaign['description']?.toString() ??
                            'Tanpa deskripsi',
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _issueVouchers(context, campaign),
                          icon: const Icon(Icons.confirmation_number_outlined),
                          label: const Text('Terbitkan voucher'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showCampaignReport(context, campaign),
                          icon: const Icon(Icons.bar_chart_rounded),
                          label: const Text('Laporan'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _editCampaign(context, campaign),
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _deleteCampaign(context, campaign),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Hapus'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _runAction(context, () async {
                            await ApiClient.instance.patch(
                              '/campaigns/${campaign['id']}/status',
                              {
                                'is_active':
                                    !(campaign['is_active'] == true ||
                                        campaign['is_active'] == 1),
                              },
                            );
                            setState(() => _reload++);
                          }),
                          child: Text(
                            campaign['is_active'] == true ||
                                    campaign['is_active'] == 1
                                ? 'Nonaktifkan'
                                : 'Aktifkan',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
  Future<void> _createCampaign() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final minPurchaseController = TextEditingController();
    final discountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedDimension = 'activity';
    var selectedSegment = 'new';
    var selectedType = 'new_customer';
    final now = DateTime.now();
    var startsAt = DateTime(now.year, now.month, now.day);
    var endsAt = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 30))
        .add(const Duration(hours: 23, minutes: 59, seconds: 59));
    Map<String, dynamic>? values;
    try {
      values = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: coffee.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.campaign_rounded, color: coffee),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Buat promo baru'),
                      SizedBox(height: 3),
                      Text(
                        'Atur penawaran dan periode promo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama promo',
                          hintText: 'Contoh: First Sip 15%',
                          prefixIcon: Icon(Icons.local_offer_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Nama promo wajib diisi.'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi promo',
                          hintText: 'Jelaskan penawaran promo...',
                          prefixIcon: Icon(Icons.description_outlined),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: minPurchaseController,
                        decoration: const InputDecoration(
                          labelText: 'Minimal pembelian (Rp)',
                          hintText: 'Contoh: 25000',
                          prefixText: 'Rp ',
                          helperText:
                              'Kosongkan jika tidak ada minimal pembelian.',
                          prefixIcon: Icon(Icons.shopping_cart_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: discountController,
                        decoration: const InputDecoration(
                          labelText: 'Diskon persen',
                          hintText: 'Contoh: 15',
                          suffixText: '%',
                          prefixIcon: Icon(Icons.percent_rounded),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Diskon wajib diisi.';
                          }
                          final discount = double.tryParse(value!.trim());
                          if (discount == null ||
                              discount < 0 ||
                              discount > 100) {
                            return 'Masukkan angka 0 sampai 100.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'TARGET PELANGGAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        key: ValueKey('create_dimension_$selectedDimension'),
                        initialValue: selectedDimension,
                        decoration: const InputDecoration(
                          labelText: 'Dimensi segmentasi',
                          prefixIcon: Icon(Icons.analytics_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'activity',
                            child: Text('Activity'),
                          ),
                          DropdownMenuItem(
                            value: 'loyalty',
                            child: Text('Loyalty'),
                          ),
                          DropdownMenuItem(
                            value: 'customer_value',
                            child: Text('Customer Value'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedDimension = value;
                            selectedSegment =
                                campaignSegments[value]!.keys.first;
                            selectedType = campaignTypeForSegment(
                              selectedDimension,
                              selectedSegment,
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        key: ValueKey(
                          'create_${selectedDimension}_$selectedSegment',
                        ),
                        initialValue: selectedSegment,
                        decoration: const InputDecoration(
                          labelText: 'Segmen target pelanggan',
                          prefixIcon: Icon(Icons.groups_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: campaignSegments[selectedDimension]!
                            .entries
                            .map(
                              (entry) => DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedSegment = value;
                            selectedType = campaignTypeForSegment(
                              selectedDimension,
                              selectedSegment,
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        key: ValueKey(selectedType),
                        initialValue: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Jenis promo',
                          prefixIcon: Icon(Icons.category_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'new_customer', child: Text('Pelanggan baru')),
                          DropdownMenuItem(value: 'loyal', child: Text('Pelanggan loyal')),
                          DropdownMenuItem(value: 'reengagement', child: Text('Re-engagement')),
                          DropdownMenuItem(value: 'personalized', child: Text('Personal')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'PERIODE BERLAKU PROMO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: startsAt,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                  helpText: 'Pilih tanggal mulai promo',
                                );
                                if (!dialogContext.mounted || date == null) return;
                                setDialogState(() {
                                  startsAt = DateTime(date.year, date.month, date.day);
                                  if (!endsAt.isAfter(startsAt)) {
                                    endsAt = DateTime(
                                      date.year, date.month, date.day, 23, 59, 59,
                                    );
                                  }
                                });
                              },
                              icon: const Icon(Icons.event_outlined),
                              label: Text(
                                'Mulai\n${_adminDate(startsAt.toIso8601String())}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: endsAt,
                                  firstDate: startsAt,
                                  lastDate: DateTime(2100),
                                  helpText: 'Pilih tanggal akhir promo',
                                );
                                if (!dialogContext.mounted || date == null) return;
                                setDialogState(() {
                                  endsAt = DateTime(
                                    date.year, date.month, date.day, 23, 59, 59,
                                  );
                                });
                              },
                              icon: const Icon(Icons.event_available_outlined),
                              label: Text(
                                'Berakhir\n${_adminDate(endsAt.toIso8601String())}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Promo berlaku mulai tanggal mulai sampai tanggal berakhir.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              FilledButton.icon(
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  final minText = minPurchaseController.text.trim();
                  final minDigits = minText.replaceAll(RegExp(r'[^0-9]'), '');
                  final minPurchase =
                      minDigits.isEmpty ? null : int.tryParse(minDigits);
                  if (minText.isNotEmpty && minPurchase == null) {
                    _message(
                      dialogContext,
                      'Minimal pembelian harus berupa angka yang valid.',
                      error: true,
                    );
                    return;
                  }
                  if (!endsAt.isAfter(startsAt)) {
                    _message(
                      dialogContext,
                      'Tanggal berakhir harus setelah tanggal mulai.',
                      error: true,
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, {
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'campaign_type': selectedType,
                    'target_dimension': selectedDimension,
                    'target_segment': selectedSegment,
                    'discount_percent':
                        double.parse(discountController.text.trim()),
                    'conditions': minPurchase != null && minPurchase > 0
                        ? {'min_purchase': minPurchase}
                        : <String, dynamic>{},
                    'starts_at': startsAt.toUtc().toIso8601String(),
                    'ends_at': endsAt.toUtc().toIso8601String(),
                  });
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Simpan Promo'),
              ),
            ],
          ),
        ),
      );
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      nameController.dispose();
      descriptionController.dispose();
      minPurchaseController.dispose();
      discountController.dispose();
    }
    if (values == null || !mounted || !context.mounted) return;
    await _runAction(context, () async {
      await ApiClient.instance.post('/campaigns', values!);
      if (!mounted || !context.mounted) return;
      setState(() => _reload++);
      await _message(context, 'Promo berhasil dibuat.');
    });
  }
  Future<void> _editCampaign(
  BuildContext context,
  Map<String, dynamic> campaign,
) async {
  final nameController = TextEditingController(
    text: campaign['name']?.toString() ?? '',
  );
  final descriptionController = TextEditingController(
    text: campaign['description']?.toString() ?? '',
  );
  final discountController = TextEditingController(
    text: campaign['discount_percent']?.toString() ?? '',
  );
  final conditionsController = TextEditingController(
    text: _campaignConditionsText(campaign['conditions']),
  );
  final formKey = GlobalKey<FormState>();
  var targetDimension =
      campaign['target_dimension']?.toString() ?? 'activity';
  if (!campaignSegments.containsKey(targetDimension)) {
    targetDimension = 'activity';
  }
  var targetSegment =
      campaign['target_segment']?.toString() ?? 'new';
  if (!campaignSegments[targetDimension]!.containsKey(targetSegment)) {
    targetSegment = campaignSegments[targetDimension]!.keys.first;
  }
  var type = campaign['campaign_type']?.toString() ??
      campaignTypeForSegment(targetDimension, targetSegment);
  const validTypes = [
    'new_customer',
    'loyal',
    'reengagement',
    'personalized',
  ];
  if (!validTypes.contains(type)) {
    type = campaignTypeForSegment(targetDimension, targetSegment);
  }
  var startsAt =
      DateTime.tryParse(campaign['starts_at']?.toString() ?? '') ??
          DateTime.now();
  var endsAt =
      DateTime.tryParse(campaign['ends_at']?.toString() ?? '') ??
          startsAt.add(const Duration(days: 30));
  Map<String, dynamic>? values;
  try {
    values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit promo'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama promo',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: conditionsController,
                      decoration: const InputDecoration(
                        labelText: 'Minimal pembelian (Rp)',
                        hintText: 'Contoh: 25000',
                        prefixText: 'Rp ',
                        helperText:
                            'Kosongkan jika tidak ada minimal pembelian.',
                      ),
                      keyboardType: TextInputType.number,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: discountController,
                      decoration: const InputDecoration(
                        labelText: 'Diskon persen',
                        hintText: 'Contoh: 15',
                        suffixText: '%',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Diskon wajib diisi.';
                        }
                        final discount = double.tryParse(value!.trim());
                        if (discount == null ||
                            discount < 0 ||
                            discount > 100) {
                          return 'Masukkan angka 0 sampai 100.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('edit_dimension_$targetDimension'),
                      initialValue: targetDimension,
                      decoration: const InputDecoration(
                        labelText: 'Dimensi segmentasi',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'activity',
                          child: Text('Activity'),
                        ),
                        DropdownMenuItem(
                          value: 'loyalty',
                          child: Text('Loyalty'),
                        ),
                        DropdownMenuItem(
                          value: 'customer_value',
                          child: Text('Customer Value'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          targetDimension = value;
                          targetSegment =
                              campaignSegments[value]!.keys.first;
                          type = campaignTypeForSegment(
                            targetDimension,
                            targetSegment,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('edit_${targetDimension}_$targetSegment'),
                      initialValue: targetSegment,
                      decoration: const InputDecoration(
                        labelText: 'Segmen target pelanggan',
                        border: OutlineInputBorder(),
                      ),
                      items: campaignSegments[targetDimension]!
                          .entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          targetSegment = value;
                          type = campaignTypeForSegment(
                            targetDimension,
                            targetSegment,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(type),
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Jenis promo',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'new_customer',
                          child: Text('Pelanggan baru'),
                        ),
                        DropdownMenuItem(
                          value: 'loyal',
                          child: Text('Pelanggan loyal'),
                        ),
                        DropdownMenuItem(
                          value: 'reengagement',
                          child: Text('Re-engagement'),
                        ),
                        DropdownMenuItem(
                          value: 'personalized',
                          child: Text('Personal'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            type = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: dialogContext,
                          initialDate: startsAt,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          helpText: 'Tanggal mulai',
                        );
                        if (!dialogContext.mounted || date == null) {
                          return;
                        }
                        setDialogState(() {
                          startsAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );
                          if (!endsAt.isAfter(startsAt)) {
                            endsAt = DateTime(
                              startsAt.year,
                              startsAt.month,
                              startsAt.day,
                              23,
                              59,
                              59,
                            );
                          }
                        });
                      },
                      icon: const Icon(Icons.event),
                      label: Text(
                        'Mulai: ${_adminDate(startsAt.toIso8601String())}',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: dialogContext,
                          initialDate: endsAt,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          helpText: 'Tanggal berakhir',
                        );
                        if (!dialogContext.mounted || date == null) {
                          return;
                        }
                        setDialogState(() {
                          endsAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            23,
                            59,
                            59,
                          );
                        });
                      },
                      icon: const Icon(Icons.event_available),
                      label: Text(
                        'Berakhir: ${_adminDate(endsAt.toIso8601String())}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                final minPurchaseText = conditionsController.text.trim();
                final minPurchaseDigits =
                    minPurchaseText.replaceAll(RegExp(r'[^0-9]'), '');
                final minPurchase = minPurchaseDigits.isEmpty
                    ? null
                    : int.tryParse(minPurchaseDigits);
                if (minPurchaseText.isNotEmpty && minPurchase == null) {
                  _message(
                    dialogContext,
                    'Minimal pembelian harus berupa angka yang valid.',
                    error: true,
                  );
                  return;
                }
                final Map<String, dynamic> conditions =
                    minPurchase != null && minPurchase > 0
                        ? {'min_purchase': minPurchase}
                        : {};
                if (!endsAt.isAfter(startsAt)) {
                  _message(
                    dialogContext,
                    'Tanggal berakhir harus setelah tanggal mulai.',
                    error: true,
                  );
                  return;
                }
                final discountText = discountController.text.trim();
                Navigator.pop(dialogContext, {
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'discount_percent': double.parse(discountText),
                  'conditions': conditions,
                  'campaign_type': type,
                  'target_dimension': targetDimension,
                  'target_segment': targetSegment,
                  'starts_at': startsAt.toUtc().toIso8601String(),
                  'ends_at': endsAt.toUtc().toIso8601String(),
                });
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  } finally {
    await Future<void>.delayed(
      const Duration(milliseconds: 350),
    );
    nameController.dispose();
    descriptionController.dispose();
    discountController.dispose();
    conditionsController.dispose();
  }
  if (values == null || !mounted || !context.mounted) {
    return;
  }
  await _runAction(context, () async {
    await ApiClient.instance.patch(
      '/campaigns/${campaign['id']}',
      values!,
    );
    if (!mounted || !context.mounted) return;
    setState(() {
      _reload++;
    });
    await _message(
      context,
      'Promo berhasil diperbarui.',
    );
  });
}
  Future<void> _deleteCampaign(
    BuildContext context,
    Map<String, dynamic> campaign,
  ) async {
    final campaignName = campaign['name']?.toString() ?? 'promo ini';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
        title: const Text('Hapus promo?'),
        content: Text(
          'Promo "$campaignName" akan dihapus. Tindakan ini tidak dapat dibatalkan.\n\n'
          'Promo yang sudah memiliki voucher tidak dapat dihapus agar riwayat voucher dan transaksi tetap aman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Ya, hapus'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await _runAction(context, () async {
      await ApiClient.instance.delete('/campaigns/${campaign['id']}');
      if (!mounted || !context.mounted) return;
      setState(() => _reload++);
      await _message(context, 'Promo berhasil dihapus.');
    });
  }
  Future<void> _issueVouchers(
    BuildContext context,
    Map<String, dynamic> campaign,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terbitkan voucher?'),
        content: const Text(
          'Voucher akan diberikan kepada pelanggan pada snapshot audiens promo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Terbitkan'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await _runAction(context, () async {
      final result = await ApiClient.instance.post(
        '/campaigns/${campaign['id']}/vouchers',
      );
      if (context.mounted) await _message(context, result['message'] as String);
    });
  }
  Future<void> _showCampaignReport(
    BuildContext context,
    Map<String, dynamic> campaign,
  ) async {
    await _runAction(context, () async {
      final result = await ApiClient.instance.get(
        '/campaigns/${campaign['id']}/report',
      );
      if (!context.mounted) return;
      final report = Map<String, dynamic>.from(result['report'] as Map);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Laporan · ${campaign['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Audiens: ${report['audience_count']} pelanggan'),
              Text('Voucher: ${report['voucher_count']}'),
              Text('Digunakan: ${report['redeemed_count']}'),
              Text('Transaksi: ${report['transaction_count']}'),
              Text('Penjualan: ${_adminMoney(report['sales_amount'])}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    });
  }
}
