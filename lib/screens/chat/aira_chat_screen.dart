import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:gym_flow/core/constants/app_constants.dart';
import 'package:gym_flow/models/chat_message.dart';
import 'package:gym_flow/providers/app_providers.dart';
import 'package:gym_flow/services/aira_chat_service.dart';
import 'package:gym_flow/services/aira_context_service.dart';
import 'package:gym_flow/widgets/markdown_text.dart';

/// Bottom-sheet chat panel for the Aira assistant.
class AiraChatSheet extends ConsumerStatefulWidget {
  const AiraChatSheet({super.key, this._service});

  final AiraChatService? _service;

  @override
  ConsumerState<AiraChatSheet> createState() => _AiraChatSheetState();
}

class _AiraChatSheetState extends ConsumerState<AiraChatSheet> {
  late final AiraChatService _service = widget._service ?? AiraChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _context;

  static final DateFormat _timeFormat = DateFormat.jm();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _buildContext() async {
    if (_context != null) return _context!;
    final context = await AiraContextService(
      users: ref.read(userRepositoryProvider),
      programs: ref.read(programRepositoryProvider),
      workouts: ref.read(workoutRepositoryProvider),
    ).build();
    _context = context;
    return context;
  }

  void _addMessage(String text, {String sender = 'user', bool isError = false}) {
    setState(() {
      _messages.add(ChatMessage(
        sender: sender,
        text: text,
        timestamp: DateTime.now(),
        isError: isError,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String raw) async {
    final message = raw.trim();
    if (message.isEmpty || _isLoading) return;

    _controller.clear();
    _addMessage(message, sender: 'user');

    setState(() => _isLoading = true);
    try {
      final context = await _buildContext();
      final reply = await _service.sendMessage(
        message: message,
        history: _messages,
        context: context,
      );
      if (!mounted) return;
      _addMessage(reply, sender: 'aira');
    } on AiraChatException catch (e) {
      if (!mounted) return;
      _addMessage(e.message, sender: 'aira', isError: true);
    } catch (_) {
      if (!mounted) return;
      _addMessage(
        'Maaf, terjadi kendala saat menghubungi Aira. Coba lagi.',
        sender: 'aira',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF12161E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _grabHandle(theme),
            _header(theme),
            Expanded(
              child: _messages.isEmpty
                  ? _emptyState(theme)
                  : _messageList(theme),
            ),
            if (_messages.isEmpty && !_isLoading) _suggestions(theme),
            _inputBar(scheme),
          ],
        ),
      ),
    );
  }

  Widget _grabHandle(ThemeData theme) => Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _header(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.smart_toy_rounded, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aira',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  'Asisten latihan Anda',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Tutup',
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: 44,
              color: scheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Halo! Saya Aira, asisten latihan Anda.\n'
              'Tanya apa saja seputar program, teknik, atau nutrisi.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageList(ThemeData theme) {
    final scheme = theme.colorScheme;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return const _TypingBubble();
        return _MessageBubble(
          key: ValueKey(_messages[index].timestamp),
          message: _messages[index],
          isUser: _messages[index].isUser,
          timeFormat: _timeFormat,
          scheme: scheme,
        );
      },
    );
  }

  Widget _suggestions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in AppConstants.airaSuggestions)
            ActionChip(
              avatar: const Icon(Icons.arrow_outward_rounded, size: 16),
              label: Text(s),
              onPressed: () => _send(s),
            ),
        ],
      ),
    );
  }

  Widget _inputBar(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: const InputDecoration(
                    hintText: 'Tanya Aira…',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _SendButton(
              enabled: !_isLoading,
              onPressed: () => _send(_controller.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton.filled(
      onPressed: enabled ? onPressed : null,
      tooltip: 'Kirim',
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: scheme.primary,
        disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.4),
      ),
      icon: const Icon(Icons.arrow_upward_rounded),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.timeFormat,
    required this.scheme,
  });

  final ChatMessage message;
  final bool isUser;
  final DateFormat timeFormat;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final bubbleColor = isUser
        ? scheme.onPrimary
        : (message.isError ? scheme.onErrorContainer : scheme.onSurface);

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser
            ? scheme.primary
            : (message.isError
                ? scheme.errorContainer
                : scheme.surfaceContainerHighest),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
      ),
      child: isUser
          ? Text(
              message.text,
              style: textStyle?.copyWith(color: bubbleColor),
            )
          : MarkdownText(message.text,
              style: textStyle?.copyWith(color: bubbleColor)),
    );

    final time = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        timeFormat.format(message.timestamp),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          bubble,
          const SizedBox(height: 3),
          time,
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final phase = (_controller.value + i / 3) % 1.0;
                  return Opacity(
                    opacity: 0.25 + 0.75 * (1 - (phase - 0.5).abs() * 2),
                    child: child,
                  );
                },
                child: Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}