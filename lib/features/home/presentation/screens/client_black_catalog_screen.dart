import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/core/widgets/search_field.dart';

class ClientBlackCatalogScreen extends StatefulWidget {
  const ClientBlackCatalogScreen({super.key});

  @override
  State<ClientBlackCatalogScreen> createState() =>
      _ClientBlackCatalogScreenState();
}

class _ClientBlackCatalogScreenState extends State<ClientBlackCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<_CatalogClient> _clients = _mockCatalogClients;
  late List<_CatalogClient> _filteredClients;
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
    _searchController
      ..removeListener(_handleSearch)
      ..dispose();
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
                child: Header(title: 'Чёрный каталог', showBackButton: true),
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
                    child: _CatalogCard(client: client),
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

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({required this.client});

  final _CatalogClient client;

  static const _shadow = [
    BoxShadow(color: Color(0x14000809), offset: Offset(2, 2), blurRadius: 4),
    BoxShadow(color: Color(0x05000809), offset: Offset(0, 0), blurRadius: 6),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _shadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'ID: ${client.id}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(AppColors.darkGrey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _LabeledValue(label: 'Дата рождения', value: client.birthDate),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _LabeledValue(label: 'Телефон', value: client.phone),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _LabeledValue(
                    label: 'WhatsApp',
                    value: client.whatsApp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({required this.label, required this.value});

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
            fontSize: 14,
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

class _CatalogClient {
  const _CatalogClient({
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

const _mockCatalogClients = [
  _CatalogClient(
    fullName: 'Ильин Владислав Михайлович',
    id: '512',
    birthDate: '04.08.1989',
    phone: '+7(900)555-22-33',
    whatsApp: '+7(900)555-22-33',
  ),
  _CatalogClient(
    fullName: 'Шевченко Анастасия Игоревна',
    id: '513',
    birthDate: '19.02.1991',
    phone: '+7(921)777-88-99',
    whatsApp: '+7(921)777-88-99',
  ),
  _CatalogClient(
    fullName: 'Горбунов Павел Сергеевич',
    id: '514',
    birthDate: '30.06.1985',
    phone: '+7(905)111-22-55',
    whatsApp: '+7(905)111-22-55',
  ),
];
