import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/screens/ai_chat_screen.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Widget createChatScreen() {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return const MaterialApp(
          home: AiChatScreen(),
        );
      },
    );
  }

  testWidgets('AiChatScreen displays welcome state and transitions to active chat', (WidgetTester tester) async {
    await tester.pumpWidget(createChatScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Welcome State matching Ai chat-1.png
    expect(find.text('مساعد الذكاء الاصطناعي'), findsOneWidget);
    expect(find.text('رفيقك الذكي للدعم'), findsOneWidget);
    expect(find.text('بدء المحادثة'), findsOneWidget);

    // Tap to transition to active chat
    await tester.tap(find.text('بدء المحادثة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Title and Subtitle
    expect(find.text('المساعد الذكي Mindora'), findsOneWidget);
    expect(find.text('Google Gemini • متصل'), findsOneWidget);

    // Verify Welcome Assistant Message
    expect(find.textContaining('المساعد الذكي Mindora AI'), findsOneWidget);

    // Verify Send button and Text field
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
  });
}
