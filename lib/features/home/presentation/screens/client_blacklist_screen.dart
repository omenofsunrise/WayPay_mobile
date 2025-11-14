import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/core/widgets/search_field.dart';

class ClientBlacklistScreen extends StatefulWidget {
  const ClientBlacklistScreen({super.key});

  @override
  State<ClientBlacklistScreen> createState() => _ClientBlacklistScreenState();
}

class _ClientBlacklistScreenState extends State<ClientBlacklistScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<_BlacklistClient> _clients = _mockClients;
  late List<_BlacklistClient> _filteredClients;
  bool _showSearchHint = false;

  @override
  void initState() {
    super.initState();
    _filteredClients = _clients;
    _searchController.addListener(_handleSearch);
  }

  void _handleSearch() => _applyFilter(_searchController.text);

  void _applyFilter(String raw) {
    final query = raw.trim();
    final digits = query.replaceAll(RegExp(r'\D'), '');
    final hintNeeded =
        query.isNotEmpty && query.length < 4 && digits.length < 11;

    if (query.isEmpty) {
      setState(() {
        _filteredClients = _clients;
        _showSearchHint = false;
      });
      return;
    }

    if (digits.length >= 11) {
      setState(() {
        _filteredClients = _clients
            .where(
              (c) =>
                  c.phoneDigits.contains(digits) ||
                  c.whatsAppDigits.contains(digits),
            )
            .toList();
        _showSearchHint = false;
      });
      return;
    }

    if (query.length >= 4) {
      final lower = query.toLowerCase();
      setState(() {
        _filteredClients = _clients
            .where((c) => c.fullName.toLowerCase().contains(lower))
            .toList();
        _showSearchHint = false;
      });
      return;
    }

    setState(() {
      _filteredClients = _clients;
      _showSearchHint = hintNeeded;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearch);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Header(title: 'Чёрный список', showBackButton: true),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: SearchField(
                  controller: _searchController,
                  hintText: 'Поиск',
                  onChanged: _applyFilter,
                ),
              ),
              if (_showSearchHint)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Введите минимум 4 символа ФИО или полный номер телефона',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(AppColors.darkGrey),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final client = _filteredClients[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BlacklistCard(client: client),
                  );
                }, childCount: _filteredClients.length),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlacklistCard extends StatelessWidget {
  const _BlacklistCard({required this.client});

  final _BlacklistClient client;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000809),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Color(0x05000809),
            offset: Offset(0, 0),
            blurRadius: 6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    client.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.black),
                    ),
                  ),
                ),
                Text(
                  'ID: ${client.id}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.darkGrey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Дата рождения',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(AppColors.darkGrey),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              client.birthDate,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(AppColors.black),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoLine(label: 'Телефон', value: client.phone),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoLine(label: 'WhatsApp', value: client.whatsApp),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(AppColors.darkGrey),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.black),
          ),
        ),
      ],
    );
  }
}

class _BlacklistClient {
  const _BlacklistClient({
    required this.fullName,
    required this.id,
    required this.birthDate,
    required this.phone,
    required this.whatsApp,
  });

  final String fullName;
  final String id;
  final String birthDate;
  final String phone;
  final String whatsApp;

  String get phoneDigits => phone.replaceAll(RegExp(r'\D'), '');
  String get whatsAppDigits => whatsApp.replaceAll(RegExp(r'\D'), '');
}

const _mockClients = [
  _BlacklistClient(
    fullName: 'Мирошниченко Владислава Филипповна',
    id: '234',
    birthDate: '12.05.1987',
    phone: '+7(999)999-99-99',
    whatsApp: '+7(999)999-99-99',
  ),
  _BlacklistClient(
    fullName: 'Антонов Сергей Леонидович',
    id: '235',
    birthDate: '03.11.1990',
    phone: '+7(912)123-45-67',
    whatsApp: '+7(912)123-45-67',
  ),
  _BlacklistClient(
    fullName: 'Семенова Алина Викторовна',
    id: '236',
    birthDate: '21.01.1994',
    phone: '+7(995)321-44-55',
    whatsApp: '+7(995)321-44-55',
  ),
  _BlacklistClient(
    fullName: 'Громов Михаил Сергеевич',
    id: '237',
    birthDate: '09.08.1983',
    phone: '+7(913)876-54-32',
    whatsApp: '+7(913)876-54-32',
  ),
];
