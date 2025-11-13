import 'package:dio/dio.dart';
import 'package:waypay/features/note/data/data_sources/note_remote_data_source.dart';
import 'package:waypay/features/note/data/models/note_create_request.dart';
import 'package:waypay/features/note/data/models/note_model.dart';

class NoteRemoteDataSourceImpl implements NoteRemoteDataSource {
  final Dio dio;

  NoteRemoteDataSourceImpl(this.dio);

  @override
  Future<List<NoteModel>> fetchNotesByCreditId(int creditId) async {
    final response = await dio.get(
      '/api/Note/by-type/credit/$creditId',
      queryParameters: {'includeFiles': true},
    );

    if (response.statusCode == 200) {
      final data = response.data as List;
      return data.map((e) => NoteModel.fromJson(e)).toList();
    } else {
      throw Exception('Ошибка при загрузке заметок');
    }
  }

  @override
  Future<void> deleteNote(int id) async {
    final response = await dio.delete('/api/Note/$id');
    if (response.statusCode != 200) {
      throw Exception('Не удалось удалить заметку');
    }
  }

  @override
  Future<void> createNote(NoteCreateRequest note) async {
    final formData = FormData.fromMap({
      'NoteableType': note.noteableType,
      'NoteableId': note.noteableId,
      'Content': note.content,
      if (note.remindDate != null)
        'RemindDate': note.remindDate!.toIso8601String(),
      if (note.file != null) 'File': await MultipartFile.fromFile(note.file!),
    });

    final response = await dio.post('/api/Note', data: formData);

    if (response.statusCode != 200) {
      throw Exception('Не удалось создать заметку');
    }
  }
}
