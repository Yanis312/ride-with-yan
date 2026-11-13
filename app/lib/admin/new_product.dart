part of 'admin_app.dart';

// ---------------------------------------------------------------------------
// Nouveaux articles : photos, nom, prix, description, tailles. Ils
// apparaissent sur la tablette et sur la boutique en ligne (?boutique).

const _shoeSizePreset = [
  'US 5',
  'US 6',
  'US 7',
  'US 8',
  'US 9',
  'US 10',
  'US 11',
  'US 12',
];
const _clothesSizePreset = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

/// Identifiant d'URL tiré du nom : « Casquette noire » → casquette-noire-k3f9.
String _slug(String name) {
  const accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e', //
    'ë': 'e', 'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'ù': 'u', 'û': 'u',
    'ü': 'u',
  };
  final base = name
      .toLowerCase()
      .split('')
      .map((c) => accents[c] ?? c)
      .join()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final cut = base.length > 40 ? base.substring(0, 40) : base;
  final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  return '${cut.isEmpty ? 'article' : cut}-$suffix';
}

class _NewProductCard extends StatefulWidget {
  const _NewProductCard({required this.session});

  final AdminSession session;

  @override
  State<_NewProductCard> createState() => _NewProductCardState();
}

class _NewProductCardState extends State<_NewProductCard> {
  final _nameFr = TextEditingController();
  final _nameEn = TextEditingController();
  final _descFr = TextEditingController();
  final _descEn = TextEditingController();
  final _price = TextEditingController();
  final _sizes = TextEditingController();
  final List<PlatformFile> _photos = [];
  ProductCategory _category = ProductCategory.other;
  final Set<Shopper> _shoppers = {...Shopper.values};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_nameFr, _nameEn, _descFr, _descEn, _price, _sizes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null || !mounted) return;
    setState(() {
      for (final f in result.files) {
        if (f.bytes != null && _photos.length < 6) _photos.add(f);
      }
    });
  }

  static String _type(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  Future<void> _save() async {
    final nameFr = _nameFr.text.trim();
    final nameEn = _nameEn.text.trim().isEmpty ? nameFr : _nameEn.text.trim();
    final price = double.tryParse(_price.text.replaceAll(',', '.').trim());
    if (nameFr.isEmpty) {
      return _toast(context, 'Il manque le nom.', error: true);
    }
    if (price == null || !price.isFinite || price < 0 || price > 10000) {
      return _toast(context, 'Prix invalide (0 à 10 000 \$).', error: true);
    }
    if (_photos.isEmpty) {
      return _toast(context, 'Ajoute au moins une photo.', error: true);
    }
    if (_photos.any((p) => p.size > 5 * 1024 * 1024)) {
      return _toast(context, 'Une photo dépasse 5 Mo.', error: true);
    }
    setState(() => _saving = true);
    try {
      final token = await widget.session.token();
      final id = _slug(nameFr);
      final urls = <String>[];
      for (final (i, photo) in _photos.indexed) {
        final ext = photo.name.split('.').last.toLowerCase();
        urls.add(
          await Backend.uploadPhoto(
            'product-photos',
            '$id/${i + 1}.$ext',
            photo.bytes!,
            contentType: _type(photo.name),
            token: token,
          ),
        );
      }
      await Backend.upsert('custom_products', {
        'id': id,
        'name_fr': nameFr,
        'name_en': nameEn,
        'description_fr': _descFr.text.trim(),
        'description_en': _descEn.text.trim().isEmpty
            ? _descFr.text.trim()
            : _descEn.text.trim(),
        'price': (price * 100).round() / 100,
        'category': _category.name,
        'shoppers': [for (final s in _shoppers) s.name],
        'sizes': [
          for (final s in _sizes.text.split(','))
            if (s.trim().isNotEmpty) s.trim(),
        ],
        'photos': urls,
      }, token: token);
      await RemoteConfig.instance.refresh();
      if (!mounted) return;
      _toast(context, '$nameFr est en ligne.');
      setState(() {
        for (final c in [_nameFr, _nameEn, _descFr, _descEn, _price, _sizes]) {
          c.clear();
        }
        _photos.clear();
      });
    } catch (e) {
      if (mounted) _toast(context, 'Échec : $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _field(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    isDense: true,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Brand.gold, width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(AppIcons.plus, color: Brand.gold),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Ajouter un article',
                    style: AppText.body(
                      18,
                      weight: FontWeight.w700,
                      color: context.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (i, photo) in _photos.indexed)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              photo.bytes!,
                              width: 92,
                              height: 92,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: IconButton.filledTonal(
                              visualDensity: VisualDensity.compact,
                              iconSize: 16,
                              onPressed: () =>
                                  setState(() => _photos.removeAt(i)),
                              icon: const Icon(AppIcons.close),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_photos.length < 6)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _saving ? null : _pickPhotos,
                      child: Container(
                        width: 92,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.line),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(AppIcons.plus),
                            Text(
                              'Photos',
                              style: AppText.body(12, color: context.inkMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameFr,
              decoration: _field('Nom (français)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameEn,
              decoration: _field(
                'Nom (anglais)',
                hint: 'Vide : même nom qu’en français',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _field('Prix (\$)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descFr,
              maxLines: 2,
              decoration: _field('Description (français)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descEn,
              maxLines: 2,
              decoration: _field('Description (anglais)'),
            ),
            const SizedBox(height: 14),
            Text('Section', style: AppText.body(13, color: context.inkMuted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in ProductCategory.values)
                  ChoiceChip(
                    label: Text(c.label.fr),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Rayon', style: AppText.body(13, color: context.inkMuted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                for (final s in Shopper.values)
                  FilterChip(
                    label: Text(s.label.fr),
                    selected: _shoppers.contains(s),
                    onSelected: (on) => setState(() {
                      if (on) {
                        _shoppers.add(s);
                      } else if (_shoppers.length > 1) {
                        _shoppers.remove(s);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sizes,
              decoration: _field(
                'Tailles, séparées par des virgules',
                hint: 'Vide : article sans taille',
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  label: const Text('Chaussures'),
                  onPressed: () => _sizes.text = _shoeSizePreset.join(', '),
                ),
                ActionChip(
                  label: const Text('Vêtements'),
                  onPressed: () => _sizes.text = _clothesSizePreset.join(', '),
                ),
                ActionChip(
                  label: const Text('Sans taille'),
                  onPressed: _sizes.clear,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(AppIcons.check),
              label: Text(_saving ? 'Envoi…' : 'Mettre en ligne'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un article ajouté depuis l'administration, avec un bouton pour le retirer.
class _CustomProductTile extends StatefulWidget {
  const _CustomProductTile({
    super.key,
    required this.row,
    required this.session,
  });

  final Map<String, dynamic> row;
  final AdminSession session;

  @override
  State<_CustomProductTile> createState() => _CustomProductTileState();
}

class _CustomProductTileState extends State<_CustomProductTile> {
  bool _busy = false;

  Future<void> _delete() async {
    final name = '${widget.row['name_fr']}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Retirer « $name » ?'),
        content: const Text('Il disparaîtra de la tablette et du site.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await Backend.delete(
        'custom_products',
        'id',
        '${widget.row['id']}',
        token: await widget.session.token(),
      );
      await RemoteConfig.instance.refresh();
      if (mounted) _toast(context, '$name retiré.');
    } catch (e) {
      if (mounted) _toast(context, 'Échec : $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = Product.fromRow(widget.row);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 52,
            height: 52,
            child: product.photos.isEmpty
                ? const Icon(AppIcons.tag)
                : productImage(product.photos.first, fit: BoxFit.cover),
          ),
        ),
        title: Text(product.name.fr),
        subtitle: Text(
          '${product.price.toStringAsFixed(0)} \$ · ${product.category.label.fr}',
        ),
        trailing: IconButton(
          tooltip: 'Retirer',
          onPressed: _busy ? null : _delete,
          icon: const Icon(AppIcons.trash),
        ),
      ),
    );
  }
}
