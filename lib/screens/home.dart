import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/future_message.dart';
import '../repository/message_repository.dart';
import '../services/notification_service.dart';
import '../utils/page_routes.dart';
import '../widgets/delete_dialog.dart';
import '../widgets/message_card.dart';
import 'compose_screen.dart';
import 'message_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final MessageRepository repository;

  const HomeScreen({super.key, required this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      for (final message in widget.repository.messages) {
        if (!message.isUnlocked) {
          unawaited(NotificationService.instance.scheduleUnlock(message));
        }
      }
    }
  }

  void _openCompose() {
    Navigator.of(context).push(
      fadePageRoute(ComposeScreen(repository: widget.repository)),
    );
  }

  void _openDetail(FutureMessage message) {
    Navigator.of(context).push(
      fadePageRoute(
        MessageDetailScreen(
          message: message,
          repository: widget.repository,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(FutureMessage message) async {
    final confirmed = await showDeleteConfirmDialog(context);
    if (!confirmed || !mounted) return;
    HapticFeedback.lightImpact();
    await widget.repository.delete(message.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Future Me'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCompose,
        tooltip: 'Write a message',
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: widget.repository,
        builder: (context, _) {
          final messages = widget.repository.messages;

          if (messages.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nothing here yet',
                      style: textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Write a note your future self will open.',
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _openCompose,
                      child: const Text('Write a message'),
                    ),
                  ],
                ),
              ),
            );
          }

          final unlocked =
              messages.where((message) => message.isUnlocked).toList();
          final locked =
              messages.where((message) => !message.isUnlocked).toList();

          final children = <Widget>[];
          var cardIndex = 0;
          void addCard(FutureMessage message) {
            children.add(
              _StaggeredCard(
                index: cardIndex++,
                message: message,
                onTap: () => _openDetail(message),
                onLongPress: () => _confirmDelete(message),
              ),
            );
            children.add(const SizedBox(height: 12));
          }

          if (unlocked.isNotEmpty) {
            children.add(Text('UNLOCKED', style: textTheme.labelSmall));
            children.add(const SizedBox(height: 12));
            for (final message in unlocked) {
              addCard(message);
            }
          }
          if (locked.isNotEmpty) {
            if (unlocked.isNotEmpty) {
              children.add(const SizedBox(height: 12));
            }
            children.add(Text('LOCKED', style: textTheme.labelSmall));
            children.add(const SizedBox(height: 12));
            for (final message in locked) {
              addCard(message);
            }
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: children,
          );
        },
      ),
    );
  }
}

class _StaggeredCard extends StatefulWidget {
  final int index;
  final FutureMessage message;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _StaggeredCard({
    required this.index,
    required this.message,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<_StaggeredCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _offset =
      Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOut),
  );
  Timer? _startDelay;

  @override
  void initState() {
    super.initState();
    _startDelay = Timer(
      Duration(milliseconds: min(widget.index * 40, 100)),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _startDelay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: MessageCard(
          message: widget.message,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
        ),
      ),
    );
  }
}
