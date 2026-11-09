import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/message.dart';
import '../../../core/theme/app_theme_mode.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/chat_notifier.dart';
import '../application/chat_request_status.dart';
import 'animated_neon_border.dart';
import 'chat_robot_state_mapper.dart';
import 'digital_space_background.dart';
import 'interactive_dasko_robot.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    await ref.read(chatNotifierProvider.notifier).send(text);
    if (!mounted) return;
    _scrollToEnd();
  }

  Widget _buildBubble(BuildContext context, Message message, double maxWidth) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isUser = message.isUser;
    // Borders are palette-specific: LED glow for Dark, animated neon for Neon,
    // plain frosted glass for Light.
    final appThemeMode = ref.watch(themeProvider);

    final bubble = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // Frosted glass: the space background shows through.
            color: isUser
                ? colors.primary.withValues(alpha: 0.2)
                : colors.surface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Text(
            message.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              height: 1.5,
              color: colors.onSurface,
            ),
          ),
        ),
      ),
    );

    final decorated = switch (appThemeMode) {
      AppThemeMode.dark => _LedGlow(child: bubble),
      AppThemeMode.neon => AnimatedNeonBorder(
        borderRadius: 18,
        borderWidth: 2,
        backgroundColor: Colors.transparent,
        duration: Duration(milliseconds: isUser ? 4200 : 3300),
        child: bubble,
      ),
      AppThemeMode.light => bubble,
    };

    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: decorated,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq_rounded, size: 34, color: colors.primary),
            const SizedBox(height: 16),
            Text(
              AppStrings.introGreeting,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, {required bool isReplying}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final glow = theme.extension<NeonGlow>();

    OutlineInputBorder roundedBorder() => OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        // Follows the active palette; no hardcoded dark bar in light mode.
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AnimatedNeonBorder(
              borderRadius: 24,
              borderWidth: 1,
              backgroundColor: colors.surfaceContainerHighest,
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                // Dark/Neon draw a dark keyboard, Light draws a light one.
                keyboardAppearance: theme.brightness == Brightness.dark
                    ? Brightness.dark
                    : Brightness.light,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  color: colors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.chatInputHint,
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  border: roundedBorder(),
                  enabledBorder: roundedBorder(),
                  focusedBorder: roundedBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: glow?.borderGlow ?? const <BoxShadow>[],
            ),
            child: IconButton.filled(
              onPressed: isReplying ? null : _send,
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                minimumSize: const Size(48, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxWidth = MediaQuery.sizeOf(context).width * .79;
    // Narrow selections: the screen rebuilds only when the message list or the
    // reply flag actually changes, never for unrelated state updates.
    final messages = ref.watch(
      chatNotifierProvider.select((state) => state.messages),
    );
    final isReplying = ref.watch(
      chatNotifierProvider.select((state) => state.isReplying),
    );

    ref.listen<ChatState>(chatNotifierProvider, (previous, next) {
      if (previous != null && next.messages.length > previous.messages.length) {
        _scrollToEnd();
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppConstants.appWordmark),
        actions: [
          IconButton(
            tooltip: AppStrings.settingsTooltip,
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: DigitalSpaceBackground(
        child: Column(
          children: [
            const _RobotStatusHeader(),
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) =>
                          _buildBubble(context, messages[index], maxWidth),
                    ),
            ),
            _buildInputBar(context, isReplying: isReplying),
          ],
        ),
      ),
    );
  }
}

/// Narrow status header: it selects only [ChatState.requestStatus], so the
/// robot subtree rebuilds on status transitions instead of every chat update.
class _RobotStatusHeader extends ConsumerWidget {
  const _RobotStatusHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final requestStatus = ref.watch(
      chatNotifierProvider.select((state) => state.requestStatus),
    );
    final isReplying = requestStatus == ChatRequestStatus.sending;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: AnimatedNeonBorder(
        borderRadius: 22,
        borderWidth: 1.15,
        backgroundColor: colors.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              InteractiveDaskoRobot(
                state: mapChatRequestStatusToRobotState(requestStatus),
                size: 82,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.robotName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isReplying
                          ? AppStrings.thinkingRobot
                          : AppStrings.readyRobot,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isReplying ? colors.secondary : colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.shield_outlined, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cyan LED halo wrapped around chat bubbles for the pitch-black Dark palette.
///
/// `AnimatedContainer` smooths each step of the pulse, and the slower
/// controller sweep produces the breathing "LED" rhythm.
class _LedGlow extends StatefulWidget {
  const _LedGlow({required this.child});

  final Widget child;

  @override
  State<_LedGlow> createState() => _LedGlowState();
}

class _LedGlowState extends State<_LedGlow>
    with SingleTickerProviderStateMixin {
  static const Color _led = Color(0xFF00E5FF);

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final intensity = Curves.easeInOut.transform(_pulse.value);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.linear,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _led.withValues(alpha: 0.18 + intensity * 0.12),
            ),
            boxShadow: [
              // Two layers: a tight rim plus a wide bloom for the LED feel.
              BoxShadow(
                color: _led.withValues(alpha: 0.12 + intensity * 0.18),
                blurRadius: 6 + intensity * 4,
                spreadRadius: 0.25 + intensity * 0.5,
              ),
              BoxShadow(
                color: _led.withValues(alpha: 0.06 + intensity * 0.09),
                blurRadius: 16 + intensity * 8,
                spreadRadius: 1 + intensity * 1.5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
