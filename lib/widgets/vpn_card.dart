import 'package:flutter/material.dart';
import '../models/vpn_data_model.dart';

class VpnCard extends StatelessWidget {
  final VpnData vpnData;
  final VoidCallback onDelete;
  final bool isConnecting;
  final Future<void> Function() onConnect;
  final Future<void> Function() onDisconnect;

  const VpnCard({
    super.key,
    required this.vpnData,
    required this.onDelete,
    required this.isConnecting,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        title: Text('Username: ${vpnData.username}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Server: ${vpnData.serverName}'),
            Text('Profile: ${vpnData.profileName}'),
          ],
        ),
        // Combine the Switch and PopupMenuButton inside a Row
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: isConnecting,
              onChanged: (value) async {
                if (value) {
                  await onConnect();
                } else {
                  await onDisconnect();
                }
              },
            ),
            PopupMenuButton(
              onSelected: (value) {
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
