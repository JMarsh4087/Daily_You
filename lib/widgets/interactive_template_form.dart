import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entries_provider.dart';

class InteractiveTemplateForm extends StatefulWidget {
  final String formJson;
  final TextEditingController editorController;
  final Entry entry;
  final VoidCallback? onSaved;

  const InteractiveTemplateForm({
    super.key,
    required this.formJson,
    required this.editorController,
    required this.entry,
    this.onSaved,
  });

  @override
  State<InteractiveTemplateForm> createState() => _InteractiveTemplateFormState();
}

class _InteractiveTemplateFormState extends State<InteractiveTemplateForm> {
  final Map<String, String> ratings = {};
  final Set<String> selectedTags = {};
  final Map<String, bool> higherIsBetter = {
  'Relief': true,   // higher number = good (4 becomes green)
  'Shame': false,   // higher number = bad  (4 becomes red)
  'Fear': false,
  'Anger': false,
};
Color _getRatingColor(String label, String valStr) {
  final int val = int.tryParse(valStr) ?? 2;

  // Flip the scale if higher number = better for this field
  final int effectiveVal = (higherIsBetter[label] ?? false) ? (4 - val) : val;

  switch (effectiveVal) {
    case 0: return Colors.green.shade400;      // good
    case 1: return Colors.lime.shade400;
    case 2: return Colors.amber.shade400;      // neutral
    case 3: return Colors.orange.shade700;
    case 4: return Colors.red.shade600;        // bad
    default: return Colors.grey;
  }
}

void _updateFormData() {
  final Map<String, dynamic> data = {
    "shame": ratings["Shame"] ?? 0,
    "relief": ratings["Relief"] ?? 0,
    "fear": ratings["Fear"] ?? 0,
    "anger": ratings["Anger"] ?? 0,
    "emotions": selectedTags.toList(),
    "interaction": ratings["Interaction"] ?? "",
  };

  final updatedEntry = widget.entry.copy(formData: data);
  EntriesProvider.instance.update(updatedEntry);
  EntriesProvider.instance.notifyListeners();
  widget.onSaved?.call();
}

void _applyToEntry() {
  final Map<String, dynamic> data = {
    "shame": ratings["Shame"] ?? 0,
    "relief": ratings["Relief"] ?? 0,
    "fear": ratings["Fear"] ?? 0,
    "anger": ratings["Anger"] ?? 0,
    "emotions": selectedTags.toList(),
  };

  String interactionText = ratings["Interaction"] ?? "";

  String markdown = "# 🧠 Daily Connections\n\n"
      "**PART 1. Interaction**\n$interactionText\n\n"
      "**PART 2. Intensity**\n"
      "Shame: ${data["shame"]} | Relief: ${data["relief"]} | Fear: ${data["fear"]} | Anger: ${data["anger"]}\n\n";

  if (selectedTags.isNotEmpty) {
    markdown += "**PART 3. Other Emotions**\n" +
        selectedTags.map((t) => "+ $t").join("\n") + "\n";
  }

  widget.editorController.text += "\n" + markdown;
  widget.editorController.selection = TextSelection.fromPosition(
    TextPosition(offset: widget.editorController.text.length),
  );

  // Save structured data
  final updatedEntry = widget.entry.copy(formData: data);
  EntriesProvider.instance.update(updatedEntry);
  EntriesProvider.instance.notifyListeners();
  widget.onSaved?.call();
}

@override
Widget build(BuildContext context) {
  final List<dynamic> fields = jsonDecode(widget.formJson);
  final textFields = fields.where((f) => f['type'] == 'text').toList();
  final ratingFields = fields.where((f) => f['type'] == 'rating').toList();
  final multiselectFields = fields.where((f) => f['type'] == 'multiselect').toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 1. Interaction text box
      ...textFields.map<Widget>((field) {
        final label = field['label'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            maxLines: 8,
            style: const TextStyle(fontSize: 16),
            onChanged: (v) {
              ratings[label] = v;
              _updateFormData();
            },
          ),
        );
      }).toList(),

      const SizedBox(height: 8),

      // 2. Rating scales (Shame, Relief, Fear, Anger)
...ratingFields.map<Widget>((field) {
  final label = field['label'] as String;
  final selectedValue = ratings[label];
  final isPositive = higherIsBetter[label] ?? false;   // true for Relief, etc.

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
    child: Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          Wrap(
            spacing: 8,
            children: List.generate(5, (i) {
              // Flip order for positive emotions (4 3 2 1 0 instead of 0 1 2 3 4)
              final int displayVal = isPositive ? (4 - i) : i;
              final val = displayVal.toString();

              final selected = selectedValue == val;
              final color = _getRatingColor(label, val);

              return SizedBox(
                width: 34,
                height: 34,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected ? color : color.withOpacity(0.15),
                    foregroundColor: selected ? Colors.black : null,
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(34, 34),
                  ),
                  onPressed: () {
                    ratings[label] = ratings[label] == val ? "" : val;
                    _updateFormData();
                  },
                  child: Text(val),
                ),
              );
            }),
          ),
        ],
      ),
    ),
  );
}).toList(),

      const SizedBox(height: 16),

      // 3. Word bank (multiselect)
      ...multiselectFields.map<Widget>((field) {
        final List<String> options = List<String>.from(field['options']);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isPositive = option.startsWith("✅");
              final color = isPositive ? Colors.green.shade400 : Colors.red.shade600;
              final selected = selectedTags.contains(option);

              return FilterChip(
                label: Text(
                  option,
                  style: TextStyle(
                    fontSize: 15,
                    color: selected ? Colors.black : null,
                  ),
                ),
                selected: selected,
                showCheckmark: false,
                backgroundColor: color.withOpacity(0.15),
                selectedColor: color,
                onSelected: (sel) {
                  sel ? selectedTags.add(option) : selectedTags.remove(option);
                  _updateFormData();
                },
              );
            }).toList(),
          ),
        );
      }).toList(),

      const SizedBox(height: 24),

      // Apply button
      ElevatedButton(
        onPressed: _applyToEntry,
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
        child: const Text("Apply Form to Entry ✅", style: TextStyle(fontSize: 16)),
      ),
    ],
  );
}
}