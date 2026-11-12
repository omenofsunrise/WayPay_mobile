import 'package:waypay_mobile/blacklist_plus/features/templates/data/document_template.dart';
import 'package:waypay_mobile/blacklist_plus/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Header(
              title: 'Шаблоны документов',
              showBackButton: true,
              showNotifications: false,
              showAvatar: false,
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _DisclaimerBanner(),
            const SizedBox(height: 16),
            for (final template in kDocumentTemplates) ...[
              _TemplateCard(
                template: template,
                onTap: () => context.pushNamed(
                  Routes.templateDetailScreen.toName,
                  extra: template,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF92400E), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Документы являются шаблонами-заготовками для самостоятельного '
              'заполнения и не заменяют юридическую консультацию. '
              'Юридическую силу приобретают после собственноручного подписания '
              'сторонами на бумажном носителе.',
              style: AppStyle.manrope(
                size: 12,
                weight: FontWeight.w400,
                height: 1.45,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final DocumentTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return WayPayEntityCard(
      title: template.title,
      subtitle: template.shortDescription,
      leading: const WayPayIconBadge(icon: Icons.description_outlined),
      details: const [WayPayInfoItem(label: 'Формат', value: 'Word (.docx)')],
      detailColumns: 1,
      onTap: onTap,
    );
  }
}
