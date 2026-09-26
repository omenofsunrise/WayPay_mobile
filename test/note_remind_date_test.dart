import 'package:flutter_test/flutter_test.dart';
import 'package:waypay_mobile/features/note/data/models/note_create_request.dart';
import 'package:waypay_mobile/features/note/data/models/note_model.dart';

void main() {
  group('NoteModel.remindDate', () {
    Map<String, dynamic> baseJson() => {
      'id': 1,
      'noteableType': 'credit',
      'noteableId': 42,
      'employeeId': 7,
      'content': 'Позвонить клиенту',
      'createdAt': '2026-09-26T10:00:00Z',
    };

    test('разбирает дату напоминания из ответа', () {
      final json = baseJson()..['remindDate'] = '2026-10-05T00:00:00Z';

      final note = NoteModel.fromJson(json);

      expect(note.remindDate, isNotNull);
      expect(note.remindDate!.toUtc(), DateTime.utc(2026, 10, 5));
    });

    test('оставляет null, когда напоминание не задано', () {
      final note = NoteModel.fromJson(baseJson());

      expect(note.remindDate, isNull);
    });

    test('оставляет null, когда сервер прислал remindDate: null', () {
      final json = baseJson()..['remindDate'] = null;

      final note = NoteModel.fromJson(json);

      expect(note.remindDate, isNull);
    });
  });

  group('NoteCreateRequest.remindDate', () {
    test('кладёт дату напоминания в тело запроса', () {
      final request = NoteCreateRequest(
        noteableId: 42,
        content: 'Позвонить клиенту',
        remindDate: DateTime.utc(2026, 10, 5),
      );

      expect(request.toJson()['remindDate'], '2026-10-05T00:00:00.000Z');
    });

    test('не кладёт ключ, когда напоминание не задано', () {
      final request = NoteCreateRequest(noteableId: 42, content: 'Текст');

      expect(request.toJson().containsKey('remindDate'), isFalse);
    });
  });
}
