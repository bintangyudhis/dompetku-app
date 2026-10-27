import 'dart:convert';

import 'package:dompetku_app/data/api_client.dart';
import 'package:dompetku_app/data/models/transaction.dart';
import 'package:dompetku_app/data/transactions_api.dart';
import 'package:dompetku_app/state/transactions_state.dart';
import 'package:dompetku_app/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('formatRupiah memakai titik sebagai pemisah ribuan', () {
    expect(formatRupiah(0), '0');
    expect(formatRupiah(2000), '2.000');
    expect(formatRupiah(1250000), '1.250.000');
    expect(formatRupiah(-500), '-500');
  });

  test('formatTanggal memakai nama bulan Indonesia', () {
    expect(formatTanggal(DateTime(2026, 10, 27)), '27 Okt 2026');
    expect(formatTanggal(DateTime(2026, 5, 3)), '3 Mei 2026');
  });

  test('TransactionItem.fromJson membaca kategori bersarang', () {
    final item = TransactionItem.fromJson({
      'id': 't1',
      'amount': 15000,
      'type': 'EXPENSE',
      'date': '2026-10-27T00:00:00.000Z',
      'category': {'id': 'c1', 'name': 'Kopi', 'icon': '☕'},
      'note': 'Kopi susu',
    });
    expect(item.categoryName, 'Kopi');
    expect(item.isIncome, isFalse);
    expect(item.toRequestJson()['categoryId'], 'c1');
  });

  test('filter tipe dan pencarian menyaring daftar dari API', () async {
    final client = MockClient((_) async {
      // Header charset wajib: tanpa itu, Response mock memakai latin1
      // dan ikon emoji kategori melempar galat encoding.
      return http.Response(
        jsonEncode({
          'transactions': [
            {
              'id': 't1',
              'amount': 15000,
              'type': 'EXPENSE',
              'date': '2026-10-27T00:00:00.000Z',
              'category': {'id': 'c1', 'name': 'Kopi', 'icon': '☕'},
              'note': 'Kopi susu',
            },
            {
              'id': 't2',
              'amount': 5000000,
              'type': 'INCOME',
              'date': '2026-10-26T00:00:00.000Z',
              'category': {'id': 'c2', 'name': 'Gaji', 'icon': '💼'},
              'note': null,
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final state = TransactionsState(
      api: TransactionsApi(
        client: ApiClient(httpClient: client, baseUrl: 'https://contoh.test'),
      ),
    );
    await state.load('token-contoh');
    expect(state.visible.length, 2);

    state.setFilter(TransactionFilter.income);
    expect(state.visible.map((t) => t.id), ['t2']);

    state.setFilter(TransactionFilter.all);
    state.setQuery('kopi');
    expect(state.visible.map((t) => t.id), ['t1']);
  });
}
