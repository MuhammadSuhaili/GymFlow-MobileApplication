/// A single message in the Aira chat thread.
class ChatMessage {
  final String sender; // 'user' | 'aira'
  final String text;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.isError = false,
  });

  bool get isUser => sender == 'user';

  Map<String, dynamic> toJson() => {
        'role': isUser ? 'user' : 'assistant',
        'content': text,
      };
}