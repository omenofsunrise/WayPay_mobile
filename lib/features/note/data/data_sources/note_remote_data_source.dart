import 'package:waypay_mobile/features/note/data/models/note_create_request.dart';
import 'package:waypay_mobile/features/note/data/models/note_model.dart';

abstract class NoteRemoteDataSource {
  Future<List<NoteModel>> fetchNotesByCreditId(int creditId);
  Future<List<NoteModel>> fetchNotesByType(
    String type,
    int noteableId, {
    bool includeFiles,
  });
  Future<void> deleteNote(int id);
  Future<void> createNote(NoteCreateRequest note);
}
