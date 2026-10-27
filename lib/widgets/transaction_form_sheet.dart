import 'package:flutter/material.dart';

import '../data/models/app_category.dart';
import '../data/models/transaction.dart';
import '../utils/format.dart';
import 'app_text_field.dart';
import 'primary_button.dart';

/// Lembar formulir tambah/ubah transaksi (bottom sheet).
///
/// Validasi di sisi klien, sebelum apa pun dikirim:
/// nominal harus bilangan bulat positif (1–999.999.999.999, sama dengan
/// batas server), kategori wajib dipilih, dan kategori yang tampil sudah
/// disaring sesuai tipe — jadi tipe dan kategori tidak mungkin bentrok.
/// [onSubmit] mengembalikan true bila server menerima perubahan.
class TransactionFormSheet extends StatefulWidget {
  const TransactionFormSheet({
    required this.categories,
    required this.onSubmit,
    this.initial,
    super.key,
  });

  final List<AppCategory> categories;
  final TransactionItem? initial;
  final Future<bool> Function(TransactionItem draft) onSubmit;

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _type;
  late DateTime _date;
  String? _categoryId;
  bool _saving = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _type = initial?.type ?? 'EXPENSE';
    _date = initial?.date ?? DateTime.now();
    _categoryId = initial?.categoryId;
    _amountController = TextEditingController(
      text: initial == null ? '' : '${initial.amount}',
    );
    _noteController = TextEditingController(text: initial?.note ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<AppCategory> get _visibleCategories =>
      widget.categories.where((c) => c.type == _type).toList();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _serverError = 'Pilih kategori dulu.');
      return;
    }
    final category = widget.categories.firstWhere(
      (c) => c.id == _categoryId,
    );
    final draft = TransactionItem(
      id: widget.initial?.id ?? '',
      amount: int.parse(_amountController.text.trim()),
      type: _type,
      date: _date,
      categoryId: category.id,
      categoryName: category.name,
      categoryIcon: category.icon,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    setState(() {
      _saving = true;
      _serverError = null;
    });
    final ok = await widget.onSubmit(draft);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _serverError = 'Gagal menyimpan. Coba lagi.';
      });
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.initial == null
                    ? 'Tambah transaksi'
                    : 'Ubah transaksi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'EXPENSE',
                    label: Text('Pengeluaran'),
                  ),
                  ButtonSegment(value: 'INCOME', label: Text('Pemasukan')),
                ],
                selected: {_type},
                onSelectionChanged: (values) {
                  setState(() {
                    _type = values.first;
                    _categoryId = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nominal (Rp)',
                controller: _amountController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null) return 'Isi nominal dengan angka.';
                  if (parsed < 1) return 'Nominal harus lebih dari 0.';
                  if (parsed > 999999999999) return 'Nominal terlalu besar.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  for (final c in _visibleCategories)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.icon ?? ''} ${c.name}'.trim()),
                    ),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
                validator: (value) =>
                    value == null ? 'Pilih kategori.' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Catatan (opsional)',
                controller: _noteController,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _pickDate,
                child: Text('Tanggal: ${formatTanggal(_date)}'),
              ),
              if (_serverError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _serverError!,
                  style: const TextStyle(color: Color(0xFF9C3B2E)),
                ),
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: widget.initial == null ? 'Simpan' : 'Simpan perubahan',
                isLoading: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
