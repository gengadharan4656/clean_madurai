import 'package:flutter/material.dart';
import 'waste_chatbot_engine.dart';
import '../../i18n/strings.dart';

class AssistantOverlay extends StatefulWidget {
  const AssistantOverlay({super.key});
  @override
  State<AssistantOverlay> createState() => _AssistantOverlayState();
}

class _AssistantOverlayState extends State<AssistantOverlay> {
  bool _open = false;

  @override
  void initState() {
    super.initState();
    // Preload once (important) - after first frame so context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WasteChatbotEngine.load().then((_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Floating button (always visible)
        Positioned(
          right: 16,
          bottom: 22,
          child: FloatingActionButton(
            heroTag: 'assistant_fab',
            onPressed: () => setState(() => _open = true),
            child: const Icon(Icons.support_agent),
          ),
        ),

        // Chat panel
        if (_open)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _open = false),
              child: Container(color: Colors.black.withOpacity(0.25)),
            ),
          ),
        if (_open)
          Positioned(
            right: 14,
            left: 14,
            bottom: 14,
            child: _ChatPanel(
              onClose: () => setState(() => _open = false),
            ),
          ),
      ],
    );
  }
}

class _ChatPanel extends StatefulWidget {
  final VoidCallback onClose;
  const _ChatPanel({required this.onClose});

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  final _ctrl = TextEditingController();

  late final List<_Msg> _msgs = [
    _Msg.bot(S.of(context, 'assistant_greeting'))
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _ask(String text) {
    final q = text.trim();
    if (q.isEmpty) return;

    setState(() {
      _msgs.add(_Msg.user(q));
    });

    final lang = Localizations.localeOf(context).languageCode; // 'en' or 'ta'

    // ✅ No lang param here
    final match = WasteChatbotEngine.bestMatch(q);

    final reply = match != null
        ? match.answerForLang(lang)
        : (lang == 'ta'
        ? S.of(context, 'assistant_fallback_ta')
        : S.of(context, 'assistant_fallback'));

    setState(() {
      _msgs.add(_Msg.bot(reply));
    });

    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;

    // ✅ No lang param here
    final quick = WasteChatbotEngine.quickQuestions(limit: 12);

    return Material(
      borderRadius: BorderRadius.circular(18),
      elevation: 16,
      child: Container(
        height: 520,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                color: Color(0xFF1B5E20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      S.of(context, 'assistant_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Quick questions (chips)
            if (quick.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                child: Row(
                  children: quick.map((qa) {
                    final qText = qa.questionForLang(lang); // ✅ localized
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(qText, overflow: TextOverflow.ellipsis),
                        onPressed: () => _ask(qText),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const Divider(height: 1),

            // Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _msgs.length,
                itemBuilder: (_, i) => _Bubble(msg: _msgs[i]),
              ),
            ),

            // Input
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _ask,
                      decoration: InputDecoration(
                        hintText: S.of(context, 'assistant_hint'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _ask(_ctrl.text),
                    child: Text(S.of(context, 'assistant_send')),
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

class _Msg {
  final String text;
  final bool fromUser;

  const _Msg.user(this.text) : fromUser = true;
  const _Msg.bot(this.text) : fromUser = false;
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final align =
    msg.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = msg.fromUser ? const Color(0xFF1B5E20) : Colors.grey.shade200;
    final fg = msg.fromUser ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(msg.text, style: TextStyle(color: fg)),
        ),
      ],
    );
  }
}