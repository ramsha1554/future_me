import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/future_message.dart';
import '../services/notification_service.dart';

class MessageRepository extends ChangeNotifier {
  static const String storageKey = 'future_messages';

  final List<FutureMessage> _messages = [];
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final storedMessages = _prefs!.getStringList(storageKey) ?? <String>[];
    _messages.clear();
    for (final storedMessage in storedMessages) {
      try {
        _messages.add(
          FutureMessage.fromJson(
            jsonDecode(storedMessage) as Map<String, dynamic>,
          ),
        );
      } catch (e) {
        debugPrint('MessageRepository: skipping corrupted entry ($e)');
      }
    }
    notifyListeners();
  }

  List<FutureMessage> get messages {
    final sortedMessages = List<FutureMessage>.of(_messages)
      ..sort((a, b) => a.unlockAt.compareTo(b.unlockAt));
    return List<FutureMessage>.unmodifiable(sortedMessages);
  }

  Future<void> add(FutureMessage message) async {
    _messages.add(message);
    await _persist();
    await NotificationService.instance.scheduleUnlock(message);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _messages.removeWhere((message) => message.id == id);
    await _persist();
    await NotificationService.instance.cancel(id);
    notifyListeners();
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    final storedMessages =
        _messages.map((message) => jsonEncode(message.toJson())).toList();
    await _prefs!.setStringList(storageKey, storedMessages);
  }
}
