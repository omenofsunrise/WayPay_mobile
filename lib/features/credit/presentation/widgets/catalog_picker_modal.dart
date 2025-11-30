import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/search_field.dart';
import 'package:waypay_mobile/features/objectType/data/models/get_object_types_query.dart';
import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_bloc.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_event.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_state.dart';
import 'package:waypay_mobile/features/objectType/presentation/modal/create_object_type_modal_state.dart';
import 'package:waypay_mobile/features/objectType/presentation/modal/edit_object_type_modal.dart';

class CatalogPickerModal extends StatefulWidget {
  const CatalogPickerModal({
    super.key,
    this.selectedCatalog,
    this.entityType = 'Credit',
    this.title,
    this.createButtonLabel,
    this.allowCreate = true,
    this.allowEdit = true,
    this.allowDelete = true,
  });

  final ObjectTypeModel? selectedCatalog;
  final String entityType;
  final String? title;
  final String? createButtonLabel;
  final bool allowCreate;
  final bool allowEdit;
  final bool allowDelete;

  @override
  State<CatalogPickerModal> createState() => _CatalogPickerModalState();
}

class _CatalogPickerModalState extends State<CatalogPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  bool get _isCategory {
    final type = widget.entityType.toLowerCase();
    return type == 'credittab' || type == 'credittype';
  }

  String get _modalTitle =>
      widget.title ?? (_isCategory ? 'Выбор категории' : 'Выбор каталога');

  String get _createText => widget.createButtonLabel ??
      (_isCategory ? 'Создать категорию' : 'Создать новый каталог');

  String get _emptyText => _isCategory
      ? 'Категории не найдены'
      : 'Каталоги не найдены';

  String get _noneText => _isCategory ? 'Без категории' : 'Без каталога';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadCatalogs();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadCatalogs() {
    context.read<ObjectTypeBloc>().add(
      LoadObjectTypesEvent(
        refresh: true,
        query: GetObjectTypesQuery(
          page: 1,
          pageSize: 200,
          entityType: widget.entityType,
        ),
      ),
    );
  }

  void _onSearchChanged() {
    setState(() => _query = _searchController.text.trim().toLowerCase());
  }

  List<ObjectTypeModel> _applyFilter(List<ObjectTypeModel> catalogs) {
    if (_query.isEmpty) return catalogs;
    return catalogs
        .where((catalog) => catalog.name.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.8;
    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _modalTitle,
                      style: const TextStyle(
                        fontSize: 18,
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
              const SizedBox(height: 12),
              SearchField(
                controller: _searchController,
                hintText: 'Поиск',
                onChanged: (_) => _onSearchChanged(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<ObjectTypeBloc, ObjectTypeState>(
                  builder: (context, state) {
                    if (state is ObjectTypeLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is ObjectTypeError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    if (state is ObjectTypeLoaded) {
                      final filtered = _applyFilter(state.objectTypes);
                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            _emptyText,
                            style: const TextStyle(
                              color: Color(AppColors.darkGrey),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: filtered.length + 1,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 16, color: Color(0xFFE5E5EA)),
                        itemBuilder: (_, index) {
                          if (index == 0) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () => Navigator.of(context).pop(null),
                              title: Text(
                                _noneText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(AppColors.black),
                                ),
                              ),
                            );
                          }
                          final catalog = filtered[index - 1];
                          final isSelected =
                              widget.selectedCatalog?.id == catalog.id;
                          return _CatalogListItem(
                            catalog: catalog,
                            isSelected: isSelected,
                            allowEdit: widget.allowEdit,
                            allowDelete: widget.allowDelete,
                            onTap: () => Navigator.of(context).pop(catalog),
                            onEdit: () => _editCatalog(catalog),
                            onDelete: () => _confirmDelete(catalog),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (widget.allowCreate)
                DefaultButton(
                  text: _createText,
                  showIcon: true,
                  icon: Icons.add,
                  isGreen: true,
                  onPressed: _openCreateCatalog,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateCatalog() async {
    final bloc = context.read<ObjectTypeBloc>();
    final created = await showModalBottomSheet<ObjectTypeModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: CreateObjectTypeModal(
          entityType: widget.entityType,
        ),
      ),
    );

    if (!mounted) return;
    if (created != null) {
      Navigator.of(context).pop(created);
      return;
    }
    _loadCatalogs();
  }

  Future<void> _editCatalog(ObjectTypeModel catalog) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ObjectTypeBloc>(),
        child: EditObjectTypeModal(objectType: catalog),
      ),
    );
  }

  Future<void> _confirmDelete(ObjectTypeModel catalog) async {
    if (!mounted) return;
    context.read<ObjectTypeBloc>().add(DeleteObjectTypeEvent(catalog.id));
  }
}

class _CatalogListItem extends StatelessWidget {
  const _CatalogListItem({
    required this.catalog,
    required this.isSelected,
    required this.allowEdit,
    required this.allowDelete,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ObjectTypeModel catalog;
  final bool isSelected;
  final bool allowEdit;
  final bool allowDelete;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final item = Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE4F2F4) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        onTap: onTap,
        title: Text(
          catalog.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(AppColors.black),
          ),
        ),
      ),
    );

    final actions = <Widget>[];
    if (allowEdit) {
      actions.add(
        CustomSlidableAction(
          onPressed: (_) => onEdit(),
          backgroundColor: const Color(AppColors.primary),
          padding: EdgeInsets.zero,
          child: const _SlidableActionContent(
            iconPath: SvgIcons.edit,
            label: 'Изменить',
          ),
        ),
      );
    }
    if (allowDelete) {
      actions.add(
        CustomSlidableAction(
          onPressed: (_) => onDelete(),
          backgroundColor: const Color(0xFFE53935),
          padding: EdgeInsets.zero,
          child: const _SlidableActionContent(
            iconPath: SvgIcons.delete,
            label: 'Удалить',
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return item;
    }

    final ratio = (0.28 * actions.length).clamp(0.28, 0.84).toDouble();

    return Slidable(
      key: ValueKey('catalog_${catalog.id}'),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: ratio,
        children: actions,
      ),
      child: item,
    );
  }
}

class _SlidableActionContent extends StatelessWidget {
  const _SlidableActionContent({
    required this.iconPath,
    required this.label,
  });

  final String iconPath;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          iconPath,
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
