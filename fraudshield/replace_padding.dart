import 'dart:io';

void main() {
  final Map<String, String> spacingMap = {
    '4.0': 'DesignTokens.spacing.xs',
    '4': 'DesignTokens.spacing.xs',
    '8.0': 'DesignTokens.spacing.sm',
    '8': 'DesignTokens.spacing.sm',
    '12.0': 'DesignTokens.spacing.md',
    '12': 'DesignTokens.spacing.md',
    '16.0': 'DesignTokens.spacing.lg',
    '16': 'DesignTokens.spacing.lg',
    '20.0': 'DesignTokens.spacing.xl',
    '20': 'DesignTokens.spacing.xl',
    '24.0': 'DesignTokens.spacing.xxl',
    '24': 'DesignTokens.spacing.xxl',
    '32.0': 'DesignTokens.spacing.xxxl',
    '32': 'DesignTokens.spacing.xxxl',
    '48.0': 'DesignTokens.spacing.huge',
    '48': 'DesignTokens.spacing.huge',
  };

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('lib directory not found');
    return;
  }

  int filesModified = 0;

  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    if (file.path.contains('design_tokens.dart')) continue;
    
    String content = file.readAsStringSync();
    String originalContent = content;

    // We do not want to replace EdgeInsets.zero, so we just focus on numbers.
    // Also need to handle cases like const EdgeInsets.all(16) -> EdgeInsets.all(DesignTokens.spacing.lg) (drop const)
    
    // Replace const EdgeInsets... with EdgeInsets... (since DesignTokens.spacing.lg is not a const literal at compile time if we access it via instance without const, wait, AppSpacing is const but accessing standard way drops const. Actually `DesignTokens.spacing.lg` is just a getter in a const class. Wait, it's NOT a const. It's final double lg = 16.0; inside AppSpacing which is instantiated as a const. But instance fields are not compile-time constants in Dart. So `EdgeInsets.all(DesignTokens.spacing.lg)` cannot be const.
    // We must drop `const ` before `EdgeInsets`.
    
    // First, let's look for `EdgeInsets.all(X)`
    content = content.replaceAllMapped(RegExp(r'(const\s+)?EdgeInsets\.all\(\s*([\d\.]+)\s*\)'), (match) {
      final isConst = match.group(1) != null;
      final valStr = match.group(2)!;
      final token = spacingMap[valStr];
      if (token != null) {
        return 'EdgeInsets.all($token)';
      }
      // If we couldn't map it, keep the original but if it's 0 we don't map anyway.
      return match.group(0)!; // Keep original
    });

    // Let's look for `EdgeInsets.symmetric(...)`
    content = content.replaceAllMapped(RegExp(r'(const\s+)?EdgeInsets\.symmetric\(([^)]+)\)'), (match) {
      String inner = match.group(2)!;
      bool changed = false;
      
      spacingMap.forEach((key, token) {
        if (inner.contains(': $key,') || inner.contains(': $key')) {
          inner = inner.replaceAll(RegExp(':\\s*$key\\b'), ': $token');
          changed = true;
        }
      });
      
      if (changed) {
        return 'EdgeInsets.symmetric($inner)';
      }
      return match.group(0)!;
    });
    
    // Let's look for `EdgeInsets.only(...)`
    content = content.replaceAllMapped(RegExp(r'(const\s+)?EdgeInsets\.only\(([^)]+)\)'), (match) {
      String inner = match.group(2)!;
      bool changed = false;
      
      spacingMap.forEach((key, token) {
        if (inner.contains(': $key,') || inner.contains(': $key')) {
          inner = inner.replaceAll(RegExp(':\\s*$key\\b'), ': $token');
          changed = true;
        }
      });
      
      if (changed) {
        return 'EdgeInsets.only($inner)';
      }
      return match.group(0)!;
    });
    
    // Let's look for `EdgeInsets.fromLTRB(...)`
    content = content.replaceAllMapped(RegExp(r'(const\s+)?EdgeInsets\.fromLTRB\(([^)]+)\)'), (match) {
      String inner = match.group(2)!;
      bool changed = false;
      
      // fromLTRB doesn't use named parameters, they are positional.
      final parts = inner.split(',').map((e) => e.trim()).toList();
      for (int i = 0; i < parts.length; i++) {
        if (spacingMap.containsKey(parts[i])) {
          parts[i] = spacingMap[parts[i]]!;
          changed = true;
        }
      }
      
      if (changed) {
        return 'EdgeInsets.fromLTRB(${parts.join(', ')})';
      }
      return match.group(0)!;
    });
    
    // Make sure 'design_tokens.dart' is imported if we used DesignTokens
    if (content != originalContent && content.contains('DesignTokens.spacing')) {
      if (!content.contains('design_tokens.dart')) {
        // Find best place to import
        final importIdx = content.lastIndexOf(RegExp(r'import\s+.*?;'));
        if (importIdx != -1) {
          final endOfImport = content.indexOf(';', importIdx) + 1;
          
          // Determine relative path depth
          int depth = file.path.split(Platform.pathSeparator).length - 2; // -2 for lib/ and filename
          String prefix = depth == 0 ? '' : '../' * depth;
          String importStr = '\nimport \'${prefix}design_system/tokens/design_tokens.dart\';';
          
          content = content.substring(0, endOfImport) + importStr + content.substring(endOfImport);
        } else {
          content = 'import \'design_system/tokens/design_tokens.dart\';\n$content';
        }
      }
      file.writeAsStringSync(content);
      filesModified++;
      print('Updated padding in \${file.path}');
    }
  }

  print('Modified \$filesModified files');
}
