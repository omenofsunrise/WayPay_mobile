import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/routes/routes.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class SearchDestination {
  const SearchDestination({
    required this.title,
    required this.route,
    required this.keywords,
  });

  final String title;
  final Routes route;
  final List<String> keywords;

  int matchScore(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return 0;
    final t = title.toLowerCase();
    if (t == q) return 100;
    if (t.startsWith(q)) return 80;
    if (t.contains(q)) return 60;
    var best = 0;
    for (final kw in keywords) {
      final k = kw.toLowerCase();
      if (k == q) {
        if (best < 55) best = 55;
      } else if (k.startsWith(q)) {
        if (best < 45) best = 45;
      } else if (k.contains(q)) {
        if (best < 30) best = 30;
      }
    }
    return best;
  }

  bool matches(String query) => matchScore(query) > 0;
}

class SearchSuggester extends StatefulWidget {
  const SearchSuggester({super.key, required this.destinations});

  final List<SearchDestination> destinations;

  @override
  State<SearchSuggester> createState() => _SearchSuggesterState();
}

class _SearchSuggesterState extends State<SearchSuggester> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _link = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  List<String> _results = [];
  Size? _fieldSize;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _hideOverlay();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureField());
  }

  @override
  void dispose() {
    _hideOverlay();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _measureField() {
    final renderObject = _fieldKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    if (!renderObject.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureField());
      return;
    }
    if (!mounted) return;
    final size = renderObject.size;
    if (_fieldSize == size) return;
    setState(() {
      _fieldSize = size;
    });
  }

  void _onChanged(String raw) {
    final query = raw.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _results = []);
      _hideOverlay();
      return;
    }
    final variants = _expandQueryVariants(query);
    final scored = <MapEntry<SearchDestination, int>>[];
    for (final d in widget.destinations) {
      var best = 0;
      for (final variant in variants) {
        final s = d.matchScore(variant);
        if (s > best) best = s;
      }
      if (best > 0) scored.add(MapEntry(d, best));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    setState(() {
      _results = scored.map((e) => e.key.title).toList();
    });
    _showOverlay();
  }

  void _onSubmit(String raw) {
    final query = raw.trim().toLowerCase();
    if (query.isEmpty) return;
    final variants = _expandQueryVariants(query);
    SearchDestination? best;
    var bestScore = 0;
    for (final d in widget.destinations) {
      for (final variant in variants) {
        final s = d.matchScore(variant);
        if (s > bestScore) {
          bestScore = s;
          best = d;
        }
      }
    }
    if (best == null) return;
    _goTo(best.title, best.route);
  }

  void _goTo(String title, Routes route) {
    context.pushNamed(route.toName);
    setState(() {
      _results = [];
      _controller.clear();
    });
    _hideOverlay();
    FocusScope.of(context).unfocus();
  }

  void _showOverlay() {
    final hasQuery = _controller.text.trim().isNotEmpty;
    if (_results.isEmpty && !hasQuery) {
      _hideOverlay();
      return;
    }
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          offset: Offset(0, (_fieldSize?.height ?? 48) + 6),
          child: Material(
            color: Colors.transparent,
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _fieldSize?.width ?? 360),
                child: _buildResultsCard(),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildResultsCard() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 360),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _results.isEmpty
          ? const ListTile(
              dense: true,
              title: Text(
                'Ничего не найдено',
                style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
              ),
            )
          : Scrollbar(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (_, index) {
                  final text = _results[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(AppColors.black),
                      ),
                    ),
                    onTap: () {
                      final match = widget.destinations.firstWhere(
                        (d) => d.title == text,
                        orElse: () => widget.destinations.first,
                      );
                      _goTo(text, match.route);
                    },
                  );
                },
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: SearchField(
        key: _fieldKey,
        hintText: 'Поиск',
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onChanged,
        onSubmitted: _onSubmit,
        onTap: () {
          if (_controller.text.trim().isNotEmpty) {
            _onChanged(_controller.text);
          }
        },
      ),
    );
  }

  List<String> _expandQueryVariants(String query) {
    final variants = <String>{query};
    final swapped = _swapKeyboardLayout(query);
    variants.add(swapped);
    return variants.toList();
  }

  String _swapKeyboardLayout(String input) {
    const ru = 'ёйцукенгшщзхъфывапролджэячсмитьбю';
    const en = '`qwertyuiop[]asdfghjkl;\'zxcvbnm,.';
    final map = <String, String>{};
    for (var i = 0; i < ru.length && i < en.length; i++) {
      map[ru[i]] = en[i];
      map[en[i]] = ru[i];
      map[ru[i].toUpperCase()] = en[i].toUpperCase();
      map[en[i].toUpperCase()] = ru[i].toUpperCase();
    }
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      buffer.write(map[ch] ?? ch);
    }
    return buffer.toString().toLowerCase();
  }
}
