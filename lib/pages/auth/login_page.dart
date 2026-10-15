import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/core/app_theme.dart';
import '/core/app_util.dart';
import '/services/google_auth_service.dart';
import '/state/session_state.dart';

/// Halaman masuk memakai akun Google kampus.
///
/// Alurnya: Google memberi `idToken`, lalu token itu ditukar ke API
/// Kantin ITK menjadi kunci akses yang dipakai seluruh permintaan.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static String routeName = 'LoginPage';
  static String routePath = '/masuk';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _google = GoogleAuthService();

  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await _google.signIn();
    if (!mounted) return;

    switch (result) {
      case GoogleAuthCancelled():
        setState(() => _busy = false);

      case GoogleAuthFailure(:final message):
        setState(() {
          _busy = false;
          _error = message;
        });

      case GoogleAuthSuccess(:final idToken):
        final session = context.read<SessionState>();
        final ok = await session.loginWithGoogle(idToken);
        if (!mounted) return;
        if (ok) {
          context.goNamed(session.homeRouteName);
          return;
        }
        // Akun yang ditolak server dilepas dari Google agar pemilih akun muncul lagi.
        await _google.signOut();
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = session.error ?? 'Gagal masuk. Coba lagi.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppTheme.of(context).primaryBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 132.0,
                  height: 132.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 24.0,
                        color: Colors.black.withValues(alpha: 0.06),
                        offset: const Offset(0.0, 8.0),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18.0),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.restaurant_menu,
                      size: 52.0,
                      color: Color(0xFFAC3509),
                    ),
                  ),
                ),
                const SizedBox(height: 28.0),
                Text(
                  'Kantin ITK',
                  style: AppTheme.of(context).headlineMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w800),
                        color: const Color(0xFF1B1C1C),
                        letterSpacing: 0.0,
                      ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Masuk dengan akun Google kampusmu untuk mulai memesan.',
                  textAlign: TextAlign.center,
                  style: AppTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight:
                              AppTheme.of(context).bodyMedium.fontWeight,
                          fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                        ),
                        color: const Color(0xFF59413A),
                        letterSpacing: 0.0,
                      ),
                ),
                const SizedBox(height: 32.0),
                if (_error != null) ...[
                  _errorBox(context, _error!),
                  const SizedBox(height: 16.0),
                ],
                _googleButton(context),
                const SizedBox(height: 16.0),
                Text(
                  'Gunakan email berakhiran @itk.ac.id atau '
                  '@student.itk.ac.id.',
                  textAlign: TextAlign.center,
                  style: AppTheme.of(context).bodySmall.override(
                        font: GoogleFonts.inter(
                          fontWeight:
                              AppTheme.of(context).bodySmall.fontWeight,
                          fontStyle: AppTheme.of(context).bodySmall.fontStyle,
                        ),
                        color: const Color(0xFF9A8C87),
                        letterSpacing: 0.0,
                      ),
                ),
                if (!_google.isConfigured) ...[
                  const SizedBox(height: 20.0),
                  _configHint(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _googleButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54.0,
      child: FilledButton(
        onPressed: _busy ? null : _signIn,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFAC3509),
          disabledBackgroundColor: const Color(0xFFD9BFB6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
        ),
        child: _busy
            ? const SizedBox(
                width: 22.0,
                height: 22.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 26.0,
                    height: 26.0,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      'G',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.0,
                        color: const Color(0xFF4285F4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Text(
                    'Masuk dengan Google',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.0,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _errorBox(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDEA),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFF5C6BE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              size: 20.0, color: Color(0xFFBA1A1A)),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              message,
              style: AppTheme.of(context).bodySmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    color: const Color(0xFF8C1D18),
                    letterSpacing: 0.0,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Petunjuk yang muncul bila client ID Google belum diisi, agar
  /// kegagalan pengaturan tidak terlihat seperti bug aplikasi.
  Widget _configHint(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFE8C99B)),
      ),
      child: Text(
        'Platform ini tidak membawa Client ID Google sendiri. Isi '
        'GOOGLE_SERVER_CLIENT_ID pada config/dart_defines.json lalu '
        'jalankan ulang aplikasi.',
        style: AppTheme.of(context).bodySmall.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.w500),
              color: const Color(0xFF7A5B1E),
              letterSpacing: 0.0,
            ),
      ),
    );
  }
}
