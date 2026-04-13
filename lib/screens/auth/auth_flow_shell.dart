import 'package:flutter/material.dart';

import '../login_screen.dart';
import 'forgot_password_screen.dart';
import 'reset_password_screen.dart';
import 'validate_otp_screen.dart';

/// Flux auth (login → mot de passe oublié → OTP → nouveau MDP), fond blanc plein écran.
class AuthFlowShell extends StatefulWidget {
  const AuthFlowShell({super.key});

  @override
  State<AuthFlowShell> createState() => _AuthFlowShellState();
}

class _AuthFlowShellState extends State<AuthFlowShell> {
  _AuthStep _step = _AuthStep.login;
  String? _email;
  String? _resetToken;
  String? _loginInfoMessage;

  void _goForgot() {
    setState(() {
      _loginInfoMessage = null;
      _step = _AuthStep.forgot;
    });
  }

  void _goLogin({bool clearMessage = true}) {
    setState(() {
      _step = _AuthStep.login;
      _email = null;
      _resetToken = null;
      if (clearMessage) _loginInfoMessage = null;
    });
  }

  void _goOtp(String email) {
    setState(() {
      _email = email;
      _step = _AuthStep.otp;
    });
  }

  void _goReset(String token) {
    setState(() {
      _resetToken = token;
      _step = _AuthStep.reset;
    });
  }

  void _onResetSuccess() {
    setState(() {
      _loginInfoMessage = 'Mot de passe modifié. Connectez-vous.';
      _step = _AuthStep.login;
      _email = null;
      _resetToken = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case _AuthStep.login:
        return LoginScreen(
          infoMessage: _loginInfoMessage,
          onForgotPassword: _goForgot,
        );
      case _AuthStep.forgot:
        return ForgotPasswordScreen(
          initialEmail: _email,
          onBackToLogin: () => _goLogin(),
          onCodeSent: _goOtp,
        );
      case _AuthStep.otp:
        return ValidateOtpScreen(
          email: _email,
          onBackToLogin: () => _goLogin(),
          onResendCode: () => setState(() => _step = _AuthStep.forgot),
          onSuccess: _goReset,
        );
      case _AuthStep.reset:
        return ResetPasswordScreen(
          resetToken: _resetToken,
          onBackToLogin: () => _goLogin(),
          onForgotPassword: _goForgot,
          onSuccess: _onResetSuccess,
        );
    }
  }
}

enum _AuthStep { login, forgot, otp, reset }
