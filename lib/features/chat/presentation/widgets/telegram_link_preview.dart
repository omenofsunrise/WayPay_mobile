import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:url_launcher/url_launcher.dart';

class TelegramLinkPreview extends StatefulWidget {
  final String url;

  const TelegramLinkPreview({super.key, required this.url});

  @override
  State<TelegramLinkPreview> createState() => _TelegramLinkPreviewState();
}

class _TelegramLinkPreviewState extends State<TelegramLinkPreview> {
  String? title;
  String? description;
  String? image;

  @override
  void initState() {
    super.initState();
    _fetchMeta();
  }

  Future<void> _fetchMeta() async {
    try {
      final res = await http.get(Uri.parse(widget.url));
      if (res.statusCode == 200) {
        final document = html.parse(res.body);

        setState(() {
          title =
              document
                  .querySelector('meta[property="og:title"]')
                  ?.attributes['content'] ??
              document.querySelector('title')?.text;

          description =
              document
                  .querySelector('meta[property="og:description"]')
                  ?.attributes['content'] ??
              document
                  .querySelector('meta[name="description"]')
                  ?.attributes['content'];

          image = document
              .querySelector('meta[property="og:image"]')
              ?.attributes['content'];
        });
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> _launch() async {
    final uri = Uri.parse(widget.url);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not launch $uri');
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _launch,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          // убрали фон
          color: Colors.transparent,
          // добавили рамку
          border: Border.all(
            color: const Color(0xFFD1D5DB), // rgba(209,213,219,1)
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // картинка или иконка
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: image != null
                  ? Image.network(
                      image!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain, // помещаем полностью в 60x60
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          color: const Color(0xFFD1D5DB),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.link, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),

            // текст
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  if (description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      widget.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
