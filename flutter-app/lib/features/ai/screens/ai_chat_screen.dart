import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_icons.dart';
import 'package:sawa/core/widgets/common/medium_title.dart';
import 'package:sawa/core/widgets/navigation/back_icon.dart';
import 'package:sawa/core/widgets/navigation/custom_app_bar.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String aiResponse = 'نعم، أقترح بعض الأنشطة.';

  final List<Map<String, dynamic>> messages = [];

  void sendMessage() {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add({'isUser': true, 'text': text});
      messages.add({'isUser': false, 'text': aiResponse});

      messageController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        leadingWidth: 300.w,
        leading: Row(
          children: [
            BackIcon(),
            Padding(
              padding: EdgeInsets.only(left: 15.r, right: 12.r),
              child: Iconify(
                AppIcons.robot,
                color: AppColors.primaryColor,
                size: 40.r,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 8.r),
                  child: MediumTitle(
                    title: 'مساعد الذكاء الاصطناعي',
                    fontSize: 14,
                  ),
                ),
                MediumTitle(
                  title: 'متصل الآن',
                  fontSize: 14,
                  color: Color(0xff008A00),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final bool isUser = message['isUser'];

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 364.w),
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: isUser
                            ? null
                            : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: MediumTitle(
                          color: isUser ? Colors.white : AppColors.primaryColor,
                          title: message['text'],
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Container(
              margin: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
              height: 48.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hint: Text(
                          'اكتب رسالتك ...',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),

                  IconButton(
                    onPressed: sendMessage,
                    icon: Icon(Icons.send, color: AppColors.primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
