import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../services/notifications.dart';
import 'common.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.name,
    required this.email,
    required this.onSignOut,
    this.notifications,
  });
  final String name, email;
  final Future<void> Function() onSignOut;
  final TaskpilotNotifications? notifications;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _signingOut = false;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('Your workspace', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text(
        'Keep Taskpilot working the way you need.',
        style: TextStyle(color: Brand.muted),
      ),
      const SizedBox(height: 24),
      Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.all(18),
          leading: CircleAvatar(
            backgroundColor: Brand.indigo,
            foregroundColor: Colors.white,
            child: Text(
              widget.name.isEmpty
                  ? 'T'
                  : widget.name.substring(0, 1).toUpperCase(),
            ),
          ),
          title: Text(widget.name),
          subtitle: Text(widget.email),
        ),
      ),
      const SizedBox(height: 20),
      if (widget.notifications == null)
        const Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Local preview\nYour sample tasks are saved on this device. Connect Firebase to use account sign-in and push notifications.',
            ),
          ),
        )
      else
        AnimatedBuilder(
          animation: widget.notifications!,
          builder: (context, _) {
            final notifications = widget.notifications!;
            return Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: Brand.indigo,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Task notifications',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Allow alerts to receive task updates even when you are away from Taskpilot.',
                      style: TextStyle(color: Brand.muted),
                    ),
                    const SizedBox(height: 18),
                    BusyButton(
                      busy: notifications.busy,
                      label: 'Enable / refresh notifications',
                      onPressed: notifications.enable,
                    ),
                    if (notifications.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            notifications.error!,
                            style: const TextStyle(color: Brand.danger),
                          ),
                        ),
                      ),
                    if (notifications.token != null) ...[
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await notifications.showTest();
                            if (context.mounted) {
                              showNotice(
                                context,
                                'Local test notification requested.',
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              showNotice(
                                context,
                                'Enable notifications and try again.',
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.notifications_outlined),
                        label: const Text('Test local notification'),
                      ),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Device token for FCM testing'),
                        children: [
                          SelectableText(
                            notifications.token!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Brand.muted,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: notifications.token!),
                              );
                              if (context.mounted) {
                                showNotice(context, 'FCM token copied.');
                              }
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy device token'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        onPressed: _signingOut
            ? null
            : () async {
                setState(() => _signingOut = true);
                try {
                  await widget.onSignOut();
                } catch (_) {
                  if (context.mounted) {
                    showNotice(context, 'Could not sign out. Try again.');
                  }
                } finally {
                  if (mounted) setState(() => _signingOut = false);
                }
              },
        icon: const Icon(Icons.logout),
        label: Text(_signingOut ? 'Signing out…' : 'Sign out'),
      ),
      const SizedBox(height: 40),
      const Center(child: BrandLogo(size: 32)),
      const SizedBox(height: 8),
      const Text(
        'A clear plan. A calmer day.\nVersion 1.0.0',
        textAlign: TextAlign.center,
        style: TextStyle(color: Brand.muted, fontSize: 12),
      ),
    ],
  );
}
