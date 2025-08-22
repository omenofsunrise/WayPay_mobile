import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/features/note/data/data_sources/note_remote_data_source.dart';
import 'package:waypay/features/note/data/models/note_model.dart';

class Note extends StatelessWidget {
  final NoteModel note;
  final void Function() onDelete;
  const Note({super.key, required this.note, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Color(AppColors.borderColor)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(note.content, style: AppStyle.manrope(size: 15, weight: FontWeight.w400)),
                ),
                InkWell(child: Icon(CupertinoIcons.trash), onTap: () => _deleteNote(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNote(BuildContext context) async {
    try {
      final noteDataSource = getIt<NoteRemoteDataSource>();
      await noteDataSource.deleteNote(note.id);
      onDelete();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
    }
  }
}
