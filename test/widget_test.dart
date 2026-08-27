import 'package:flutter_test/flutter_test.dart';
import 'package:phf/main.dart';

void main() {
  testWidgets('PHF app starts', (tester) async {
    await tester.pumpWidget(const PHFApp());
    await tester.pump();
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
