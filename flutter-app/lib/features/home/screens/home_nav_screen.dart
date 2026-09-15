import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/bi.dart';
import 'package:iconify_flutter/icons/fluent_mdl2.dart';
import 'package:sawa/core/constants/app_colors.dart';
import 'package:sawa/core/constants/app_icons.dart';
import 'package:sawa/features/ai/screens/ai_chat_intro_screen.dart';
import 'package:sawa/features/home/screens/home_screen.dart';
import 'package:sawa/features/plan/screens/plan_screen.dart';
import 'package:sawa/features/practise/screens/practise_screen.dart';
import 'package:sawa/features/profile/screens/profile_screen.dart';

class HomeNavScreen extends StatefulWidget {
  const HomeNavScreen({super.key, this.initialIndex = 0});
  final int initialIndex;
  @override
  State<HomeNavScreen> createState() => _HomeNavScreenState();
}

class _HomeNavScreenState extends State<HomeNavScreen> {
  late int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  final List<Widget> screens = [
    HomeScreen(),
    PlanScreen(),
    AiChatIntroScreen(),
    PractiseScreen(),
    ProfileScreen(),
  ];

  late final List<_NavItemData> _navItems = [
    _NavItemData(icon: FluentMdl2.home, activeIcon: FluentMdl2.home_solid),
    _NavItemData(icon: Bi.clipboard_check, activeIcon: Bi.clipboard_check_fill),
    _NavItemData(icon: AppIcons.ai, activeIcon: AppIcons.aiFilled),
    _NavItemData(
      icon: AppIcons.mouseClick,
      activeIcon: AppIcons.mouseClickFilled,
    ),
    _NavItemData(icon: AppIcons.profile, activeIcon: AppIcons.profileFilled),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final double iconSize = (23 * screenWidth / 360)
        .clamp(19.0, 25.0)
        .toDouble();

    const double barContentHeight = 56.0;

    return Scaffold(
      body: screens.elementAt(currentIndex),

      bottomNavigationBar: Container(
        height: barContentHeight + bottomInset,
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isActive = currentIndex == index;

            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                  child: SizedBox(
                    height: barContentHeight,
                    child: Center(
                      child: Iconify(
                        isActive ? item.activeIcon : item.icon,
                        size: iconSize,
                        color: isActive ? AppColors.primaryColor : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItemData {
  final dynamic icon;
  final dynamic activeIcon;

  _NavItemData({required this.icon, required this.activeIcon});
}
