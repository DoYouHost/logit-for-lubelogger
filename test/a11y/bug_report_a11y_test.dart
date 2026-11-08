import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:app_report_ui/app_report_ui.dart';
import 'package:app_report_ui/l10n/report_localizations_pl.dart';
import 'package:app_test_kit/app_test_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'a11y_harness.dart';

/// The strings of the shared report screens, as the app renders them.
final _rpl = ReportLocalizationsPl();

Finder _kind(String label) =>
    find.descendant(of: byLogId('bug_report.kind'), matching: find.text(label));

/// The words a parameterised string starts with, to find it without knowing the
/// number that fills it in.
String _prefixOfInt(String Function(int) format) =>
    format(0).split('0').first.trim();

/// Starts a real recording through the controller, the way its button does, and
/// makes sure none outlives the test: the recorder is process-wide.
Future<void> _record(WidgetTester tester) async {
  final controller = a11yContainer(tester).read(bugReportProvider.notifier);
  a11yOnDone(controller.discard);
  await controller.start();
  await a11ySettle(tester, const Duration(milliseconds: 500));
}

/// A recording with something in it, stopped, so the review is what is shown.
Future<void> _review(WidgetTester tester) async {
  await _record(tester);
  DiagnosticRecorder.active?.add(
    LogSource.http,
    'response',
    lvl: LogLevel.warn,
    fields: const {'status': 502},
  );
  await a11yContainer(tester).read(bugReportProvider.notifier).stop();
  await a11ySettle(tester, const Duration(milliseconds: 500));
}

void main() {
  group('choosing what to report', () {
    a11ySurface(
      'bug report: explanation',
      location: bugReportRoute,
      shows: find.text(_rpl.bugReportIntroHeader),
    );

    a11ySurface(
      'bug report: bug chosen',
      location: bugReportRoute,
      arrange: (tester) async {
        // The bug is the default, so leave it first: only a choice made back
        // to it can show the recording button.
        await a11yTap(tester, _kind(_rpl.bugReportKindChange));
        expect(find.text(_rpl.bugReportChangeHeader), findsOneWidget);
        await a11yTap(tester, _kind(_rpl.bugReportKindBug));
      },
      shows: find.text(_rpl.bugReportStart),
    );

    a11ySurface(
      'bug report: change chosen',
      location: bugReportRoute,
      arrange: (tester) => a11yTap(tester, _kind(_rpl.bugReportKindChange)),
      shows: find.text(_rpl.bugReportChangeHeader),
    );

    a11ySurface(
      'bug report: feature chosen',
      location: bugReportRoute,
      arrange: (tester) => a11yTap(tester, _kind(_rpl.bugReportKindFeature)),
      shows: find.text(_rpl.bugReportFeatureHeader),
    );
  });

  group('requests without a log', () {
    for (final (index, kind) in [
      (1, _rpl.bugReportKindChange),
      (2, _rpl.bugReportKindFeature),
    ]) {
      a11ySurface(
        'request $index: sent without a description',
        location: bugReportRoute,
        arrange: (tester) async {
          await a11yTap(tester, _kind(kind));
          await a11yTap(tester, byLogId('bug_report.send'));
        },
        shows: find.textContaining(_prefixOfInt(_rpl.bugReportRequestRequired)),
      );

      a11ySurface(
        'request $index: refused in demo mode',
        location: bugReportRoute,
        arrange: (tester) async {
          await a11yTap(tester, _kind(kind));
          await a11yEnter(
            tester,
            find.descendant(
              of: byLogId('bug_report.description'),
              matching: find.byType(TextField),
            ),
            'Please let me attach a photo to a reminder.',
          );
          await a11yTap(tester, byLogId('bug_report.send'));
        },
        shows: find.text(_rpl.bugReportRequestFailedDemo),
      );
    }
  });

  group('recording', () {
    a11ySurface(
      'bug report: recording in progress',
      location: bugReportRoute,
      arrange: _record,
      shows: find.text(_rpl.bugReportRecordingHeader),
    );

    a11ySurface(
      'garage with the recording bar',
      arrange: (tester) async {
        await _record(tester);
        await a11yGo(tester, '/');
      },
      shows: find.text(_rpl.bugReportStopShort),
    );
  });

  group('review', () {
    a11ySurface(
      'bug report: review',
      location: bugReportRoute,
      arrange: _review,
      shows: find.text(_rpl.bugReportReviewHeader),
    );

    a11ySurface(
      'bug report: review with the raw log',
      location: bugReportRoute,
      arrange: (tester) async {
        await _review(tester);
        await a11yTap(tester, byLogId('bug_report.toggle_raw'));
      },
      shows: find.text(_rpl.bugReportHideRaw),
    );

    a11ySurface(
      'bug report: review with a record opened',
      location: bugReportRoute,
      arrange: (tester) async {
        await _review(tester);
        await a11yTap(tester, byLogId('bug_report.toggle_line').first);
      },
      // The chevron of a clamped record turns over once it is opened.
      shows: find.byIcon(Icons.expand_less_rounded),
    );

    a11ySurface(
      'bug report: GitHub chosen',
      location: bugReportRoute,
      arrange: (tester) async {
        await _review(tester);
        await a11yTap(tester, byLogId('bug_report.destination').last);
      },
      shows: find.text(_rpl.bugReportDescriptionLabel),
    );

    a11ySurface(
      'bug report: GitHub chosen, refused in demo mode',
      location: bugReportRoute,
      arrange: (tester) async {
        await _review(tester);
        await a11yTap(tester, byLogId('bug_report.destination').last);
        await a11yEnter(
          tester,
          find.descendant(
            of: byLogId('bug_report.description'),
            matching: find.byType(TextField),
          ),
          'The reminder list jumps back to the top after a refresh.',
        );
        await a11yTap(tester, byLogId('bug_report.send'));
      },
      shows: find.text(_rpl.bugReportSendFailedDemo),
    );

    a11ySurface(
      'bug report: discard asked',
      location: bugReportRoute,
      arrange: (tester) async {
        await _review(tester);
        await a11yTap(tester, byLogId('bug_report.discard'));
      },
      shows: find.text(_rpl.bugReportDiscardQuestion),
    );
  });
}
