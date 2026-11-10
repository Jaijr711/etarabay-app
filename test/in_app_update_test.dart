import 'dart:async';
import 'dart:io';

import 'package:e_tarabay/l10n/app_localizations.dart';
import 'package:e_tarabay/services/apk_patch.dart';
import 'package:e_tarabay/services/update_checker.dart';
import 'package:e_tarabay/widgets/update_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The update is downloaded by the app into its own folder and handed to
/// Android's installer, so no copy piles up in Downloads.
void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('upd'));
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  UpdateInfo info({int size = 10}) => UpdateInfo(
        versionName: '9.9.9',
        pageUrl: 'https://example.invalid',
        apkUrl: 'https://example.invalid/E-Tarabay.apk',
        apkSize: size,
      );

  group('the patch', () {
    const fx = 'test/fixtures/apk_patch';
    late String oldSha, newSha;
    setUpAll(() async {
      oldSha = await ApkPatch.sha256Of('$fx/old.bin');
      newSha = await ApkPatch.sha256Of('$fx/new.bin');
    });

    test('pickPatch finds the one for this version', () {
      final list = {
        'patches': [
          {'from': '1.2.59', 'patch': 'a.patch', 'patchSize': 5},
          {
            'from': '1.2.60',
            'patch': 'b.patch',
            'patchSize': 7,
            'fromSha256': 'f',
            'toSha256': 't',
            'toSize': 9
          },
        ]
      };
      final p = UpdateChecker.pickPatch(list, '1.2.60', (n) => 'https://x/$n');
      expect(p?.url, 'https://x/b.patch');
      expect(p?.size, 7);
      expect(p?.toSize, 9);
      expect(UpdateChecker.pickPatch(list, '1.2.58', (n) => 'u'), isNull);
      expect(
          UpdateChecker.pickPatch({'nope': 1}, '1.2.60', (n) => 'u'), isNull);
    });

    UpdateInfo withPatch({String? from}) => UpdateInfo(
          versionName: '9.9.9',
          pageUrl: 'https://example.invalid',
          apkUrl: 'https://example.invalid/E-Tarabay.apk',
          apkSize: 64000,
          patch: PatchInfo(
            url: 'https://example.invalid/x.patch',
            size: File('$fx/old-to-new.patch').lengthSync(),
            fromSha256: from ?? oldSha,
            toSha256: newSha,
            toSize: 64000,
          ),
        );

    test('builds the new APK from the installed one and a small download',
        () async {
      final patchBytes = File('$fx/old-to-new.patch').readAsBytesSync();
      var preparing = false;
      final client = MockClient((req) async => http.Response.bytes(
          patchBytes, 200,
          headers: {'content-length': '${patchBytes.length}'}));
      final apk = await UpdateChecker.instance.buildFromPatch(
          withPatch(), '$fx/old.bin',
          onProgress: (_, __) {},
          onPreparing: () => preparing = true,
          client: client,
          folder: tmp);
      expect(preparing, isTrue);
      expect(apk.readAsBytesSync(), File('$fx/new.bin').readAsBytesSync());
      // Only the APK is left: the patch and the half-built file are gone.
      expect(tmp.listSync().map((f) => f.path.split(RegExp(r'[/\\]')).last),
          ['E-Tarabay-9.9.9.apk']);
    });

    test('an installed APK that is not the one patched from is refused',
        () async {
      var asked = false;
      final client = MockClient((req) async {
        asked = true;
        return http.Response('', 200);
      });
      await expectLater(
          UpdateChecker.instance.buildFromPatch(
              withPatch(from: 'other'), '$fx/old.bin',
              onProgress: (_, __) {},
              onPreparing: () {},
              client: client,
              folder: tmp),
          throwsA(isA<StateError>()));
      expect(asked, isFalse);
    });

    test('the popup offers the patch size', () {
      expect(
          withPatch().downloadSize, File('$fx/old-to-new.patch').lengthSync());
      expect(megabytes(1936003), '1.8 MB');
      expect(megabytes(122902714), '117 MB');
    });
  });

  group('pickApk', () {
    test('prefers E-Tarabay.apk, as the website does', () {
      final apk = UpdateChecker.pickApk([
        {'name': 'notes.txt', 'size': 1, 'browser_download_url': 'n'},
        {
          'name': 'E-Tarabay-1.2.61.apk',
          'size': 5,
          'browser_download_url': 'a'
        },
        {'name': 'E-Tarabay.apk', 'size': 7, 'browser_download_url': 'b'},
      ]);
      expect(apk?.url, 'b');
      expect(apk?.size, 7);
    });
    test('otherwise the first apk; none when there is none', () {
      expect(
          UpdateChecker.pickApk([
            {'name': 'x.apk', 'size': 3, 'browser_download_url': 'x'}
          ])?.url,
          'x');
      expect(UpdateChecker.pickApk([]), isNull);
      expect(UpdateChecker.pickApk(null), isNull);
    });
  });

  group('downloadApk', () {
    test('writes the whole file and reports progress', () async {
      final client =
          MockClient.streaming((req, _) async => http.StreamedResponse(
              Stream.fromIterable([
                [1, 2, 3, 4],
                [5, 6, 7, 8, 9, 10]
              ]),
              200,
              contentLength: 10));
      final seen = <int>[];
      final file = await UpdateChecker.instance.downloadApk(info(),
          onProgress: (r, t) => seen.add(r), client: client, folder: tmp);
      expect(await file.length(), 10);
      expect(seen, [4, 10]);
      expect(file.path, contains('E-Tarabay-9.9.9.apk'));
    });

    test('a download cut short is thrown away', () async {
      final client =
          MockClient.streaming((req, _) async => http.StreamedResponse(
              Stream.fromIterable([
                [1, 2, 3]
              ]),
              200));
      await expectLater(
          UpdateChecker.instance.downloadApk(info(),
              onProgress: (_, __) {}, client: client, folder: tmp),
          throwsA(anything));
      expect(tmp.listSync(), isEmpty);
    });

    test('a refused request is an error', () async {
      final client = MockClient((req) async => http.Response('no', 404));
      await expectLater(
          UpdateChecker.instance.downloadApk(info(),
              onProgress: (_, __) {}, client: client, folder: tmp),
          throwsA(isA<HttpException>()));
    });

    test('cancel stops it and leaves nothing', () async {
      final chunks = StreamController<List<int>>();
      final client = MockClient.streaming((req, _) async =>
          http.StreamedResponse(chunks.stream, 200, contentLength: 10));
      final cancel = Completer<void>();
      final run = UpdateChecker.instance.downloadApk(info(),
          onProgress: (_, __) {},
          cancel: cancel.future,
          client: client,
          folder: tmp);
      chunks.add([1, 2]);
      await Future<void>.delayed(Duration.zero);
      cancel.complete();
      await expectLater(run, throwsA(isA<StateError>()));
      expect(tmp.listSync(), isEmpty);
      await chunks.close();
    });
  });

  test('cleanUpDownloads drops what is installed, keeps what is waiting',
      () async {
    final folder = Directory('${tmp.path}/update')..createSync();
    File('${folder.path}/E-Tarabay-1.2.60.apk').writeAsStringSync('x');
    File('${folder.path}/E-Tarabay-1.2.61.apk').writeAsStringSync('x');
    await UpdateChecker.cleanUpDownloads(
        folder: folder, installedVersion: '1.2.60');
    expect(folder.listSync().map((f) => f.path.split(RegExp(r'[/\\]')).last),
        ['E-Tarabay-1.2.61.apk']);
    await UpdateChecker.cleanUpDownloads(
        folder: folder, installedVersion: '1.2.61');
    expect(folder.existsSync(), isFalse);
  });

  test('a whole download already there is not fetched again', () async {
    final file = File('${tmp.path}/E-Tarabay-9.9.9.apk')
      ..writeAsBytesSync(List.filled(10, 1));
    var asked = false;
    final client = MockClient((req) async {
      asked = true;
      return http.Response('', 500);
    });
    final got = await UpdateChecker.instance.downloadApk(info(),
        onProgress: (_, __) {}, client: client, folder: tmp);
    expect(asked, isFalse);
    expect(got.path, file.path);
  });

  group('the flow', () {
    var allowed = true;
    setUp(() => allowed = true);
    Future<List<String>> run(WidgetTester tester, {bool fail = false}) async {
      final calls = <String>[];
      final ops = UpdateOps(
        download: (u, onProgress, cancel, onPreparing) async {
          calls.add('download');
          if (fail) throw const HttpException('down');
          onProgress(10, 10);
          return File('${tmp.path}/a.apk');
        },
        canInstall: () async => allowed,
        openInstallSettings: () async => calls.add('settings'),
        install: (path) async => calls.add('install'),
        openWebsite: (_) async {
          calls.add('website');
          return true;
        },
      );
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('fil'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => UpdateFlowDialog(update: info(), ops: ops)),
            child: const Text('go'),
          ),
        ),
      ));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      return calls;
    }

    testWidgets('downloads, then hands it to the installer', (tester) async {
      final calls = await run(tester);
      expect(calls, ['download', 'install']);
      expect(find.text('Handa na!'), findsWidgets);
    });

    testWidgets('asks for the permission before downloading anything',
        (tester) async {
      allowed = false;
      final calls = await run(tester);
      expect(calls, isEmpty);
      expect(find.text('Isang hakbang pa'), findsWidgets);
      await tester.tap(find.text('Buksan ang setting'));
      await tester.pumpAndSettle();
      expect(calls, ['settings']);
      // Back from Android's settings with the switch on: now it downloads.
      allowed = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(calls, ['settings', 'download', 'install']);
    });

    testWidgets('a failed download offers retry and the website',
        (tester) async {
      final calls = await run(tester, fail: true);
      expect(find.text('Hindi natapos ang download'), findsWidgets);
      await tester.tap(find.text('Buksan ang website'));
      await tester.pumpAndSettle();
      expect(calls, ['download', 'website']);
      expect(find.text('Hindi natapos ang download'), findsNothing);
    });
  });
}
