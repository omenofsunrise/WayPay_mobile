import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay_mobile/core/widgets/app_modal.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/pagination_widget.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart'
    show EmployeeRole, admin, director, superAdmin;
import 'package:waypay_mobile/features/product/presentation/bloc/products_bloc.dart';
import 'package:waypay_mobile/features/product/presentation/widgets/product_card.dart';
import 'package:waypay_mobile/features/product/data/data_sources/products_remote_data_source.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsBloc>().add(LoadProductsEvent());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterModal() {
    final productsBloc = context.read<ProductsBloc>();
    final tempController = TextEditingController(text: _searchController.text);

    showDialog(
      context: context,
      builder: (_) => AppModal(
        title: 'Фильтры',
        backgroundColor: const Color(AppColors.background),
        contentPadding: const EdgeInsets.all(16),
        content: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: tempController,
                  decoration: InputDecoration(
                    hintText: 'Поиск продуктов...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (value) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      final q = value.trim();
                      if (q.isNotEmpty) {
                        productsBloc.add(SearchProductsEvent(q));
                      } else {
                        productsBloc.add(ResetSearchProductsEvent());
                      }
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          DefaultButton(
            text: 'Сбросить',
            onPressed: () {
              tempController.clear();
              setState(() => _searchController.clear());
              productsBloc.add(ResetSearchProductsEvent());
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 12),
          DefaultButton(
            text: 'Применить',
            isGreen: true,
            onPressed: () {
              setState(() => _searchController.text = tempController.text);
              final q = _searchController.text.trim();
              if (q.isNotEmpty) {
                productsBloc.add(SearchProductsEvent(q));
              } else {
                productsBloc.add(ResetSearchProductsEvent());
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAddProductModal() {
    final nameController = TextEditingController();
    final ValueNotifier<String?> nameError = ValueNotifier(null);

    bool validateInput() {
      nameError.value = null;
      if (nameController.text.trim().isEmpty) {
        nameError.value = 'Введите название продукта';
        return false;
      }
      return true;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerDialogContext, setState) {
          return AppModal(
            backgroundColor: Color(AppColors.background),
            title: 'Добавить продукт',
            content: Column(
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: nameError,
                  builder: (_, error, __) => TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Название продукта',
                      errorText: error,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DefaultButton(
                        text: 'Отмена',
                        isGreen: false,
                        onPressed: () {
                          if (!innerDialogContext.mounted) return;
                          Navigator.pop(innerDialogContext);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DefaultButton(
                        text: 'Создать',
                        isGreen: true,
                        onPressed: () async {
                          if (!validateInput()) {
                            setState(() {});
                            return;
                          }

                          if (!innerDialogContext.mounted) return;
                          Navigator.pop(innerDialogContext);

                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          try {
                            await getIt<ProductsRemoteDataSource>()
                                .createProduct(
                                  name: nameController.text.trim(),
                                );

                            if (!context.mounted) return;
                            Navigator.pop(context);

                            context.read<ProductsBloc>().add(
                              LoadProductsEvent(refresh: true, page: 1),
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Продукт успешно создан'),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            Navigator.pop(context);

                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Ошибка'),
                                content: Text(
                                  'Не удалось создать продукт.\n$e',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Ок'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<EmployeeRole?>(
      valueListenable: UserStorage().roleNotifier,
      builder: (context, role, _) {
        final canAddProduct = UserStorage().hasViewContent([
          EmployeeRole.employee,
          EmployeeRole.director,
          EmployeeRole.admin,
          EmployeeRole.superAdmin,
        ]);

        return Scaffold(
          drawer: const AppDrawer(),
          backgroundColor: const Color(AppColors.primary),
          appBar: AppBar(
            surfaceTintColor: Colors.transparent,
            backgroundColor: const Color(AppColors.primary),
            elevation: 0,
            title: Text(
              'Продукты',
              style: AppStyle.medium20.copyWith(
                color: const Color(AppColors.background),
              ),
            ),
            actions: [
              if (canAddProduct)
                IconButton(
                  tooltip: 'Добавить продукт',
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _showAddProductModal,
                ),
              IconButton(
                icon: const Icon(Icons.filter_alt, color: Colors.white),
                onPressed: _openFilterModal,
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: BlocBuilder<ProductsBloc, ProductsState>(
                    builder: (context, state) {
                      if (state is ProductsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is ProductsError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Color(AppColors.red),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Ошибка загрузки\n${state.message}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(AppColors.red),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    context.read<ProductsBloc>().add(
                                      LoadProductsEvent(),
                                    );
                                  },
                                  child: const Text('Повторить'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (state is ProductsLoaded) {
                        if (state.products.isEmpty) {
                          return const Center(
                            child: Text('Продукты не найдены'),
                          );
                        }
                        return Column(
                          children: [
                            Expanded(
                              child: Refresher(
                                onRefresh: () async {
                                  context.read<ProductsBloc>().add(
                                    LoadProductsEvent(page: state.currentPage),
                                  );
                                },
                                content: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: state.products.length,
                                  itemBuilder: (context, index) {
                                    return ProductCard(
                                      product: state.products[index],
                                    );
                                  },
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 16,
                              ),
                              child: PaginationWidget(
                                currentPage: state.currentPage,
                                totalPages: state.totalPages,
                                onPageSelected: (page) {
                                  context.read<ProductsBloc>().add(
                                    LoadProductsEvent(page: page),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }

                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
