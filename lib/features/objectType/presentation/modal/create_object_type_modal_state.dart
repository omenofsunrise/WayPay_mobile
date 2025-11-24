import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/inputs/modal_text_field.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_bloc.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_event.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_state.dart';
import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';

class CreateObjectTypeModal extends StatefulWidget {
  final String entityType;
  final ValueChanged<ObjectTypeModel> onObjectTypeCreated; // Исправлен тип

  const CreateObjectTypeModal({
    super.key,
    required this.entityType,
    required this.onObjectTypeCreated,
  });

  @override
  State<CreateObjectTypeModal> createState() => _CreateObjectTypeModalState();
}

class _CreateObjectTypeModalState extends State<CreateObjectTypeModal> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isCreating = false;
  ObjectTypeModel? _createdObjectType; // Сохраняем созданный объект

  void _createObjectType() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isCreating = true;
    });

    final request = CreateObjectTypeRequest(
      name: name,
      entityType: widget.entityType,
    );

    final objectTypeBloc = context.read<ObjectTypeBloc>();
    objectTypeBloc.add(CreateObjectTypeEvent(request: request));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Новый каталог',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: ModalTextField(
                controller: _nameController,
                label: 'Название каталога',
                hintText: 'Введите название',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: DefaultButton(
                    text: 'Отменить',
                    onPressed: () => Navigator.of(context).pop(),
                    isGreen: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BlocConsumer<ObjectTypeBloc, ObjectTypeState>(
                    listener: (context, state) {
                      if (state is ObjectTypeLoaded && _isCreating) {
                        final createdObjectType = state.objectTypes.firstWhere(
                          (ot) =>
                              ot.name == _nameController.text.trim() &&
                              ot.entityType == widget.entityType,
                          orElse: () => ObjectTypeModel(
                            id: -1,
                            name: _nameController.text.trim(),
                            entityType: widget.entityType,
                          ),
                        );
                        widget.onObjectTypeCreated(createdObjectType);
                        Navigator.of(context).pop();
                      }
                      if (state is ObjectTypeError && _isCreating) {
                        setState(() {
                          _isCreating = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.message)),
                        );
                      }
                    },
                    builder: (context, state) {
                      return DefaultButton(
                        text: _isCreating ? 'Создание...' : 'Создать',
                        isGreen: true,
                        onPressed: _isCreating ? null : _createObjectType,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
