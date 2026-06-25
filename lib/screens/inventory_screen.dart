import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/api_product.dart';
import '../models/global_category.dart';
import '../models/global_product.dart';
import '../providers/api_data_provider.dart';
import '../providers/business_api_provider.dart';
import '../providers/business_profile_provider.dart';
import '../providers/business_theme_provider.dart';
import '../widgets/centered_dialog.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _imagePicker = ImagePicker();

  Future<void> _offerProductImage(
    BuildContext context,
    ApiProduct product,
  ) async {
    final palette = ref.read(businessThemePaletteProvider);
    final addPhoto = await showCenteredDialog<bool>(
      context,
      palette: palette,
      builder: (ctx, colors) => CenteredDialogFrame(
        palette: colors,
        title: '${product.name} added',
        subtitle: 'Add a photo now or skip and add one later.',
        body: const SizedBox.shrink(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Skip'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Add photo'),
          ),
        ],
      ),
    );

    if (addPhoto == true && context.mounted) {
      await _pickAndUploadImage(context, product);
    }
  }

  Future<void> _pickAndUploadImage(
    BuildContext context,
    ApiProduct product,
  ) async {
    final palette = ref.read(businessThemePaletteProvider);
    final source = await showCenteredDialog<ImageSource>(
      context,
      palette: palette,
      builder: (ctx, colors) => CenteredDialogFrame(
        palette: colors,
        title: 'Add product photo',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemedOptionTile(
              icon: Icons.photo_camera,
              title: 'Take photo',
              subtitle: 'Use your device camera',
              palette: colors,
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 12),
            ThemedOptionTile(
              icon: Icons.photo_library,
              title: 'Choose from gallery',
              subtitle: 'Pick an existing image',
              palette: colors,
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      await ref.read(uploadProductImageProvider)(
        productId: product.id,
        filePath: picked.path,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo saved for ${product.name}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Photo upload failed: $e')));
      }
    }
  }

  Widget _productLeading(ApiProduct product) {
    final palette = ref.watch(businessThemePaletteProvider);
    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          product.imagePath!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Icon(
            product.isFromGlobalCatalog ? Icons.public : Icons.store,
            color: palette.primary,
          ),
        ),
      );
    }
    return Icon(
      product.isFromGlobalCatalog ? Icons.public : Icons.store,
      color: product.isFromGlobalCatalog ? palette.primary : palette.secondary,
    );
  }

  Future<void> _showAddOptions(BuildContext context) async {
    final palette = ref.read(businessThemePaletteProvider);
    await showCenteredDialog<void>(
      context,
      palette: palette,
      builder: (ctx, colors) => CenteredDialogFrame(
        palette: colors,
        title: 'Add to inventory',
        subtitle: 'Choose how you want to add a product',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemedOptionTile(
              icon: Icons.public,
              title: 'From global catalog',
              subtitle: 'Coca Cola, Rice, Sugar, and more',
              palette: colors,
              onTap: () {
                Navigator.pop(ctx);
                _showCatalogSearch(context);
              },
            ),
            const SizedBox(height: 12),
            ThemedOptionTile(
              icon: Icons.edit_outlined,
              title: 'Custom product',
              subtitle: 'Create a product unique to your shop',
              palette: colors,
              onTap: () {
                Navigator.pop(ctx);
                _showCustomProductDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCatalogSearch(BuildContext context) async {
    final config = ref.read(businessTypeConfigProvider);
    final palette = ref.read(businessThemePaletteProvider);

    List<GlobalCategory> categories = [];
    List<GlobalProduct> allProducts = [];
    int? selectedCategoryId;
    GlobalProduct? selectedProduct;
    String filterQuery = '';
    bool loading = true;
    bool catalogRequested = false;
    String? error;

    Future<void> loadCatalog(void Function(void Function()) setLocal) async {
      setLocal(() {
        loading = true;
        error = null;
      });
      try {
        final api = ref.read(businessApiProvider);
        if (api == null) throw Exception('Not signed in');

        final results = await Future.wait([
          api.getGlobalCategories(),
          api.getGlobalProducts(),
        ]);
        final loadedCategories = results[0] as List<GlobalCategory>;
        final loadedProducts = results[1] as List<GlobalProduct>;

        setLocal(() {
          categories = loadedCategories;
          allProducts = loadedProducts;
          selectedCategoryId = loadedCategories.length == 1
              ? loadedCategories.first.id
              : null;
          selectedProduct = null;
          loading = false;
        });
      } catch (e) {
        setLocal(() {
          loading = false;
          error = e.toString().replaceFirst('ApiException: ', '');
        });
      }
    }

    await showCenteredDialog<void>(
      context,
      palette: palette,
      maxWidth: 440,
      builder: (ctx, colors) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            if (!catalogRequested && loading && error == null) {
              catalogRequested = true;
              loadCatalog(setLocal);
            }

            List<GlobalProduct> visibleProducts = allProducts;
            if (selectedCategoryId != null) {
              visibleProducts = allProducts
                  .where((p) => p.globalCategoryId == selectedCategoryId)
                  .toList();
            }
            if (filterQuery.trim().isNotEmpty) {
              final q = filterQuery.trim().toLowerCase();
              visibleProducts = visibleProducts
                  .where((p) => p.name.toLowerCase().contains(q))
                  .toList();
            }
            visibleProducts.sort((a, b) => a.name.compareTo(b.name));

            final selectedStillVisible =
                selectedProduct != null &&
                visibleProducts.any((p) => p.id == selectedProduct!.id);
            final effectiveSelection = selectedStillVisible
                ? selectedProduct
                : null;

            final chosen = effectiveSelection;

            return CenteredDialogFrame(
              palette: colors,
              title: 'Global catalog',
              subtitle: 'Products for ${config.label}',
              body: loading
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(color: colors.primary),
                      ),
                    )
                  : error != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => loadCatalog(setLocal),
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (categories.length > 1) ...[
                          DropdownButtonFormField<int>(
                            initialValue: selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Catalog category',
                            ),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('All categories'),
                              ),
                              ...categories.map(
                                (c) => DropdownMenuItem<int>(
                                  value: c.id,
                                  child: Text('${c.name} (${c.productsCount})'),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setLocal(() {
                                selectedCategoryId = value;
                                selectedProduct = null;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Filter products',
                            hintText: 'Type to narrow the list',
                            prefixIcon: Icon(
                              Icons.filter_list,
                              color: colors.primary,
                            ),
                          ),
                          onChanged: (value) {
                            setLocal(() => filterQuery = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<GlobalProduct>(
                          initialValue: effectiveSelection,
                          decoration: const InputDecoration(
                            labelText: 'Select product',
                          ),
                          isExpanded: true,
                          menuMaxHeight: 320,
                          hint: Text(
                            visibleProducts.isEmpty
                                ? 'No products found'
                                : 'Choose a product',
                          ),
                          items: visibleProducts
                              .map(
                                (p) => DropdownMenuItem<GlobalProduct>(
                                  value: p,
                                  child: Text(
                                    [
                                      p.name,
                                      if (p.unit.isNotEmpty) p.unit,
                                      if (categories.length > 1 &&
                                          selectedCategoryId == null &&
                                          p.categoryName != null)
                                        p.categoryName,
                                    ].join(' • '),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: visibleProducts.isEmpty
                              ? null
                              : (value) {
                                  setLocal(() => selectedProduct = value);
                                },
                        ),
                        if (visibleProducts.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${visibleProducts.length} product(s) available',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
              actions: loading || error != null
                  ? null
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: chosen == null
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                _showImportDialog(context, chosen);
                              },
                        child: const Text('Add to inventory'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Future<void> _showImportDialog(
    BuildContext context,
    GlobalProduct global,
  ) async {
    final priceCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();

    final palette = ref.read(businessThemePaletteProvider);
    final saved = await showCenteredDialog<bool>(
      context,
      palette: palette,
      builder: (ctx, colors) => CenteredDialogFrame(
        palette: colors,
        title: 'Add ${global.name}',
        subtitle: 'From platform catalog • ${global.unit}',
        body: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Your selling price (KES)',
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: costCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Cost price (KES, optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Opening stock'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Enter a valid quantity';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Add to inventory'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    try {
      final product = await ref.read(addProductFromGlobalProvider)(
        globalProductId: global.id,
        sellingPrice: double.parse(priceCtrl.text.trim()),
        costPrice: costCtrl.text.trim().isEmpty
            ? null
            : double.parse(costCtrl.text.trim()),
        stockQuantity: int.parse(stockCtrl.text.trim()),
      );
      if (context.mounted) {
        await _offerProductImage(context, product);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _showCustomProductDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();

    final palette = ref.read(businessThemePaletteProvider);
    final saved = await showCenteredDialog<bool>(
      context,
      palette: palette,
      builder: (ctx, colors) => CenteredDialogFrame(
        palette: colors,
        title: 'Custom product',
        subtitle: 'Create a product unique to your shop',
        body: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Product name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Selling price (KES)',
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock quantity'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Enter a valid quantity';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    try {
      final product = await ref.read(createApiProductProvider)(
        name: nameCtrl.text.trim(),
        sellingPrice: double.parse(priceCtrl.text.trim()),
        stockQuantity: int.parse(stockCtrl.text.trim()),
      );
      if (context.mounted) {
        await _offerProductImage(context, product);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _adjustStock(
    BuildContext context,
    WidgetRef ref,
    ApiProduct product,
  ) async {
    final stockCtrl = TextEditingController(
      text: product.stockQuantity.toString(),
    );
    final palette = ref.read(businessThemePaletteProvider);
    final saved = await showCenteredDialog<bool>(
      context,
      palette: palette,
      builder: (ctx, colors) => CenteredDialogFrame(
        palette: colors,
        title: 'Update stock',
        subtitle: product.name,
        body: TextField(
          controller: stockCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Stock quantity'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    final qty = int.tryParse(stockCtrl.text.trim());
    if (qty == null || qty < 0) return;

    try {
      await ref.read(updateApiProductProvider)(
        productId: product.id,
        stockQuantity: qty,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Stock updated')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final useCloud = ref.watch(useCloudDataProvider);
    final productsAsync = ref.watch(apiProductsProvider);
    final palette = ref.watch(businessThemePaletteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          if (useCloud)
            IconButton(
              onPressed: () => _showAddOptions(context),
              icon: const Icon(Icons.add),
              tooltip: 'Add product',
            ),
        ],
      ),
      body: !useCloud
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sign in to manage inventory',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Search the global catalog or add custom products.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(apiProductsProvider),
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error: $e'),
                    ),
                  ],
                ),
                data: (products) {
                  if (products.isEmpty) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 56,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No products yet',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Search the global catalog for Coca Cola, Rice, Sugar… or create a custom product.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () => _showAddOptions(context),
                                icon: const Icon(Icons.add),
                                label: const Text('Add first product'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  final lowStock = products
                      .where((p) => p.stockQuantity <= 5)
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (lowStock.isNotEmpty)
                        Card(
                          color: palette.accent.withValues(alpha: 0.15),
                          child: ListTile(
                            leading: Icon(
                              Icons.warning_amber,
                              color: palette.primary,
                            ),
                            title: const Text('Low stock alert'),
                            subtitle: Text(
                              '${lowStock.length} product(s) at 5 or fewer units',
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      ...products.map(
                        (product) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: _productLeading(product),
                            title: Text(product.name),
                            subtitle: Text(
                              'KES ${product.sellingPrice.toStringAsFixed(0)}'
                              ' • Stock: ${product.stockQuantity}'
                              '${product.unit != null ? ' • ${product.unit}' : ''}'
                              '${product.isActive ? '' : ' • Inactive'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add_a_photo_outlined),
                                  onPressed: () =>
                                      _pickAndUploadImage(context, product),
                                  tooltip: 'Add photo',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _adjustStock(context, ref, product),
                                  tooltip: 'Update stock',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
      floatingActionButton: useCloud
          ? FloatingActionButton.extended(
              onPressed: () => _showAddOptions(context),
              icon: const Icon(Icons.add),
              label: const Text('Add product'),
            )
          : null,
    );
  }
}
