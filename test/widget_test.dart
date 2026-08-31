import 'package:flutter_test/flutter_test.dart';
import 'package:phf/main.dart';

void main() {
  testWidgets('CrewFlow starts', (tester) async {
    await tester.pumpWidget(const CrewFlowApp());
    await tester.pump();
    expect(find.text('CrewFlow'), findsOneWidget);
  });
}
