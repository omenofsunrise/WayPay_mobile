import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/search_field.dart';
import 'package:waypay_mobile/features/objectType/data/models/get_object_types_query.dart';
import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_bloc.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_event.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_state.dart';
import 'package:waypay_mobile/features/objectType/presentation/modal/create_object_type_modal_state.dart';

class CatalogPickerModal extends StatefulWidget {
  const CatalogPickerModal({super.key, this.selectedCatalog});

  final ObjectTypeModel? selectedCatalog;

  @override
  State<CatalogPickerModal> createState() => _CatalogPickerModalState();
}

class _CatalogPickerModalState extends State<CatalogPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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
          entityType: 'Credit',
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
                  const Expanded(
                    child: Text(
                      'Выбор каталога',
                      style: TextStyle(
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
                        return const Center(
                          child: Text(
                            'Каталоги не найдены',
                            style: TextStyle(color: Color(AppColors.darkGrey)),
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
                              title: const Text(
                                'Без каталога',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(AppColors.black),
                                ),
                              ),
                            );
                          }
                          final catalog = filtered[index - 1];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () => Navigator.of(context).pop(catalog),
                            title: Text(
                              catalog.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(AppColors.black),
                              ),
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              const SizedBox(height: 16),
              DefaultButton(
                text: 'Создать новый каталог',
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
          entityType: 'Credit',
          onObjectTypeCreated: (catalog) {
            Navigator.of(context).pop(catalog);
          },
        ),
      ),
    );

    if (created != null && mounted) {
      Navigator.of(context).pop(created);
    } else {
      _loadCatalogs();
    }
  }
}
