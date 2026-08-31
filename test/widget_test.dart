import 'package:flutter_test/flutter_test.dart';
import 'package:crewflow/main.dart';

void main() {
  testWidgets('CrewFlow login screen loads', (tester) async {
    await tester.pumpWidget(const CrewFlowApp());
    expect(find.text('CrewFlow'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
