import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/demo/demo_config.dart';
import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import 'providers.dart';
import 'setup_error_text.dart';

/// Login / server setup: server URL + API key. The key is validated against
/// `GET /api/whoami`; on success the profile is saved and the router advances
/// to the app.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _url = TextEditingController();
  final _apiKey = TextEditingController();
  bool _obscureKey = true;

  @override
  void dispose() {
    _url.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  void _submit() {
    ref
        .read(setupControllerProvider.notifier)
        .connect(rawUrl: _url.text, apiKey: _apiKey.text);
  }

  /// Fill the fields with the demo credentials (store-review mode); revealing
  /// the key so it's visible. The user still taps Connect to enter the demo.
  void _fillDemo() {
    setState(() {
      _url.text = 'demo';
      _apiKey.text = DemoConfig.token;
      _obscureKey = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final state = ref.watch(setupControllerProvider);

    return logSurface(
      'setup',
      DashBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: dashAppBar(context, title: l10n.connectToServer),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(DashSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.only(
                    bottom: DashSpace.xs,
                    left: DashSpace.xs,
                  ),
                  child: AppWordmark(fontSize: 30),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DashSpace.xs,
                    DashSpace.xs,
                    DashSpace.xs,
                    DashSpace.lg,
                  ),
                  child: Text(
                    l10n.setupIntro,
                    style: TextStyle(
                      fontFamily: DashTokens.fontUi,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: t.textSecondary,
                    ),
                  ),
                ),
                _card(t, l10n, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(DashTokens t, AppLocalizations l10n, SetupState state) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DashSpace.lg),
        decoration: BoxDecoration(
          gradient: t.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _url,
              enabled: !state.busy,
              keyboardType: TextInputType.url,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              style: _fieldStyle(t, mono: false),
              decoration: dashFieldDecoration(
                t,
                labelText: l10n.serverAddressLabel,
                hintText: l10n.serverAddressHint,
                helperText: l10n.serverAddressHelper,
                prefixIcon: Icon(Icons.dns_outlined, color: t.textTertiary),
              ),
            ).tagged('setup.url'),
            const SizedBox(height: DashSpace.lg),
            Text(
              l10n.apiKeyExplain,
              style: TextStyle(
                fontFamily: DashTokens.fontUi,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(height: DashSpace.md),
            TextField(
              controller: _apiKey,
              enabled: !state.busy,
              obscureText: _obscureKey,
              autocorrect: false,
              enableSuggestions: false,
              style: _fieldStyle(t, mono: true),
              onSubmitted: (_) => state.busy ? null : _submit(),
              decoration: dashFieldDecoration(
                t,
                labelText: l10n.apiKeyLabel,
                prefixIcon: Icon(Icons.key_outlined, color: t.textTertiary),
                suffixIcon: IconButton(
                  tooltip: _obscureKey ? l10n.apiKeyShow : l10n.apiKeyHide,
                  icon: Icon(
                    _obscureKey
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: t.textTertiary,
                  ),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ).tagged('setup.apiKey.reveal'),
              ),
            ).tagged('setup.apiKey'),
            const SizedBox(height: DashSpace.lg),
            FilledButton(
              style: dashPrimaryButtonStyle(t),
              onPressed: state.busy ? null : _submit,
              child: state.busy
                  ? _busyLabel(l10n.connecting)
                  : Text(l10n.connect),
            ).tagged('setup.connect'),
            const SizedBox(height: DashSpace.xs),
            Center(
              child: TextButton.icon(
                onPressed: state.busy ? null : _fillDemo,
                // Named because it is the store reviewer's way in, and a demo
                // session that goes wrong is reported like any other.
                icon: Icon(
                  Icons.play_circle_outline,
                  size: 18,
                  color: t.textSecondary,
                ),
                label: Text(l10n.tryDemo),
                style: TextButton.styleFrom(
                  foregroundColor: t.textSecondary,
                  textStyle: const TextStyle(
                    fontFamily: DashTokens.fontUi,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).tagged('setup.demo'),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: DashSpace.lg),
                child: Text(
                  setupErrorText(l10n, state.error!),
                  style: TextStyle(
                    fontFamily: DashTokens.fontUi,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.dangerInk,
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _busyLabel(String text) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF1A1206),
        ),
      ),
      const SizedBox(width: DashSpace.md),
      Text(text),
    ],
  );

  TextStyle _fieldStyle(DashTokens t, {required bool mono}) => TextStyle(
    fontFamily: mono ? DashTokens.fontMono : DashTokens.fontUi,
    fontSize: mono ? 13 : 14,
    fontWeight: FontWeight.w600,
    color: t.textPrimary,
  );
}
