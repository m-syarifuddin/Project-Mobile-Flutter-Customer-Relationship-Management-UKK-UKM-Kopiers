import 'package:flutter_test/flutter_test.dart';
import 'package:kopiers/app.dart';
import 'package:kopiers/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient.instance.setBaseUrl(ApiClient.defaultBaseUrl);
  });

  test('API URL can be changed and restored without rebuilding', () async {
    await ApiClient.instance.setBaseUrl('http://192.168.1.20:3000/');

    expect(ApiClient.baseUrl, 'http://192.168.1.20:3000/api');

    await ApiClient.instance.restore();

    expect(ApiClient.baseUrl, 'http://192.168.1.20:3000/api');
  });

  test('API URL rejects non-HTTP addresses', () {
    expect(
      () => ApiClient.normalizeBaseUrl('not a URL'),
      throwsFormatException,
    );
  });

  test('API uses the single local backend URL by default', () {
    expect(ApiClient.baseUrl, 'http://localhost:3000/api');
  });

  test('protected requests require a signed-in user', () async {
    await expectLater(
      ApiClient.instance.get('/customers/me'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having(
              (error) => error.message,
              'message',
              contains('Silakan login kembali'),
            ),
      ),
    );
  });

  testWidgets('Admin and Customer share the same login screen', (tester) async {
    await tester.pumpWidget(const KopiersApp());
    await tester.pumpAndSettle();

    expect(find.text('Selamat datang di Kopiers'), findsOneWidget);
    expect(
      find.text('Masuk dengan akun Admin atau Customer Kopiers.'),
      findsOneWidget,
    );
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('Login screen can configure the API host', (tester) async {
    await tester.pumpWidget(const KopiersApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Pengaturan Host Server API'));
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan Host Server API'), findsOneWidget);
    await tester.tap(find.text('Emulator'));
    await tester.pump();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(ApiClient.baseUrl, 'http://10.0.2.2:3000/api');
  });
}
