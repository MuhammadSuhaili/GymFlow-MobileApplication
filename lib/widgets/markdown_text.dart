import 'package:flutter/material.dart';

/// Lightweight markdown renderer for chat bubbles: bold, italic, inline code,
/// fenced code blocks, headers, bullet/numbered lists, links and horizontal
/// rules.
class MarkdownText extends StatelessWidget {
  const MarkdownText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final blocks = _Parser(data).parse();
    if (blocks.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linkColor = isDark ? Colors.lightBlueAccent : Colors.blue.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks)
          _block(context, base, block, linkColor: linkColor),
      ],
    );
  }

  Widget _block(
    BuildContext context,
    TextStyle base,
    _Block block, {
    required Color linkColor,
  }) {
    switch (block.type) {
      case _BlockType.header:
        final style = base.copyWith(
          fontWeight: block.level <= 2 ? FontWeight.w800 : FontWeight.w700,
          fontSize: (base.fontSize ?? 14) +
              (block.level == 1 ? 3 : block.level == 2 ? 2 : 1),
        );
        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 3),
          child: RichText(
            textAlign: textAlign ?? TextAlign.start,
            text: TextSpan(
              style: style,
              children: _inline(block.text, style, linkColor),
            ),
          ),
        );
      case _BlockType.bullet:
        return _listRow(
          base,
          Text('•  ', style: base.copyWith(fontWeight: FontWeight.w800)),
          _inline(block.text, base, linkColor),
          linkColor,
        );
      case _BlockType.numbered:
        return _listRow(
          base,
          Text('${block.level}.  ',
              style: base.copyWith(fontWeight: FontWeight.w700)),
          _inline(block.text, base, linkColor),
          linkColor,
        );
      case _BlockType.code:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: base.color!.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              block.text,
              style: base.copyWith(
                fontFamily: 'monospace',
                fontSize: (base.fontSize ?? 14) - 1,
              ),
            ),
          ),
        );
      case _BlockType.rule:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(
            height: 1,
            thickness: 1,
            color: base.color!.withValues(alpha: 0.3),
          ),
        );
      case _BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: RichText(
            textAlign: textAlign ?? TextAlign.start,
            text: TextSpan(
              style: base,
              children: _inline(block.text, base, linkColor),
            ),
          ),
        );
    }
  }

  Widget _listRow(
    TextStyle base,
    Widget prefix,
    List<InlineSpan> children,
    Color linkColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          prefix,
          Expanded(
            child: RichText(
              textAlign: textAlign ?? TextAlign.start,
              text: TextSpan(style: base, children: children),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _inline(String text, TextStyle base, Color linkColor) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(
      r'(`[^`]+`|\*\*[^*]+\*\*|\*[^*]+\*|\[[^\]]+\]\([^)\s]+\))',
    );
    var last = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final token = m.group(0)!;
      if (token.startsWith('`') && token.endsWith('`')) {
        final content = token.substring(1, token.length - 1);
        spans.add(TextSpan(
          text: content,
          style: base.copyWith(
            fontFamily: 'monospace',
            fontSize: (base.fontSize ?? 14) * 0.92,
            backgroundColor: base.color!.withValues(alpha: 0.12),
          ),
        ));
      } else if (token.startsWith('**')) {
        final content = token.substring(2, token.length - 2);
        final bold = base.copyWith(fontWeight: FontWeight.w700);
        spans.add(TextSpan(style: bold, children: _inline(content, bold, linkColor)));
      } else if (token.startsWith('*')) {
        final content = token.substring(1, token.length - 1);
        final italic = base.copyWith(fontStyle: FontStyle.italic);
        spans.add(TextSpan(style: italic, children: _inline(content, italic, linkColor)));
      } else {
        final match = _linkPattern.firstMatch(token);
        if (match != null) {
          final linkStyle = base.copyWith(
            color: linkColor,
            decoration: TextDecoration.underline,
          );
          spans.add(TextSpan(
            style: linkStyle,
            children: _inline(match.group(1)!, linkStyle, linkColor),
          ));
        } else {
          spans.add(TextSpan(text: token));
        }
      }
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return spans;
  }

  static final RegExp _linkPattern = RegExp(r'^\[([^\]]+)\]\(([^)\s]+)\)$');
}

enum _BlockType { paragraph, header, bullet, numbered, code, rule }

class _Block {
  final _BlockType type;
  final String text;
  final int level;

  const _Block(this.type, this.text, {this.level = 0});
}

class _Parser {
  _Parser(this.input);

  final String input;

  static final RegExp _header = RegExp(r'^(#{1,6})\s+(.*)$');
  static final RegExp _bullet = RegExp(r'^\s*([-*+]|\u2022)\s+(.*)$');
  static final RegExp _numbered = RegExp(r'^\s*(\d+)[.)]\s+(.*)$');
  static final RegExp _rule = RegExp(r'^-{3,}$');

  List<_Block> parse() {
    final blocks = <_Block>[];
    final paragraph = <String>[];
    final lines = input.split('\n');
    var inCode = false;
    var code = <String>[];

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      blocks.add(_Block(_BlockType.paragraph, paragraph.join(' ')));
      paragraph.clear();
    }

    void closeCode() {
      blocks.add(_Block(_BlockType.code, code.join('\n')));
      code = <String>[];
      inCode = false;
    }

    for (final raw in lines) {
      if (inCode) {
        if (raw.trim().startsWith('```')) {
          closeCode();
        } else {
          code.add(raw);
        }
        continue;
      }

      if (raw.trim().startsWith('```')) {
        flushParagraph();
        inCode = true;
        continue;
      }

      final trimmed = raw.trim();
      if (trimmed.isEmpty) {
        flushParagraph();
        continue;
      }

      final h = _header.firstMatch(raw);
      if (h != null) {
        flushParagraph();
        blocks.add(_Block(
          _BlockType.header,
          h.group(2)!,
          level: h.group(1)!.length,
        ));
        continue;
      }

      if (_rule.hasMatch(trimmed)) {
        flushParagraph();
        blocks.add(const _Block(_BlockType.rule, ''));
        continue;
      }

      final b = _bullet.firstMatch(raw);
      if (b != null) {
        flushParagraph();
        blocks.add(_Block(_BlockType.bullet, b.group(2)!));
        continue;
      }

      final n = _numbered.firstMatch(raw);
      if (n != null) {
        flushParagraph();
        blocks.add(_Block(
          _BlockType.numbered,
          n.group(2)!,
          level: int.tryParse(n.group(1)!) ?? 1,
        ));
        continue;
      }

      paragraph.add(trimmed);
    }

    flushParagraph();
    if (inCode && code.isNotEmpty) closeCode();
    return blocks;
  }
}