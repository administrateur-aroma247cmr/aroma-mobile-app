import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/aroma_api.dart';
import '../../widgets/auth_page_layout.dart';
import '../../widgets/otp_digit_row.dart';

const _otpLength = 6;

class ValidateOtpScreen extends StatefulWidget {
  const ValidateOtpScreen({
    super.key,
    required this.email,
    required this.onBackToLogin,
    required this.onResendCode,
    required this.onSuccess,
  });

  final String? email;
  final VoidCallback onBackToLogin;
  final VoidCallback onResendCode;
  final void Function(String resetToken) onSuccess;

  @override
  State<ValidateOtpScreen> createState() => _ValidateOtpScreenState();
}

class _ValidateOtpScreenState extends State<ValidateOtpScreen> {
  String _otp = '';
  String? _error;
  bool _loading = false;
  int _otpWidgetKey = 0;

  Future<void> _submit() async {
    final email = widget.email;
    if (email == null || email.isEmpty) return;
    if (_otp.length != _otpLength) {
      setState(() => _error = 'Saisissez les $_otpLength chiffres du code.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final token = await context.read<AuthProvider>().api.validateOtp(
            email: email,
            otp: _otp,
          );
      if (!mounted) return;
      widget.onSuccess(token);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email;
    if (email == null || email.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: AuthPageLayout(
          title: 'Lien invalide',
          description:
              'Veuillez demander un nouveau code depuis « Mot de passe oublié ».',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: widget.onResendCode,
                  child: const Text('Mot de passe oublié'),
                ),
              ),
              TextButton(
                onPressed: widget.onBackToLogin,
                child: const Text('Retour à la connexion'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: AuthPageLayout(
        title: 'Vérification du code',
        description:
            'Saisissez le code à $_otpLength chiffres envoyé à $email',
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OtpDigitRow(
                key: ValueKey(_otpWidgetKey),
                length: _otpLength,
                onChanged: (v) {
                  setState(() {
                    _otp = v;
                    _error = null;
                  });
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: (_otp.length != _otpLength || _loading)
                      ? null
                      : _submit,
                  child: _loading
                      ? const Text('Vérification…')
                      : const Text('Valider le code'),
                ),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() {
                          _otpWidgetKey++;
                          _otp = '';
                          _error = null;
                        });
                        widget.onResendCode();
                      },
                child: const Text('Renvoyer un code'),
              ),
              TextButton(
                onPressed: _loading ? null : widget.onBackToLogin,
                child: const Text('Retour à la connexion'),
              ),
            ],
          ),
      ),
    );
  }
}
