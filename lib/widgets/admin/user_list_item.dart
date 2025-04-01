// lib/widgets/admin/user_list_item.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';

class UserListItem extends StatelessWidget {
  final User user;
  final VoidCallback onApprove;
  final VoidCallback onSuspend;
  final VoidCallback onRemove;

  const UserListItem({super.key, 
    required this.user,
    required this.onApprove,
    required this.onSuspend,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        title: Text(user.name),
        subtitle: Text(user.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: Icon(Icons.check), onPressed: onApprove),
            IconButton(icon: Icon(Icons.pause), onPressed: onSuspend),
            IconButton(icon: Icon(Icons.delete), onPressed: onRemove),
          ],
        ),
      ),
    );
  }
}