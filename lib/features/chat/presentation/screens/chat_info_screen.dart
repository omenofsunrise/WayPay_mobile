import 'package:flutter/material.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/helpers.dart';
import 'package:waypay/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay/features/chat/presentation/widgets/employes_tab_content.dart';
import 'package:waypay/features/chat/presentation/widgets/files_tab_content.dart';
import 'package:waypay/features/chat/presentation/widgets/links_tab_content.dart';
import 'package:waypay/features/chat/presentation/widgets/photo_tab_content.dart';
import 'package:waypay/features/chat/presentation/widgets/video_tab_content.dart';
import 'package:waypay/features/profile/data/data_sources/employee_remote_data_source.dart';
import 'package:waypay/features/profile/data/models/employee.dart';
import 'package:waypay/features/profile/presentation/screens/profile_screen.dart';

class ChatInfoScreen extends StatefulWidget {
  final bool isGroup;
  final int id;
  final String chanName;
  final String? avatarPath;
  final String? membersCount;
  final int? empId;
  const ChatInfoScreen({
    super.key,
    required this.isGroup,
    required this.chanName,
    this.avatarPath,
    this.membersCount,
    this.empId,
    required this.id,
  });

  @override
  State<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> {
  final List<ProfileTabItem> _tabItems = [];
  Employee? _currentEmployee;
  Employee? _employee;

  bool _isLoadingEmployee = false;

  int _selectedIndex = 0;
  @override
  void initState() {
    super.initState();

    if (!widget.isGroup && widget.empId != null) {
      _loadEmployee();
    }

    // Инициализация вкладок
    if (widget.isGroup) {
      _tabItems.add(
        ProfileTabItem(
          title: 'Участники',
          content: EmployesTabContent(chatId: widget.id),
        ),
      );
    }
    _tabItems.add(
      ProfileTabItem(
        title: 'Фотографии',
        content: PhotosTabContent(chatId: widget.id),
      ),
    );
    _tabItems.add(
      ProfileTabItem(
        title: 'Файлы',
        content: FilesTabContent(chatId: widget.id),
      ),
    );
    _tabItems.add(
      ProfileTabItem(
        title: 'Видео',
        content: VideosTabContent(chatId: widget.id),
      ),
    );
    _tabItems.add(
      ProfileTabItem(
        title: 'Ссылки',
        content: LinksTabContent(chatId: widget.id),
      ),
    );
  }

  Future<void> _loadEmployee() async {
    setState(() => _isLoadingEmployee = true);

    try {
      final dataSource = getIt<EmployeeRemoteDataSource>();
      final dataSourceAuth = getIt<AuthRemoteDataSource>();
      final employeeMap = await dataSource.getEmployeeById(widget.empId!);
      final info = await dataSourceAuth.getAuthInfo();
      final employeeJson = info['employee'] as Map<String, dynamic>?;
      setState(() {
        _currentEmployee = employeeJson != null ? Employee.fromJson(employeeJson) : null;
        _employee = Employee.fromJson(employeeMap);
      });
    } catch (e) {
      print('Ошибка загрузки сотрудника: $e');
    } finally {
      setState(() => _isLoadingEmployee = false);
    }
  }

  Widget _buildTabItem(int index) {
    final bool isSelected = index == _selectedIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Opacity(
        opacity: 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          decoration: BoxDecoration(
            color: isSelected ? Color(AppColors.tabSelected) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(_tabItems[index].title, style: AppStyle.manrope(size: 14, weight: FontWeight.w400)),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(int index) => _tabItems[index].content;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.background),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close)),
          ),
          buildAvatar(fullName: widget.chanName, radius: 65, photoPath: widget.avatarPath),
          const SizedBox(height: 16),
          Text(widget.chanName, style: AppStyle.manrope(size: 18, weight: FontWeight.w500)),
          if (widget.isGroup) ...[
            const SizedBox(height: 8),
            Text(widget.membersCount ?? '', style: AppStyle.manrope(size: 14, weight: FontWeight.w400)),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          if (!widget.isGroup && _employee != null && _employee?.id != _currentEmployee?.id) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: Row(
                spacing: 12,
                children: [
                  Icon(Icons.person),
                  Text(_employee!.role.toLabel(), style: AppStyle.manrope(size: 14, weight: FontWeight.w400)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: Row(
                spacing: 12,
                children: [
                  Icon(Icons.phone),
                  Text(_employee!.phone, style: AppStyle.manrope(size: 14, weight: FontWeight.w400)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  _tabItems.length,
                  (index) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _buildTabItem(index)),
                ),
              ),
            ),
          ),
          Expanded(child: _buildTabContent(_selectedIndex)),
        ],
      ),
    );
  }
}
