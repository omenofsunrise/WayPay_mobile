import 'package:flutter/material.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay_mobile/features/admin_panel/data/data_sources/company_remote_data_source.dart';
import 'package:waypay_mobile/features/info/privacy_policy_screen.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  DateTime? licenceDate;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
  }

  Future<void> _loadCompanyInfo() async {
    try {
      final companyRemoteDataSource = getIt<CompanyRemoteDataSource>();
      final info = await companyRemoteDataSource.getCompanyCommonInfo();
      setState(() {
        licenceDate = info.licenceDate;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка загрузки данных';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.primary),
      drawer: const AppDrawer(),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(AppColors.primary),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'О программе',
          style: AppStyle.medium20.copyWith(
            color: const Color(AppColors.background),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(AppColors.background),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
                child: Text(errorMessage!, style: TextStyle(color: Colors.red)),
              )
            : Column(
                children: [
                  SizedBox(height: 70),
                  Center(
                    child: Image.asset(
                      Images.backgroundLogo,
                      height: 107,
                      width: 107,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Версия 1.140.0 (40084)',
                    style: AppStyle.inter(
                      size: 16,
                      weight: FontWeight.w400,
                      color: Color(AppColors.darkGrey),
                    ),
                  ),
                  SizedBox(height: 50),
                  Text(
                    'Контакты',
                    style: AppStyle.manrope(
                      size: 20,
                      weight: FontWeight.w400,
                      color: Color(AppColors.black),
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Элипханов Ибрахим Султанович',
                    style: AppStyle.inter(
                      size: 16,
                      weight: FontWeight.w400,
                      color: Color(AppColors.darkGrey),
                    ),
                  ),
                  Text(
                    '8 (995) 702-23-04',
                    style: AppStyle.inter(
                      size: 16,
                      weight: FontWeight.w400,
                      color: Color(AppColors.comfPayment),
                    ),
                  ),
                  SizedBox(height: 25),
                  Text(
                    'Cрок лицензии',
                    style: AppStyle.manrope(
                      size: 20,
                      weight: FontWeight.w400,
                      color: Color(AppColors.black),
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    licenceDate != null
                        ? 'до ${_formatDate(licenceDate!)}'
                        : 'Дата лицензии недоступна',
                    style: AppStyle.inter(
                      size: 16,
                      weight: FontWeight.w400,
                      color: Color(AppColors.darkGrey),
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      height: 1,
                      color: Color(AppColors.uncomfPayment),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 30,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Политика конфиденциальности',
                        style: AppStyle.inter(
                          size: 20,
                          weight: FontWeight.w400,
                          color: Color(AppColors.comfPayment),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
