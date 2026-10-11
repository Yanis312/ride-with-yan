import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/data/poll.dart';

void main() {
  test('la base accepte exactement les questions et réponses de l’app', () {
    final sql = File('../supabase/migrations/20261011_poll_allow_list.sql')
        .readAsStringSync();
    final start = sql.indexOf("jsonb := '") + "jsonb := '".length;
    final allowed = jsonDecode(
      sql.substring(start, sql.indexOf("}';", start) + 1),
    ) as Map<String, dynamic>;

    expect(allowed, {
      for (final q in pollQuestions) q.id: [for (final o in q.options) o.id],
    });
  });
}
