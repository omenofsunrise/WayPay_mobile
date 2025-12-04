import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waypay_mobile/core/config/api_config.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay_mobile/features/admin_panel/presentation/cubit/company_cubit.dart';
import 'package:waypay_mobile/features/admin_panel/data/models/company_model.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final nameController = TextEditingController();
  final chiefController = TextEditingController();
  final cityController = TextEditingController();
  final addressController = TextEditingController();
  final innController = TextEditingController();
  final emailController = TextEditingController();
  final bankController = TextEditingController();
  final phoneController = TextEditingController();

  File? _newImageFile;
  late CompanyModel _initialCompany;

  @override
  void initState() {
    super.initState();
    context.read<CompanyCubit>().loadCompany();
  }

  String? _resolvePhotoUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${ApiConfig.filesBaseUrl}$path';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      _newImageFile = File(picked.path);
      await context.read<CompanyCubit>().uploadCompanyPhoto(picked.path);
      setState(() {});
    }
  }

  void _resetEmptyFields() {
    if (_initialCompany.name.isEmpty) nameController.clear();
    if (_initialCompany.chief.isEmpty) chiefController.clear();
    if (_initialCompany.city.isEmpty) cityController.clear();
    if (_initialCompany.officeAddress.isEmpty) addressController.clear();
    if (_initialCompany.inn.isEmpty) innController.clear();
    if (_initialCompany.email.isEmpty) emailController.clear();
    if (_initialCompany.phone.isEmpty) phoneController.clear();
    if (_initialCompany.bank.isEmpty) bankController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyCubit, CompanyState>(
      builder: (context, state) {
        if (state is CompanyLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CompanyError) {
          return Center(child: Text(state.message));
        }

        if (state is CompanyLoaded && state.companies.isNotEmpty) {
          final CompanyModel company = state.companies.first;
          _initialCompany = company;

          // Заполняем поля, телефон без ведущей "8"
          nameController.text = company.name;
          chiefController.text = company.chief;
          cityController.text = company.city;
          addressController.text = company.officeAddress;
          innController.text = company.inn;
          emailController.text = company.email;
          bankController.text = company.bank;

          String rawPhone = company.phone;
          if (rawPhone.startsWith('8')) {
            rawPhone = rawPhone.substring(1); // убираем ведущую 8
          }
          phoneController.text = rawPhone;

          return _buildFormUI(company);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFormUI(CompanyModel company) {
    final photoUrl = _resolvePhotoUrl(company.photoPath);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
      child: ListView(
        children: [
          Center(
            child: Text(
              'Сведения о компании',
              textAlign: TextAlign.center,
              style: AppStyle.manrope(
                size: 20,
                weight: FontWeight.w500,
                color: Color(AppColors.radioColor),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            'Логотип',
            style: AppStyle.manrope(
              size: 14,
              weight: FontWeight.w400,
              color: Color(AppColors.grey),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 89,
                height: 89,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                  image: _newImageFile != null
                      ? DecorationImage(
                          image: FileImage(_newImageFile!),
                          fit: BoxFit.cover,
                        )
                      : (photoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover,
                              )
                            : null),
                ),
                child: photoUrl == null && _newImageFile == null
                    ? const Icon(Icons.apartment, size: 32, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 20),
          LabeledTextField(
            label: 'Название компании',
            controller: nameController,
          ),
          const SizedBox(height: 20),
          LabeledTextField(label: 'Учредитель', controller: chiefController),
          const SizedBox(height: 20),
          LabeledTextField(
            label: 'Населённый пункт',
            controller: cityController,
          ),
          const SizedBox(height: 20),
          LabeledTextField(label: 'Адрес офиса', controller: addressController),
          const SizedBox(height: 20),
          LabeledTextField(
            label: 'ИНН',
            controller: innController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          LabeledTextField(label: 'Email', controller: emailController),
          const SizedBox(height: 20),
          // Телефон с prefix '8 '
          LabeledTextField(
            label: 'Телефон',
            controller: phoneController,
            keyboardType: TextInputType.phone,
            format: LabeledTextFieldFormat.phone,
            prefix: const Text('8 '),
          ),
          const SizedBox(height: 20),
          LabeledTextField(
            label: 'Рассчётный счёт',
            controller: bankController,
          ),
          const SizedBox(height: 20),
          Text(
            '*Все данные компании используются только для автоматического оформления договора займа и не передаются третьим лицам.',
            style: AppStyle.manrope(size: 12, weight: FontWeight.w400),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: DefaultButton(
                  text: 'Сбросить',
                  onPressed: _resetEmptyFields,
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DefaultButton(
                  text: 'Подтвердить',
                  onPressed: () async {
                    final updatedCompany = _initialCompany.copyWith(
                      name: nameController.text.trim(),
                      chief: chiefController.text.trim(),
                      phone:
                          '8${phoneController.text.trim()}', // добавляем 8 перед отправкой
                      city: cityController.text.trim(),
                      officeAddress: addressController.text.trim(),
                      bank: bankController.text.trim(),
                      inn: innController.text.trim(),
                      email: emailController.text.trim(),
                    );

                    try {
                      await context.read<CompanyCubit>().updateCompany(
                        updatedCompany,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Данные компании обновлены'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка при обновлении: $e')),
                      );
                    }
                  },
                  color: Color(AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
