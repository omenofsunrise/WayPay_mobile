import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/core/widgets/search_field.dart';
import 'package:waypay_mobile/core/widgets/buttons/add_button.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/client_info_card.dart';
import 'package:waypay_mobile/routes/routes.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<ClientInfo> _clients = _mockClients;
  late List<ClientInfo> _filteredClients;
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
    final digits = _normalizeDigits(query);

    if (query.isEmpty) {
      setState(() {
        _filteredClients = _clients;
        _showSearchHint = false;
      });
      return;
    }

    if (digits.length >= 11) {
      final filtered = _clients
          .where(
            (c) =>
                c.phoneDigits.contains(digits) ||
                c.whatsAppDigits.contains(digits),
          )
          .toList();
      setState(() {
        _filteredClients = filtered;
        _showSearchHint = false;
      });
      return;
    }

    if (query.length >= 4) {
      final lower = query.toLowerCase();
      final filtered = _clients
          .where((c) => c.fullName.toLowerCase().contains(lower))
          .toList();
      setState(() {
        _filteredClients = filtered;
        _showSearchHint = false;
      });
      return;
    }

    setState(() {
      _filteredClients = _clients;
      _showSearchHint = true;
    });
  }

  String _normalizeDigits(String input) => input.replaceAll(RegExp(r'\D'), '');

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
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Header(title: 'Список клиентов', showBackButton: true),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: SearchField(
                        controller: _searchController,
                        hintText: 'Поиск',
                        onChanged: _applyFilter,
                      ),
                    ),
                    const SizedBox(width: 12),
                    AddButton(
                      onPressed: () =>
                          context.pushNamed(Routes.clientCreateScreen.toName),
                    ),
                  ],
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
                    child: ClientInfoCard(
                      fullName: client.fullName,
                      clientId: client.id,
                      birthDate: client.birthDate,
                      phone: client.phone,
                      whatsApp: client.whatsApp,
                      onTap: () => context.pushNamed(
                        Routes.clientDetailScreen.toName,
                        extra: client,
                      ),
                    ),
                  );
                }, childCount: _filteredClients.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class ClientInfo {
  const ClientInfo({
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

const List<ClientInfo> _mockClients = [
  ClientInfo(
    fullName: 'Мирошниченко Владислава Филипповна',
    id: '234',
    birthDate: '12.05.1987',
    phone: '+7(999)999-99-99',
    whatsApp: '+7(999)999-99-99',
  ),
  ClientInfo(
    fullName: 'Антонов Сергей Леонидович',
    id: '235',
    birthDate: '03.11.1990',
    phone: '+7(912)123-45-67',
    whatsApp: '+7(912)123-45-67',
  ),
  ClientInfo(
    fullName: 'Мирошниченко Владислава Филипповна',
    id: '236',
    birthDate: '12.05.1987',
    phone: '+7(900)555-33-22',
    whatsApp: '+7(900)555-33-22',
  ),
  ClientInfo(
    fullName: 'Семенова Алина Викторовна',
    id: '237',
    birthDate: '21.01.1994',
    phone: '+7(995)321-44-55',
    whatsApp: '+7(995)321-44-55',
  ),
  ClientInfo(
    fullName: 'Громов Михаил Сергеевич',
    id: '238',
    birthDate: '09.08.1983',
    phone: '+7(913)876-54-32',
    whatsApp: '+7(913)876-54-32',
  ),
];
