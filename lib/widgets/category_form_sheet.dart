import 'package:flutter/material.dart';

import '../data/models/app_category.dart';
import 'app_text_field.dart';
import 'primary_button.dart';

/// Lembar formulir tambah/ubah kategori (bottom sheet).
///
/// Validasi klien mengikuti batas server: nama 1–60 karakter, ikon
/// maksimal 10 karakter, tipe salah satu dari dua nilai. Ikon diisi
/// satu emoji; bila kosong, server memakai 💰 sebagai bawaan.
class CategoryFormSheet extends StatefulWidget {
  const CategoryFormSheet({required this.onSubmit, this.initial, super.key});

  final AppCategory? initial;
  final Future<bool> Function(AppCategory draft) onSubmit;

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _iconController;
  late String _type;
  bool _saving = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _type = initial?.type ?? 'EXPENSE';
    _nameController = TextEditingController(text: initial?.name ?? '');
    _iconController = TextEditingController(text: initial?.icon ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _serverError = null;
    });
    final draft = AppCategory(
      id: widget.initial?.id ?? '',
      name: _nameController.text.trim(),
      type: _type,
      icon: _iconController.text.trim().isEmpty
          ? null
          : _iconController.text.trim(),
    );
    final ok = await widget.onSubmit(draft);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(
        () => _serverError = 'Gagal menyimpan. Cek koneksi, lalu coba lagi.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initial == null ? 'Kategori baru' : 'Ubah kategori',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _nameController,
              label: 'Nama kategori (mis. Kopi, Transport, Gaji)',
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return 'Nama tidak boleh kosong.';
                if (text.length > 60) return 'Nama maksimal 60 karakter.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _iconController,
              label: 'Ikon (satu emoji, opsional, mis. ☕)',
              validator: (value) {
                if ((value ?? '').trim().length > 10) {
                  return 'Ikon terlalu panjang.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'EXPENSE', label: Text('Pengeluaran')),
                ButtonSegment(value: 'INCOME', label: Text('Pemasukan')),
              ],
              selected: {_type},
              onSelectionChanged: (values) =>
                  setState(() => _type = values.first),
            ),
            if (_serverError != null) ...[
              const SizedBox(height: 12),
              Text(
                _serverError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: _saving ? 'Menyimpan…' : 'Simpan',
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
