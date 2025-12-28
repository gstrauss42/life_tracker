import 'package:flutter/material.dart';

/// Stateful text field for notes with proper controller management.
class NotesField extends StatefulWidget {
  const NotesField({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<NotesField> {
  late TextEditingController _controller;
  String _lastSavedValue = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _lastSavedValue = widget.initialValue;
  }

  @override
  void didUpdateWidget(NotesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _lastSavedValue && widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
      _lastSavedValue = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'How are you feeling today? Any notes...',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              _lastSavedValue = value;
              widget.onChanged(value);
            },
          ),
        ),
      ),
    );
  }
}

