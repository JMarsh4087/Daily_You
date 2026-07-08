import 'dart:async';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/template_dao.dart';
import 'package:daily_you/models/template.dart';
import 'package:flutter/material.dart';

class TemplatesProvider with ChangeNotifier {
  static final TemplatesProvider instance = TemplatesProvider._init();

  TemplatesProvider._init();

  List<Template> templates = List.empty(growable: true);

  /// Load the provider's data from the app database
  Future<void> load() async {
    templates = await TemplateDao.getAll();
    notifyListeners();
  }

  // CRUD operations

  Future<void> add(Template template) async {
    // Insert the template into the database so that it has an ID
    final templateWithId = await TemplateDao.add(template);
    templates.add(templateWithId);
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> remove(Template template) async {
    await TemplateDao.remove(template.id!);
    templates.removeWhere((x) => x.id == template.id);
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> update(Template template) async {
    await TemplateDao.update(template);
    final index = templates.indexWhere((x) => x.id == template.id);
    templates[index] = template;
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Template? getDefaultTemplate() {
    var defaultTemplateId =
        ConfigProvider.instance.get(ConfigKey.defaultTemplate);
    return templates.where((t) => t.id == defaultTemplateId).firstOrNull;
  }

  Future<void> createDefaultTemplates() async {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    Locale locale;
    if (AppLocalizations.delegate.isSupported(deviceLocale)) {
      locale = deviceLocale;
    } else {
      final langOnly = Locale(deviceLocale.languageCode);
      locale = AppLocalizations.delegate.isSupported(langOnly)
          ? langOnly
          : const Locale('en');
    }
    final l10n = await AppLocalizations.delegate.load(locale);
    final defaultTemplates = [
      Template(
          name: l10n.templateDefaultTimestampTitle,
          text: l10n.templateDefaultTimestampBody("{{date}}", "{{time}}"),
          timeCreate: DateTime.now(),
          timeModified: DateTime.now()),
      Template(
          name: l10n.templateDefaultSummaryTitle,
          text: l10n.templateDefaultSummaryBody,
          timeCreate: DateTime.now(),
          timeModified: DateTime.now()),
      Template(
          name: l10n.templateDefaultReflectionTitle,
          text: l10n.templateDefaultReflectionBody,
          timeCreate: DateTime.now(),
          timeModified: DateTime.now()),
      Template(
          name: l10n.templateDefaultDailyConnectionsTitle,
          text: l10n.templateDefaultDailyConnectionsBody,  // keeps your nice Markdown as fallback
          formJson: '''
      [
        {"type":"text","label":"Interaction (Who did you connect with today? What happened? Write 1-3 sentences.)"},
        {"type":"rating","label":"Shame"},
        {"type":"rating","label":"Relief"},
        {"type":"rating","label":"Fear"},
        {"type":"rating","label":"Anger"},
        {"type":"multiselect","label":"Other emotions","options":["Accepted","Affectionate","Alive","Amused","Attractive","Beautiful","Blameless","Brave","Calm","Capable","Caring","Cheerful","Cherished","Comfortable","Comforted","Competent","Concerned","Confident","Content","Courageous","Curious","Delighted","Desirable","Eager","Excited","Flattered","Forgiving","Friendly","Fulfilled","Generous","Glad","Good","Grateful","Great","Happy","Honored","Hopeful","Humorous","Interested","Joyful","Lovable","Loving","Loyal","Passionate","Peaceful","Playful","Pleased","Powerful","Proud","Quiet","Relaxed","Relieved","Respected","Satisfied","Safe","Secure","Self-reliant","Sexy","Silly","Special","Strong","Supportive","Surprised","Sympathetic","Tender","Trusted","Trusting","Understood","Warm","Welcomed","Abandoned","Afraid","Alone","Angry","Annoyed","Apprehensive","Ashamed","Betrayed","Bitter","Blamed","Contempt","Defeated","Dependent","Despairing","Desperate","Disappointed","Disbelief","Discouraged","Disgust","Distrust","Embarrassed","Empty","Evil","Fearful","Foolish","Frantic","Frustrated","Furious","Guilty","Hateful","Helpless","Hesitant","Hopeless","Horrified","Humiliated","Hurt","Impatient","Inadequate","Incompetent","Indebted","Indecisive","Inferior","Inhibited","Insecure","Intruded","Irresponsible","Irritated","Jealous","Let down","Lonely","Mad","Misunderstood","Needy","Rage","Rejected","Responsible","Sad","Scared","Sleazy","Sorry","Touchy","Trapped","Ugly","Unappreciated","Uncertain","Unfulfilled","Unsafe","Worried","Worthless"]}
      ]
      ''',
          timeCreate: DateTime.now(),
          timeModified: DateTime.now()),
    ];

    for (final template in defaultTemplates) {
      add(template);
    }
  }
}
