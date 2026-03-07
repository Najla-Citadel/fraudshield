import 'dart:io';

void main() {
  final file = File('analyze_output_padding_3.txt');
  if (!file.existsSync()) {
    print('Analyze file not found');
    return;
  }

  final lines = file.readAsLinesSync();
  final Map<String, Set<int>> fileErrors = {};

  final regex = RegExp(r' (lib[\\/].*?\.dart):(\d+):');

  for (final line in lines) {
    if (line.contains('constant expression') || 
        line.contains('Arguments of a constant creation') || 
        line.contains('Invalid constant value')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final path = match.group(1)!;
        final lineNum = int.parse(match.group(2)!);
        fileErrors.putIfAbsent(path, () => {}).add(lineNum);
      }
    }
  }

  print('Found errors in \${fileErrors.length} files');

  for (final entry in fileErrors.entries) {
    final path = entry.key;
    final errorLines = entry.value.toList()..sort();
    
    final f = File(path);
    if (!f.existsSync()) continue;

    List<String> fileLines = f.readAsLinesSync();
    bool modified = false;

    // To avoid shifting line numbers, we process without changing line count.
    for (final lineNum in errorLines) {
      if (lineNum <= 0 || lineNum > fileLines.length) continue;
      
      // Search backwards up to 10 lines to find 'const ' and replace it.
      // E.g., const Padding( 
      for (int i = lineNum - 1; i >= 0 && i >= lineNum - 15; i--) {
        if (fileLines[i].contains('const ')) {
          int idx = fileLines[i].lastIndexOf('const ');
          if (idx != -1) {
            fileLines[i] = fileLines[i].substring(0, idx) + fileLines[i].substring(idx + 6);
            modified = true;
            break; // Fix one const per error
          }
        }
      }
    }

    if (modified) {
      f.writeAsStringSync('${fileLines.join('\\n')}\\n');
      print('Fixed lines in $path');
    }
  }
}
