import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/network/dio_client.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/blacklist_plus_remote_data_source.dart';
import 'package:waypay_mobile/features/clients/data/models/blacklist_plus_model.dart';

class BlacklistPlusScreen extends StatefulWidget {
  const BlacklistPlusScreen({super.key});

  @override
  State<BlacklistPlusScreen> createState() => _BlacklistPlusScreenState();
}

class _BlacklistPlusScreenState extends State<BlacklistPlusScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  late final BlacklistPlusRemoteDataSource _source;

  bool _loading = false;
  bool _searched = false;
  String? _error;
  List<BlacklistPlusEntry> _items = const [];

  @override
  void initState() {
    super.initState();
    _source = BlacklistPlusRemoteDataSource(createDio());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final name = _nameController.text.trim();
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (name.length < 3 && phoneDigits.length < 11) {
      showAppMessage(
        context,
        'Введите минимум 3 буквы ФИО или полный номер телефона',
        type: AppMessageType.info,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _source.search(
        fullName: name.length >= 3 ? name : null,
        phone: phoneDigits.length >= 11 ? phoneDigits : null,
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _searched = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _searched = true;
        _items = const [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    _nameController.clear();
    _phoneController.clear();
    setState(() {
      _searched = false;
      _items = const [];
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(
                title: 'ЧС+',
                showBackButton: true,
                showNotifications: false,
                showAvatar: false,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: _decoration(
                  'ФИО клиента (минимум 3 символа)',
                  Icons.person_search_outlined,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: _decoration(
                  'Полный номер телефона',
                  Icons.phone_outlined,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DefaultButton(
                      text: 'Сбросить',
                      isPrimary: false,
                      onPressed: _reset,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DefaultButton(
                      text: 'Проверить',
                      isPrimary: true,
                      onPressed: _loading ? null : _search,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(AppColors.uiBorder)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _MessageState(icon: Icons.error_outline, text: _error!);
    }
    if (!_searched) {
      return const _MessageState(
        icon: Icons.fact_check_outlined,
        text: 'Введите ФИО или телефон, чтобы проверить человека в ЧС+',
      );
    }
    if (_items.isEmpty) {
      return const _MessageState(
        icon: Icons.verified_user_outlined,
        text: 'Совпадений в ЧС+ не найдено',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) => _BlacklistPlusCard(entry: _items[index]),
    );
  }
}

class _BlacklistPlusCard extends StatelessWidget {
  const _BlacklistPlusCard({required this.entry});

  final BlacklistPlusEntry entry;

  String _date(DateTime? value) {
    return value == null ? '—' : DateFormat('dd.MM.yyyy').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final activeDebts = entry.debts.where((debt) => !debt.paid).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD7D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.fullName.isEmpty ? 'Без имени' : entry.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  entry.isSwindler ? 'Мошенник' : 'В ЧС+',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(icon: Icons.phone_outlined, value: entry.phone),
          _InfoRow(
            icon: Icons.cake_outlined,
            value: 'Дата рождения: ${_date(entry.birthdate)}',
          ),
          if (entry.document.isNotEmpty)
            _InfoRow(
              icon: Icons.badge_outlined,
              value:
                  'Паспорт: ${entry.document}${entry.documentIssueDate == null ? '' : ' от ${_date(entry.documentIssueDate)}'}',
            ),
          if (entry.address.isNotEmpty)
            _InfoRow(icon: Icons.location_on_outlined, value: entry.address),
          if (activeDebts > 0)
            _InfoRow(
              icon: Icons.warning_amber_rounded,
              value: 'Активных долгов: $activeDebts',
              color: Colors.red,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.value, this.color});

  final IconData icon;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color ?? const Color(AppColors.uiBorder)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(fontSize: 14, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(AppColors.uiBorder)),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(AppColors.uiBorder)),
            ),
          ],
        ),
      ),
    );
  }
}
