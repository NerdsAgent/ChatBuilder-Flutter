import 'package:flutter/material.dart';
import '../../models/chat_widget_config.dart';
import '../../utils/text_style_helper.dart';

/// Lightweight, dependency-free markdown-to-widget renderer for plain-text
/// agent messages that use markdown syntax but contain no real HTML tags.
/// Ported from the nerdagent app's ChatMarkdownText, retargeted to
/// ChatWidgetConfig/TextStyleHelper so the package stays dependency-free.
///
/// Supported syntax:
///   **bold** / __bold__        -> bold
///   *italic* / _italic_        -> italic
///   ***bold italic***          -> bold + italic
///   `inline code`              -> inline code chip
///   ```lang\n...\n```          -> fenced code block
///   # / ## / ### ... heading   -> headings (levels 1-6)
///   - / * / + item              -> bullet list
///   1. item                     -> numbered list
///   > quote                     -> blockquote
///   ---                         -> horizontal rule
///   | a | b |                   -> table
///   [text](url)                 -> styled link (visual only, not tappable)
class ChatMarkdownText extends StatelessWidget {
  final String data;
  final TextStyle baseStyle;
  final ChatWidgetConfig config;

  const ChatMarkdownText({
    Key? key,
    required this.data,
    required this.baseStyle,
    required this.config,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final blocks = _parseMarkdownBlocks(data);

    if (blocks.isEmpty) {
      return SelectableText(data, style: baseStyle);
    }

    final children = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      children.add(_buildBlock(blocks[i]));
      if (i != blocks.length - 1) {
        children.add(SizedBox(
          height: blocks[i].type == _MdBlockType.heading ? 6 : 8,
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  // ── Block rendering ──────────────────────────────────────────────────────

  Widget _buildBlock(_MdBlock block) {
    switch (block.type) {
      case _MdBlockType.heading:
        const sizes = {1: 20.0, 2: 18.0, 3: 16.5, 4: 15.5, 5: 15.0, 6: 14.5};
        final headingStyle = baseStyle.copyWith(
          fontSize: sizes[block.level] ?? 15,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        );
        return SelectableText.rich(
          TextSpan(
            style: headingStyle,
            children: _parseInline(block.text, headingStyle),
          ),
        );

      case _MdBlockType.paragraph:
        return SelectableText.rich(
          TextSpan(
            style: baseStyle,
            children: _parseInline(block.text, baseStyle),
          ),
        );

      case _MdBlockType.ulist:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: block.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1, right: 6),
                    child: Text('•',
                        style: baseStyle.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: SelectableText.rich(
                      TextSpan(
                        style: baseStyle,
                        children: _parseInline(item, baseStyle),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );

      case _MdBlockType.olist:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(block.items.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1, right: 6),
                    child: Text('${i + 1}.',
                        style: baseStyle.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: SelectableText.rich(
                      TextSpan(
                        style: baseStyle,
                        children: _parseInline(block.items[i], baseStyle),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );

      case _MdBlockType.code:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              block.text,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.4,
                color: Color(0xFFE8E8E8),
              ),
            ),
          ),
        );

      case _MdBlockType.quote:
        final quoteStyle = baseStyle.copyWith(
          color: Colors.black54,
          fontStyle: FontStyle.italic,
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                  color: config.primaryColor.withOpacity(0.5), width: 3),
            ),
            color: config.primaryColor.withOpacity(0.05),
          ),
          child: SelectableText.rich(
            TextSpan(
              style: quoteStyle,
              children: _parseInline(block.text, quoteStyle),
            ),
          ),
        );

      case _MdBlockType.hr:
        return Container(height: 1, color: Colors.grey[300]);

      case _MdBlockType.table:
        final rows = block.tableRows;
        if (rows.isEmpty) return const SizedBox.shrink();
        final header = rows.first;
        final body = rows.skip(1).toList();
        final columnCount = header.length;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 0),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(
                color: Colors.grey.shade300,
                width: 1,
                borderRadius: BorderRadius.circular(6),
              ),
              columnWidths: {
                for (int c = 0; c < columnCount; c++)
                  c: const IntrinsicColumnWidth(),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: config.primaryColor.withOpacity(0.08),
                  ),
                  children: header
                      .map((cell) => _tableCell(cell, isHeader: true))
                      .toList(),
                ),
                for (int r = 0; r < body.length; r++)
                  TableRow(
                    decoration: BoxDecoration(
                      color: r.isOdd ? Colors.grey.shade50 : Colors.white,
                    ),
                    children: List.generate(columnCount, (c) {
                      final text = c < body[r].length ? body[r][c] : '';
                      return _tableCell(text, isHeader: false);
                    }),
                  ),
              ],
            ),
          ),
        );
    }
  }

  Widget _tableCell(String text, {required bool isHeader}) {
    final cellStyle = baseStyle.copyWith(
      fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
      fontSize: (baseStyle.fontSize ?? 14) - 1,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: SelectableText.rich(
        TextSpan(style: cellStyle, children: _parseInline(text, cellStyle)),
      ),
    );
  }

  // ── Inline parsing (bold / italic / code / links) ───────────────────────

  static final RegExp _inlinePattern = RegExp(
    r'(\*\*\*(.+?)\*\*\*)'      // 1,2  ***bold italic***
    r'|(\*\*(.+?)\*\*)'         // 3,4  **bold**
    r'|(__(.+?)__)'             // 5,6  __bold__
    r'|(\*(.+?)\*)'             // 7,8  *italic*
    r'|(_(.+?)_)'               // 9,10 _italic_
    r'|(`([^`]+?)`)'            // 11,12 `code`
    r'|(\[([^\]]+?)\]\(([^)]+?)\))', // 13,14,15 [text](url)
  );

  List<InlineSpan> _parseInline(String text, TextStyle style) {
    final spans = <InlineSpan>[];
    int last = 0;

    for (final m in _inlinePattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start), style: style));
      }

      if (m.group(1) != null) {
        spans.add(TextSpan(
          text: m.group(2),
          style: style.copyWith(
              fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
        ));
      } else if (m.group(3) != null) {
        spans.add(TextSpan(
            text: m.group(4), style: style.copyWith(fontWeight: FontWeight.w700)));
      } else if (m.group(5) != null) {
        spans.add(TextSpan(
            text: m.group(6), style: style.copyWith(fontWeight: FontWeight.w700)));
      } else if (m.group(7) != null) {
        spans.add(TextSpan(
            text: m.group(8), style: style.copyWith(fontStyle: FontStyle.italic)));
      } else if (m.group(9) != null) {
        spans.add(TextSpan(
            text: m.group(10), style: style.copyWith(fontStyle: FontStyle.italic)));
      } else if (m.group(11) != null) {
        spans.add(TextSpan(
          text: m.group(12),
          style: style.copyWith(
            fontFamily: 'monospace',
            fontSize: (style.fontSize ?? 14) - 1,
            backgroundColor: const Color(0xFFF0F0F0),
            color: const Color(0xFFD6336C),
          ),
        ));
      } else if (m.group(13) != null) {
        spans.add(TextSpan(
          text: m.group(14),
          style: style.copyWith(
              color: config.accentColor, decoration: TextDecoration.underline),
        ));
      }

      last = m.end;
    }

    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: style));
    }
    return spans;
  }
}

// ── Block model + parser ────────────────────────────────────────────────────

enum _MdBlockType { paragraph, heading, ulist, olist, code, quote, hr, table }

class _MdBlock {
  final _MdBlockType type;
  final String text;
  final List<String> items;
  final int level;
  final String? codeLang;
  final List<List<String>> tableRows;

  _MdBlock.paragraph(this.text)
      : type = _MdBlockType.paragraph,
        items = const [],
        level = 0,
        codeLang = null,
        tableRows = const [];
  _MdBlock.heading(this.text, this.level)
      : type = _MdBlockType.heading,
        items = const [],
        codeLang = null,
        tableRows = const [];
  _MdBlock.ulist(this.items)
      : type = _MdBlockType.ulist,
        text = '',
        level = 0,
        codeLang = null,
        tableRows = const [];
  _MdBlock.olist(this.items)
      : type = _MdBlockType.olist,
        text = '',
        level = 0,
        codeLang = null,
        tableRows = const [];
  _MdBlock.code(this.text, this.codeLang)
      : type = _MdBlockType.code,
        items = const [],
        level = 0,
        tableRows = const [];
  _MdBlock.quote(this.text)
      : type = _MdBlockType.quote,
        items = const [],
        level = 0,
        codeLang = null,
        tableRows = const [];
  _MdBlock.hr()
      : type = _MdBlockType.hr,
        text = '',
        items = const [],
        level = 0,
        codeLang = null,
        tableRows = const [];
  _MdBlock.table(this.tableRows)
      : type = _MdBlockType.table,
        text = '',
        items = const [],
        level = 0,
        codeLang = null;
}

final RegExp _fenceOpenRe = RegExp(r'^\s*```(\w*)\s*$');
final RegExp _fenceCloseRe = RegExp(r'^\s*```\s*$');
final RegExp _hrRe = RegExp(r'^\s*(-{3,}|\*{3,}|_{3,})\s*$');
final RegExp _headingRe = RegExp(r'^(#{1,6})\s+(.*)$');
final RegExp _quoteRe = RegExp(r'^\s*>\s?');
final RegExp _ulistRe = RegExp(r'^\s*[-*+]\s+.+$');
final RegExp _ulistStripRe = RegExp(r'^\s*[-*+]\s+');
final RegExp _olistRe = RegExp(r'^\s*\d+\.\s+.+$');
final RegExp _olistStripRe = RegExp(r'^\s*\d+\.\s+');

final RegExp _tableRowRe = RegExp(r'^\s*\|.*\|\s*$');
final RegExp _tableSeparatorRe =
    RegExp(r'^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)+\|?\s*$');

List<String> _splitTableRow(String line) {
  var trimmed = line.trim();
  if (trimmed.startsWith('|')) trimmed = trimmed.substring(1);
  if (trimmed.endsWith('|')) trimmed = trimmed.substring(0, trimmed.length - 1);
  return trimmed.split('|').map((c) => c.trim()).toList();
}

List<_MdBlock> _parseMarkdownBlocks(String source) {
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final blocks = <_MdBlock>[];
  final paragraphBuffer = <String>[];
  int i = 0;

  void flushParagraph() {
    if (paragraphBuffer.isNotEmpty) {
      final joined = paragraphBuffer.join('\n').trim();
      if (joined.isNotEmpty) blocks.add(_MdBlock.paragraph(joined));
      paragraphBuffer.clear();
    }
  }

  while (i < lines.length) {
    final line = lines[i];
    final trimmed = line.trimRight();

    final fenceMatch = _fenceOpenRe.firstMatch(trimmed);
    if (fenceMatch != null) {
      flushParagraph();
      final lang = fenceMatch.group(1);
      final codeLines = <String>[];
      i++;
      while (i < lines.length && !_fenceCloseRe.hasMatch(lines[i])) {
        codeLines.add(lines[i]);
        i++;
      }
      blocks.add(_MdBlock.code(
          codeLines.join('\n'), (lang?.isNotEmpty ?? false) ? lang : null));
      i++;
      continue;
    }

    if (_hrRe.hasMatch(trimmed)) {
      flushParagraph();
      blocks.add(_MdBlock.hr());
      i++;
      continue;
    }

    final headingMatch = _headingRe.firstMatch(trimmed);
    if (headingMatch != null) {
      flushParagraph();
      blocks.add(_MdBlock.heading(
          headingMatch.group(2)!.trim(), headingMatch.group(1)!.length));
      i++;
      continue;
    }

    if (_quoteRe.hasMatch(line)) {
      flushParagraph();
      final quoteLines = <String>[];
      while (i < lines.length && _quoteRe.hasMatch(lines[i])) {
        quoteLines.add(lines[i].replaceFirst(_quoteRe, ''));
        i++;
      }
      blocks.add(_MdBlock.quote(quoteLines.join('\n')));
      continue;
    }

    if (_tableRowRe.hasMatch(line) &&
        i + 1 < lines.length &&
        _tableSeparatorRe.hasMatch(lines[i + 1])) {
      flushParagraph();
      final headerCells = _splitTableRow(line);
      i += 2;
      final bodyRows = <List<String>>[];
      while (i < lines.length && _tableRowRe.hasMatch(lines[i])) {
        bodyRows.add(_splitTableRow(lines[i]));
        i++;
      }
      blocks.add(_MdBlock.table([headerCells, ...bodyRows]));
      continue;
    }

    if (_ulistRe.hasMatch(line)) {
      flushParagraph();
      final items = <String>[];
      while (i < lines.length && _ulistRe.hasMatch(lines[i])) {
        items.add(lines[i].replaceFirst(_ulistStripRe, ''));
        i++;
      }
      blocks.add(_MdBlock.ulist(items));
      continue;
    }

    if (_olistRe.hasMatch(line)) {
      flushParagraph();
      final items = <String>[];
      while (i < lines.length && _olistRe.hasMatch(lines[i])) {
        items.add(lines[i].replaceFirst(_olistStripRe, ''));
        i++;
      }
      blocks.add(_MdBlock.olist(items));
      continue;
    }

    if (trimmed.isEmpty) {
      flushParagraph();
      i++;
      continue;
    }

    paragraphBuffer.add(line);
    i++;
  }

  flushParagraph();
  return blocks;
}