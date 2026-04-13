import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../widgets/auth_page_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onForgotPassword,
    this.infoMessage,
  });

  final VoidCallback onForgotPassword;
  final String? infoMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      if (auth.mustChangePassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vous devez changer votre mot de passe depuis le CRM.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } else {
      setState(() => _error = auth.lastError ?? 'Erreur de connexion');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final info = widget.infoMessage;
    final disabledAccount = _error != null &&
        _error!.toLowerCase().contains('désactivé');

    return Scaffold(
      backgroundColor: Colors.white,
      body: AuthPageLayout(
        title: 'Connexion',
        description: 'Connectez-vous à votre compte Aroma JPC',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (info != null) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF6EE7B7)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      info,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF065F46),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  hintText: 'vous@exemple.com',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'E-mail requis';
                  }
                  if (!v.contains('@')) return 'E-mail invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Mot de passe',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AromaColors.zinc900,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: auth.loading ? null : widget.onForgotPassword,
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Mot de passe requis';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: disabledAccount
                        ? const Color(0xFFFFFBEB)
                        : Theme.of(context)
                            .colorScheme
                            .errorContainer
                            .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: disabledAccount
                          ? const Color(0xFFFDE68A)
                          : Theme.of(context).colorScheme.error.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (disabledAccount) ...[
                          Icon(
                            Icons.shield_outlined,
                            size: 20,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: disabledAccount
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Compte désactivé',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Votre accès a été suspendu. Contactez votre administrateur pour réactiver votre compte.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.amber.shade900
                                            .withValues(alpha: 0.9),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  _error!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: auth.loading ? null : _submit,
                  child: auth.loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Se connecter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
