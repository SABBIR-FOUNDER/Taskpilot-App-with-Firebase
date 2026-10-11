import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import 'common.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.auth, this.onPreview});
  final AuthService? auth;
  final VoidCallback? onPreview;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _signup = false, _busy = false, _obscure = true;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit({bool google = false}) async {
    if (widget.auth == null) {
      showNotice(
        context,
        'This is the local preview. Use Explore Taskpilot below.',
      );
      return;
    }
    if (!google && !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (google) {
        await widget.auth!.signInWithGoogle();
      } else if (_signup) {
        await widget.auth!.signUp(_name.text, _email.text, _password.text);
      } else {
        await widget.auth!.signIn(_email.text, _password.text);
      }
    } catch (e) {
      if (mounted) setState(() => _error = authError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (widget.auth == null) {
      showNotice(
        context,
        'Password reset becomes available after Firebase setup.',
      );
      return;
    }
    final validation = validateEmail(_email.text);
    if (validation != null) {
      setState(
        () => _error = 'Enter your email above, then tap Forgot password.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth!.resetPassword(_email.text);
      if (mounted) {
        showNotice(
          context,
          'If this account exists, a reset email is on its way.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = authError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _hero(bool wide) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(wide ? 42 : 28),
    decoration: BoxDecoration(
      color: Brand.navy,
      borderRadius: BorderRadius.circular(28),
      image: const DecorationImage(
        image: AssetImage('assets/brand/welcome_background.png'),
        fit: BoxFit.cover,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const BrandLogo(white: true),
        SizedBox(height: wide ? 96 : 30),
        Text(
          'A clear plan.\nA calmer day.',
          style: TextStyle(
            color: Colors.white,
            fontSize: wide ? 43 : 32,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Give your priorities a place.\nMove forward, one task at a time.',
          style: TextStyle(color: Color(0xFFD9E3F4), fontSize: 16, height: 1.6),
        ),
        SizedBox(height: wide ? 92 : 24),
        const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Brand.mint, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Your next step, in focus.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _fields() => AutofillGroup(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _signup ? 'Make room for progress.' : 'Welcome back.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _signup
                ? 'Create your Taskpilot account.'
                : 'Sign in to pick up where you left off.',
            style: const TextStyle(color: Brand.muted),
          ),
          const SizedBox(height: 28),
          if (_signup) ...[
            TextFormField(
              controller: _name,
              enabled: !_busy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Your name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter your name.' : null,
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.alternate_email),
            ),
            validator: validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            enabled: !_busy,
            obscureText: _obscure,
            autofillHints: [
              _signup ? AutofillHints.newPassword : AutofillHints.password,
            ],
            textInputAction: _signup
                ? TextInputAction.next
                : TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!_signup && !_busy) _submit();
            },
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (v) => v == null || v.isEmpty
                ? 'Enter your password.'
                : _signup && v.length < 8
                ? 'Use at least 8 characters.'
                : null,
          ),
          if (_signup) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              enabled: !_busy,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_busy) _submit();
              },
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) =>
                  v != _password.text ? 'Passwords do not match.' : null,
            ),
          ],
          if (!_signup)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy ? null : _reset,
                child: const Text('Forgot password?'),
              ),
            ),
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Brand.danger),
                ),
              ),
            ),
          const SizedBox(height: 12),
          BusyButton(
            busy: _busy,
            label: _signup ? 'Create account' : 'Sign in',
            onPressed: _submit,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('or', style: TextStyle(color: Brand.muted)),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _submit(google: true),
            icon: const Icon(Icons.account_circle_outlined),
            label: const Text('Continue with Google'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _signup = !_signup;
                    _error = null;
                  }),
            child: Text(
              _signup
                  ? 'Already have an account? Sign in'
                  : 'New to Taskpilot? Create an account',
            ),
          ),
          if (widget.onPreview != null) ...[
            const Divider(),
            TextButton.icon(
              onPressed: widget.onPreview,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Explore Taskpilot · local preview'),
            ),
            const Text(
              'Sample workspace saved on this device. Cloud sign-in and push notifications are available after Firebase setup.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Brand.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, bounds) {
          final wide = bounds.maxWidth >= 850;
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(wide ? 32 : 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _hero(true)),
                          const SizedBox(width: 48),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: _fields(),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _hero(false),
                          const SizedBox(height: 30),
                          _fields(),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
