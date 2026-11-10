import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:waypay_mobile/core/config/api_config.dart';

bool isWhatsAppNotification(String? type) => type == 'whats_app';

bool isAdminWhatsAppNotification(String? type) => type == 'admin_whats_app';

String formatNotificationPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  final normalized =
      digits.length == 11 && (digits.startsWith('7') || digits.startsWith('8'))
      ? digits.substring(1)
      : digits;
  if (normalized.length != 10) return raw;
  return '+7 ${normalized.substring(0, 3)} '
      '${normalized.substring(3, 6)}-${normalized.substring(6, 8)}-'
      '${normalized.substring(8)}';
}

String notificationDisplayTitle(String title, String? type) {
  if (isWhatsAppNotification(type) || isAdminWhatsAppNotification(type)) {
    return formatNotificationPhone(title);
  }
  return title;
}

String? resolveNotificationImageUrl(String? value) {
  final path = value?.trim();
  if (path == null || path.isEmpty) return null;
  final uri = Uri.tryParse(path);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return path;
  }
  return '${ApiConfig.filesBaseUrl}/${path.replaceFirst(RegExp(r'^/+'), '')}';
}

String formatNotificationRelativeTime(DateTime value, {DateTime? now}) {
  final local = value.toLocal();
  final difference = (now ?? DateTime.now()).difference(local);
  if (difference.isNegative || difference.inSeconds < 10) return 'только что';
  if (difference.inMinutes < 1) return '${difference.inSeconds} сек. назад';
  if (difference.inHours < 1) return '${difference.inMinutes} мин. назад';
  if (difference.inDays < 1) return '${difference.inHours} ч. назад';
  if (difference.inDays == 1) return 'вчера';
  if (difference.inDays < 7) return '${difference.inDays} дн. назад';
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day.$month.${local.year}';
}

class NotificationLeading extends StatelessWidget {
  const NotificationLeading({
    super.key,
    required this.title,
    required this.type,
    this.image,
    this.size = 46,
  });

  final String title;
  final String? type;
  final String? image;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (isAdminWhatsAppNotification(type)) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFF25D366)],
          ),
        ),
        child: const Icon(Icons.campaign_outlined, color: Colors.white),
      );
    }
    if (isWhatsAppNotification(type)) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF25D366),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.chat_outlined, color: Colors.white),
      );
    }

    final imageUrl = resolveNotificationImageUrl(image);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFF00858E),
      backgroundImage: imageUrl == null
          ? null
          : CachedNetworkImageProvider(imageUrl),
      child: imageUrl == null
          ? Text(
              _initials(title),
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.34,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );
  }

  static String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .toList();
    if (words.isEmpty) return 'У';
    return words.map((word) => word[0].toUpperCase()).join();
  }
}

class NotificationLinkText extends StatefulWidget {
  const NotificationLinkText(
    this.text, {
    super.key,
    required this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.onLinkTap,
  });

  final String text;
  final TextStyle style;
  final TextStyle? linkStyle;
  final int? maxLines;
  final TextOverflow overflow;
  final Future<void> Function(Uri uri)? onLinkTap;

  @override
  State<NotificationLinkText> createState() => _NotificationLinkTextState();
}

class _NotificationLinkTextState extends State<NotificationLinkText> {
  final List<TapGestureRecognizer> _recognizers = [];
  late List<InlineSpan> _spans;

  @override
  void initState() {
    super.initState();
    _spans = _buildSpans();
  }

  @override
  void didUpdateWidget(covariant NotificationLinkText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.linkStyle != widget.linkStyle ||
        oldWidget.onLinkTap != widget.onLinkTap) {
      _disposeRecognizers();
      _spans = _buildSpans();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  List<InlineSpan> _buildSpans() {
    final spans = <InlineSpan>[];
    final expression = RegExp(r'https?://[^\s]+');
    var offset = 0;
    for (final match in expression.allMatches(widget.text)) {
      if (match.start > offset) {
        spans.add(TextSpan(text: widget.text.substring(offset, match.start)));
      }
      final rawUrl = match.group(0)!;
      final uri = Uri.parse(rawUrl);
      final recognizer = TapGestureRecognizer()
        ..onTap = () async {
          final callback = widget.onLinkTap;
          if (callback != null) {
            await callback(uri);
          } else {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        };
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: rawUrl,
          style:
              widget.linkStyle ??
              widget.style.copyWith(
                color: const Color(0xFF00858E),
                decoration: TextDecoration.underline,
              ),
          recognizer: recognizer,
        ),
      );
      offset = match.end;
    }
    if (offset < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(offset)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (_recognizers.isEmpty) {
      return Text(
        widget.text,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }
    return Text.rich(
      TextSpan(style: widget.style, children: _spans),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
