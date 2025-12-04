import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_bloc.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_event.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_state.dart';
import 'package:waypay_mobile/features/objectType/data/models/get_object_types_query.dart';
import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';
import 'package:waypay_mobile/features/objectType/presentation/modal/create_object_type_modal_state.dart';
import 'package:waypay_mobile/features/objectType/presentation/modal/edit_object_type_modal.dart';

class ObjectTypeSelectionModal extends StatefulWidget {
  final ObjectTypeModel? selectedObjectType;
  final ValueChanged<ObjectTypeModel?> onObjectTypeSelected;
  final String entityType;
  final String? title;

  const ObjectTypeSelectionModal({
    super.key,
    this.selectedObjectType,
    required this.onObjectTypeSelected,
    required this.entityType,
    this.title,
  });

  @override
  State<ObjectTypeSelectionModal> createState() =>
      _ObjectTypeSelectionModalState();
}

class _ObjectTypeSelectionModalState extends State<ObjectTypeSelectionModal> {
  ObjectTypeModel? _selectedObjectType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedObjectType = widget.selectedObjectType;
    _loadObjectTypes();
  }

  void _loadObjectTypes() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final objectTypeBloc = context.read<ObjectTypeBloc>();
    objectTypeBloc.add(
      LoadObjectTypesEvent(
        refresh: true,
        query: GetObjectTypesQuery(
          page: 1,
          pageSize: 100,
          entityType: widget.entityType,
        ),
      ),
    );
  }

  void _handleSelectObjectType(ObjectTypeModel? objectType) {
    widget.onObjectTypeSelected(objectType);
  }

  void _openCreateObjectTypeModal() {
    showModalBottomSheet<ObjectTypeModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateObjectTypeModal(
        entityType: widget.entityType,
      ),
    ).then((created) {
      if (created != null) {
        widget.onObjectTypeSelected(created);
      }
      _loadObjectTypes();
    });
  }

  bool _shouldShowAddButton(List<ObjectTypeModel> objectTypes) {
    if (widget.entityType == 'CreditTab') {
      return objectTypes.length < 5;
    }
    return true;
  }

  void _showObjectTypeActions(
    BuildContext context,
    ObjectTypeModel objectType,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  objectType.name,
                  style: AppStyle.manrope(size: 18, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: Color(AppColors.grey),
                ),
                title: Text('Редактировать'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openEditObjectTypeModal(objectType);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Color(AppColors.grey),
                ),
                title: Text('Удалить каталог'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteConfirmationDialog(context, objectType);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditObjectTypeModal(ObjectTypeModel objectType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditObjectTypeModal(objectType: objectType),
    ).then((_) {
      _loadObjectTypes();
    });
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    ObjectTypeModel objectType,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Удалить каталог?',
          style: AppStyle.manrope(size: 18, weight: FontWeight.w600),
        ),
        content: Text(
          'Вы уверены, что хотите удалить каталог "${objectType.name}"? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteObjectType(objectType);
            },
            child: Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _deleteObjectType(ObjectTypeModel objectType) {
    final objectTypeBloc = context.read<ObjectTypeBloc>();
    objectTypeBloc.add(DeleteObjectTypeEvent(objectType.id));

    if (_selectedObjectType?.id == objectType.id) {
      setState(() {
        _selectedObjectType = null;
      });
      widget.onObjectTypeSelected(null);
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _loadObjectTypes();
    });
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
                    widget.title ?? 'Выберите каталог',
                    textAlign: TextAlign.left,
                    style: AppStyle.manrope(size: 20, weight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: false).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BlocConsumer<ObjectTypeBloc, ObjectTypeState>(
      listener: (context, state) {
        if (state is ObjectTypeLoaded || state is ObjectTypeError) {
          setState(() {
            _isLoading = false;
          });
        }
      },
      builder: (context, state) {
        if (_isLoading || state is ObjectTypeLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ObjectTypeError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка загрузки каталогов'),
                  const SizedBox(height: 8),
                  DefaultButton(
                    text: 'Повторить',
                    isPrimary: true,
                    onPressed: _loadObjectTypes,
                  ),
                ],
              ),
            ),
          );
        }

        List<ObjectTypeModel> objectTypes = [];
        if (state is ObjectTypeLoaded) {
          objectTypes = state.objectTypes;
        }

        final bool showAddButton = _shouldShowAddButton(objectTypes);
        final double itemHeight = 56.0;
        final double headerHeight = 120.0;
        final double buttonHeight = 50.0;
        final double padding = 16.0;

        double calculatedHeight = headerHeight;

        if (objectTypes.isNotEmpty) {
          calculatedHeight += (objectTypes.length * itemHeight);
        } else {
          calculatedHeight += 80;
        }

        if (showAddButton) {
          calculatedHeight += buttonHeight + padding;
        }

        final double maxHeight = MediaQuery.of(context).size.height * 0.7;
        final double finalHeight = calculatedHeight > maxHeight
            ? maxHeight
            : calculatedHeight;

        return SizedBox(
          height: finalHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(child: _buildObjectTypesList(objectTypes)),
              if (showAddButton) ...[
                const SizedBox(height: 16),
                DefaultButton(
                  text: 'Новый каталог',
                  isPrimary: true,
                  onPressed: _openCreateObjectTypeModal,
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildObjectTypesList(List<ObjectTypeModel> objectTypes) {
    if (objectTypes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [const SizedBox(height: 8), Text('Создайте новый каталог')],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: objectTypes.length,
      itemBuilder: (context, index) {
        final objectType = objectTypes[index];
        final isSelected = _selectedObjectType?.id == objectType.id;

        return GestureDetector(
          onLongPress: () => _showObjectTypeActions(context, objectType),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              objectType.name,
              style: AppStyle.manrope(
                size: 16,
                weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Color(AppColors.primary) : Colors.black,
              ),
            ),
            trailing: isSelected
                ? const Icon(
                    Icons.radio_button_checked,
                    color: Color(AppColors.primary),
                  )
                : null,
            onTap: () => _handleSelectObjectType(objectType),
          ),
        );
      },
    );
  }
}
