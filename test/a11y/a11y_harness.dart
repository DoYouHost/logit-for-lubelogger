import 'dart:convert';
import 'dart:math' as math;

import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:app_report_ui/app_report_ui.dart';
import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/app.dart';
import 'package:lubelogger_mobile/core/auth/credentials_store.dart';
import 'package:lubelogger_mobile/core/cache/sync_service.dart';
import 'package:lubelogger_mobile/core/demo/demo_config.dart';
import 'package:lubelogger_mobile/core/diagnostics/diagnostics_wiring.dart';
import 'package:lubelogger_mobile/core/theme/dash_theme.dart';
import 'package:lubelogger_mobile/features/bug_report/report_wiring.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:lubelogger_mobile/l10n/app_localizations_pl.dart';
import 'package:lubelogger_mobile/providers.dart';
import 'package:lubelogger_mobile/router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'a11y_contrast_report.dart';

/// The shared half of the rendered-guideline tests: one surface of the real app,
/// measured in both themes at 100 % text and in the light theme at 150 and 200 %.
/// A feature's file only lists its surfaces. The rules are in
/// docs/a11y-guideline-tests.md.

/// Tall enough that a lazy list builds most of a screen in one frame; the rest is
/// reached by [a11ySurface]'s scroll pass.
const a11yWindow = Size(411, 2000);

/// Text scales a surface is measured at besides 100 %. Layout, overflow and
/// tap-target findings come from the text size, not from the colours, so these run
/// in the light theme only.
const a11yTextScales = [1.5, 2.0];

/// The locale every surface renders in: Polish words are the longer ones, so a
/// label that fits here fits in English too.
const a11yLocale = Locale('pl');

/// The copy a surface is found by, read from the localization API rather than
/// spelled out.
final pl = AppLocalizationsPl();

/// What a form shows under a field that refused its value: only an error says
/// "required" or "not a number", so it proves a submit was answered.
final a11yValidationError = find.byWidgetPredicate(
  (w) =>
      w is Text &&
      (w.data == pl.validationRequired || w.data == pl.validationNumber),
);

/// An API key that never leaves memory: the platform keystore has no platform to
/// ask in a test.
class A11yCredentials implements CredentialsStore {
  String? _key = DemoConfig.token;

  @override
  Future<String?> readApiKey() async => _key;

  @override
  Future<void> writeApiKey(String key) async => _key = key;

  @override
  Future<void> clearAll() async => _key = null;
}

/// A sync state that stays as given: the offline layer is bypassed for a demo
/// profile, so a surface that shows what is waiting has to be told.
class A11yFixedSync extends SyncStateNotifier {
  A11yFixedSync(this._fixed);

  final SyncState _fixed;

  @override
  SyncState build() => _fixed;

  @override
  Future<void> reload() async {}

  @override
  Future<SyncOutcome> syncNow() async => (
    delivered: 0,
    refused: 0,
    remaining: _fixed.pending.length,
    stopped: true,
  );

  @override
  Future<void> discardRejected([String? id]) async {}
}

/// What a screen touches on its first frame that has no platform in a test.
final List<Override> a11yPlatformOverrides = [
  credentialsStoreProvider.overrideWithValue(A11yCredentials()),
  // The app's own recorder, kept off the disk: a recording that wrote files would
  // need the real event loop, which a widget test's fake clock never gives it.
  diagnosticRecorderProvider.overrideWith(
    (ref) => lubeloggerRecorder(
      settings: ref.watch(settingsRepositoryProvider),
      loadFacts: () async =>
          const SessionFacts(app: '1.0.0+1', os: 'Android 15', locale: 'pl-PL'),
      resolveDirectory: () async => null,
    ),
  ),
  packageInfoProvider.overrideWith(
    (ref) async => PackageInfo(
      appName: 'Logit',
      packageName: 'page.codeberg.doyouhost.lubelogger_mobile',
      version: '1.0.0',
      buildNumber: '1',
    ),
  ),
];

/// Horizontal paint offset of the whole app, in dp. The pump applies it; the
/// contrast guideline moves it to re-measure a finding at another sub-pixel phase.
final a11yPhase = ValueNotifier<double>(0);

/// A one-to-one window: the contrast judge reads one pixel per dp.
void a11yWindowSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

/// The platform's side of a scenario: brightness, text scale and language reach
/// the app as they do on a phone, so `ThemeMode.system` and the localization
/// delegates are exercised too.
void _platform(WidgetTester tester, Brightness brightness, double textScale) {
  final dispatcher = tester.platformDispatcher;
  dispatcher.platformBrightnessTestValue = brightness;
  dispatcher.textScaleFactorTestValue = textScale;
  dispatcher.localesTestValue = const [a11yLocale];
  dispatcher.localeTestValue = a11yLocale;
  addTearDown(dispatcher.clearAllTestValues);
}

Future<void> _mount(WidgetTester tester, Widget app) => tester.pumpWidget(
  ValueListenableBuilder<double>(
    valueListenable: a11yPhase,
    builder: (_, dx, child) =>
        Transform.translate(offset: Offset(dx, 0), child: child),
    child: app,
  ),
);

/// Pumps a plain [home] widget in the app theme. For the harness's own fixtures
/// (a node the guideline misreads); a surface of the app goes through
/// [a11ySurface].
Future<void> a11yPump(
  WidgetTester tester,
  Widget home,
  Brightness brightness, {
  Size window = a11yWindow,
  Duration settleFor = const Duration(milliseconds: 100),
  double textScale = 1,
}) async {
  a11yWindowSize(tester, window);
  _platform(tester, brightness, textScale);
  a11yPhase.value = 0;
  await _mount(
    tester,
    MaterialApp(
      theme: buildDashThemeData(brightness, brand: lubeLoggerBrand),
      locale: a11yLocale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        ReportLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
  await a11ySettle(tester, settleFor);
}

/// Pumps the real [LubeLoggerApp] on the demo server and lets it settle.
///
/// Not `pumpAndSettle`: the demo answers after a timed delay and a sync pass can
/// start at any frame, so it runs [settleFor] of frames instead.
Future<void> a11yPumpApp(
  WidgetTester tester,
  Brightness brightness, {
  List<Override> overrides = const [],
  Size window = a11yWindow,
  Duration settleFor = const Duration(seconds: 2),
  Map<String, Object> prefs = const {},
  double textScale = 1,
  bool signedIn = true,
}) async {
  a11yWindowSize(tester, window);
  _platform(tester, brightness, textScale);
  SharedPreferences.setMockInitialValues({
    if (signedIn)
      'server_profile': jsonEncode({
        'baseUrl': DemoConfig.baseUrl,
        'label': 'Demo',
      }),
    ...prefs,
  });
  final sharedPrefs = await SharedPreferences.getInstance();
  a11yPhase.value = 0;
  await _mount(
    tester,
    ProviderScope(
      retry: neverRetry,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        reportBindingsOverride,
        ...a11yPlatformOverrides,
        ...overrides,
      ],
      child: const LubeLoggerApp(),
    ),
  );
  await a11ySettle(tester, settleFor);
}

/// Frames in 100 ms steps, so each timed answer lands before the next is asked.
Future<void> a11ySettle(WidgetTester tester, Duration total) async {
  for (
    var t = Duration.zero;
    t < total;
    t += const Duration(milliseconds: 100)
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The app's container, for a surface that navigates or reads a provider.
ProviderContainer a11yContainer(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(LubeLoggerApp)));

/// Moves the app to [location] the way a deep link does.
Future<void> a11yGo(
  WidgetTester tester,
  String location, {
  Duration settle = const Duration(seconds: 2),
}) async {
  a11yContainer(tester).read(routerProvider).go(location);
  await a11ySettle(tester, settle);
}

/// A context under the app's navigator, for the `show…Form` and `show…Sheet`
/// entry points a surface opens without hunting for the button.
BuildContext a11yContext(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).last);

/// `androidTapTargetGuideline` (48 dp), measured here instead of by Flutter's own
/// traversal, which excuses more than a viewport cut: a node touching the edge of an
/// implicitly scrolling ancestor **or of the window** is skipped, and a row as wide as
/// its list touches both edges all the time, so a full-width row of any height passed.
///
/// Here every tappable node is measured, with one narrowing that concerns a
/// measurement artefact, not a finding: a control a scrollable's viewport cuts reads
/// as smaller than it is **across the cut only** ([_cutAxes]). That axis is excused
/// and the other is still held to 48 dp: a tab half scrolled out of the strip is
/// narrow, its 46 dp height is real. Nothing else is ever excused.
class A11yTapTargets extends MinimumTapTargetGuideline {
  const A11yTapTargets()
    : super(
        size: const Size(48, 48),
        link:
            'https://support.google.com/accessibility/android/answer/7101858?hl=en',
      );

  @override
  FutureOr<Evaluation> evaluate(WidgetTester tester) {
    var result = const Evaluation.pass();
    for (final view in tester.binding.renderViews) {
      result += _measure(
        view.flutterView.devicePixelRatio,
        view.owner!.semanticsOwner!.rootSemanticsNode!,
      );
    }
    return result;
  }

  Evaluation _measure(double pixelRatio, SemanticsNode node) {
    var result = const Evaluation.pass();
    node.visitChildren((child) {
      result += _measure(pixelRatio, child);
      return true;
    });
    // Skips what has no tap action, what is hidden and links: the guideline's own.
    if (node.isMergedIntoParent || shouldSkipNode(node)) return result;
    var bounds = node.rect;
    for (SemanticsNode? n = node; n != null; n = n.parent) {
      final transform = n.transform;
      if (transform != null) {
        bounds = MatrixUtils.transformRect(transform, bounds);
      }
    }
    final found = bounds.size / pixelRatio;
    final cut = _cutAxes(node);
    const tolerance = 0.001;
    final narrow =
        found.width < size.width - tolerance && !(cut?.horizontal ?? false);
    final short =
        found.height < size.height - tolerance && !(cut?.vertical ?? false);
    if (!narrow && !short) return result;
    return result +
        Evaluation.fail(
          '$node: expected tap target size of at least $size, '
          'but found $found'
          '${cut == null ? '' : ' (cut by its viewport; the cut axis is excused)'}\n'
          'See also: $link',
        );
  }

  /// A control a scrollable's viewport cuts. `SemanticsNode.rect` is already
  /// clipped, so a button half scrolled out reads as a small one and fails for a
  /// reason that is not in the app. Flutter's own guideline skips a node that
  /// touches *any* edge of a scrollable, sides included, so it hides a control
  /// flush with the left of a list and still misses one a scale moved.
  ///
  /// Each scrollable above the node is asked on its own, against its own viewport:
  /// the node is cut at an edge of *that* viewport only when it is flush with it
  /// there **and** that scrollable has content beyond the edge. The scroll actions
  /// say so: at offset 0 a vertical scrollable offers `scrollUp` only (more below),
  /// at the end `scrollDown` only (more above), between them both; horizontally
  /// `scrollLeft` is more to the right and `scrollRight` more to the left. So the
  /// first row at offset 0 is whole, however flush with the top. Pooling the actions
  /// of every ancestor would let the page's "more below" excuse the height of a
  /// strip whose own viewport is as tall as its buttons.
  /// [a11yMeetsAllWhileScrolling] pages with an overlap taller than any target, so a
  /// control cut at one stop stands whole at the next. Null when nothing is cut.
  static ({bool vertical, bool horizontal})? _cutAxes(SemanticsNode node) {
    final rect = node.rect;
    const eps = 0.01;
    var vertical = false, horizontal = false;
    for (var a = node.parent; a != null; a = a.parent) {
      final data = a.getSemanticsData();
      final above = data.hasAction(SemanticsAction.scrollDown);
      final below = data.hasAction(SemanticsAction.scrollUp);
      final before = data.hasAction(SemanticsAction.scrollRight);
      final after = data.hasAction(SemanticsAction.scrollLeft);
      if (!above && !below && !before && !after) continue;
      final viewport = _inNodeCoordinates(node, a);
      if (viewport == null) continue;
      vertical |=
          (above && (rect.top - viewport.top).abs() < eps) ||
          (below && (rect.bottom - viewport.bottom).abs() < eps);
      horizontal |=
          (before && (rect.left - viewport.left).abs() < eps) ||
          (after && (rect.right - viewport.right).abs() < eps);
    }
    if (!vertical && !horizontal) return null;
    return (vertical: vertical, horizontal: horizontal);
  }

  /// [ancestor]'s own rect, its viewport, in [node]'s coordinates.
  static Rect? _inNodeCoordinates(SemanticsNode node, SemanticsNode ancestor) {
    var toAncestor = Matrix4.identity();
    for (SemanticsNode? n = node; n != null && n != ancestor; n = n.parent) {
      final transform = n.transform;
      if (transform != null) toAncestor = transform * toAncestor;
    }
    final back = Matrix4.tryInvert(toAncestor);
    return back == null ? null : MatrixUtils.transformRect(back, ancestor.rect);
  }
}

/// The three guidelines on what is laid out right now. All three run and every
/// finding is reported together: stopping at the first failing guideline hid the
/// tap-target and label findings behind the contrast ones.
Future<void> a11yMeetsAll(
  WidgetTester tester, {
  bool Function(SemanticsData data)? skipContrast,
}) async {
  final guidelines = <AccessibilityGuideline>[
    _ContrastBesideMisreads(skipContrast),
    const A11yTapTargets(),
    labeledTapTargetGuideline,
  ];
  var result = const Evaluation.pass();
  for (final guideline in guidelines) {
    result += await guideline.evaluate(tester);
  }
  expect(result.passed, isTrue, reason: result.reason);
}

/// Whether [finder] matches now. `.first` and `.last` finders throw instead of
/// matching nothing.
bool _built(Finder finder) {
  try {
    return finder.evaluate().isNotEmpty;
  } on StateError {
    return false;
  }
}

/// The list of the route on top: behind an open sheet, the first vertical
/// scrollable in the tree is the screen underneath, not the sheet.
ScrollPosition? _mainList() {
  final scrollables = find.byType(Scrollable).evaluate().where((e) {
    final state = (e as StatefulElement).state as ScrollableState;
    return state.position.axis == Axis.vertical &&
        (ModalRoute.of(e)?.isCurrent ?? true);
  });
  if (scrollables.isEmpty) return null;
  return ((scrollables.first as StatefulElement).state as ScrollableState)
      .position;
}

/// Pages the screen's list from the top until [finder] builds. A lazy list holds
/// no element for a row past the fold.
Future<bool> _pageUntilBuilt(
  WidgetTester tester,
  Finder finder, {
  int maxPages = 12,
}) async {
  if (_built(finder)) return true;
  final position = _mainList();
  if (position == null) return false;
  if (position.pixels > 0) {
    position.jumpTo(0);
    await tester.pump(const Duration(milliseconds: 100));
  }
  for (var page = 0; page < maxPages && !_built(finder); page++) {
    if (position.pixels >= position.maxScrollExtent) break;
    position.jumpTo(
      (position.pixels + position.viewportDimension).clamp(
        0.0,
        position.maxScrollExtent,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  return _built(finder);
}

/// Whether [finder] builds, paging the screen's list to find out, then back to the
/// top. At a large text size the widget that proves a surface was reached can be
/// past the fold.
Future<bool> _reveal(WidgetTester tester, Finder finder) async {
  final found = await _pageUntilBuilt(tester, finder);
  final position = _mainList();
  if (position != null && position.pixels > 0) {
    position.jumpTo(0);
    await tester.pump(const Duration(milliseconds: 100));
  }
  return found;
}

/// How far one stop of [a11yMeetsAllWhileScrolling] overlaps the last: taller than
/// any target on a screen, so a control cut by the edge at one stop stands whole at
/// the next.
const _pageOverlap = 72.0;

/// Whether [route] is a menu a control opened: a `PopupMenuButton`'s or a
/// `DropdownButton`'s. Both are routes of their own with a scrollable inside, so
/// [_mainList] takes that scrollable for the screen's list and the screen under
/// the menu is never paged.
bool _isMenuRoute(Route<dynamic>? route) {
  final name = route.runtimeType.toString();
  return name.startsWith('_PopupMenuRoute') ||
      name.startsWith('_DropdownRoute');
}

/// Closes a menu that is open over the list about to be paged, once the surface
/// has been measured with it open.
///
/// * A `MenuAnchor` menu hangs off the list: paging that list takes the anchor out
///   of a lazy list and Flutter lays the overlay out at NaN. Escape closes it.
/// * A popup or a dropdown is a route of its own: a tap on its barrier closes it,
///   as a finger would.
///
/// No finger can scroll the list under an open menu (the barrier takes the first
/// drag and only closes it), and the screen behind the menu is worth its scrolling
/// pass all the same.
Future<void> _closeMenus(WidgetTester tester) async {
  for (var closed = 0; closed < 3; closed++) {
    final position = _mainList();
    if (position == null) return;
    final route = ModalRoute.of(position.context.storageContext);
    if (_isMenuRoute(route)) {
      await tester.tapAt(const Offset(2, 2));
    } else if (find
        .byType(MenuItemButton)
        .evaluate()
        .any((e) => ModalRoute.of(e) == route)) {
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    } else {
      return;
    }
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Scrolls the screen's main list one viewport less [_pageOverlap] at a time and
/// asserts at each stop: a guideline only sees what is built, and a lazy list
/// builds the viewport plus a little. A screen without a vertical scrollable has
/// nothing to do.
Future<void> a11yMeetsAllWhileScrolling(
  WidgetTester tester, {
  bool Function(SemanticsData data)? skipContrast,
  int maxPages = 16,
}) async {
  await a11yMeetsAll(tester, skipContrast: skipContrast);
  await _closeMenus(tester);
  final position = _mainList();
  if (position == null) return;
  // A tap on a target down the list leaves it scrolled; the pages above would
  // never be measured.
  if (position.pixels > 0) {
    position.jumpTo(0);
    await tester.pump(const Duration(milliseconds: 100));
    await a11yMeetsAll(tester, skipContrast: skipContrast);
  }
  // Never less than half a viewport, so a short one still advances.
  final step = math.max(
    position.viewportDimension - _pageOverlap,
    position.viewportDimension / 2,
  );
  for (var page = 0; page < maxPages; page++) {
    if (position.pixels >= position.maxScrollExtent) return;
    position.jumpTo(
      (position.pixels + step).clamp(0.0, position.maxScrollExtent),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await a11yMeetsAll(tester, skipContrast: skipContrast);
  }
}

/// Scrolls the first match into view, taps it and lets the animation it starts
/// finish. Not `pumpAndSettle`: a sync pass or a poll can keep the tree busy.
Future<void> a11yTap(
  WidgetTester tester,
  Finder finder, {
  Duration settle = const Duration(milliseconds: 700),
}) async {
  await _pageUntilBuilt(tester, finder);
  await _scrollIntoView(tester, finder);
  await tester.tap(finder.first);
  await a11ySettle(tester, settle);
}

/// Scrolls the first match to the middle of its scrollable and lays the frame out.
///
/// `ensureVisible` moves the scroll position but not the render tree: without a
/// frame the finder still answers with the old position, and a tap lands where the
/// control was. Its default puts the control at the leading edge, which under a
/// pinned header is a place nothing can be tapped at; the middle is clear of it.
Future<void> _scrollIntoView(WidgetTester tester, Finder finder) async {
  if (!_built(finder)) {
    fail('Nothing on screen matches $finder, so there is nothing to act on.');
  }
  await Scrollable.ensureVisible(tester.element(finder.first), alignment: 0.5);
  await tester.pump();
}

Future<void> a11yLongPress(
  WidgetTester tester,
  Finder finder, {
  Duration settle = const Duration(milliseconds: 700),
}) async {
  await _pageUntilBuilt(tester, finder);
  await _scrollIntoView(tester, finder);
  await tester.longPress(finder.first);
  await a11ySettle(tester, settle);
}

/// Types into the first text field under [finder] and lets the frame settle.
Future<void> a11yEnter(
  WidgetTester tester,
  Finder finder,
  String text, {
  Duration settle = const Duration(milliseconds: 300),
}) async {
  await _pageUntilBuilt(tester, finder);
  await _scrollIntoView(tester, finder);
  await tester.enterText(finder.first, text);
  await a11ySettle(tester, settle);
}

final _cleanups = <Future<void> Function()>[];

/// Runs [cleanup] when the surface ends, pass or fail, before the app unmounts.
/// For work that must stop while the providers it talks to are still alive.
void a11yOnDone(Future<void> Function() cleanup) => _cleanups.add(cleanup);

/// A diagnostic id that only starts with [prefix]: `byLogId` matches whole ids.
Finder a11yByLogIdStarting(String prefix) => find.byWidgetPredicate(
  (w) => w is Semantics && (w.properties.identifier ?? '').startsWith(prefix),
);

/// Registers one test per scenario for a single surface of the real app.
///
/// * [location] is the route to start on (the app opens on the garage);
/// * [arrange] gets it into the state to measure (an open form, a switched tab, a
///   filled field);
/// * [shows] must match something before anything is measured — what the surface
///   is about (its title, a row the demo seeds), never a placeholder;
/// * [signedIn] false starts without a server profile, on the setup screen;
/// * [prefs] seeds SharedPreferences before the app builds;
/// * [skipContrast] narrows [textContrastGuideline] for a node it misreads — a
///   false positive only, and always with the reason in a comment. A real
///   violation is fixed in the app;
/// * [scroll] re-asserts after each viewport of the main list;
/// * [textScales] are the extra text sizes, see [a11yTextScales]. A surface that
///   cannot hold one passes a narrower list and says why in a comment, never
///   drops it silently;
/// * [skip] switches the whole surface off, for a screen whose findings are all in
///   code this repository does not own and the maintainer has accepted. It takes
///   the reason, which a reader of the call sees next to it; the test body is not
///   run. A red that is not fixed is better skipped openly than hidden in a
///   narrower guideline.
void a11ySurface(
  String name, {
  String location = '/',
  Future<void> Function(WidgetTester tester)? arrange,
  List<Override> overrides = const [],
  Size window = a11yWindow,
  Duration settleFor = const Duration(seconds: 2),
  bool Function(SemanticsData data)? skipContrast,
  bool scroll = true,
  required Finder shows,
  Map<String, Object> prefs = const {},
  bool signedIn = true,
  List<double> textScales = a11yTextScales,
  String? skip,
}) {
  final runs = <(Brightness, double)>[
    for (final brightness in Brightness.values) (brightness, 1),
    for (final scale in textScales) (Brightness.light, scale),
  ];
  for (final (brightness, scale) in runs) {
    final label = scale == 1 ? '' : ', text ${(scale * 100).round()}%';
    testWidgets(skip: skip != null, '$name: ${brightness.name}$label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await a11yPumpApp(
        tester,
        brightness,
        overrides: overrides,
        window: window,
        settleFor: settleFor,
        prefs: prefs,
        textScale: scale,
        signedIn: signedIn,
      );
      var finished = false;
      try {
        if (location != '/' && signedIn) await a11yGo(tester, location);
        if (arrange != null) {
          await arrange(tester);
          await a11ySettle(tester, const Duration(milliseconds: 500));
        }
        // Proves the surface was reached, so a failure below is a guideline and
        // not a screen that never built.
        if (!await _reveal(tester, shows)) {
          expect(shows, findsWidgets);
        }
        if (scroll) {
          await a11yMeetsAllWhileScrolling(tester, skipContrast: skipContrast);
        } else {
          await a11yMeetsAll(tester, skipContrast: skipContrast);
        }
        // A request the scroll pass started would end the test in flight.
        await a11ySettle(tester, const Duration(milliseconds: 700));
        finished = true;
      } finally {
        // Whatever the surface started has to stop while its providers are alive,
        // and on a failing run too: a recording left running would fail the next
        // surface for a reason that is not in it.
        // Every cleanup runs and the list is always emptied, so one that throws
        // cannot be replayed into the next surface; the first error is rethrown
        // after the app is unmounted.
        Object? cleanupError;
        StackTrace? cleanupStack;
        while (_cleanups.isNotEmpty) {
          try {
            await _cleanups.removeLast()();
          } catch (error, stack) {
            cleanupError ??= error;
            cleanupStack ??= stack;
          }
        }
        // Unmounting stops the polls; 200 ms lets a request that started in the
        // last frame finish.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 200));
        handle.dispose();
        // A failure already in flight is the finding; a cleanup error must not hide it.
        if (finished && cleanupError != null) {
          Error.throwWithStackTrace(cleanupError, cleanupStack!);
        }
      }
    });
  }
}

/// The findings of an earlier measurement whose **node** a later one still reports.
///
/// Keyed by node, not by the ordinal a finding has among its node's: one node can
/// carry several findings (a label several `Text`s share), and when the first of them
/// passes at another phase the second moves to ordinal 0, so a match by ordinal keeps
/// the one that passed and drops the one that never did. A node whose elements fail
/// at different phases stays: that over-reports, and the judge clears it when the text's
/// own colours pass; the other way would hide a finding.
Map<String, String> a11yStillFailing(
  Map<String, String> earlier,
  Map<String, String> later,
) {
  String node(String key) => key.split('/').first;
  final still = {for (final key in later.keys) node(key)};
  return {
    for (final entry in earlier.entries)
      if (still.contains(node(entry.key))) entry.key: entry.value,
  };
}

/// [textContrastGuideline] minus the nodes it misreads. It takes the text colour
/// from the commonest light and dark pixels of the node's whole rect, and a
/// section header fools it: a short label in a full-width row leaves too few text
/// pixels. Its ink is `accentInk`, which `brand_contrast_test.dart` holds to the
/// design system's audit on every ground.
///
/// Beyond that, a finding has to survive two more checks before it fails a test:
/// it must fail at every sub-pixel phase (see [phases]), and the text's own
/// colours must fail too ([judgeContrastFindings]). The pixel measure reads 11-14
/// dp semi-transparent text badly; a finding the colours back up, or cannot judge,
/// still fails.
///
/// [extra] is a surface's own narrowing, reason in its file.
class _ContrastBesideMisreads extends MinimumTextContrastGuideline {
  const _ContrastBesideMisreads([this.extra]);

  final bool Function(SemanticsData data)? extra;

  @override
  bool shouldSkipNode(SemanticsData data) =>
      super.shouldSkipNode(data) ||
      data.flagsCollection.isHeader ||
      (extra?.call(data) ?? false);

  /// Paint offsets, in dp, a finding is measured again at. The histogram's
  /// "commonest dark colour" depends on where a glyph's edge falls in a pixel: 13 px
  /// dark ink on a light chip read 1.37:1 at one x phase out of twenty and passed at
  /// the other nineteen. A real shortfall does not depend on the phase.
  static const phases = [0.37, 0.71];

  static final _nodeId = RegExp(r'SemanticsNode#(\d+)');

  /// One finding per node and element: a report is the nodes' messages one after
  /// another, and a node whose label several Texts share is reported once per Text.
  static Map<String, String> _findings(Evaluation e) {
    final seen = <String, int>{};
    return {
      for (final part in (e.reason ?? '').split(
        RegExp(r'(?=SemanticsNode#\d+\()'),
      ))
        if (_nodeId.firstMatch(part) case final m?)
          '${m.group(1)}/${seen.update(m.group(1)!, (n) => n + 1, ifAbsent: () => 0)}':
              part,
    };
  }

  /// Fails only the nodes that fail at the shipped position and at every phase.
  /// Needs [a11yPhase] to move something: on a tree built without a pump of this
  /// harness the phases measure the same pixels and the findings stand.
  @override
  Future<Evaluation> evaluate(WidgetTester tester) async {
    final shipped = await super.evaluate(tester);
    if (shipped.passed) return shipped;
    var findings = _findings(shipped);
    for (final phase in phases) {
      a11yPhase.value = phase;
      await tester.pump();
      final again = _findings(await super.evaluate(tester));
      findings = a11yStillFailing(findings, again);
      if (findings.isEmpty) break;
    }
    a11yPhase.value = 0;
    await tester.pump();
    // The guideline reads no colour; see [ContrastVerdict]. A finding stands unless
    // the text's own colours pass on every ground behind every paragraph of the
    // node.
    final judged = await judgeContrastFindings(tester, findings);
    reportContrastFindings(judged);
    findings.removeWhere(
      (k, _) => judged[k]?.verdict == ContrastVerdict.artefact,
    );
    return findings.isEmpty
        ? const Evaluation.pass()
        : Evaluation.fail(findings.values.join('\n'));
  }
}
