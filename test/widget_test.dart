import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:future_me/main.dart';
import 'package:future_me/models/future_message.dart';
import 'package:future_me/repository/message_repository.dart';

FutureMessage _buildMessage({
  required String id,
  required String content,
  required DateTime unlockAt,
}) {
  return FutureMessage(
    id: id,
    content: content,
    createdAt: DateTime(2026, 1, 1, 9),
    unlockAt: unlockAt,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      return null;
    });
  });

  group('FutureMessage', () {
    test('toJson and fromJson round trip', () {
      final original = _buildMessage(
        id: 'test-123',
        content: 'Hello future me!',
        unlockAt: DateTime(2027, 5, 4, 18, 30),
      );

      final restored = FutureMessage.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.content, original.content);
      expect(restored.createdAt, original.createdAt);
      expect(restored.unlockAt, original.unlockAt);
    });

    test('isUnlocked is true after unlockAt', () {
      final message = _buildMessage(
        id: 'past',
        content: 'Already open',
        unlockAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(message.isUnlocked, isTrue);
    });

    test('isUnlocked is false before unlockAt', () {
      final message = _buildMessage(
        id: 'future',
        content: 'Still sealed',
        unlockAt: DateTime.now().add(const Duration(days: 1)),
      );

      expect(message.isUnlocked, isFalse);
    });
  });

  group('MessageRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('add stores a message and messages returns it', () async {
      final repository = MessageRepository();
      await repository.init();

      await repository.add(
        _buildMessage(
          id: '1',
          content: 'Test message',
          unlockAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );

      expect(repository.messages.length, 1);
      expect(repository.messages.first.id, '1');
    });

    test('messages are sorted by unlockAt ascending', () async {
      final repository = MessageRepository();
      await repository.init();
      final now = DateTime.now();

      await repository.add(
        _buildMessage(id: 'late', content: 'Late', unlockAt: now.add(const Duration(days: 9))),
      );
      await repository.add(
        _buildMessage(id: 'early', content: 'Early', unlockAt: now.add(const Duration(days: 2))),
      );

      expect(
        repository.messages.map((message) => message.id).toList(),
        ['early', 'late'],
      );
    });

    test('delete removes a message by id', () async {
      final repository = MessageRepository();
      await repository.init();
      final now = DateTime.now();

      await repository.add(
        _buildMessage(id: '1', content: 'One', unlockAt: now.add(const Duration(days: 1))),
      );
      await repository.add(
        _buildMessage(id: '2', content: 'Two', unlockAt: now.add(const Duration(days: 2))),
      );
      await repository.delete('1');

      expect(repository.messages.length, 1);
      expect(repository.messages.first.id, '2');
    });

    test('messages persist across repository instances', () async {
      final repository = MessageRepository();
      await repository.init();
      await repository.add(
        _buildMessage(
          id: 'saved',
          content: 'Persist me',
          unlockAt: DateTime.now().add(const Duration(days: 3)),
        ),
      );

      final reloaded = MessageRepository();
      await reloaded.init();

      expect(reloaded.messages.length, 1);
      expect(reloaded.messages.first.content, 'Persist me');
    });

    test('corrupted entries are skipped instead of crashing', () async {
      final valid = _buildMessage(
        id: 'valid',
        content: 'Good entry',
        unlockAt: DateTime.now().add(const Duration(days: 3)),
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        'future_messages': <String>[
          'this is not json',
          '{"id": "broken"',
          jsonEncode(valid.toJson()),
        ],
      });

      final repository = MessageRepository();
      await repository.init();

      expect(repository.messages.length, 1);
      expect(repository.messages.first.id, 'valid');
    });
  });

  group('HomeScreen', () {
    testWidgets('shows the empty state when there are no messages',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = MessageRepository();
      await repository.init();

      await tester.pumpWidget(FutureMeApp(repository: repository));
      await tester.pump();

      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.text('Write a message'), findsOneWidget);
    });

    testWidgets('shows a locked card without its content', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = MessageRepository();
      await repository.init();
      const secret = 'TOP SECRET FUTURE MESSAGE 12345';
      await repository.add(
        _buildMessage(
          id: 'locked-1',
          content: secret,
          unlockAt: DateTime.now().add(const Duration(days: 5)),
        ),
      );

      await tester.pumpWidget(FutureMeApp(repository: repository));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
      expect(find.text(secret), findsNothing);
    });

    testWidgets('long-press deletes a message after confirmation',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = MessageRepository();
      await repository.init();
      await repository.add(
        _buildMessage(
          id: 'doomed-1',
          content: 'Delete me',
          unlockAt: DateTime.now().add(const Duration(days: 5)),
        ),
      );

      await tester.pumpWidget(FutureMeApp(repository: repository));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.longPress(find.text('Locked'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Delete this message?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Message deleted'), findsOneWidget);
      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(repository.messages, isEmpty);
    });
  });
}
