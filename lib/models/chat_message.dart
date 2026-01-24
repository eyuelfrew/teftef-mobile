class ChatMessage {
  final String text;
  final bool isSender; // true if it's the current user (buyer), false if it's the seller
  final String timestamp;

  ChatMessage({
    required this.text,
    required this.isSender,
    required this.timestamp,
  });
}