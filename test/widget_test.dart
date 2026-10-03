import 'package:flutter_test/flutter_test.dart';
import 'package:run_4_tree/main.dart';

void main() {
  testWidgets('inicia o aplicativo na tela de login', (tester) async {
    await tester.pumpWidget(const Run4TreeApp(initialRoute: '/login'));

    expect(find.text('Run4Tree'), findsWidgets);
  });
}
