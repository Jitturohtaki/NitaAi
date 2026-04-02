import 'package:flutter/material.dart';

import '../../../models/chat_message.dart';
import '../../../services/nitaai_api.dart';
import '../../widgets/section_card.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.api,
  });

  final NitaAiApi api;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    _controller.clear();

    try {
      await widget.api.sendMessage(text);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('AI Chat', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 6),
                      Text(
                        widget.api.isLive
                            ? 'Live conversation backed by Firestore.'
                            : 'Demo mode is active until Firebase is configured.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: widget.api.watchMessages(),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <ChatMessage>[];

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  reverse: true,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    return _MessageBubble(message: message);
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: messages.length,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SectionCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask NitaAi about your order...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isSending ? null : _send,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.north_east),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isUser ? theme.colorScheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isUser ? 'You' : 'NitaAi',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isUser ? Colors.white70 : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message.text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isUser ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
