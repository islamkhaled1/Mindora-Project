import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sawa/app_text_styles.dart';
import 'package:sawa/constants.dart';
import 'package:sawa/core/errors/api_exception.dart';
import 'package:sawa/core/models/chat_models.dart';
import 'package:sawa/core/services/chat_service.dart';
import 'package:sawa/screens/activities_screen.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialQuery;
  final bool showBackButton;
  final bool startImmediately;

  const AiChatScreen({
    super.key,
    this.initialQuery,
    this.showBackButton = true,
    this.startImmediately = false,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> with TickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessageModel> _messages = [];
  bool _isSending = false;
  bool _hasStartedChat = false;
  String? _errorMessage;
  String? _lastFailedMessage;

  // Animation for pulsing thinking indicator
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _quickSuggestions = [
    'تمارين لتقوية عضلات اليدين ✍️',
    'نصائح لتطوير النطق في المنزل 🗣️',
    'التعامل مع تشتت الانتباه 🎯',
    'كيف أشجع طفلي على التكرار؟ 🌟',
    'أنشطة التناسق الحركي والتوازن 🤸‍♂️',
    'روتين يومي مقترح للتدريب ⏰',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial warm welcoming message from the assistant
    _messages.add(
      ChatMessageModel(
        role: 'assistant',
        content:
            'أهلاً بك في المساعد الذكي Mindora AI! 💜\nأنا هنا لمساعدتك في استشارات تأهيل النطق، الحركة، وتطوير مهارات طفلك اليومية.\nكيف يمكنني مساعدتك اليوم؟',
        timestamp: DateTime.now(),
      ),
    );

    if (widget.startImmediately || (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty)) {
      _hasStartedChat = true;
    }

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialQuery!.trim());
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  Future<void> _sendMessage([String? textToSend]) async {
    final text = (textToSend ?? _textController.text).trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() {
      _errorMessage = null;
      _lastFailedMessage = null;

      final isRetryOfLastUserMessage = _messages.isNotEmpty &&
          _messages.last.isUser &&
          _messages.last.content == text;

      if (!isRetryOfLastUserMessage) {
        _messages.add(
          ChatMessageModel(
            role: 'user',
            content: text,
            timestamp: DateTime.now(),
          ),
        );
      }
      _isSending = true;
    });

    _scrollToBottom();

    try {
      // Pass the existing conversation turns excluding the newly appended user message
      final conversationHistory = _messages.sublist(0, _messages.length - 1);

      final response = await _chatService.sendMessage(
        message: text,
        conversation: conversationHistory,
      );

      ChatSuggestion? suggestion;
      final lowerText = text.toLowerCase();
      final lowerReply = response.reply.toLowerCase();
      if (lowerText.contains('تمارين') ||
          lowerText.contains('تمرين') ||
          lowerText.contains('نشاط') ||
          lowerReply.contains('تمرين') ||
          lowerReply.contains('نشاط')) {
        if (lowerText.contains('يد') ||
            lowerText.contains('حرك') ||
            lowerReply.contains('يد') ||
            lowerReply.contains('أصابع')) {
          suggestion = const ChatSuggestion(
            title: 'نشاط تحفيز التناسق الحركي لليدين',
            domain: 'المهارات الحركية الدقيقة',
            duration: '8 دقائق',
            description:
                'تمرين تفاعلي يركز على فتح وقبض الكفين وتتبع الأهداف المرئية لتقوية العضلات الدقيقة.',
          );
        } else if (lowerText.contains('نطق') ||
            lowerText.contains('كلام') ||
            lowerReply.contains('نطق')) {
          suggestion = const ChatSuggestion(
            title: 'تمرين مخارج الحروف والأصوات',
            domain: 'مهارات النطق والتواصل',
            duration: '10 دقائق',
            description:
                'نشاط تقليد نغمات وأصوات الحروف اليومية مع تعزيز التفاعل البصري.',
          );
        } else {
          suggestion = const ChatSuggestion(
            title: 'تمرين التركيز والتفاعل البصري',
            domain: 'الانتباه والمهارات المعرفية',
            duration: '10 دقائق',
            description:
                'نشاط تتبع حركي يساعد الطفل على زيادة مدة التركيز والتفاعل المتواصل.',
          );
        }
      }

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessageModel(
              role: response.role,
              content: response.reply,
              timestamp: response.createdAtUtc,
              isFallback: response.isFallback,
              suggestion: suggestion,
            ),
          );
          _isSending = false;
        });
        _scrollToBottom();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _errorMessage = e.firstErrorMessage;
          _lastFailedMessage = text;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _errorMessage = 'تعذر استلام الرد. يرجى التحقق من الاتصال بالإنترنت.';
          _lastFailedMessage = text;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasStartedChat && !_messages.any((m) => m.role == 'user')) {
      return _buildWelcomeView();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              // Error banner if any
              if (_errorMessage != null) _buildErrorBanner(),

              // Quick suggestions (visible when conversation is young)
              if (_messages.length <= 3 && !_isSending) _buildQuickSuggestions(),

              // Message list
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  itemCount: _messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isSending) {
                      return _buildThinkingIndicator();
                    }
                    final msg = _messages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),

              // Bottom input bar
              _buildBottomInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeView() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: widget.showBackButton
              ? Container(
                  margin: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.circleAvatarColor),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16.r,
                      color: AppColors.primaryColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              : const SizedBox.shrink(),
          centerTitle: true,
          title: Column(
            children: [
              Text(
                'مساعد الذكاء الاصطناعي',
                style: AppTextStyles.font700Bold.copyWith(
                  fontSize: 18.sp,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'رفيقك الذكي للدعم',
                style: AppTextStyles.font400Regular.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.secondaryColor,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Robot Mascot + Speech Bubble matching Ai chat-1.png
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Mascot
                    Image.asset(
                      'assets/images/secBot.png',
                      height: 270.h,
                      fit: BoxFit.contain,
                    ),
                    // Speech Bubble positioned to the right of robot
                    Positioned(
                      top: 40.h,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppColors.circleAvatarColor.withValues(alpha: 0.8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'أهلاً\nأنا هنا لمساعدتك\nبالنصائح والأنشطة\nوالإرشادات.',
                          style: AppTextStyles.font700Bold.copyWith(
                            fontSize: 13.5.sp,
                            color: AppColors.primaryColor,
                            height: 1.45,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // Button: بدء المحادثة
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasStartedChat = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryTextColor,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'بدء المحادثة',
                      style: AppTextStyles.font700Bold.copyWith(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontFamily: 'Readex Pro',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: widget.showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryColor),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryColor, AppColors.secondaryTextColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'المساعد الذكي Mindora',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font600SimiBold.copyWith(
                    fontSize: 15.sp,
                    color: AppColors.primaryColor,
                    fontFamily: 'Readex Pro',
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Container(
                      width: 7.r,
                      height: 7.r,
                      decoration: const BoxDecoration(
                        color: Color(0xff10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: Text(
                        'Google Gemini • متصل',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.font400Regular.copyWith(
                          fontSize: 11.sp,
                          color: AppColors.secondaryColor,
                          fontFamily: 'Readex Pro',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'بدء محادثة جديدة',
          icon: const Icon(Icons.refresh_rounded, color: AppColors.secondaryColor),
          onPressed: () {
            setState(() {
              _messages.clear();
              _errorMessage = null;
              _messages.add(
                ChatMessageModel(
                  role: 'assistant',
                  content:
                      'تم بدء جلسة محادثة جديدة.\nأنا جاهز للإجابة عن أي استفسار يخص تطوير مهارات طفلك! 💜',
                  timestamp: DateTime.now(),
                ),
              );
            });
          },
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      color: Colors.red.shade50,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20.r),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.font400Regular.copyWith(
                fontSize: 12.sp,
                color: Colors.red.shade900,
                fontFamily: 'Readex Pro',
              ),
            ),
          ),
          if (_lastFailedMessage != null && !_isSending) ...[
            SizedBox(width: 6.w),
            TextButton(
              onPressed: () {
                final retryMsg = _lastFailedMessage!;
                _sendMessage(retryMsg);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                backgroundColor: Colors.red.shade100,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'إعادة المحاولة',
                style: AppTextStyles.font500Medium.copyWith(
                  fontSize: 11.sp,
                  color: Colors.red.shade900,
                  fontFamily: 'Readex Pro',
                ),
              ),
            ),
          ],
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18.r, color: Colors.red.shade700),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() {
              _errorMessage = null;
              _lastFailedMessage = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'مقترحات استشارية سريعة:',
              style: AppTextStyles.font600SimiBold.copyWith(
                fontSize: 12.sp,
                color: AppColors.secondaryColor,
                fontFamily: 'Readex Pro',
              ),
            ),
          ),
          SizedBox(height: 6.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: _quickSuggestions.map((suggestion) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: ActionChip(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: AppColors.frameColor.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    label: Text(
                      suggestion,
                      style: AppTextStyles.font400Regular.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.primaryColor,
                        fontFamily: 'Readex Pro',
                      ),
                    ),
                    onPressed: () => _sendMessage(suggestion),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg) {
    final isUser = msg.isUser;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32.r,
              height: 32.r,
              margin: EdgeInsets.only(left: 8.w, top: 4.h),
              decoration: BoxDecoration(
                color: AppColors.circleAvatarColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.secondaryTextColor.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: AppColors.primaryColor,
                size: 18,
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: isUser ? Radius.circular(4.r) : Radius.circular(16.r),
                  bottomRight: isUser ? Radius.circular(16.r) : Radius.circular(4.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isUser
                    ? null
                    : Border.all(
                        color: msg.isFallback
                            ? Colors.amber.shade300
                            : AppColors.frameColor.withOpacity(0.2),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fallback advisory tag if response is fallback
                  if (msg.isFallback) ...[
                    Container(
                      margin: EdgeInsets.only(bottom: 6.h),
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, size: 13.r, color: Colors.amber.shade900),
                          SizedBox(width: 4.w),
                          Text(
                            'إرشاد داعم من Mindora',
                            style: AppTextStyles.font500Medium.copyWith(
                              fontSize: 10.sp,
                              color: Colors.amber.shade900,
                              fontFamily: 'Readex Pro',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Main content
                  SelectableText(
                    msg.content.startsWith('[نمط احتياطي] ')
                        ? msg.content.substring('[نمط احتياطي] '.length)
                        : msg.content,
                    style: AppTextStyles.font400Regular.copyWith(
                      fontSize: 13.5.sp,
                      height: 1.5,
                      color: isUser ? Colors.white : const Color(0xff2D2D2D),
                      fontFamily: 'Readex Pro',
                    ),
                  ),

                  if (!isUser && msg.suggestion != null) ...[
                    SizedBox(height: 8.h),
                    _buildSuggestionCard(msg.suggestion!),
                  ],

                  SizedBox(height: 4.h),

                  // Timestamp & model footer
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimestamp(msg.timestamp),
                        style: AppTextStyles.font400Regular.copyWith(
                          fontSize: 9.5.sp,
                          color: isUser
                              ? Colors.white.withOpacity(0.7)
                              : AppColors.secondaryColor.withOpacity(0.7),
                          fontFamily: 'Readex Pro',
                        ),
                      ),
                      if (!isUser) ...[
                        SizedBox(width: 6.w),
                        Text(
                          msg.isFallback ? '• وضع احتياطي' : '• Gemini',
                          style: AppTextStyles.font400Regular.copyWith(
                            fontSize: 9.5.sp,
                            color: msg.isFallback
                                ? Colors.amber.shade900
                                : AppColors.secondaryTextColor.withOpacity(0.8),
                            fontFamily: 'Readex Pro',
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              width: 32.r,
              height: 32.r,
              margin: EdgeInsets.only(right: 8.w, top: 4.h),
              decoration: const BoxDecoration(
                color: AppColors.secondaryTextColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            margin: EdgeInsets.only(left: 8.w),
            decoration: BoxDecoration(
              color: AppColors.circleAvatarColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondaryTextColor.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: AppColors.primaryColor,
              size: 18,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.frameColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _pulseAnimation,
                  child: Row(
                    children: [
                      Container(
                        width: 7.r,
                        height: 7.r,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryTextColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        width: 7.r,
                        height: 7.r,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryTextColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        width: 7.r,
                        height: 7.r,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryTextColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'المساعد يفكر مع Google Gemini...',
                  style: AppTextStyles.font400Regular.copyWith(
                    fontSize: 11.5.sp,
                    color: AppColors.secondaryColor,
                    fontFamily: 'Readex Pro',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInputBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: AppColors.frameColor.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                style: AppTextStyles.font400Regular.copyWith(
                  fontSize: 13.5.sp,
                  color: const Color(0xff2D2D2D),
                  fontFamily: 'Readex Pro',
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب سؤالك للمساعد الذكي هنا...',
                  hintStyle: AppTextStyles.font400Regular.copyWith(
                    fontSize: 12.5.sp,
                    color: AppColors.secondaryColor.withOpacity(0.6),
                    fontFamily: 'Readex Pro',
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            height: 44.r,
            width: 44.r,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryColor, AppColors.secondaryTextColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: _isSending
                  ? SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
              onPressed: _isSending ? null : () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(ChatSuggestion suggestion) {
    return Container(
      margin: EdgeInsets.only(top: 4.h, bottom: 4.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xffFAF7FF),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xffD9C8F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        textDirection: TextDirection.rtl,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 12.r, color: Colors.white),
                    SizedBox(width: 4.w),
                    Text(
                      'مقترح نشاط تطبيقي',
                      style: AppTextStyles.font500Medium.copyWith(
                        fontSize: 10.sp,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xffEDE4FF),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  suggestion.duration,
                  style: AppTextStyles.font500Medium.copyWith(
                    fontSize: 10.sp,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            suggestion.title,
            style: AppTextStyles.font700Bold.copyWith(
              fontSize: 12.5.sp,
              color: AppColors.primaryColor,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 2.h),
          Text(
            suggestion.domain,
            style: AppTextStyles.font500Medium.copyWith(
              fontSize: 10.5.sp,
              color: AppColors.secondaryTextColor,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 6.h),
          Text(
            suggestion.description,
            style: AppTextStyles.font400Regular.copyWith(
              fontSize: 11.sp,
              color: AppColors.secondaryColor,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 10.h),
          ElevatedButton.icon(
            onPressed: () => _handleApplySuggestion(suggestion),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
            label: const Text('تطبيق الاقتراح'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              textStyle: AppTextStyles.font600SimiBold.copyWith(fontSize: 11.5.sp),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _handleApplySuggestion(ChatSuggestion suggestion) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: const BoxDecoration(
                      color: Color(0xffEDE4FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.tips_and_updates_rounded,
                      size: 24.r,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'تطبيق المقترح التدريبي',
                      style: AppTextStyles.font700Bold.copyWith(
                        fontSize: 15.sp,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'تم تحديد نشاط: "${suggestion.title}" كنشاط مقترح.',
                style: AppTextStyles.font600SimiBold.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'تنبيه: لا يتم إجراء حفظ تلقائي على الخطة العلاجية بالخلفية عبر المحادثة، يمكنك الآن الانتقال لقائمة الأنشطة لبدء التمرين وتسجيل جلسة قياس حقيقية.',
                style: AppTextStyles.font400Regular.copyWith(
                  fontSize: 11.5.sp,
                  color: AppColors.secondaryColor,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ActivitiesScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                child: Text(
                  'الانتقال إلى قائمة التمارين',
                  style: AppTextStyles.font600SimiBold.copyWith(fontSize: 13.sp),
                ),
              ),
              SizedBox(height: 8.h),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'إغلاق',
                  style: AppTextStyles.font500Medium.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $period';
  }
}
