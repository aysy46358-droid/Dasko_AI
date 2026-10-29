import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/message.dart';
import '../application/chat_notifier.dart';
import 'animated_neon_border.dart';
import 'chat_robot_state_mapper.dart';
import 'digital_space_background.dart';
import 'interactive_dasko_robot.dart';

const _cyan = Color(0xFF00E5FF);
const _violet = Color(0xFF7C4DFF);

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

  Widget _buildBubble(Message message, double maxWidth) {
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
                isUser ? const Color(0xFF10263A) : const Color(0xFF171326),
            duration: Duration(milliseconds: isUser ? 4200 : 3300),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                message.text,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.graphic_eq_rounded,
              size: 34,
              color: _cyan,
              shadows: [Shadow(color: _cyan, blurRadius: 20)],
            ),
            SizedBox(height: 16),
            Text(
              'أهلاً بك يا داسكو.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [Shadow(color: _violet, blurRadius: 18)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar({required bool isReplying}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xF20B0F19),
        border: Border(top: BorderSide(color: Color(0x443C5C80))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AnimatedNeonBorder(
              borderRadius: 24,
              borderWidth: 1,
              backgroundColor: const Color(0xFF111827),
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x6600E5FF), blurRadius: 18),
                BoxShadow(color: Color(0x447C4DFF), blurRadius: 25),
              ],
            ),
            child: IconButton.filled(
              onPressed: isReplying ? null : _send,
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: const Color(0xFF061018),
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
    final maxWidth = MediaQuery.sizeOf(context).width * .79;
    final chat = ref.watch(chatNotifierProvider);

    ref.listen<ChatState>(chatNotifierProvider, (previous, next) {
      if (previous != null && next.messages.length > previous.messages.length) {
        _scrollToEnd();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        title: const Text(
          'DASKO AI',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            shadows: [Shadow(color: _cyan, blurRadius: 14)],
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xDD0B0F19),
        surfaceTintColor: Colors.transparent,
      ),
      body: DigitalSpaceBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: AnimatedNeonBorder(
                borderRadius: 22,
                borderWidth: 1.15,
                backgroundColor: const Color(0xD9101829),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      InteractiveDaskoRobot(
                        state: mapChatRequestStatusToRobotState(
                          chat.requestStatus,
                        ),
                        size: 82,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'داسكو',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              chat.isReplying
                                  ? 'أفكر بالرد...'
                                  : 'جاهز لمساعدتك',
                              style: TextStyle(
                                fontSize: 12,
                                color: chat.isReplying ? _violet : _cyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.shield_outlined, color: _cyan),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: chat.messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) =>
                          _buildBubble(chat.messages[index], maxWidth),
                    ),
            ),
            _buildInputBar(isReplying: chat.isReplying),
          ],
        ),
      ),
    );
  }
}
