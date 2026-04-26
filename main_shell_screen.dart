import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../courses/presentation/providers/courses_provider.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final Widget child;
  const MainShellScreen({super.key, required this.child});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  bool _isNavExpanded = false;

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/courses')) return 0;
    if (location.startsWith('/feed')) return 1;
    if (location.startsWith('/profile')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    setState(() {
      _isNavExpanded = false;
    });
    switch (index) {
      case 0:
        context.go('/courses');
        break;
      case 1:
        context.go('/feed');
        break;
      case 2:
        context.go('/profile');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBottomNavAsync = ref.watch(bottomNavConfigProvider);
    final location = GoRouterState.of(context).matchedLocation;

    final bool isMainTab = ['/courses', '/feed', '/profile', '/settings'].contains(location);
    final bool isCoursesRoot = location == '/courses';
    final int currentIndex = _calculateSelectedIndex(location);
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children:[
          Positioned.fill(child: widget.child),

          if (!isCoursesRoot && _isNavExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isNavExpanded = false;
                  });
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

          showBottomNavAsync.when(
            data: (showConfig) {
              final bool shouldShow = showConfig && isMainTab;
              final bool isHiddenToSide = !isCoursesRoot && !_isNavExpanded;

              return Stack(
                children:[
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                    bottom: shouldShow ? 20 : -100,
                    left: isHiddenToSide ? -screenWidth : 16,
                    width: screenWidth - 32,
                    child: _GlassBottomNav(
                      currentIndex: currentIndex,
                      onTap: (index) => _onItemTapped(index, context),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                    bottom: 30,
                    left: isHiddenToSide && shouldShow ? 0 : -100,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isNavExpanded = true;
                        });
                      },
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.only(left: 12, right: 16, top: 14, bottom: 14),
                            decoration: BoxDecoration(
                                color: const Color(0xFF1E293B).withOpacity(0.85),
                                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5), width: 1.5),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(24),
                                  bottomRight: Radius.circular(24),
                                ),
                                boxShadow:[
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8).withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  )
                                ]
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children:[
                                const Icon(Icons.menu_rounded, color: Color(0xFF38BDF8), size: 24),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF38BDF8), size: 20)
                                    .animate(onPlay: (c) => c.repeat())
                                    .moveX(begin: -2, end: 4, duration: const Duration(milliseconds: 800))
                                    .fade(begin: 1, end: 0, duration: const Duration(milliseconds: 800)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 75,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3), width: 1.5),
            boxShadow:[
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:[
              _NavItem(icon: Icons.menu_book_rounded, label: "Kurslar", index: 0, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.rocket_launch_rounded, label: "Testlar", index: 1, currentIndex: currentIndex, onTap: onTap),
              _CenterAiButton(
                  onTap: () {
                    onTap(currentIndex);
                    context.push('/ai-mentor-chat');
                  }
              ),
              _NavItem(icon: Icons.person_rounded, label: "Profil", index: 2, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.settings_rounded, label: "Sozlamalar", index: 3, currentIndex: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterAiButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterAiButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors:[
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow:[
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5), width: 1.5),
              ),
              child: Center(
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 24,
                ).animate(onPlay: (c) => c.repeat()).shimmer(
                  duration: const Duration(seconds: 2),
                  colors: const[
                    Color(0xFF4285F4),
                    Color(0xFFEA4335),
                    Color(0xFFFBBC05),
                    Color(0xFF34A853),
                    Color(0xFF4285F4),
                  ],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: const Duration(seconds: 2),
            ),
            const SizedBox(height: 4),
            const Text(
              "AI Mentor",
              style: TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final color = isSelected ? const Color(0xFF38BDF8) : const Color(0xFF64748B);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: isSelected ? 4.0 : 0.0),
              child: Icon(icon, color: color, size: isSelected ? 28 : 24),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}