import 'dart:convert';

import 'package:dompetku_app/data/budgets_api.dart';
import 'package:dompetku_app/data/categories_api.dart';
import 'package:dompetku_app/data/models/app_category.dart';
import 'package:dompetku_app/data/models/budget.dart';
import 'package:dompetku_app/data/offline_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dompetku_app/data/api_client.dart';

void main() {
  test('Budget.fromJson membaca realisasi server dan status', () {
    final budget = Budget.fromJson({
      'id': 'b1',
      'amount': 500000,
      'month': 10,
      'year': 2026,
      'category': {'id': 'c1', 'name': 'Kopi', 'icon': '☕'},
      'spent': 450000,
      'persen': 90,
      'sisa': 50000,
      'status': 'WASPADA',
    });
    expect(budget.categoryName, 'Kopi');
    expect(budget.isWarning, isTrue);
    expect(budget.isOver, isFalse);
    expect(budget.progressRatio, 0.9);
    expect(budget.remaining, 50000);
  });

  test('Budget.fromJson tanpa realisasi menurunkan sisa dari nominal', () {
    // Respons upsert buat/ubah tidak membawa spent/persen/sisa.
    final budget = Budget.fromJson({
      'id': 'b2',
      'amount': 300000,
      'month': 10,
      'year': 2026,
      'category': {'id': 'c2', 'name': 'Transport', 'icon': '🚌'},
    });
    expect(budget.spent, 0);
    expect(budget.remaining, 300000);
    expect(budget.progressRatio, 0);
  });

  test('Budget lewat batas membatasi rasio progres di 1.0', () {
    final budget = Budget.fromJson({
      'id': 'b3',
      'amount': 100000,
      'month': 10,
      'year': 2026,
      'category': {'id': 'c3', 'name': 'Jajan', 'icon': '🍜'},
      'spent': 150000,
      'persen': 150,
      'sisa': -50000,
      'status': 'LEWAT',
    });
    expect(budget.isOver, isTrue);
    expect(budget.progressRatio, 1.0);
  });

  test('Budget round-trip lewat toJson dan fromJson', () {
    final original = Budget.fromJson({
      'id': 'b4',
      'amount': 200000,
      'month': 10,
      'year': 2026,
      'category': {'id': 'c4', 'name': 'Buku', 'icon': '📚'},
      'spent': 50000,
      'persen': 25,
      'sisa': 150000,
      'status': 'AMAN',
    });
    final restored = Budget.fromJson(original.toJson());
    expect(restored.categoryName, 'Buku');
    expect(restored.spent, 50000);
    expect(restored.toRequestJson()['amount'], 200000);
  });

  test('AppCategory round-trip lewat toJson dan toRequestJson', () {
    const category = AppCategory(
      id: 'c9',
      name: 'Kopi',
      type: 'EXPENSE',
      icon: '☕',
    );
    expect(AppCategory.fromJson(category.toJson()).name, 'Kopi');
    expect(category.toRequestJson(), {
      'name': 'Kopi',
      'type': 'EXPENSE',
      'icon': '☕',
    });
  });

  test('PendingOp serialisasi bolak-balik tanpa kehilangan payload', () {
    const op = PendingOp(
      kind: 'budget_update',
      payload: {'id': 'b1', 'amount': 250000},
    );
    final restored = PendingOp.fromJson(
      jsonDecode(jsonEncode(op.toJson())) as Map<String, dynamic>,
    );
    expect(restored.kind, 'budget_update');
    expect(restored.payload['amount'], 250000);
  });

  test('BudgetsApi.list mem-parse daftar budget bulan berjalan', () async {
    final client = MockClient((_) async {
      return http.Response(
        jsonEncode({
          'bulan': 'Oktober 2026',
          'month': 10,
          'year': 2026,
          'budgets': [
            {
              'id': 'b1',
              'amount': 500000,
              'month': 10,
              'year': 2026,
              'category': {'id': 'c1', 'name': 'Kopi', 'icon': '☕'},
              'spent': 100000,
              'persen': 20,
              'sisa': 400000,
              'status': 'AMAN',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final api = BudgetsApi(
      client: ApiClient(httpClient: client, baseUrl: 'https://contoh.test'),
    );
    final budgets = await api.list(token: 'token-test');
    expect(budgets, hasLength(1));
    expect(budgets.first.percent, 20);
  });

  test('CategoriesApi.create mengirim badan kategori baru', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'category': {
            'id': 'c10',
            'name': 'Langganan',
            'icon': '📺',
            'type': 'EXPENSE',
          },
        }),
        201,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final api = CategoriesApi(
      client: ApiClient(httpClient: client, baseUrl: 'https://contoh.test'),
    );
    const draft = AppCategory(
      id: '',
      name: 'Langganan',
      type: 'EXPENSE',
      icon: '📺',
    );
    final created = await api.create(token: 'token-test', draft: draft);
    expect(created.id, 'c10');
    expect(captured?.method, 'POST');
    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['name'], 'Langganan');
    expect(captured?.headers['Authorization'], 'Bearer token-test');
  });
}
