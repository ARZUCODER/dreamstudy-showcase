import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/providers/animation_provider.dart';
import '../../../../core/providers/idle_provider.dart';
import '../../../../core/providers/dnd_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/data/repositories/user_repository_impl.dart';
import '../providers/courses_provider.dart';
import '../providers/course_progress_provider.dart';
import '../../data/models/course_models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  // YANGI AI MENTOR BANNERI
  Widget _buildAiMentorBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/ai-mentor-chat'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.5), blurRadius: 15)],
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 32),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: const Duration(seconds: 2)),

            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Shaxsiy AI Ustoz",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Istalgan faningizni tanlang va yordam oling.",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 16),
          ],
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 600)).slideX(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final progress = ref.watch(courseProgressProvider);
    final userProfileAsync = ref.watch(currentUserProvider);
    final authUser = ref.watch(authStateChangesProvider).value;

    final isAnimEnabled = ref.watch(animationProvider);
    final isIdle = ref.watch(idleProvider);
    final shimmerStyle = ref.watch(dynamicShimmerProvider);
    final shouldAnimate = isAnimEnabled && !isIdle;

    final aiColors = const [Color(0xFFCBD5E1), Color(0xFF38BDF8), Colors.white, Color(0xFF818CF8), Color(0xFFCBD5E1)];
    final videoColors = const [Color(0xFFCBD5E1), Color(0xFF4285F4), Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853), Color(0xFFCBD5E1)];
    final currentColors = shimmerStyle == LogoAnimationStyle.aiThinking ? aiColors : videoColors;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: coursesAsync.when(
          data: (subjects) {
            int totalLessons = 0;
            for (var s in subjects) {
              totalLessons += s.lessons.length;
            }
            final completedLessonsCount = progress.completedLessons.length;
            final overallProgress = totalLessons == 0 ? 0 : ((completedLessonsCount / totalLessons) * 100).round();

            final scores = progress.quizScores.values;
            final averageScore = scores.isNotEmpty ? (scores.reduce((a, b) => a + b) / scores.length).round() : 0;

            String displayName = "Talaba";
            String? photoUrl;

            if (authUser != null) {
              userProfileAsync.whenData((user) {
                if (user != null) {
                  displayName = user.displayName ?? user.email.split('@').first;
                  photoUrl = user.photoUrl;
                }
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(displayName, photoUrl, shouldAnimate, currentColors),
                  const SizedBox(height: 24),

                  // AI MENTOR BANNERI SHU YERGA QO'SHILDI
                  _buildAiMentorBanner(context),
                  const SizedBox(height: 8),

                  _buildProgressBanner(overallProgress, averageScore, shouldAnimate, currentColors),
                  const SizedBox(height: 24),
                  _buildStatsGrid(subjects.length, completedLessonsCount, totalLessons, averageScore),
                  const SizedBox(height: 32),
                  Text("O'quv Fanlari", style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 24)),
                  const SizedBox(height: 16),
                  _buildSubjectsList(context, subjects, progress, shouldAnimate),
                  const SizedBox(height: 120),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
          error: (e, s) => Center(child: Text("Ma'lumot topilmadi: $e", style: const TextStyle(color: Color(0xFFF43F5E)))),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String? photoUrl, bool shouldAnimate, List<Color> colors) {
    Widget nameWidget = Text(
      "$name! 👋",
      style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 24),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (shouldAnimate) {
      nameWidget = nameWidget.animate(onPlay: (c) => c.repeat()).shimmer(
        duration: const Duration(seconds: 4),
        colors: colors,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Xush kelibsiz,",
                  style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF94A3B8), fontSize: 14)
              ),
              const SizedBox(height: 4),
              nameWidget,
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF818CF8)]),
            boxShadow: shouldAnimate ? [BoxShadow(color: const Color(0xFF38BDF8).withOpacity(0.5), blurRadius: 15)] : [],
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF1E293B),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null ? const Icon(Icons.person, color: Color(0xFF38BDF8), size: 28) : null,
          ),
        ).animate(target: shouldAnimate ? 1 : 0, onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: const Duration(seconds: 2)),
      ],
    ).animate().fadeIn(duration: const Duration(milliseconds: 600)).slideX(begin: -0.1);
  }

  Widget _buildProgressBanner(int overallProgress, int averageScore, bool shouldAnimate, List<Color> colors) {
    Widget banner = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF38BDF8).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreItem("$overallProgress%", "Umumiy progress"),
          Container(width: 1.5, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildScoreItem("$averageScore%", "O'rtacha ball"),
        ],
      ),
    );

    if (shouldAnimate) {
      banner = banner.animate(onPlay: (c) => c.repeat()).shimmer(
        duration: const Duration(seconds: 3),
        colors: [Colors.transparent, Colors.white.withOpacity(0.3), Colors.transparent],
        stops: const [0.0, 0.5, 1.0],
      );
    }

    return banner.animate().fadeIn(delay: const Duration(milliseconds: 150)).slideY(begin: 0.1);
  }

  Widget _buildScoreItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.9))),
      ],
    );
  }

  Widget _buildStatsGrid(int subjectsCount, int completedCount, int totalCount, int avgScore) {
    return Row(
      children: [
        _buildStatCard(Icons.menu_book_rounded, "Fanlar", "$subjectsCount", const Color(0xFF38BDF8), const Color(0xFF38BDF8).withOpacity(0.15)),
        const SizedBox(width: 12),
        _buildStatCard(Icons.check_circle_rounded, "Tugallangan", "$completedCount / $totalCount", const Color(0xFF10B981), const Color(0xFF10B981).withOpacity(0.15)),
        const SizedBox(width: 12),
        _buildStatCard(Icons.emoji_events_rounded, "O'rtacha", "$avgScore%", const Color(0xFFF59E0B), const Color(0xFFF59E0B).withOpacity(0.15)),
      ],
    ).animate().fadeIn(delay: const Duration(milliseconds: 200)).slideY(begin: 0.2);
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color iconColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF334155)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(label, style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF94A3B8), fontSize: 10)),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsList(BuildContext context, List<CourseSubject> subjects, CourseProgressState progress, bool shouldAnimate) {
    return Column(
      children: List.generate(subjects.length, (index) {
        final subject = subjects[index];
        final subjectLessons = subject.lessons.length;

        Color mainColor;
        try {
          mainColor = Color(int.parse(subject.color));
        } catch (_) {
          mainColor = const Color(0xFF38BDF8);
        }

        IconData getIcon(String iconName) {
          switch (iconName) {
            case 'Calculator': return Icons.calculate_rounded;
            case 'Code': return Icons.code_rounded;
            case 'Languages': return Icons.language_rounded;
            case 'Atom': return Icons.science_rounded;
            default: return Icons.public_rounded;
          }
        }

        return GestureDetector(
          onTap: () => context.push('/courses/subject/${subject.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF334155)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: mainColor.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: mainColor.withOpacity(0.5), width: 2)),
                      child: Icon(getIcon(subject.icon), color: mainColor, size: 28),
                    ).animate(target: shouldAnimate ? 1 : 0, onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: const Duration(seconds: 1)),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: mainColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: mainColor.withOpacity(0.3))
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow_rounded, color: mainColor, size: 16),
                          const SizedBox(width: 4),
                          Text("Boshlash", style: AppTextStyles.bodySmall.copyWith(color: mainColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ).animate(target: shouldAnimate ? 1 : 0, onPlay: (c) => c.repeat()).shimmer(duration: const Duration(seconds: 2), color: Colors.white.withOpacity(0.5))
                  ],
                ),
                const SizedBox(height: 16),
                Text(subject.title, style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 22)),
                const SizedBox(height: 8),
                Text(subject.description, style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF94A3B8)), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: const Color(0xFF94A3B8), size: 16),
                    const SizedBox(width: 6),
                    Text("10 ta dars mavjud", style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 300 + (index * 100))).slideX();
      }),
    );
  }
}