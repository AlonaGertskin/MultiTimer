import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'app_colors.dart';

ActionPane deleteActionPane({
  required VoidCallback onDelete,
  EdgeInsets margin = const EdgeInsets.fromLTRB(0, 8, 16, 8),
}) {
  return _actionPane(
    onPressed: onDelete,
    margin: margin,
    colors: (scheme) => (deleteButtonColor(scheme), scheme.onErrorContainer),
    icon: Icons.delete_outline,
  );
}

ActionPane restartActionPane({required VoidCallback onRestart}) {
  return _actionPane(
    onPressed: onRestart,
    margin: const EdgeInsets.fromLTRB(16, 8, 0, 8),
    colors: (scheme) => (scheme.primary, scheme.onPrimary),
    icon: Icons.restart_alt,
  );
}

ActionPane _actionPane({
  required VoidCallback onPressed,
  required EdgeInsets margin,
  required (Color, Color) Function(ColorScheme scheme) colors,
  required IconData icon,
}) {
  return ActionPane(
    motion: const DrawerMotion(),
    extentRatio: 0.22,
    children: [
      CustomSlidableAction(
        onPressed: (_) => onPressed(),
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        child: Builder(
          builder: (context) {
            final (background, foreground) = colors(
              Theme.of(context).colorScheme,
            );
            return Container(
              margin: margin,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: foreground),
            );
          },
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
      persist: false,
    ),
  );
}
