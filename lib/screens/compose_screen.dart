import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../main.dart';
import '../models/future_message.dart';
import '../repository/message_repository.dart';

class ComposeScreen extends StatefulWidget {
  final MessageRepository repository;

  const ComposeScreen({super.key, required this.repository});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final TextEditingController _messageController = TextEditingController();
  DateTime _unlockAt = DateTime.now().add(const Duration(days: 7));
  int? _selectedChipIndex;
  String? _messageError;
  String? _dateError;
  bool _saved = false;

  static const List<String> _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _formatUnlockAt(DateTime value) {
    final local = value.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${local.day} ${_months[local.month - 1]} ${local.year}, $hour12:$minute $period';
  }

  Future<void> _pickUnlockAt() async {
    final now = DateTime.now();
    final initial = _unlockAt.isAfter(now)
        ? _unlockAt
        : now.add(const Duration(minutes: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_unlockAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _unlockAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _selectedChipIndex = null;
      _dateError = null;
    });
  }

  void _applyQuickPick(int index, Duration offset) {
    setState(() {
      _unlockAt = DateTime.now().add(offset);
      _selectedChipIndex = index;
      _dateError = null;
    });
  }

  Future<void> _sealMessage() async {
    final content = _messageController.text.trim();
    final now = DateTime.now();

    setState(() {
      _messageError = content.isEmpty ? 'Write a message first.' : null;
      _dateError = _unlockAt.isBefore(now.add(const Duration(minutes: 1)))
          ? 'Choose a date and time at least 1 minute in the future.'
          : null;
    });

    if (_messageError != null || _dateError != null) return;

    HapticFeedback.lightImpact();
    final message = FutureMessage(
      id: const Uuid().v4(),
      content: content,
      createdAt: now,
      unlockAt: _unlockAt,
    );
    await widget.repository.add(message);
    if (!mounted) return;
    _saved = true;
    Navigator.of(context).pop();
  }

  Future<void> _confirmDiscard() async {
    final textTheme = Theme.of(context).textTheme;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Discard this message?',
          style: textTheme.headlineSmall,
        ),
        content: Text(
          'Your unsent words will be lost.',
          style: textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep writing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.softCoral,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if ((discard ?? false) && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final errorColor = Theme.of(context).colorScheme.error;
    const quickPicks = <Map<String, Duration>>[
      {'1 week': Duration(days: 7)},
      {'1 month': Duration(days: 30)},
      {'6 months': Duration(days: 182)},
      {'1 year': Duration(days: 365)},
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_saved || _messageController.text.trim().isEmpty) {
          Navigator.of(context).pop();
        } else {
          _confirmDiscard();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Write to Future Me'),
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your message',
              style: textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              minLines: 5,
              maxLines: 12,
              keyboardType: TextInputType.multiline,
              style: textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Dear future me...',
                errorText: _messageError,
              ),
              onChanged: (_) {
                if (_messageError != null) {
                  setState(() => _messageError = null);
                }
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Unlocks',
              style: textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickUnlockAt,
              icon: const Icon(Icons.schedule),
              label: Text(_formatUnlockAt(_unlockAt)),
            ),
            if (_dateError != null) ...[
              const SizedBox(height: 4),
              Text(
                _dateError!,
                style: textTheme.bodySmall?.copyWith(color: errorColor),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < quickPicks.length; i++)
                  ChoiceChip(
                    label: Text(quickPicks[i].keys.single),
                    selected: _selectedChipIndex == i,
                    onSelected: (_) => _applyQuickPick(
                      i,
                      quickPicks[i].values.single,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _sealMessage,
              child: const Text('Seal message'),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
