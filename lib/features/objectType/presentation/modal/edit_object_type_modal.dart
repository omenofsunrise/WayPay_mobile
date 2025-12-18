import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_bloc.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_event.dart';
import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_state.dart';

class EditObjectTypeModal extends StatefulWidget {
  final ObjectTypeModel objectType;

  const EditObjectTypeModal({super.key, required this.objectType});

  @override
  State<EditObjectTypeModal> createState() => _EditObjectTypeModalState();
}

class _EditObjectTypeModalState extends State<EditObjectTypeModal> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.objectType.name;
  }

  void _updateObjectType() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    if (name.isEmpty || name == widget.objectType.name) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    final request = UpdateObjectTypeRequest(name: name);

    final objectTypeBloc = context.read<ObjectTypeBloc>();
    objectTypeBloc.add(
      UpdateObjectTypeEvent(
        objectTypeId: widget.objectType.id,
        request: request,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ObjectTypeBloc, ObjectTypeState>(
      listener: (context, state) {
        if (state is ObjectTypeLoaded && _isUpdating) {
          // Успешно обновили - закрываем модалку
          Navigator.of(context).pop();
        }

        if (state is ObjectTypeError && _isUpdating) {
          // Ошибка - показываем сообщение и сбрасываем состояние
          setState(() {
            _isUpdating = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Редактировать каталог',
                      textAlign: TextAlign.left,
                      style: AppStyle.manrope(
                        size: 20,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: CustomInput(
                  controller: _nameController,
                  label: 'Название каталога',
                ),
              ),
              const SizedBox(height: 24),
              DefaultButton(
                text: _isUpdating ? 'Сохранение...' : 'Сохранить',
                isPrimary: true,
                onPressed: _isUpdating ? () {} : _updateObjectType,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
