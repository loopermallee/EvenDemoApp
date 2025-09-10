// lib/services/evenai_data_method.dart
//
// Helpers used by text_service.dart to wrap/measure lines and signal new screen.

class EvenAIDataMethod {
  /// Split long text into lines that fit the HUD (≈34 chars per line).
  /// text_service.dart sends 5 lines per page.
  static List<String> measureStringList(String text, {int maxCharsPerLine = 34}) {
    final cleaned = text.replaceAll('\r', ' ').replaceAll('\t', ' ');
    final words = cleaned.split(RegExp(r'\s+'));
    final lines = <String>[];

    var currentLine = '';
    for (final w in words) {
      if (w.isEmpty) continue;
      if (currentLine.isEmpty) {
        currentLine = w;
      } else if (currentLine.length + 1 + w.length <= maxCharsPerLine) {
        currentLine = "$currentLine $w";
      } else {
        lines.add(currentLine);
        currentLine = w;
      }
    }
    if (currentLine.isNotEmpty) lines.add(currentLine);

    return lines.isEmpty ? <String>["(no content)"] : lines;
  }

  /// Return 1 to open a new screen for the first page, else 0.
  /// Your firmware treats type==0x01 as "text page" → new screen on first send.
  static int transferToNewScreen(int type, int status) {
    return (type == 0x01) ? 1 : 0;
  }
}