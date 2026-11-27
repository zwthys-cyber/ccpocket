from pathlib import Path
import shutil
root = Path(__file__).resolve().parent
dest = Path('test/status_inset_capture_test.dart')
source = Path('test/workspace_shell_screen_test.dart').read_text()
def insert_once(text, original, new):
    if text.count(original) != 1:
        raise ValueError('Unexpected workspace harness: '+original)
    return text.replace(original, new, 1)
source = insert_once(source, ': MaterialApp(\n              localizationsDelegates:', ': MaterialApp(\n              debugShowCheckedModeBanner: false,\n              builder: simulatedStatusBar,\n              localizationsDelegates:')
source = source.replace('theme: AppTheme.darkTheme.copyWith(platform: platform),', 'theme: previewTheme(),')
source = insert_once(source, '  TestWidgetsFlutterBinding.ensureInitialized();', '  TestWidgetsFlutterBinding.ensureInitialized();\n  registerSafeAreaCapture();')
shutil.copyfile(root/'support.dart', 'test/zh_preview_support.dart')
dest.write_text("import 'zh_preview_support.dart';\n"+source+'\n'+(root/'safe-area.dart').read_text())
