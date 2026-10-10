import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/future_message.dart';
import '../repository/message_repository.dart';
import '../utils/date_format.dart';
import '../widgets/delete_dialog.dart';

class MessageDetailScreen extends StatefulWidget {
  final FutureMessage message;
  final MessageRepository repository;

  const MessageDetailScreen({
    super.key,
    required this.message,
    required this.repository,
  });

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  Timer? _countdownTimer;
  bool _revealed = false;
  bool _celebrating = false;
  bool _celebrationShown = false;

  @override
  void initState() {
    super.initState();
    // If opened already unlocked, don't celebrate — just fade the letter in.
    _celebrationShown = widget.message.isUnlocked;
    if (!widget.message.isUnlocked) {
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          if (!mounted) return;
          setState(() {});
          if (widget.message.isUnlocked) {
            timer.cancel();
            if (!_celebrationShown) {
              _celebrationShown = true;
              _celebrating = true;
              HapticFeedback.mediumImpact();
            }
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _maybeReveal(bool unlockedNow) {
    if (unlockedNow && !_revealed && !_celebrating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _revealed = true);
      });
    }
  }

  void _dismissCelebration() {
    HapticFeedback.lightImpact();
    setState(() {
      _celebrating = false;
      _revealed = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _revealed = true);
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDeleteConfirmDialog(context);
    if (!confirmed || !mounted) return;
    HapticFeedback.lightImpact();
    await widget.repository.delete(widget.message.id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Message deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlockedNow = widget.message.isUnlocked;
    _maybeReveal(unlockedNow);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete message',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Stack(
        children: [
          unlockedNow ? _buildUnlocked(context) : _buildLocked(context),
          if (_celebrating) _buildUnsealedOverlay(context),
        ],
      ),
    );
  }

  /// Calm, on-theme "unsealing" moment shown once when a locked message
  /// flips to unlocked while the user is watching. Deliberately no
  /// confetti/particles per PRD §11 + UI/UX §14 — just paper, ink,
  /// burgundy seal breaking open.
  Widget _buildUnsealedOverlay(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Positioned.fill(
      child: Container(
        color: AppColors.softCream.withValues(alpha: 0.98),
        padding: const EdgeInsets.all(24),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.96 + (0.04 * value),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Wax-seal metaphor: hairline ring, burgundy core, unlocked mark.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.warmBeige,
                        border: Border.all(
                          color: AppColors.deepBurgundy,
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_open,
                        size: 36,
                        color: AppColors.deepBurgundy,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                "It's time.",
                style: textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Written ${formatDate(widget.message.createdAt)} — kept sealed until now.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                width: 48,
                height: 1,
                color: AppColors.hairlineBorder,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _dismissCelebration,
                  child: const Text('Read your letter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocked(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final remaining = widget.message.unlockAt.difference(DateTime.now());
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: AppColors.deepBurgundy,
            ),
            const SizedBox(height: 16),
            Text(
              'Not yet.',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'This message opens on ${formatDateTime(widget.message.unlockAt)}.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CountdownUnit(
                  value: days.toString(),
                  unit: days == 1 ? 'DAY' : 'DAYS',
                ),
                _CountdownUnit(
                  value: hours.toString().padLeft(2, '0'),
                  unit: 'HRS',
                ),
                _CountdownUnit(
                  value: minutes.toString().padLeft(2, '0'),
                  unit: 'MIN',
                ),
                _CountdownUnit(
                  value: seconds.toString().padLeft(2, '0'),
                  unit: 'SEC',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlocked(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AnimatedOpacity(
        opacity: _revealed ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "It's time.",
              style: textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'WRITTEN ${formatDate(widget.message.createdAt).toUpperCase()}',
              style: textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'OPENED ${formatDate(widget.message.unlockAt).toUpperCase()}',
              style: textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            Text(
              daysSinceWritten(widget.message.createdAt),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              widget.message.content,
              style: textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  final String value;
  final String unit;

  const _CountdownUnit({required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: textTheme.displayLarge),
          const SizedBox(height: 4),
          Text(unit, style: textTheme.labelSmall),
        ],
      ),
    );
  }
}
