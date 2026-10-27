import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/message.dart';
import '../../../services/ai_engine/mock_ai_engine.dart';
import 'interactive_dasko_robot.dart';

final _uuid = Uuid();

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _isReplying = false;
  DaskoRobotState _robotState = DaskoRobotState.ready;

  final _aiEngine = MockAiEngine();

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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isReplying) return;

    final userMessage = Message(
      id: _uuid.v4(),
      text: text,
      isUser: true,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isReplying = true;
      _robotState = DaskoRobotState.thinking;
    });
    _controller.clear();
    _scrollToEnd();

    final result = await _aiEngine.generateResponse(prompt: text);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _messages.add(
            Message(
              id: _uuid.v4(),
              text: 'حدث خطأ: ${failure.message}',
              isUser: false,
              createdAt: DateTime.now(),
            ),
          );
          _isReplying = false;
          _robotState = DaskoRobotState.happy;
        });
      },
      (response) {
        setState(() {
          _messages.add(
            Message(
              id: _uuid.v4(),
              text: response,
              isUser: false,
              createdAt: DateTime.now(),
            ),
          );
          _isReplying = false;
          _robotState = DaskoRobotState.happy;
        });
      },
    );

    _scrollToEnd();
  }

  Widget _buildBubble(Message message, double maxWidth) {
    return Align(
      alignment: message.isUser
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: message.isUser
                ? const Color(0xFF1F3A5F)
                : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: message.isUser
                  ? const Color(0xAA00E5FF)
                  : const Color(0xAA7C4DFF),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (message.isUser
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFF7C4DFF))
                        .withOpacity(0.12),
                blurRadius: 14,
              ),
            ],
          ),
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
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 40, color: Color(0xFF8AB4F8)),
          SizedBox(height: 16),
          Text(
            'كيف أقدر أساعدك اليوم؟',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: Colors.black,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _isReplying ? null : _send,
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF8AB4F8),
              foregroundColor: Colors.black,
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DASKO AI'),
        centerTitle: true,
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const SizedBox(width: 4),
                InteractiveDaskoRobot(state: _robotState, size: 54),
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
                      Text(
                        _isReplying ? 'أفكر بالرد...' : 'جاهز لمساعدتك',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isReplying
                              ? const Color(0xFF7C4DFF)
                              : const Color(0xFF00E5FF),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.shield_outlined, color: Color(0xFF00E5FF)),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _buildBubble(_messages[index], maxWidth),
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }
}
