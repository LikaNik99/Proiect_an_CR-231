import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../network/connectivity_manager.dart';
import '../network/connection_status.dart';
import '../sync/sync_manager.dart';

class ConnectionStatusBar extends StatefulWidget {
  const ConnectionStatusBar({super.key});

  @override
  State<ConnectionStatusBar> createState() => _ConnectionStatusBarState();
}

class _ConnectionStatusBarState extends State<ConnectionStatusBar> {
  final ConnectivityManager connectivity = GetIt.instance.get<ConnectivityManager>();
  final SyncManager syncManager = GetIt.instance.get<SyncManager>();

  ConnectionStateType? _lastState;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectionStatus>(
      stream: connectivity.stream,
      initialData: connectivity.currentStatus,
      builder: (context, snap) {
        final status = snap.data ?? connectivity.currentStatus;


        if (_lastState != null && _lastState != status.state) {
          if (_lastState != ConnectionStateType.online && status.state == ConnectionStateType.online) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final messenger = ScaffoldMessenger.maybeOf(context);
              messenger?.hideCurrentSnackBar();
              messenger?.showSnackBar(
                const SnackBar(
                  content: Text('Conexiune restabilită. Sincronizez datele…'),
                  duration: Duration(seconds: 2),
                ),
              );
            });
          }
          _lastState = status.state;
        } else {
          _lastState ??= status.state;
        }

        return ValueListenableBuilder<bool>(
          valueListenable: syncManager.syncing,
          builder: (context, syncing, _) {

            final show = syncing || status.state != ConnectionStateType.online;
            if (!show) return const SizedBox.shrink();

            final (color, title, icon) = switch (status.state) {
              ConnectionStateType.online => (Colors.blue, 'Sincronizare…', Icons.sync),
              ConnectionStateType.serverDown => (Colors.orange, 'Server indisponibil', Icons.cloud_off),
              ConnectionStateType.offline => (Colors.red, 'Offline', Icons.wifi_off),
            };

            final subtitle = status.details ?? (syncing ? 'Sincronizare în curs…' : null);

            return Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.92),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            if (subtitle != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (syncing) ...[
                        const SizedBox(width: 10),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
