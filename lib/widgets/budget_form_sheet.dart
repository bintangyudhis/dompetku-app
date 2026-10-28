import 'package:flutter/material.dart';

import '../data/models/app_category.dart';
import '../data/models/budget.dart';
import 'app_text_field.dart';
import 'primary_button.dart';

/// Lembar formulir tambah/ubah budget bulan berjalan (bottom sheet).
///
/// Buat memakai upsert server: memilih kategori yang sudah punya budget
/// bulan ini berarti mengubah nominalnya, bukan menambah baris kedua.
/// Ubah hanya mengganti nominal; kategorinya tidak bisa dipindah, jadi
/// dropdown dikunci pada nama kategori yang sedang diubah.
/// Validasi klien mengikuti batas server: nominal minimal Rp1.000.
class BudgetFormSheet extends StatefulWidget {
  const BudgetFormSheet({
    required this.expenseCategories,
    required this.onSubmit,
    this.initial,
    super.key,
  });

  final List<AppCategory> expenseCategories;
  final Budget? initial;
  final Future<bool> Function(Budget draft) onSubmit;

  @override
  State<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  String? _categoryId;
  bool _saving = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _categoryId = initial?.categoryId;
    _amountController = TextEditingController(
      text: initial == null ? '' : '${initial.amount}',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _serverError = 'Pilih kategori pengeluaran dulu.');
      return;
    }
    final category = widget.expenseCategories.firstWhere(
      (c) => c.id == _categoryId,
      orElse: () => AppCategory(
        id: _categoryId!,
        name: widget.initial?.categoryName ?? '',
        type: 'EXPENSE',
        icon: widget.initial?.categoryIcon,
      ),
    );
    setState(() {
      _saving = true;
      _serverError = null;
    });
    final now = DateTime.now();
    final draft = Budget(
      id: widget.initial?.id ?? '',
      amount: int.parse(_amountController.text.trim()),
      month: widget.initial?.month ?? now.month,
      year: widget.initial?.year ?? now.year,
      categoryId: category.id,
      categoryName: category.name,
      categoryIcon: category.icon,
      spent: widget.initial?.spent ?? 0,
      percent: widget.initial?.percent ?? 0,
      remaining: widget.initial?.remaining ?? 0,
      status: widget.initial?.status ?? 'AMAN',
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
    final isEdit = widget.initial != null;
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
              isEdit ? 'Ubah budget' : 'Budget baru',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (isEdit)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(
                  widget.initial!.categoryIcon ?? '💰',
                  style: const TextStyle(fontSize: 22),
                ),
                title: Text(widget.initial!.categoryName),
                subtitle: const Text('Kategori budget tidak bisa dipindah.'),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Kategori pengeluaran',
                ),
                items: widget.expenseCategories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.icon ?? '💰'} ${c.name}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _categoryId = value),
                validator: (value) =>
                    value == null ? 'Pilih kategori dulu.' : null,
              ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _amountController,
              label: 'Batas budget (Rp, minimal 1.000)',
              keyboardType: TextInputType.number,
              validator: (value) {
                final amount = int.tryParse((value ?? '').trim());
                if (amount == null) return 'Isi nominal dengan angka.';
                if (amount < 1000) return 'Batas budget minimal Rp1.000.';
                if (amount > 999999999999) return 'Nominal terlalu besar.';
                return null;
              },
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
