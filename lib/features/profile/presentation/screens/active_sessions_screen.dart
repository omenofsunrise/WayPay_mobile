import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay/features/auth/data/models/session_model.dart';
import 'package:waypay/routes/routes.dart';

class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  final _auth = getIt<AuthRemoteDataSource>();
  final _tokenStorage = TokenStorage();
  final _fmt = DateFormat('dd-MM-yyyy');

  bool _loading = true;
  String? _error;
  List<SessionModel> _sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessions = await _auth.getSessions();
      setState(() => _sessions = sessions);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revoke(SessionModel s) async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(AppColors.background),
        title: const Text('Завершить сессию?'),
        content: Text(
          s.isCurrentSession
              ? 'Вы собираетесь завершить ТЕКУЩУЮ сессию. После этого потребуется повторный вход.'
              : 'Вы уверены, что хотите завершить выбранную сессию?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Завершить')),
        ],
      ),
    );
    if (agreed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _auth.revokeSession(s.id);

      if (s.isCurrentSession) {
        await _tokenStorage.clearAll();
        if (!mounted) return;
        Navigator.pop(context);
        context.goNamed(Routes.phoneAuthScreen.toName);
        return;
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сессия завершена')));
      _load();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка завершения: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final teal = const Color(AppColors.primary);

    return Scaffold(
      backgroundColor: Color(AppColors.background),
      appBar: AppBar(
        title: const Text('Активные сессии'),
        backgroundColor: Color(AppColors.background),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _loading ? null : _load,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Color(AppColors.greyLight),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Обновить'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 46),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _load, child: const Text('Повторить')),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _SessionCard(
                  s: _sessions[i],
                  onRevoke: () => _revoke(_sessions[i]),
                  dateFmt: _fmt,
                  accentColor: teal,
                ),
              ),
            ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionModel s;
  final VoidCallback onRevoke;
  final DateFormat dateFmt;
  final Color accentColor;

  const _SessionCard({required this.s, required this.onRevoke, required this.dateFmt, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final stripeColor = s.isCurrentSession ? accentColor : Colors.transparent;
    const double minCardHeight = 116;

    final grey = Colors.grey.shade600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Левая цветная полоска
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: stripeColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
              ),
            ),

            // Контент + кнопка снизу на всю ширину
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: minCardHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок с IP и бейджем "Текущая"
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'IP: ${s.ipAddress}',
                              style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (s.isCurrentSession)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Текущая',
                                style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Тексты
                      Text(
                        'Создана: ${dateFmt.format(s.createdAt.toLocal())}',
                        style: TextStyle(fontSize: 14, color: grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Последняя активность: ${dateFmt.format(s.lastUsedAt.toLocal())}',
                        style: TextStyle(fontSize: 14, color: grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Истекает: ${dateFmt.format(s.expiresAt.toLocal())}',
                        style: TextStyle(fontSize: 14, color: grey),
                      ),

                      const SizedBox(height: 16),

                      // Кнопка во всю ширину под текстом
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onRevoke,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(s.isCurrentSession ? 'Завершить текущую сессию' : 'Завершить'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
