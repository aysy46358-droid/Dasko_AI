import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/message.dart';
import '../../../services/ai_engine/mock_ai_engine.dart';

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
    });
    _controller.clear();
    _scrollToEnd();

    final result = await _aiEngine.generateResponse(prompt: text);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _messages.add(Message(
            id: _uuid.v4(),
            text: 'حدث خطأ: ${failure.message}',
            isUser: false,
            createdAt: DateTime.now(),
          ));
          _isReplying = false;
        });
      },
      (response) {
        setState(() {
          _messages.add(Message(
            id: _uuid.v4(),
            text: response,
            isUser: false,
            createdAt: DateTime.now(),
          ));
          _isReplying = false;
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
        title: const Text('Dasko AI'),
        centerTitle: true,
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
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
