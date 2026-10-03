import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

ActionPane deleteActionPane({
  required VoidCallback onDelete,
  EdgeInsets margin = const EdgeInsets.fromLTRB(0, 8, 16, 8),
}) {
  return ActionPane(
    motion: const DrawerMotion(),
    extentRatio: 0.22,
    children: [
      CustomSlidableAction(
        onPressed: (_) => onDelete(),
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        child: Container(
          margin: margin,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
      ),
    ],
  );
}

void showUndoSnackBar(
  BuildContext context,
  String message,
  VoidCallback onUndo,
) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      action: SnackBarAction(label: 'Undo', onPressed: onUndo),
    ),
  );
}
