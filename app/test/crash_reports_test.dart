import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/backend/crash_reports.dart';

void main() {
  const dsn = 'https://cle@exemple.ingest.sentry.io/1';

  test('sur la tablette, les plantages sont signalés', () {
    expect(
      CrashReports.shouldReport(dsn, Uri.parse('https://app.ca/')),
      isTrue,
    );
  });

  test('sans adresse Sentry, rien ne part', () {
    expect(
      CrashReports.shouldReport('', Uri.parse('https://app.ca/')),
      isFalse,
    );
  });

  test('les tests de bout en bout ne polluent jamais les rapports', () {
    expect(
      CrashReports.shouldReport(dsn, Uri.parse('https://app.ca/?e2e')),
      isFalse,
    );
  });
}
