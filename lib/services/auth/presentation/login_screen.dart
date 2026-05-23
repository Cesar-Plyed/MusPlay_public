import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../main.dart';
import '../../../shared/widgets/terms_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _termsAccepted = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => _isLogin || _termsAccepted;

  Future<void> _submitEmail() async {
    if (!_canSubmit) {
      setState(() => _error = 'Debes aceptar los Términos y la Política de Privacidad');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await _authService.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
      } else {
        await _authService.registerWithEmail(
            _emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim());
      }
    } on FirebaseAuthException {
      setState(() => _error = 'Verifica tu email y contraseña');
    } catch (e) {
      setState(() => _error = 'Error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInGoogle() async {
    if (!_isLogin && !_termsAccepted) {
      setState(() => _error = 'Debes aceptar los Términos y la Política de Privacidad');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      setState(() => _error = 'Error al iniciar con Google. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _continueAsGuest() {
    isGuestMode = true;
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _showTerms() => showDialog(context: context,
      builder: (_) => const TermsDialog(isPrivacy: false));

  void _showPrivacy() => showDialog(context: context,
      builder: (_) => const TermsDialog(isPrivacy: true));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo ────────────────────────────────────────────────────
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(
                      color: AppTheme.accentDim, shape: BoxShape.circle),
                  child: const Icon(Icons.music_note, color: AppTheme.accent, size: 40),
                ),
                const SizedBox(height: 20),
                Text('MusPlay', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 6),
                Text('Tu música, en cualquier lugar',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 36),

                // ── Aviso de contenido ────────────────────────────────────
                if (!_isLogin)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentDim,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: AppTheme.accent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        'Solo sube música de la que tengas los derechos.',
                        style: const TextStyle(color: AppTheme.accent, fontSize: 12),
                      )),
                    ]),
                  ),

                // ── Campos ───────────────────────────────────────────────
                if (!_isLogin) ...[
                  _InputField(controller: _nameCtrl, hint: 'Nombre', icon: Icons.person),
                  const SizedBox(height: 12),
                ],
                _InputField(controller: _emailCtrl, hint: 'Email', icon: Icons.email,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _InputField(controller: _passCtrl, hint: 'Contraseña',
                    icon: Icons.lock, obscure: true),
                const SizedBox(height: 12),

                // ── Checkbox términos (solo en registro) ─────────────────
                if (!_isLogin)
                  _TermsCheckbox(
                    value: _termsAccepted,
                    onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                    onTermsTap: _showTerms,
                    onPrivacyTap: _showPrivacy,
                  ),

                // ── Error ────────────────────────────────────────────────
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center),
                  ),
                const SizedBox(height: 12),

                // ── Botón principal ──────────────────────────────────────
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submitEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: AppTheme.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(_isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Divisor ──────────────────────────────────────────────
                Row(children: [
                  const Expanded(child: Divider(color: AppTheme.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('o', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  const Expanded(child: Divider(color: AppTheme.divider)),
                ]),
                const SizedBox(height: 16),

                // ── Google ───────────────────────────────────────────────
                SizedBox(
                  width: double.infinity, height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _signInGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 28, color: AppTheme.textPrimary),
                    label: const Text('Continuar con Google',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Invitado ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity, height: 44,
                  child: TextButton(
                    onPressed: _loading ? null : _continueAsGuest,
                    child: const Text('Continuar como invitado',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Toggle login/registro ────────────────────────────────
                TextButton(
                  onPressed: () => setState(() { _isLogin = !_isLogin; _error = null; }),
                  child: Text(
                    _isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión',
                    style: const TextStyle(color: AppTheme.accent),
                  ),
                ),

                // ── Links de términos (siempre visibles abajo) ───────────
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  GestureDetector(
                    onTap: _showTerms,
                    child: const Text('Términos de uso',
                        style: TextStyle(color: AppTheme.textSecondary,
                            fontSize: 11, decoration: TextDecoration.underline)),
                  ),
                  const Text('  ·  ',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  GestureDetector(
                    onTap: _showPrivacy,
                    child: const Text('Política de Privacidad',
                        style: TextStyle(color: AppTheme.textSecondary,
                            fontSize: 11, decoration: TextDecoration.underline)),
                  ),
                ]),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Checkbox con links a términos ─────────────────────────────────────────────

class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 24, height: 24,
        child: Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accent,
          side: const BorderSide(color: AppTheme.textSecondary),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
            children: [
              const TextSpan(text: 'He leído y acepto los '),
              TextSpan(
                text: 'Términos y Condiciones',
                style: const TextStyle(color: AppTheme.accent,
                    decoration: TextDecoration.underline),
                recognizer: TapGestureRecognizer()..onTap = onTermsTap,
              ),
              const TextSpan(text: ' y la '),
              TextSpan(
                text: 'Política de Privacidad',
                style: const TextStyle(color: AppTheme.accent,
                    decoration: TextDecoration.underline),
                recognizer: TapGestureRecognizer()..onTap = onPrivacyTap,
              ),
              const TextSpan(text: ' de MusPlay.'),
            ],
          ),
        ),
      ),
    ]);
  }
}

// ── Campo de texto ────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
