import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/repositories.dart';
import '../../../core/services/permission_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _requestBellPermissions() async {
    final granted =
        await PermissionService.instance.requestNotificationPermission();
    if (!granted) return;

    final hasExact =
        await PermissionService.instance.hasExactAlarmPermission();
    if (!hasExact && mounted) {
      await PermissionService.instance.showExactAlarmDialog(context);
    }

    final batteryIgnored =
        await PermissionService.instance.isBatteryOptimizationIgnored();
    if (!batteryIgnored) {
      await PermissionService.instance.requestBatteryOptimizationExemption();
    }
  }

  Future<void> _finish() async {
    await ref.read(settingsRepositoryProvider).markOnboardingSeen();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _WelcomePage(),
                  _BellsPage(),
                  _ReadyPage(),
                ],
              ),
            ),
            _BottomBar(
              page: _page,
              onNext: _next,
              onRequestPermissions: _requestBellPermissions,
              onFinish: _finish,
              scheme: scheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.self_improvement_rounded,
              size: 52,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Attend',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'A simple meditation timer and mindfulness companion.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface.withAlpha(180),
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

class _BellsPage extends StatelessWidget {
  const _BellsPage();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: scheme.secondary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 52,
              color: scheme.secondary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Mindfulness bells',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Gentle reminders throughout the day to pause, breathe, '
            'and return to the present moment.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface.withAlpha(180),
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'On the next step, we\'ll ask for notification permission '
            'and one battery setting so bells arrive reliably.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withAlpha(120),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReadyPage extends StatelessWidget {
  const _ReadyPage();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.spa_outlined,
              size: 52,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'You\'re ready',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Begin a session whenever you\'re ready.\n\n'
            'You can always configure bells and sounds in Settings.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface.withAlpha(180),
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.page,
    required this.onNext,
    required this.onRequestPermissions,
    required this.onFinish,
    required this.scheme,
  });

  final int page;
  final VoidCallback onNext;
  final Future<void> Function() onRequestPermissions;
  final Future<void> Function() onFinish;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 16, 40, 32),
      child: Column(
        children: [
          // Page dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == page ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == page
                      ? scheme.primary
                      : scheme.primary.withAlpha(50),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          // CTA button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                if (page == 1) {
                  await onRequestPermissions();
                  onNext();
                } else if (page == 2) {
                  await onFinish();
                } else {
                  onNext();
                }
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
              child: Text(
                page == 0
                    ? 'Get started'
                    : page == 1
                        ? 'Enable bells'
                        : 'Begin',
              ),
            ),
          ),
          if (page == 1) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onNext,
              child: Text(
                'Skip for now',
                style: TextStyle(color: scheme.onSurface.withAlpha(120)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
