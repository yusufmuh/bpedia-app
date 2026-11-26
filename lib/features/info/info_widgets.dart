/// Bagian bersama halaman info: artikel bertajuk (S&K, Privasi), tanya-jawab
/// lipat, dan pembuka tautan luar dengan pesan galat.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_scope.dart';
import '../../design/design.dart';
import '../account/account_ui.dart';

/// Satu bagian artikel: judul + paragraf dan/atau butir.
final class ArticleSection {
  const ArticleSection({
    required this.title,
    this.paragraphs = const <String>[],
    this.bullets = const <String>[],
  });

  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
}

/// Halaman artikel panjang (S&K, Kebijakan Privasi) dengan daftar isi
/// "Isi dokumen" yang menggulir ke tiap bagian.
class ArticlePage extends StatefulWidget {
  const ArticlePage({
    super.key,
    required this.title,
    required this.heading,
    required this.updated,
    required this.intro,
    required this.sections,
  });

  /// Judul bilah atas.
  final String title;

  /// Judul besar di awal artikel.
  final String heading;

  /// Keterangan versi, mis. "Berlaku sejak 25 Nov 2026".
  final String updated;
  final String intro;
  final List<ArticleSection> sections;

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  late final List<GlobalKey> _keys = List<GlobalKey>.generate(
    widget.sections.length,
    (i) => GlobalKey(debugLabel: 'article-section-${i + 1}'),
  );

  Future<void> _jumpTo(int index) async {
    final target = _keys[index].currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: BpMotion.reduced(context)
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    final sections = widget.sections;
    return Scaffold(
      backgroundColor: c.surface,
      appBar: BpAppBar(title: widget.title),
      body: ListView(
        // Semua bagian dibangun supaya daftar isi bisa menggulir ke sana.
        cacheExtent: 100000,
        padding: const EdgeInsets.fromLTRB(
          BpSpace.screen,
          BpSpace.x4,
          BpSpace.screen,
          BpSpace.x8,
        ),
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              widget.heading,
              style: BpText.titleL.copyWith(color: c.text),
            ),
          ),
          const SizedBox(height: BpSpace.x1),
          Text(
            widget.updated,
            style: BpText.caption.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: BpSpace.x4),
          NoteBox(
            tone: StatusTone.gold,
            icon: LucideIcons.flaskConical,
            title: 'Dokumen demo',
            message: widget.intro,
          ),
          const SizedBox(height: BpSpace.x5),
          _TableOfContents(sections: sections, onSelected: _jumpTo),
          for (var i = 0; i < sections.length; i++)
            _ArticleBlock(key: _keys[i], number: i + 1, section: sections[i]),
        ],
      ),
    );
  }
}

/// Kartu "Isi dokumen": daftar bagian bernomor yang bisa diketuk.
class _TableOfContents extends StatelessWidget {
  const _TableOfContents({required this.sections, required this.onSelected});

  final List<ArticleSection> sections;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'Isi dokumen',
            style: BpText.title.copyWith(color: c.text),
          ),
        ),
        const SizedBox(height: BpSpace.x2),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BpRadius.cardAll,
            border: Border.all(color: c.line),
          ),
          child: Column(
            children: <Widget>[
              for (var i = 0; i < sections.length; i++) ...<Widget>[
                if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
                BpTappable(
                  key: ValueKey<String>('toc-${i + 1}'),
                  onTap: () => onSelected(i),
                  semanticLabel: 'Bagian ${i + 1}, ${sections[i].title}',
                  focusRadius: BpRadius.cardAll,
                  pressScale: false,
                  builder: (context, states) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BpSpace.x3,
                      vertical: BpSpace.x3,
                    ),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${i + 1}',
                            style: BpText.bodyS.copyWith(
                              color: c.brandStrong,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            sections[i].title,
                            style: BpText.body.copyWith(color: c.text),
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 18,
                          color: c.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ArticleBlock extends StatelessWidget {
  const _ArticleBlock({super.key, required this.number, required this.section});

  final int number;
  final ArticleSection section;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Padding(
      padding: const EdgeInsets.only(top: BpSpace.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            label: '$number. ${section.title}',
            excludeSemantics: true,
            child: Row(
              children: <Widget>[
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.brandTint,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: BpText.label.copyWith(color: c.brandStrong),
                  ),
                ),
                const SizedBox(width: BpSpace.x2),
                Expanded(
                  child: Text(
                    section.title,
                    style: BpText.title.copyWith(color: c.text),
                  ),
                ),
              ],
            ),
          ),
          for (final paragraph in section.paragraphs)
            Padding(
              padding: const EdgeInsets.only(top: BpSpace.x2),
              child: Text(
                paragraph,
                style: BpText.body.copyWith(color: c.text),
              ),
            ),
          for (final bullet in section.bullets)
            Padding(
              padding: const EdgeInsets.only(top: BpSpace.x2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: BpSpace.x2),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: c.brand,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      bullet,
                      style: BpText.body.copyWith(color: c.text),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Satu tanya-jawab. [topic] mengelompokkan jawaban (mis. `HelpTopic`).
final class FaqItem {
  const FaqItem(this.question, this.answer, {this.topic});

  final String question;
  final String answer;
  final Object? topic;
}

/// Daftar tanya-jawab yang bisa dibuka satu per satu.
class FaqList extends StatelessWidget {
  const FaqList({super.key, required this.items});

  final List<FaqItem> items;

  @override
  Widget build(BuildContext context) {
    final c = context.bp;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < items.length; i++) ...<Widget>[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: BpSpace.screen,
                endIndent: BpSpace.screen,
                color: c.line,
              ),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: BpSpace.screen,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                BpSpace.screen,
                0,
                BpSpace.screen,
                BpSpace.x4,
              ),
              expandedAlignment: Alignment.centerLeft,
              iconColor: c.brand,
              collapsedIconColor: c.textMuted,
              title: Text(
                items[i].question,
                style: BpText.subtitle.copyWith(color: c.text),
              ),
              children: <Widget>[
                Text(
                  items[i].answer,
                  style: BpText.body.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Membuka tautan luar lewat [open]; bila gagal, menampilkan [fallback].
Future<void> openExternal(
  BuildContext context,
  Future<bool> Function() open, {
  required String fallback,
}) async {
  final services = AppScope.of(context);
  services.haptics.selection();
  final opened = await open();
  if (!opened && context.mounted) showAppSnack(context, fallback);
}
