import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../providers/products_provider.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final notifier = ref.read(productsProvider.notifier);

    Future<void> openEditor([Product? existing]) async {
      final picker = ImagePicker();
      final nameCtrl = TextEditingController(text: existing?.name ?? '');
      final priceCtrl = TextEditingController(
        text: existing == null ? '' : existing.price.toStringAsFixed(0),
      );
      String imagePath = existing?.imagePath ?? '';
      final imageCtrl = TextEditingController(text: imagePath);
      String category = (existing?.category ?? existing?.unit ?? 'General')
          .trim();
      if (category.isEmpty) category = 'General';
      final formKey = GlobalKey<FormState>();

      final result = await showDialog<Product>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocal) {
              return AlertDialog(
                title: Text(existing == null ? 'Add product' : 'Edit product'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty)
                            return 'Enter product name';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final parsed = double.tryParse((value ?? '').trim());
                          if (parsed == null || parsed <= 0)
                            return 'Enter valid price';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'General',
                            child: Text('General'),
                          ),
                          DropdownMenuItem(value: 'Meat', child: Text('Meat')),
                          DropdownMenuItem(
                            value: 'Legume',
                            child: Text('Legume'),
                          ),
                          DropdownMenuItem(
                            value: 'Drink',
                            child: Text('Drink'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setLocal(() => category = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        readOnly: true,
                        controller: imageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Selected image path',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  final picked = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85,
                                  );
                                  if (picked == null) return;
                                  setLocal(() {
                                    imagePath = picked.path;
                                    imageCtrl.text = imagePath;
                                  });
                                } on PlatformException {
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Image picker is not ready. Fully restart the app and try again.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Pick from device'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Clear image',
                            onPressed: () => setLocal(() {
                              imagePath = '';
                              imageCtrl.text = '';
                            }),
                            icon: const Icon(Icons.clear),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final price = double.parse(priceCtrl.text.trim());
                      final item = Product(
                        id: existing?.id ?? 0,
                        name: nameCtrl.text.trim(),
                        price: price,
                        category: category,
                        unit: category,
                        imagePath: imagePath.trim().isEmpty
                            ? null
                            : imagePath.trim(),
                      );
                      Navigator.pop(ctx, item);
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == null) return;
      if (existing == null) {
        notifier.add(result);
      } else {
        notifier.update(result.copyWith(id: existing.id));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openEditor,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: products.isEmpty
          ? const Center(
              child: Text('No products yet. Add your first product.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withValues(alpha: 0.2),
                      child: const Icon(Icons.inventory_2_outlined),
                    ),
                    title: Text(product.name),
                    subtitle: Text(
                      '${(product.category ?? product.unit ?? 'General')} • KES ${product.price.toStringAsFixed(0)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => openEditor(product),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => notifier.remove(product.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
