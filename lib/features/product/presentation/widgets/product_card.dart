import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay/core/storage/user_storage.dart';
import 'package:waypay/core/widgets/form_modal/app_form_modal.dart';
import 'package:waypay/core/widgets/form_modal/form_field_config.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/widgets/form_modal/labeled_container.dart';
import 'package:waypay/features/product/data/data_sources/products_remote_data_source.dart';
import 'package:waypay/features/product/data/models/product_model.dart';
import 'package:waypay/features/product/presentation/bloc/products_bloc.dart';
import 'package:waypay/features/profile/data/models/employee.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final userStorage = getIt<UserStorage>();

    return ValueListenableBuilder<EmployeeRole?>(
      valueListenable: userStorage.roleNotifier,
      builder: (context, role, _) {
        final canManage = userStorage.hasViewContent([
          EmployeeRole.employee,
          EmployeeRole.director,
          EmployeeRole.admin,
          EmployeeRole.superAdmin,
        ]);

        return InkWell(
          onTap: () async {
            final dataSource = getIt<ProductsRemoteDataSource>();

            final detailedProduct = product;

            showDialog(
              context: context,
              builder: (_) => AppModal(
                title: 'О продукте',
                menuItems: canManage
                    ? [
                        PopupMenuItem(
                          child: const Text('Редактировать'),
                          onTap: () async {
                            context.pop();
                            final nameController = TextEditingController(text: detailedProduct.name);

                            await showDialog(
                              context: context,
                              builder: (_) => AppFormModal(
                                title: 'Редактировать продукт',
                                fields: [
                                  FormFieldConfig(
                                    controller: nameController,
                                    label: 'Название',
                                    placeholder: 'Введите название',
                                  ),
                                ],
                                onCancel: () => context.pop(),
                                onSave: () async {
                                  context.pop();
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(child: CircularProgressIndicator()),
                                  );
                                  try {
                                    await dataSource.updateProduct(
                                      id: detailedProduct.id,
                                      name: nameController.text.trim(),
                                    );
                                    context.pop();
                                    context.read<ProductsBloc>().add(LoadProductsEvent(refresh: true));
                                  } catch (e) {
                                    context.pop();
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Ошибка'),
                                        content: Text('Не удалось обновить продукт.\n$e'),
                                        actions: [TextButton(onPressed: () => context.pop(), child: const Text('Ок'))],
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                        PopupMenuItem(
                          child: const Text('Удалить'),
                          onTap: () async {
                            context.pop();
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Удаление продукта'),
                                content: const Text('Вы уверены, что хотите удалить этот продукт?'),
                                actions: [
                                  TextButton(onPressed: () => context.pop(false), child: const Text('Отмена')),
                                  TextButton(onPressed: () => context.pop(true), child: const Text('Удалить')),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(child: CircularProgressIndicator()),
                              );
                              try {
                                await dataSource.deleteProduct(detailedProduct.id);
                                context.pop();
                                context.read<ProductsBloc>().add(LoadProductsEvent(refresh: true));
                              } catch (e) {
                                context.pop();
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Ошибка'),
                                    content: Text('Не удалось удалить продукт.\n$e'),
                                    actions: [TextButton(onPressed: () => context.pop(), child: const Text('Ок'))],
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ]
                    : null,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [LabeledContainer(label: 'Название:', text: detailedProduct.name)],
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.all(16),
            child: Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }
}
