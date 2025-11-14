import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/helpers.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:waypay_mobile/features/profile/presentation/widgets/credit_count.dart';
import 'package:waypay_mobile/features/profile/presentation/widgets/payment_stats_table.dart';

class MyProfileScreen extends StatefulWidget {
  final int? employeeId;
  final void Function() refresh;
  const MyProfileScreen({super.key, this.employeeId, required this.refresh});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.background),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProfileError) {
            return Center(child: Text(state.message));
          } else if (state is ProfileLoaded) {
            final employee = state.employee;
            return Refresher(
              onRefresh: () async {
                final cubit = context.read<ProfileCubit>();
                if (widget.employeeId == null) {
                  cubit.loadProfile();
                } else {
                  cubit.loadProfileById(widget.employeeId!);
                }
                widget.refresh();
              },
              content: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 25,
                ),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Личные данные и статистика',
                          textAlign: TextAlign.center,
                          style: AppStyle.manrope(
                            size: 20,
                            weight: FontWeight.w500,
                            color: Color(0xff007D88),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Center(
                        child: buildAvatar(
                          photoPath: employee.photoPath,
                          fullName: employee.fullName,
                        ),
                      ),
                      const SizedBox(height: 21),
                      Center(
                        child: Text(
                          employee.fullName,
                          style: AppStyle.inter(
                            size: 20,
                            weight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Center(
                        child: Text(
                          employee.roleLabel,
                          style: AppStyle.inter(
                            size: 16,
                            weight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        spacing: 5,
                        children: [
                          Icon(
                            Icons.phone,
                            color: Color(AppColors.darkGrey),
                            size: 24,
                          ),
                          Text(
                            employee.phone,
                            style: AppStyle.manrope(
                              weight: FontWeight.w400,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        spacing: 5,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Color(AppColors.darkGrey),
                            size: 24,
                          ),
                          Text(
                            employee.address,
                            style: AppStyle.manrope(
                              weight: FontWeight.w400,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        spacing: 5,
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Color(AppColors.darkGrey),
                            size: 24,
                          ),
                          Text(
                            'Мин. надбавка ${employee.minSurcharge} %',
                            style: AppStyle.manrope(
                              weight: FontWeight.w400,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      if (employee.role.toLabel() !=
                          EmployeeRole.accountant.toLabel()) ...[
                        const SizedBox(height: 30),
                        PaymentStatsProfileTable(employeeId: widget.employeeId),
                      ],
                      if (employee.role.toLabel() !=
                          EmployeeRole.accountant.toLabel()) ...[
                        const SizedBox(height: 20),
                        CreditCount(employeeId: widget.employeeId),
                      ],
                      const SizedBox(height: 30),
                      if (employee.role != EmployeeRole.superAdmin &&
                          employee.role != EmployeeRole.admin &&
                          employee.role != EmployeeRole.director) ...[
                        Center(
                          child: Text(
                            'Права пользователя',
                            textAlign: TextAlign.center,
                            style: AppStyle.manrope(
                              size: 20,
                              weight: FontWeight.w500,
                              color: Color(0xff007D88),
                            ),
                          ),
                        ),
                        const SizedBox(height: 23),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: Permission.values.map((permission) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: buildPermissionIndicator(
                                isGranted: employee.permissions.contains(
                                  permission,
                                ),
                                label: permission.toLabel(),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('Нет данных о пользователе'));
          }
        },
      ),
    );
  }

  Widget buildPermissionIndicator({
    required bool isGranted,
    required String label,
  }) {
    return Row(
      spacing: 8,
      children: [
        Container(
          width: 19,
          height: 19,
          decoration: BoxDecoration(
            color: isGranted ? Color(AppColors.radioColor) : Colors.transparent,
            border: Border.all(color: Color(AppColors.borderColor), width: 1),
          ),
          child: isGranted
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
        Text(label, style: AppStyle.manrope(size: 20, weight: FontWeight.w400)),
      ],
    );
  }
}
