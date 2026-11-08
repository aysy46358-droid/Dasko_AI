import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/message.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/chat_notifier.dart';
import '../application/chat_request_status.dart';
import 'animated_neon_border.dart';
import 'chat_robot_state_mapper.dart';
import 'digital_space_background.dart';
import 'interactive_dasko_robot.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.robotViewerOverride});

  final Widget? robotViewerOverride;

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

    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: AnimatedNeonBorder(
            borderRadius: 18,
            borderWidth: 1.25,
            backgroundColor:
                isUser ? colors.primaryContainer : colors.secondaryContainer,
            duration: Duration(milliseconds: isUser ? 4200 : 3300),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                message.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  height: 1.5,
                  color: isUser
                      ? colors.onPrimaryContainer
                      : colors.onSecondaryContainer,
                ),
              ),
            ),
          ),
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
        color: colors.surface,
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
            _RobotStatusHeader(
              robotViewerOverride: widget.robotViewerOverride,
            ),
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

/// Narrow status header: it selects only [ChatState.requestStatus], so the 3D
/// robot subtree rebuilds on status transitions instead of every chat update.
class _RobotStatusHeader extends ConsumerWidget {
  const _RobotStatusHeader({this.robotViewerOverride});

  final Widget? robotViewerOverride;

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
                modelViewerOverride: robotViewerOverride,
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
