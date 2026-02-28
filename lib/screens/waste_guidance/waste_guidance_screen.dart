// lib/screens/waste_guidance/waste_guidance_screen.dart
// NEW FILE – Predefined waste segregation guidance (no AI/ML)
import 'package:flutter/material.dart';

class WasteCategory {
  final String name;
  final String emoji;
  final String type;
  final String bin;
  final String binColor;
  final Color cardColor;
  final Color accentColor;
  final String instruction;
  final List<String> examples;

  const WasteCategory({
    required this.name,
    required this.emoji,
    required this.type,
    required this.bin,
    required this.binColor,
    required this.cardColor,
    required this.accentColor,
    required this.instruction,
    required this.examples,
  });
}

const List<WasteCategory> kWasteCategories = [
  WasteCategory(
    name: 'Plastic',
    emoji: '🧴',
    type: 'Non-biodegradable',
    bin: 'Blue Bin',
    binColor: '🔵',
    cardColor: Color(0xFFE3F2FD),
    accentColor: Color(0xFF1565C0),
    instruction:
        'Rinse plastic items before disposal. Flatten bottles to save space. Do NOT mix with food waste.',
    examples: ['Plastic bottles', 'Carry bags', 'Containers', 'Straws', 'Packaging'],
  ),
  WasteCategory(
    name: 'Food Waste',
    emoji: '🥗',
    type: 'Biodegradable',
    bin: 'Green Bin',
    binColor: '🟢',
    cardColor: Color(0xFFE8F5E9),
    accentColor: Color(0xFF2E7D32),
    instruction:
        'Collect in a separate container. Drain excess liquid before disposal. Can be composted at home.',
    examples: ['Vegetable peels', 'Leftover food', 'Tea leaves', 'Fruit waste', 'Eggshells'],
  ),
  WasteCategory(
    name: 'Glass',
    emoji: '🫙',
    type: 'Recyclable',
    bin: 'Drop-off Center',
    binColor: '⚪',
    cardColor: Color(0xFFF3E5F5),
    accentColor: Color(0xFF6A1B9A),
    instruction:
        'Wrap in newspaper before disposal to prevent cuts. Take to nearest glass drop-off point. DO NOT mix with regular waste.',
    examples: ['Glass bottles', 'Jars', 'Broken glass', 'Mirrors', 'Bulbs'],
  ),
  WasteCategory(
    name: 'E-Waste',
    emoji: '💻',
    type: 'Hazardous',
    bin: 'Special Collection',
    binColor: '🔴',
    cardColor: Color(0xFFFFEBEE),
    accentColor: Color(0xFFC62828),
    instruction:
        '⚠️ NEVER put in regular bins. Take to authorized e-waste collection center. Check local municipality schedule for special collection days.',
    examples: ['Mobile phones', 'Batteries', 'Laptops', 'Cables', 'Circuit boards'],
  ),
  WasteCategory(
    name: 'Paper & Cardboard',
    emoji: '📦',
    type: 'Recyclable',
    bin: 'Dry Waste Bin',
    binColor: '🟡',
    cardColor: Color(0xFFFFF8E1),
    accentColor: Color(0xFFF57F17),
    instruction:
        'Keep dry — wet paper cannot be recycled. Remove staples and plastic windows from envelopes. Flatten cardboard boxes.',
    examples: ['Newspapers', 'Cardboard boxes', 'Office paper', 'Magazines', 'Paper bags'],
  ),
  WasteCategory(
    name: 'Metal & Cans',
    emoji: '🥫',
    type: 'Recyclable',
    bin: 'Dry Waste Bin',
    binColor: '🟡',
    cardColor: Color(0xFFF1F8E9),
    accentColor: Color(0xFF558B2F),
    instruction:
        'Rinse metal cans. Crush if possible to save space. Scrap metal dealers also accept clean metal items.',
    examples: ['Tin cans', 'Aluminium foil', 'Metal utensils', 'Iron scraps', 'Steel containers'],
  ),
];

class WasteGuidanceScreen extends StatelessWidget {
  /// Optional: pre-select a category by name (e.g. after complaint submission)
  final String? preselectedCategory;

  const WasteGuidanceScreen({super.key, this.preselectedCategory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Segregation Guide'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F7F0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF66BB6A).withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Text('♻️', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Proper segregation helps collectors and the environment. Follow the guide below.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...kWasteCategories.map((cat) => _WasteCategoryCard(
                category: cat,
                initiallyExpanded: preselectedCategory != null &&
                    cat.name
                        .toLowerCase()
                        .contains(preselectedCategory!.toLowerCase()),
              )),
          const SizedBox(height: 16),
          // Quick reference table
          const Text(
            'Quick Reference',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                _TableRow('Waste Type', 'Bin', isHeader: true),
                ...kWasteCategories.map((c) =>
                    _TableRow('${c.emoji} ${c.name}', '${c.binColor} ${c.bin}')),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _WasteCategoryCard extends StatefulWidget {
  final WasteCategory category;
  final bool initiallyExpanded;
  const _WasteCategoryCard({required this.category, this.initiallyExpanded = false});

  @override
  State<_WasteCategoryCard> createState() => _WasteCategoryCardState();
}

class _WasteCategoryCardState extends State<_WasteCategoryCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cat.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cat.accentColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cat.accentColor.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(cat.emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: cat.accentColor)),
                        const SizedBox(height: 2),
                        Text(cat.type,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cat.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: cat.accentColor.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      '${cat.binColor} ${cat.bin}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cat.accentColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: cat.accentColor,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Container(height: 1, color: cat.accentColor.withOpacity(0.15)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📋 How to dispose:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: cat.accentColor)),
                  const SizedBox(height: 6),
                  Text(cat.instruction,
                      style: const TextStyle(
                          fontSize: 13, height: 1.4, color: Color(0xFF333333))),
                  const SizedBox(height: 10),
                  Text('📝 Examples:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: cat.accentColor)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: cat.examples
                        .map((e) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color:
                                        cat.accentColor.withOpacity(0.25)),
                              ),
                              child: Text(e,
                                  style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final String col1;
  final String col2;
  final bool isHeader;
  const _TableRow(this.col1, this.col2, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isHeader
            ? const Color(0xFFE8F5E9)
            : Colors.transparent,
        border: const Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(col1,
                  style: TextStyle(
                      fontWeight:
                          isHeader ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13))),
          Text(col2,
              style: TextStyle(
                  fontWeight:
                      isHeader ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                  color: isHeader
                      ? const Color(0xFF1B5E20)
                      : Colors.grey.shade700)),
        ],
      ),
    );
  }
}
