import 'package:flutter/material.dart';
import 'package:waypay/core/storage/user_storage.dart';
import 'package:waypay/features/profile/data/models/employee.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/buttons/add_button.dart';
import 'package:waypay/core/widgets/buttons/more_info_button.dart';
import 'package:waypay/core/widgets/header.dart';
import 'package:waypay/core/widgets/search_field.dart';
import 'package:waypay/features/home/presentation/widgets/dashboard_card.dart';
import 'package:waypay/features/home/presentation/widgets/section_title.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String get _mockFullName => 'Иван Петров';
  String? get _mockPhotoPath => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Header(
                  fullName: _mockFullName,
                  photoPath: _mockPhotoPath,
                  showBackButton: false,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: SearchField(
                        hintText: 'Поиск',
                        onChanged: (value) {},
                        onSubmitted: (value) {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    AddButton(onPressed: () {}),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 13)),

              _buildCompaniesSection(),
              const SliverToBoxAdapter(child: SizedBox(height: 13)),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SectionTitle(text: 'Финансы'),
                        Spacer(),
                        MoreDetailsButton(
                          onPressed: () {
                            print('asd');
                          },
                        ),
                      ],
                    ),
                    DashboardCard(title: 'Бюджет', value: '15 000'),
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            title: 'Текущий доход',
                            value: '125 000',
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: DashboardCard(
                            title: 'Ожидаемый доход',
                            value: '125 000',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 13)),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SectionTitle(text: 'Платежи'),
                        Spacer(),
                        MoreDetailsButton(
                          onPressed: () {
                            print('asd');
                          },
                        ),
                      ],
                    ),
                    DashboardCard(
                      title: 'Подтверждённые платежи',
                      value: '15 000',
                      additionalValue: '15 штук',
                    ),
                    DashboardCard(
                      title: 'Неподтверждённые платежи',
                      value: '125 000',
                      additionalValue: '43 штук',
                      valueColor: Color(AppColors.red),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 13)),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SectionTitle(text: 'Договоры'),
                        Spacer(),
                        MoreDetailsButton(
                          onPressed: () {
                            print('asd');
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            title: 'Закрытые',
                            value: '15 000',
                            description: 'за сентябрь',
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: DashboardCard(
                            title: 'Доход',
                            value: '125 000',
                            description: 'за сентябрь',
                            valueColor: Color(AppColors.red),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            title: 'Остаток выплат',
                            value: '15 000',
                            description: 'за сентябрь',
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: DashboardCard(
                            title: 'Задолженности',
                            value: '125 000',
                            description: 'за сентябрь',
                            valueColor: Color(AppColors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 13)),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SectionTitle(text: 'Клиенты'),
                        Spacer(),
                        MoreDetailsButton(
                          onPressed: () {
                            print('asd');
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(title: 'Всего', value: '2463'),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: DashboardCard(title: 'Заявки', value: '500'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 13)),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SectionTitle(text: 'Инвесторы'),
                        Spacer(),
                        MoreDetailsButton(
                          onPressed: () {
                            print('asd');
                          },
                        ),
                      ],
                    ),
                    DashboardCard(title: 'Касса', value: '2463'),
                    DashboardCard(title: 'Сумма инвестиций', value: '500'),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompaniesSection() {
    final userRole = UserStorage().getRoleSync();

    if (userRole != EmployeeRole.superAdmin) {
      return SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionTitle(text: 'Компании'),
              Spacer(),
              MoreDetailsButton(
                onPressed: () {
                  print('asd');
                },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: DashboardCard(title: 'Активные', value: '125 000'),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: DashboardCard(title: 'Всего', value: '125 000'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
