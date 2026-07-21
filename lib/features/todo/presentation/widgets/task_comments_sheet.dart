import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay_mobile/features/todo/data/data_soucres/task_note_remote_data_source.dart';
import 'package:waypay_mobile/features/todo/data/models/task_note_model.dart';
import 'package:waypay_mobile/features/todo/data/models/todo_model.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class TaskCommentsSheet extends StatefulWidget {
  const TaskCommentsSheet({super.key, required this.task, required this.onCountChanged});

  final TodoTask task;
  final ValueChanged<int> onCountChanged;

  @override
  State<TaskCommentsSheet> createState() => _TaskCommentsSheetState();
}

class _TaskCommentsSheetState extends State<TaskCommentsSheet> {
  final _noteSource = getIt<TaskNoteRemoteDataSource>();
  final _authSource = getIt<AuthRemoteDataSource>();
  final _commentController = TextEditingController();
  List<TaskNote> _notes = [];
  bool _isLoading = true;
  String? _error;
  bool _isExpanded = true;
  bool _isSending = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _initComments() async {
    await _ensureCurrentUserId();
    await _loadNotes();
  }

  Future<int?> _ensureCurrentUserId() async {
    if (_currentUserId != null) return _currentUserId;
    try {
      final info = await _authSource.getAuthInfo();
      final employee = info['employee'] as Map<String, dynamic>?;
      _currentUserId = (employee?['id'] as num?)?.toInt();
    } catch (_) {
      _currentUserId = null;
    }
    return _currentUserId;
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final notes = await _noteSource.getTaskNotes(widget.task.id);
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() {
        _notes = notes;
      });
      widget.onCountChanged(notes.length);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      final userId = await _ensureCurrentUserId();
      if (userId == null) {
        throw Exception('Не удалось определить пользователя');
      }
      await _noteSource.createTaskNote(
        text: text,
        taskId: widget.task.id,
        createdBy: userId,
      );
      _commentController.clear();
      await _loadNotes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _editNote(TaskNote note) async {
    final controller = TextEditingController(text: note.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Комментарий'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await _noteSource.updateTaskNote(id: note.id, text: result);
    await _loadNotes();
  }

  Future<void> _deleteNote(TaskNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить комментарий?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _noteSource.deleteTaskNote(note.id);
    await _loadNotes();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '—';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final statusLabel = task.taskStatus.label;
    final notesCount = _notes.length;
    final canSend = _commentController.text.trim().isNotEmpty;
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: maxHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Комментарии',
                      style: AppStyle.manrope(
                        size: 20,
                        weight: FontWeight.w600,
                        color: const Color(AppColors.black),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.black54),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: AppStyle.manrope(
                        size: 16,
                        weight: FontWeight.w500,
                        color: const Color(AppColors.black),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: AppStyle.manrope(
                        size: 12,
                        weight: FontWeight.w500,
                        color: const Color(AppColors.uiBorder),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Комментарии ($notesCount)',
                    style: AppStyle.manrope(
                      size: 14,
                      weight: FontWeight.w500,
                      color: const Color(AppColors.black),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    icon: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              if (_isExpanded)
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _notes.length,
                              itemBuilder: (context, index) {
                                final note = _notes[index];
                                return TaskNoteCard(
                                  note: note,
                                  isMine: note.createdBy == _currentUserId,
                                  onEdit: () => _editNote(note),
                                  onDelete: () => _deleteNote(note),
                                  formatDate: _formatDate,
                                  initials: _initials,
                                );
                              },
                            ),
                )
              else if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                minLines: 4,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Напишите комментарий...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD9DDE5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD9DDE5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: DefaultButton(
                  text: 'Отправить',
                  color: canSend
                      ? const Color(AppColors.primary)
                      : const Color(0xFFA8DADB),
                  textColor: Colors.white,
                  onPressed: canSend && !_isSending ? _sendComment : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskNoteCard extends StatelessWidget {
  TaskNoteCard({
    super.key,
    required this.note,
    required this.isMine,
    required this.onEdit,
    required this.onDelete,
    required this.formatDate,
    required this.initials,
  });

  final TaskNote note;
  final bool isMine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String Function(DateTime) formatDate;
  final String Function(String) initials;
  final GlobalKey _menuKey = GlobalKey();

  Future<void> _showNoteMenu(BuildContext context) async {
    final renderBox = _menuKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    const double menuWidth = 167;
    final double screenWidth = overlayBox.size.width;
    double left = offset.dx + size.width - menuWidth;
    left = left.clamp(16, screenWidth - menuWidth - 16);
    final double top = offset.dy + size.height + 12;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      barrierLabel: 'note_menu',
      pageBuilder: (dialogContext, _, __) {
        return GestureDetector(
          onTap: () => Navigator.of(dialogContext).pop(),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned(
                  left: left,
                  top: top,
                  child: NoteContextMenu(
                    onEdit: () {
                      Navigator.of(dialogContext).pop();
                      onEdit();
                    },
                    onDelete: () {
                      Navigator.of(dialogContext).pop();
                      onDelete();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = note.creator?.fullName ?? 'Пользователь';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFFF5A5A),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials(name),
              style: AppStyle.manrope(
                size: 12,
                weight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyle.manrope(
                          size: 14,
                          weight: FontWeight.w500,
                          color: const Color(AppColors.black),
                        ),
                      ),
                    ),
                    if (isMine)
                      InkWell(
                        key: _menuKey,
                        onTap: () => _showNoteMenu(context),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_horiz,
                            size: 18,
                            color: Color(AppColors.uiBorder),
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  formatDate(note.createdAt),
                  style: AppStyle.manrope(
                    size: 12,
                    weight: FontWeight.w400,
                    color: const Color(AppColors.uiBorder),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  note.text,
                  style: AppStyle.manrope(
                    size: 14,
                    weight: FontWeight.w400,
                    color: const Color(AppColors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NoteContextMenu extends StatelessWidget {
  const NoteContextMenu({super.key, required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 167,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000809),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(color: Color(0x0D000809), blurRadius: 6),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NoteMenuActionRow(
            icon: Icons.delete_outline,
            label: 'Удалить',
            onTap: onDelete,
          ),
          const SizedBox(height: 24),
          NoteMenuActionRow(
            icon: Icons.edit_outlined,
            label: 'Редактировать',
            onTap: onEdit,
          ),
        ],
      ),
    );
  }
}

class NoteMenuActionRow extends StatelessWidget {
  const NoteMenuActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.manrope(size: 14, weight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
