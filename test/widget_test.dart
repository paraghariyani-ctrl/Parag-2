import 'package:flutter_test/flutter_test.dart';
import 'package:crewflow/main.dart';

void main() {
  testWidgets('CrewFlow starts', (WidgetTester tester) async {
    await tester.pumpWidget(const CrewFlowApp());
    expect(find.text('CrewFlow'), findsOneWidget);
  });
}
