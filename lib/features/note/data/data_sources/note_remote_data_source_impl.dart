import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/features/note/data/data_sources/note_remote_data_source.dart';
import 'package:waypay_mobile/features/note/data/models/note_create_request.dart';
import 'package:waypay_mobile/features/note/data/models/note_model.dart';

class NoteRemoteDataSourceImpl implements NoteRemoteDataSource {
  final Dio dio;

  NoteRemoteDataSourceImpl(this.dio);

  @override
  Future<List<NoteModel>> fetchNotesByCreditId(int creditId) async {
    return fetchNotesByType('credit', creditId);
  }

  @override
  Future<List<NoteModel>> fetchNotesByType(
    String type,
    int noteableId, {
    bool includeFiles = true,
  }) async {
    final response = await dio.get(
      'Note/by-type/$type/$noteableId',
      queryParameters: {'includeFiles': includeFiles},
    );

    if (response.statusCode == 200) {
      final data = response.data as List;
      return data.map((e) => NoteModel.fromJson(e)).toList();
    } else {
      throw const ApiError('Не удалось загрузить заметки.');
    }
  }

  @override
  Future<void> deleteNote(int id) async {
    final response = await dio.delete('Note/$id');
    if (response.statusCode != 200) {
      throw const ApiError('Не удалось удалить заметку.');
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

    final response = await dio.post('Note', data: formData);

    if (response.statusCode != 200) {
      throw const ApiError('Не удалось создать заметку.');
    }
  }
}
