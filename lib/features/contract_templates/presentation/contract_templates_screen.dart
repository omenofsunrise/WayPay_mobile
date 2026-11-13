import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/contract_templates/data/contract_template.dart';
import 'package:waypay_mobile/features/contract_templates/data/contract_template_service.dart';

class ContractTemplatesScreen extends StatefulWidget {
  const ContractTemplatesScreen({super.key});

  @override
  State<ContractTemplatesScreen> createState() =>
      _ContractTemplatesScreenState();
}

class _ContractTemplatesScreenState extends State<ContractTemplatesScreen> {
  final _service = getIt<ContractTemplateService>();
  List<ContractTemplate> _templates = const [];
  List<String> _variables = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await Future.wait([
        _service.getAll(),
        _service.getVariables(),
      ]);
      if (!mounted) return;
      setState(() {
        _templates = result[0] as List<ContractTemplate>;
        _variables = result[1] as List<String>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppMessage(
        context,
        'Не удалось загрузить шаблоны',
        type: AppMessageType.error,
      );
    }
  }

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['docx'],
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final controller = TextEditingController(
      text: result!.files.single.name.replaceFirst(
        RegExp(r'\.docx$', caseSensitive: false),
        '',
      ),
    );
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Название шаблона'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Загрузить'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;

    try {
      final template = await _service.upload(name: name, filePath: path);
      if (!mounted) return;
      setState(
        () =>
            _templates = [..._templates, template]
              ..sort((a, b) => a.name.compareTo(b.name)),
      );
      showAppMessage(context, 'Шаблон загружен');
    } catch (error) {
      if (mounted) {
        showAppMessage(
          context,
          'Не удалось загрузить шаблон',
          type: AppMessageType.error,
        );
      }
    }
  }

  Future<void> _delete(ContractTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить шаблон?'),
        content: Text(template.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.delete(template.id);
    if (mounted) {
      setState(
        () => _templates = _templates
            .where((item) => item.id != template.id)
            .toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Header(
                title: 'Шаблоны договоров',
                showBackButton: true,
                showNotifications: false,
                showAvatar: false,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      children: [
                        const Text(
                          'Добавьте в DOCX переменные в фигурных скобках. Нажмите на переменную, чтобы скопировать её.',
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: _variables
                              .map(
                                (item) => ActionChip(
                                  label: Text('{$item}'),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: '{$item}'),
                                    );
                                    showAppMessage(
                                      context,
                                      'Переменная скопирована',
                                    );
                                  },
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        if (_templates.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('Шаблонов пока нет'),
                            ),
                          ),
                        ..._templates.map(
                          (template) => Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.description_outlined,
                                color: Color(AppColors.primary),
                              ),
                              title: Text(template.name),
                              subtitle: Text(template.fileName),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _delete(template),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _upload,
        backgroundColor: const Color(AppColors.primary),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file_outlined),
        label: const Text('Загрузить DOCX'),
      ),
    );
  }
}
