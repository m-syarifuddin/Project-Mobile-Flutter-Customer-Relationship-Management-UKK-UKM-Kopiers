
part of kopiers;

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  int _reload = 0;

  Widget _gradientIcon(
    IconData icon, {
    double size = 24,
    double padding = 11,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
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
        size: size,
      ),
    );
  }

  Widget _addProductButton() {
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
        onPressed: _createProduct,
        tooltip: 'Tambah produk',
        padding: const EdgeInsets.all(12),
        icon: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _AdminDataPage(
        key: ValueKey('products-$_reload'),
        load: () => ApiClient.instance.get('/products'),
        builder: (context, data) {
          final products = List<Map<String, dynamic>>.from(
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
                        'Produk & menu',
                        'Kelola foto, harga, dan menu Kopiers',
                      ),
                    ),
                    _addProductButton(),
                  ],
                ),
                const SizedBox(height: 12),

                // Ringkasan jumlah produk
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.local_cafe_rounded,
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
                              'Katalog Kopiers',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${products.length} produk terdaftar',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (products.isEmpty)
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
                        _gradientIcon(
                          Icons.local_cafe_rounded,
                          size: 36,
                          padding: 18,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Belum ada produk',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tambahkan menu kopi atau non-kopi '
                          'untuk mulai mengelola katalog.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _createProduct,
                          icon: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                          ),
                          label: const Text('Tambah produk'),
                        ),
                      ],
                    ),
                  ),

                ...products.map((product) {
                  final name = product['name']?.toString() ?? '-';
                  final description =
                      product['description']?.toString() ?? 'Menu Kopiers';
                  final price = _adminMoney(product['price']);

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _AdminProductImage(
                              imageUrl: product['image_url']?.toString(),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 3,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 9),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: softRed,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Text(
                                      price,
                                      style: const TextStyle(
                                        color: darkCoffee,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.image_rounded,
                                        size: 15,
                                        color: coffee,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          (product['image_url']
                                                      ?.toString()
                                                      .isNotEmpty ??
                                                  false)
                                              ? 'Foto tersedia'
                                              : 'Belum ada foto',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Aksi produk',
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: coffee,
                            ),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final nameValue = await _askText(
                                  context,
                                  'Nama produk',
                                  initial: product['name']?.toString(),
                                );
                                if (nameValue == null || !context.mounted) {
                                  return;
                                }

                                final priceValue = await _askInt(
                                  context,
                                  'Harga (Rupiah)',
                                  initial:
                                      (product['price'] as num?)?.toInt() ??
                                          0,
                                );
                                if (priceValue == null ||
                                    !context.mounted) {
                                  return;
                                }

                                await _runAction(context, () async {
                                  await ApiClient.instance.patch(
                                    '/products/${product['id']}',
                                    {
                                      'name': nameValue,
                                      'price': priceValue,
                                    },
                                  );

                                  if (!mounted) return;
                                  setState(() => _reload++);
                                  await _message(
                                    context,
                                    'Produk berhasil diperbarui.',
                                  );
                                });
                              } else if (value == 'photo') {
                                await _changeProductPhoto(context, product);
                              } else if (value == 'archive') {
                                await _runAction(context, () async {
                                  await ApiClient.instance.request(
                                    '/products/${product['id']}',
                                    method: 'DELETE',
                                  );

                                  if (!mounted) return;
                                  setState(() => _reload++);
                                  await _message(
                                    context,
                                    'Produk berhasil dinonaktifkan.',
                                  );
                                });
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_rounded,
                                      color: coffee,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text('Ubah produk'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'photo',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_rounded,
                                      color: coffee,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text('Tambah/ubah foto'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'archive',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_rounded,
                                      color: coffee,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text('Nonaktifkan'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      );

  Future<void> _createProduct() async {
    final name = await _askText(context, 'Nama produk');
    if (name == null || !mounted) return;

    final price = await _askInt(context, 'Harga (Rupiah)');
    if (price == null || !mounted) return;

    final description = await _askText(
      context,
      'Deskripsi (opsional)',
      required: false,
    );
    if (description == null || !mounted) return;

    final addPhoto = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              color: coffee,
            ),
            SizedBox(width: 10),
            Expanded(child: Text('Foto produk')),
          ],
        ),
        content: const Text(
          'Mau sekalian menambahkan foto produk?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Nanti saja'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(
              Icons.image_rounded,
              color: Colors.white,
            ),
            label: const Text('Pilih foto'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    XFile? selectedImage;
    if (addPhoto == true) {
      selectedImage = await _pickProductImage();
      if (selectedImage == null || !mounted) return;
    }

    await _runAction(context, () async {
      final imageUrl = selectedImage == null
          ? null
          : await _uploadProductImage(selectedImage);

      final product = <String, dynamic>{
        'name': name,
        'price': price,
        'description': description.isEmpty ? null : description,
      };

      if (imageUrl != null) {
        product['image_url'] = imageUrl;
      }

      await ApiClient.instance.post('/products', product);

      if (!mounted) return;
      setState(() => _reload++);
      await _message(context, 'Produk berhasil ditambahkan.');
    });
  }

  Future<void> _changeProductPhoto(
    BuildContext context,
    Map<String, dynamic> product,
  ) async {
    final image = await _pickProductImage();
    if (image == null || !mounted || !context.mounted) return;

    await _runAction(context, () async {
      final imageUrl = await _uploadProductImage(image);

      await ApiClient.instance.patch(
        '/products/${product['id']}',
        {'image_url': imageUrl},
      );

      if (!mounted) return;
      setState(() => _reload++);
      await _message(context, 'Foto produk berhasil diperbarui.');
    });
  }

  Future<XFile?> _pickProductImage() => ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );

  Future<String> _uploadProductImage(XFile image) async {
    final bytes = await image.readAsBytes();
    final contentType = _productImageContentType(bytes);

    final uploaded = await ApiClient.instance.uploadProductImage(
      bytes,
      contentType,
    );

    return uploaded['image_url'] as String;
  }
}

String _productImageContentType(List<int> bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }

  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a) {
    return 'image/png';
  }

  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
      String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP') {
    return 'image/webp';
  }

  throw const FormatException(
    'Format foto tidak didukung. Gunakan gambar JPG, PNG, atau WebP.',
  );
}

class _AdminProductImage extends StatelessWidget {
  const _AdminProductImage({this.imageUrl});

  final String? imageUrl;
  static const double _size = 76;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFE0E0),
            Color(0xFFFFF5F5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.local_cafe_rounded,
        color: coffee,
        size: 32,
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return placeholder;
    }

    return FutureBuilder(
      future: ApiClient.instance.getBytes(imageUrl!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            width: _size,
            height: _size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => placeholder,
          );
        }

        if (snapshot.hasError) {
          return placeholder;
        }

        return SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              placeholder,
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: coffee,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
