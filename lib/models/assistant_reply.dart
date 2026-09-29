class AssistantReply {
  const AssistantReply({
    required this.text,
    this.actions = const [],
    this.ai = false,
  });

  final String text;
  final List<String> actions;
  final bool ai;

  factory AssistantReply.fromJson(Map<String, dynamic> json) {
    return AssistantReply(
      text: json['reply'] as String? ?? '',
      actions: (json['actions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      ai: json['ai'] == true,
    );
  }
}
