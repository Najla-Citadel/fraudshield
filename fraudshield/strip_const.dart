import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) return;

  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  final constTargets = [
    'Padding', 'EdgeInsets', 'SizedBox', 'Row', 'Column', 'Stack', 
    'Center', 'Align', 'Positioned', 'Expanded', 'Container', '\\\\[',
    'Text', 'Icon', 'IconData', 'Flexible', 'Spacer', 'Wrap', 'SingleChildScrollView',
    'ListView', 'GridView', 'CustomScrollView', 'LayoutBuilder', 'Builder',
    'ClipRRect', 'Card', 'BottomNavigationBarItem', 'BottomNavigationBar',
    'Material', 'InkWell', 'GestureDetector', 'AppButton', 'AppEmptyState',
    'AppLoadingIndicator', 'ElevatedButton', 'TextButton', 'OutlinedButton',
    'GlassSurface', 'AlertDialog', 'IconButton', 'ListTile', 'CircleAvatar',
    'Divider', 'AppDivider', 'SliverToBoxAdapter', 'SliverPadding',
    'SliverFillRemaining', 'SliverList', 'SliverChildBuilderDelegate',
    'SliverAppBar', 'SafeArea', 'InkResponse', 'FloatingActionButton',
    'FloatingActionButton.extended', 'Scaffold', 'ScreenScaffold',
    'TextField', 'TextFormField', 'Form', 'InputDecoration',
    'OutlineInputBorder', 'UnderlineInputBorder', 'BorderSide',
    'BorderRadius', 'BoxDecoration', 'LinearGradient', 'RadialGradient',
    'Color', 'ColorFilter', 'Icons', 'LucideIcons'
  ];

  int modifiedCount = 0;

  for (final file in files) {
    String original = file.readAsStringSync();
    String content = original;

    for (final target in constTargets) {
      if (target == '\\\\[') {
        content = content.replaceAll(RegExp(r'const\s+\['), '[');
      } else {
        // We use \\b$target\\b but since some targets have dots (e.g. FloatingActionButton.extended)
        final safeTarget = target.replaceAll('.', '\\.');
        content = content.replaceAll(RegExp('const\\s+$safeTarget\\b'), target);
      }
    }

    if (content != original) {
      file.writeAsStringSync(content);
      modifiedCount++;
    }
  }

  print('Stripped const from \$modifiedCount files');
}
