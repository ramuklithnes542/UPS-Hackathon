class CommandParser {
  static final List<String> commands = [
    "shipment from",
    "shipment to",
    "weight",
    "package type"
  ];

  static Map<String, String> extractFields(String transcript) {
    final Map<String, String> results = {};
    final normalized = transcript.toLowerCase();

    for (int i = 0; i < commands.length; i++) {
      final command = commands[i];
      final nextCommand = i + 1 < commands.length ? commands[i + 1] : null;

      if (normalized.contains(command)) {
        int start = normalized.indexOf(command) + command.length;
        int end = nextCommand != null && normalized.contains(nextCommand)
            ? normalized.indexOf(nextCommand)
            : normalized.length;

        String value = normalized.substring(start, end).trim();
        results[command] = value;
      }
    }

    return results;
  }

  static String? getLastMatchedField(String transcript) {
    final normalized = transcript.toLowerCase();
    String? lastMatch;
    int lastIndex = -1;

    for (var command in commands) {
      int index = normalized.lastIndexOf(command);
      if (index > lastIndex) {
        lastMatch = command;
        lastIndex = index;
      }
    }
    return lastMatch;
  }
}
