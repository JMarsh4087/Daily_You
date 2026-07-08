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

void _updateFormData() {
  final Map<String, dynamic> data = {
    "shame": ratings["Shame"] ?? 0,
    "relief": ratings["Relief"] ?? 0,
    "fear": ratings["Fear"] ?? 0,
    "anger": ratings["Anger"] ?? 0,
    "emotions": selectedTags.toList(),
    "interaction": ratings["Interaction"] ?? "",   // only the real interaction text
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

  // Find the first text field (the interaction one) — works with any label
  String interactionText = ratings.values.firstWhere(
    (v) => v.isNotEmpty,
    orElse: () => "",
  );

  String markdown = "# 🧠 Daily Connections\n\n"
      "**PART 1.   Interaction**\n$interactionText\n\n"
      "**PART 2.   Intensity**\n"
      "Shame: ${data["shame"]} | Relief: ${data["relief"]} | Fear: ${data["fear"]} | Anger: ${data["anger"]}\n\n";

  if (selectedTags.isNotEmpty) {
    markdown += "**PART 3.   Other Emotions**\n" + selectedTags.map((t) => "+ $t").join("\n") + "\n";
  }

  widget.editorController.text += "\n" + markdown;
  widget.editorController.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.editorController.text.length));

  // Save structured data
  final updatedEntry = widget.entry.copy(formData: data);
  EntriesProvider.instance.update(updatedEntry);
  EntriesProvider.instance.notifyListeners();
  widget.onSaved?.call();
}

  @override
  Widget build(BuildContext context) {
    final List<dynamic> fields = jsonDecode(widget.formJson);

    return Column(
      children: [
        ...fields.map<Widget>((field) {
          final type = field['type'];
          final label = field['label'];

          if (type == "text") {
            return TextField(
              decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
              maxLines: 3,
              onChanged: (v) {
                ratings[label] = v;
                _updateFormData();   // silent save
              },
            );
          } else if (type == "rating") {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: List.generate(5, (i) {
                    final val = i.toString();
                    return Padding(
                      padding: const EdgeInsets.all(4),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: ratings[label] == val ? Colors.green : null),
                        onPressed: () {
                          ratings[label] = ratings[label] == val ? "" : val;
                          _updateFormData();   // silent save
                        },
                        child: Text(val),
                      ),
                    );
                  }),
                ),
              ],
            );
          } else if (type == "multiselect") {
            final List<String> options = List<String>.from(field['options']);
            return Wrap(
              children: options.map((option) => FilterChip(
                label: Text(option),
                selected: selectedTags.contains(option),
                onSelected: (sel) {
                  sel ? selectedTags.add(option) : selectedTags.remove(option);
                  _updateFormData();   // silent save
                },
              )).toList(),
            );
          }
          return const SizedBox();
        }).toList(),

        ElevatedButton(
          onPressed: _applyToEntry,
          child: const Text("Apply Form to Entry ✅"),
        ),
      ],
    );
  }
}