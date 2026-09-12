import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/bi.dart';
import 'package:iconify_flutter/icons/fluent_mdl2.dart';
import 'package:sawa/app_icons.dart';
import 'package:sawa/app_colors.dart';
import 'package:sawa/screens/ai_chat_screen.dart';
import 'package:sawa/screens/home_screen.dart';
import 'package:sawa/screens/plan_screen.dart';
import 'package:sawa/screens/practise_screen.dart';
import 'package:sawa/screens/profile_screen.dart';

class HomeNavScreen extends StatefulWidget {
  const HomeNavScreen({super.key});

  @override
  State<HomeNavScreen> createState() => _HomeNavScreenState();
}

class _HomeNavScreenState extends State<HomeNavScreen> {
  int currentIndex = 0;

  final List<Widget> screens = [
    HomeScreen(),
    PlanScreen(),
    AiChatScreen(),
    PractiseScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final double iconSize = (23 * screenWidth / 360)
        .clamp(19.0, 25.0)
        .toDouble();

    final double iconContainerSize = (29 * screenWidth / 360)
        .clamp(26.0, 31.0)
        .toDouble();

    return Scaffold(
      body: screens.elementAt(currentIndex),

      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: Container(
          height: 75.h,

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

          child: BottomNavigationBar(
            backgroundColor: Colors.white,

            currentIndex: currentIndex,

            iconSize: iconSize,

            selectedItemColor: AppColors.primaryColor,
            unselectedItemColor: Colors.black,

            type: BottomNavigationBarType.fixed,

            showSelectedLabels: false,
            showUnselectedLabels: false,

            items: [
              BottomNavigationBarItem(
                icon: _navIcon(
                  containerSize: iconContainerSize,
                  child: Iconify(
                    FluentMdl2.home,
                    size: iconSize,
                    color: AppColors.primaryColor,
                  ),
                ),
                activeIcon: _navIcon(
                  containerSize: iconContainerSize,
                  child: Iconify(
                    FluentMdl2.home_solid,
                    size: iconSize,
                    color: AppColors.primaryColor,
                  ),
                ),
                label: '',
              ),

              BottomNavigationBarItem(
                icon: _navIcon(
                  containerSize: iconContainerSize,
                  child: Iconify(
                    Bi.clipboard_check,
                    size: iconSize,
                    color: Colors.black,
                  ),
                ),
                activeIcon: _navIcon(
                  containerSize: iconContainerSize,
                  child: Iconify(
                    Bi.clipboard_check_fill,
                    size: iconSize,
                    color: AppColors.primaryColor,
                  ),
                ),
                label: '',
              ),

              BottomNavigationBarItem(
                icon: _navIcon(
                  containerSize: iconContainerSize,
                  child: Iconify(
                    AppIcons.ai,
                    size: iconSize,
                    color: Colors.black,
                  ),
                ),
                activeIcon: _navIcon(
                  containerSize: iconContainerSize,
                  child: Iconify(
                    AppIcons.aiFilled,
                    size: iconSize,
                    color: AppColors.primaryColor,
                  ),
                ),
                label: '',
              ),

              BottomNavigationBarItem(
                icon: _navIcon(
                  containerSize: iconContainerSize,
                  child: Iconify(
                    AppIcons.mouseClick,
                    size: iconSize,
                    color: Colors.black,
                  ),
                ),
                activeIcon: _navIcon(
                  containerSize: iconContainerSize,
                  child: Iconify(
                    AppIcons.mouseClickFilled,
                    size: iconSize,
                    color: AppColors.primaryColor,
                  ),
                ),
                label: '',
              ),

              BottomNavigationBarItem(
                icon: _navIcon(
                  containerSize: iconContainerSize,
                  child: Iconify(
                    AppIcons.profile,
                    size: iconSize,
                    color: Colors.black,
                  ),
                ),
                activeIcon: _navIcon(
                  containerSize: iconContainerSize,
                  child: Iconify(
                    AppIcons.profileFilled,
                    size: iconSize,
                    color: AppColors.primaryColor,
                  ),
                ),
                label: '',
              ),
            ],

            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _navIcon({required double containerSize, required Widget child}) {
    return SizedBox(
      width: containerSize,
      height: containerSize,
      child: Center(child: child),
    );
  }
}
