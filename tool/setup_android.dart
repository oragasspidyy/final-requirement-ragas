// Patches android/app/build.gradle(.kts) for PetCareHub.
//
// Run once from the project folder, AFTER `flutter create .`:
//     dart run tool/setup_android.dart
//
// It enables core library desugaring (needed by flutter_local_notifications)
// and makes sure minSdk is at least 23 (needed by Firebase Auth).
import 'dart:io';

const desugarVersion = '2.1.4';

void main() {
  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');

  if (kts.existsSync()) {
    _patch(kts, isKts: true);
  } else if (groovy.existsSync()) {
    _patch(groovy, isKts: false);
  } else {
    stderr.writeln('Could not find android/app/build.gradle(.kts).\n'
        'Run `flutter create --platforms android .` first.');
    exitCode = 1;
  }
}

void _patch(File f, {required bool isKts}) {
  var s = f.readAsStringSync();
  final original = s;

  // 1) Enable desugaring inside compileOptions { ... }
  final desugarFlag =
      isKts ? 'isCoreLibraryDesugaringEnabled = true' : 'coreLibraryDesugaringEnabled true';
  if (!s.contains('oreLibraryDesugaringEnabled')) {
    final i = s.indexOf('compileOptions {');
    if (i >= 0) {
      final insertAt = i + 'compileOptions {'.length;
      s = '${s.substring(0, insertAt)}\n        $desugarFlag${s.substring(insertAt)}';
    } else {
      final a = s.indexOf('android {');
      if (a < 0) {
        stderr.writeln('No `android {` block found in ${f.path}');
        exitCode = 1;
        return;
      }
      final insertAt = a + 'android {'.length;
      s = '${s.substring(0, insertAt)}\n    compileOptions {\n        $desugarFlag\n    }${s.substring(insertAt)}';
    }
  }

  // 2) minSdk >= 23
  if (isKts) {
    s = s.replaceAll(RegExp(r'minSdk\s*=\s*flutter\.minSdkVersion'),
        'minSdk = maxOf(23, flutter.minSdkVersion)');
  } else {
    s = s.replaceAll(RegExp(r'minSdk(Version)?\s*=?\s*flutter\.minSdkVersion'),
        'minSdkVersion Math.max(23, flutter.minSdkVersion)');
  }

  // 3) desugaring library dependency
  if (!s.contains('desugar_jdk_libs')) {
    final dep = isKts
        ? '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:$desugarVersion")'
        : "    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:$desugarVersion'";
    final d = s.lastIndexOf(RegExp(r'^dependencies\s*\{', multiLine: true));
    if (d >= 0) {
      final brace = s.indexOf('{', d) + 1;
      s = '${s.substring(0, brace)}\n$dep${s.substring(brace)}';
    } else {
      s = '${s.trimRight()}\n\ndependencies {\n$dep\n}\n';
    }
  }

  if (s == original) {
    stdout.writeln('${f.path} already patched — nothing to do.');
  } else {
    f.writeAsStringSync(s);
    stdout.writeln('Patched ${f.path}:\n'
        '  • core library desugaring enabled\n'
        '  • minSdk set to at least 23\n'
        '  • desugar_jdk_libs:$desugarVersion added');
  }
}
