import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/presentation/widgets/custom_drawer.dart';
import '../../../../core/presentation/widgets/glowing_ai_fab.dart';
import '../../../../core/providers/animation_provider.dart';
import '../../../../core/providers/dnd_provider.dart';
import '../../../../core/providers/idle_provider.dart';
import '../../../profile/data/repositories/user_repository_impl.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/feed_provider.dart';
import '../widgets/test_set_view.dart';
import '../widgets/futuristic_tab_bar.dart';

class PremiumBrandLogo extends ConsumerWidget {
  const PremiumBrandLogo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnimEnabled = ref.watch(animationProvider);
    final isIdle = ref.watch(idleProvider);
    final shimmerStyle = ref.watch(dynamicShimmerProvider);

    final shouldAnimate = isAnimEnabled && !isIdle;

    Widget textWidget = Text(
      "DREAM STUDY",
      style: GoogleFonts.cinzelDecorative(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: shouldAnimate ? const Color(0xFFCBD5E1) : Colors.white,
        letterSpacing: 1.5,
      ),
    );

    if (shouldAnimate) {
      final colors = shimmerStyle == LogoAnimationStyle.aiThinking
          ? const [Color(0xFFCBD5E1), Color(0xFF38BDF8), Colors.white, Color(0xFF818CF8), Color(0xFFCBD5E1)]
          : const [Color(0xFFCBD5E1), Color(0xFF4285F4), Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853), Color(0xFFCBD5E1)];

      textWidget = textWidget.animate(onPlay: (c) => c.repeat()).shimmer(
        duration: const Duration(seconds: 4),
        colors: colors,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.rocket_launch_rounded, color: Color(0xFF38BDF8), size: 28),
        const SizedBox(width: 8),
        textWidget,
      ],
    );
  }
}

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PageController _feedPageController;
  int _lastPageIndex = 0;

  bool _isFilterVisible = true;
  Timer? _tabsTimer;
  Timer? _inactivityTimer;
  Timer? _animationSafetyTimer;
  bool _showStreak = true;

  @override
  void initState() {
    super.initState();
    _feedPageController = PageController();
    _startTabsTimer();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showStreak = false);
    });

    _resetInactivityTimer();
    _startAnimationSafetyTimer();
  }

  @override
  void dispose() {
    _feedPageController.dispose();
    _tabsTimer?.cancel();
    _inactivityTimer?.cancel();
    _animationSafetyTimer?.cancel();
    super.dispose();
  }

  void _startAnimationSafetyTimer() {
    _animationSafetyTimer?.cancel();

    final dndState = ref.read(dndProvider);
    if (!dndState.isAutoAnimOffEnabled) return;

    _animationSafetyTimer = Timer(Duration(seconds: dndState.autoAnimOffDuration), () {
      if (mounted && ref.read(animationProvider)) {
        ref.read(animationProvider.notifier).toggle();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Quvvatni tejash maqsadida animatsiyalar avtomatik to'xtatildi."),
              backgroundColor: Color(0xFFF59E0B),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  void _toggleTabs() {
    if (!mounted) return;
    setState(() {
      _isFilterVisible = !_isFilterVisible;
      if (_isFilterVisible) {
        _startTabsTimer();
      } else {
        _tabsTimer?.cancel();
      }
    });
  }

  void _startTabsTimer() {
    if (!mounted) return;
    setState(() => _isFilterVisible = true);
    _tabsTimer?.cancel();
    _tabsTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _isFilterVisible = false);
    });
  }

  void _hideTabsInstantly() {
    _tabsTimer?.cancel();
    if (_isFilterVisible && mounted) {
      setState(() => _isFilterVisible = false);
    }
  }

  void _resetInactivityTimer() {
    if (mounted && ref.read(idleProvider)) {
      ref.read(idleProvider.notifier).state = false;
      _startTabsTimer();
    }
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 60), () {
      if (mounted) ref.read(idleProvider.notifier).state = true;
    });
  }

  void _onFeedPageChanged(int index) {
    if (mounted) setState(() => _lastPageIndex = index);
  }

  Widget _buildStreakCalendar(dynamic userProfile, bool shouldAnimate) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final streak = userProfile.currentStreak as int;
    final lastActive = userProfile.lastActiveDate ?? now;

    final streakStartDate = DateTime(lastActive.year, lastActive.month, lastActive.day).subtract(Duration(days: streak > 0 ? streak - 1 : 0));
    final streakEndDate = DateTime(lastActive.year, lastActive.month, lastActive.day);
    final weekDays = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF43F5E).withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final date = startOfWeek.add(Duration(days: index));
          final cleanDate = DateTime(date.year, date.month, date.day);
          final cleanNow = DateTime(now.year, now.month, now.day);

          bool isLit = false;
          if ((cleanDate.isAfter(streakStartDate) || cleanDate.isAtSameMomentAs(streakStartDate)) &&
              (cleanDate.isBefore(streakEndDate) || cleanDate.isAtSameMomentAs(streakEndDate))) {
            isLit = true;
          }

          Widget fireIcon = Icon(
            Icons.local_fire_department_rounded,
            color: isLit ? const Color(0xFFF43F5E) : const Color(0xFF334155),
            size: 32,
          );

          if (isLit && shouldAnimate) {
            fireIcon = fireIcon.animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: const Duration(milliseconds: 800)
            ).shimmer(duration: const Duration(seconds: 2), colors: [const Color(0xFFF43F5E), const Color(0xFFF59E0B), const Color(0xFFF43F5E)]);
          }

          return Column(
            children: [
              Text(weekDays[index], style: AppTextStyles.bodySmall.copyWith(color: cleanDate.isAtSameMomentAs(cleanNow) ? const Color(0xFFF43F5E) : const Color(0xFF64748B), fontSize: 11)),
              const SizedBox(height: 8),
              fireIcon,
              const SizedBox(height: 8),
              Text("${date.day}", style: AppTextStyles.bodyMedium.copyWith(color: cleanDate.isAtSameMomentAs(cleanNow) ? const Color(0xFFF43F5E) : const Color(0xFF64748B))),
            ],
          );
        }),
      ),
    );
  }

  void _showFocusModeSheet(BuildContext context, WidgetRef ref) {
    _tabsTimer?.cancel();
    if (mounted) setState(() => _isFilterVisible = false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Consumer(
          builder: (context, ref, child) {
            final dnd = ref.watch(dndProvider);
            final dndNotifier = ref.read(dndProvider.notifier);
            final userProfile = ref.watch(currentUserProvider).value;

            final isAnimEnabled = ref.watch(animationProvider);
            final isIdle = ref.watch(idleProvider);
            final shouldAnimate = isAnimEnabled && !isIdle;
            final shimmerStyle = ref.watch(dynamicShimmerProvider);

            Widget titleWidget = Text(" Sozlamalar", style: AppTextStyles.h1.copyWith(color: shouldAnimate ? const Color(0xFFCBD5E1) : Colors.white));
            Widget streakWidget = const Text("HAFTALIK OLOV (STREAK)", style: TextStyle(color: Color(0xFFF43F5E), fontSize: 12, fontWeight: FontWeight.bold));

            if (shouldAnimate) {
              final colors = shimmerStyle == LogoAnimationStyle.aiThinking
                  ? const [Color(0xFFCBD5E1), Color(0xFF38BDF8), Colors.white, Color(0xFF818CF8), Color(0xFFCBD5E1)]
                  : const [Color(0xFFCBD5E1), Color(0xFF4285F4), Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853), Color(0xFFCBD5E1)];

              titleWidget = titleWidget.animate(onPlay: (c) => c.repeat()).shimmer(duration: const Duration(seconds: 3), colors: colors);
              streakWidget = streakWidget.animate(onPlay: (c) => c.repeat()).shimmer(duration: const Duration(seconds: 2), colors: [const Color(0xFFF43F5E), const Color(0xFFF59E0B), Colors.white, const Color(0xFFF43F5E)]);
            }

            return Container(
              padding: const EdgeInsets.only(top: 16, bottom: 30),
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(color: Color(0xFF0F172A), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                children: [
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.settings_suggest_rounded, color: Color(0xFF38BDF8), size: 28),
                      const SizedBox(width: 10),
                      titleWidget,
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text("Sayohatni o'zingizga moslashtiring", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  const Divider(color: Color(0xFF334155), height: 30),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (userProfile != null) ...[
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), child: streakWidget),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: _buildStreakCalendar(userProfile, shouldAnimate)),
                          const SizedBox(height: 10),
                        ],

                        const Divider(color: Color(0xFF334155)),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10), child: Text("ANIMATSIYALAR VA TEJASH", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold))),
                        _buildSettingSwitch(
                          "Fon va Logotip animatsiyalari",
                          Icons.animation_rounded,
                          isAnimEnabled,
                              (val) => ref.read(animationProvider.notifier).toggle(),
                        ),
                        _buildSettingSwitch(
                          "Avto-o'chirish (Batareya uchun)",
                          Icons.timer_off_rounded,
                          dnd.isAutoAnimOffEnabled,
                              (val) {
                            dndNotifier.toggleAutoAnimOff(val);
                          },
                        ),
                        if (dnd.isAutoAnimOffEnabled)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Kutish vaqti", style: TextStyle(color: Color(0xFF94A3B8))),
                                DropdownButton<int>(
                                  dropdownColor: const Color(0xFF1E293B),
                                  value: dnd.autoAnimOffDuration,
                                  underline: const SizedBox(),
                                  icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF38BDF8)),
                                  items: const [
                                    DropdownMenuItem(value: 30, child: Text("30 sekund", style: TextStyle(color: Colors.white))),
                                    DropdownMenuItem(value: 60, child: Text("1 daqiqa", style: TextStyle(color: Colors.white))),
                                    DropdownMenuItem(value: 120, child: Text("2 daqiqa", style: TextStyle(color: Colors.white))),
                                    DropdownMenuItem(value: 300, child: Text("5 daqiqa", style: TextStyle(color: Colors.white))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) dndNotifier.setAutoAnimOffDuration(val);
                                  },
                                ),
                              ],
                            ),
                          ),

                        const Divider(color: Color(0xFF334155)),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10), child: Text("LOGOTIP USLUBI", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold))),
                        RadioListTile<LogoAnimationStyle>(
                          title: const Text("Oq rang, oddiy", style: TextStyle(color: Colors.white)),
                          value: LogoAnimationStyle.cosmic,
                          groupValue: dnd.logoStyle,
                          activeColor: const Color(0xFF38BDF8),
                          onChanged: (style) => dndNotifier.setLogoStyle(style!),
                        ),
                        RadioListTile<LogoAnimationStyle>(
                          title: const Text("AI Fikrlash (Ko'k va Binafsha)", style: TextStyle(color: Colors.white)),
                          value: LogoAnimationStyle.aiThinking,
                          groupValue: dnd.logoStyle,
                          activeColor: const Color(0xFF38BDF8),
                          onChanged: (style) => dndNotifier.setLogoStyle(style!),
                        ),
                        RadioListTile<LogoAnimationStyle>(
                          title: const Text("Videodagi AI (Rangbarang)", style: TextStyle(color: Colors.white)),
                          value: LogoAnimationStyle.videoStyle,
                          groupValue: dnd.logoStyle,
                          activeColor: const Color(0xFF38BDF8),
                          onChanged: (style) => dndNotifier.setLogoStyle(style!),
                        ),

                        const Divider(color: Color(0xFF334155)),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10), child: Text("BOSHQARUV REJIMI", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold))),
                        RadioListTile<SwipeMode>(
                          title: const Text("Rejim 1: Fanlar pastga, Savollar yonga", style: TextStyle(color: Colors.white)),
                          value: SwipeMode.mode1,
                          groupValue: dnd.swipeMode,
                          activeColor: const Color(0xFF38BDF8),
                          onChanged: (mode) => dndNotifier.setSwipeMode(mode!),
                        ),
                        RadioListTile<SwipeMode>(
                          title: const Text("Rejim 2: Fanlar yonga, Savollar pastga", style: TextStyle(color: Colors.white)),
                          value: SwipeMode.mode2,
                          groupValue: dnd.swipeMode,
                          activeColor: const Color(0xFF38BDF8),
                          onChanged: (mode) => dndNotifier.setSwipeMode(mode!),
                        ),

                        const Divider(color: Color(0xFF334155)),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10), child: Text("TEST ELEMENTLARI", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold))),
                        _buildSettingSwitch("Taymerni yoqish", Icons.timer, dnd.isTimerEnabled, dndNotifier.toggleTimer),
                        _buildSettingSwitch("AI Yordamchini ko'rsatish", Icons.auto_awesome, dnd.showAiHelper, dndNotifier.toggleAiHelper),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingSwitch(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF38BDF8).withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF38BDF8), size: 20)),
      title: Text(title, style: AppTextStyles.bodyLarge.copyWith(color: Colors.white)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF38BDF8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final dndState = ref.watch(dndProvider);
    final isIdle = ref.watch(idleProvider);
    final userProfile = ref.watch(currentUserProvider).value;

    ref.listen<DndState>(dndProvider, (prev, next) {
      if (prev?.isAutoAnimOffEnabled != next.isAutoAnimOffEnabled ||
          prev?.autoAnimOffDuration != next.autoAnimOffDuration) {
        _startAnimationSafetyTimer();
      }
    });

    final feedScrollAxis = dndState.swipeMode == SwipeMode.mode1 ? Axis.vertical : Axis.horizontal;

    return Listener(
      onPointerDown: (_) {
        _resetInactivityTimer();
        _startAnimationSafetyTimer();
      },
      onPointerMove: (_) => _resetInactivityTimer(),
      onPointerUp: (_) => _resetInactivityTimer(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const CustomDrawer(),
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF1E293B),
          centerTitle: true,
          title: const PremiumBrandLogo(),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _showStreak && userProfile != null
                    ? Row(
                  key: const ValueKey('streak'),
                  children: [
                    const Text("🔥", style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 4),
                    Text("${userProfile.currentStreak}", style: AppTextStyles.h2.copyWith(color: const Color(0xFFF43F5E))),
                  ],
                )
                    : IconButton(
                  key: const ValueKey('dnd'),
                  icon: const Icon(Icons.tune_rounded, color: Color(0xFF38BDF8)),
                  onPressed: () => _showFocusModeSheet(context, ref),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80.0),
          child: GlowingAiFab(onPressed: () => context.push('/feed/ai-generator')),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                FuturisticTabBar(isVisible: _isFilterVisible, onTimerRestart: _startTabsTimer),
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF38BDF8),
                    backgroundColor: const Color(0xFF1E293B),
                    onRefresh: () async => ref.invalidate(rawFeedProvider),
                    child: feedState.when(
                      data: (testSets) {
                        if (testSets.isEmpty) return ListView(children: const [SizedBox(height: 200), Center(child: Text("Testlar topilmadi", style: TextStyle(color: Color(0xFF94A3B8))))]);
                        return PageView.builder(
                          controller: _feedPageController,
                          scrollDirection: feedScrollAxis,
                          onPageChanged: _onFeedPageChanged,
                          itemCount: testSets.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 80.0),
                              child: TestSetView(
                                testSet: testSets[index],
                                isActive: _lastPageIndex == index,
                                onOptionSelected: _hideTabsInstantly,
                                onGoNext: () { if (index < testSets.length - 1) _feedPageController.animateToPage(index + 1, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut); },
                                onSwipeNextTestSet: () { if (index < testSets.length - 1) _feedPageController.animateToPage(index + 1, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut); },
                                onSwipePrevTestSet: () { if (index > 0) _feedPageController.animateToPage(index - 1, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut); },
                              ),
                            );
                          },
                        );
                      },
                      error: (err, stack) => Center(child: Text('Xatolik: $err', style: const TextStyle(color: Colors.red))),
                      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
                    ),
                  ),
                ),
              ],
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              top: 12,
              right: _isFilterVisible ? -50 : 12,
              child: SafeArea(
                child: GestureDetector(
                  onTap: _toggleTabs,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B).withOpacity(0.8), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF334155))),
                    child: Icon(_isFilterVisible ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: const Color(0xFF38BDF8)),
                  ),
                ),
              ),
            ),
            if (isIdle)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _resetInactivityTimer,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black.withOpacity(0.9),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.nightlight_round, color: Color(0xFF38BDF8), size: 80).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: const Duration(seconds: 2)),
                          const SizedBox(height: 24),
                          Text("Siz shu yerdamisiz?", style: AppTextStyles.h1.copyWith(color: Colors.white)),
                          const SizedBox(height: 16),
                          Text("Batareyani tejash maqsadida\ndastur vaqtinchalik to'xtatildi.", style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70), textAlign: TextAlign.center),
                          const SizedBox(height: 40),
                          ElevatedButton(onPressed: _resetInactivityTimer, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)), child: Text("Davom etish", style: AppTextStyles.bodyLarge.copyWith(color: Colors.white)))
                        ],
                      ),
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}