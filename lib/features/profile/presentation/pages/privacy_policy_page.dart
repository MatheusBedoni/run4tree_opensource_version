import 'package:flutter/material.dart';

import '../widgets/legal_text_page.dart';

/// Política de Privacidade do Run4Tree.
///
/// ATENÇÃO: rascunho funcional que reflete com precisão o que o app coleta
/// hoje (sem login, dados locais, SDKs de terceiros usados). Ainda assim,
/// não é aconselhamento jurídico — recomenda-se revisão antes de tratar como
/// texto final, especialmente porque a Play Store também exige uma URL
/// pública hospedada com este mesmo conteúdo (não basta a tela dentro do app).
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalTextPage(
      title: 'Privacy Policy',
      lastUpdated: 'Last updated: September 2026',
      sections: [
        LegalSection(
          heading: 'Overview',
          body:
              'This Privacy Policy explains what information Run4Tree collects, how it is used, and which third-party '
              'services it relies on. Run4Tree has no login, no account, and no email/password collection — most of '
              'what the App knows about you stays on your device.',
        ),
        LegalSection(
          heading: 'Information You Provide',
          body:
              'During onboarding, you may enter your name, age, weight, height, and weekly running goal. This '
              'information is stored locally on your device (in the App\'s local database) and is used only to '
              'personalize goals, calorie estimates, and stats shown inside the App. We do not transmit it to any '
              'server we operate.',
        ),
        LegalSection(
          heading: 'Location Data',
          body:
              'While you have an active run, walk, or ride, the App uses your device\'s GPS location to draw your '
              'route on the map and calculate distance, pace, and speed. This data is saved locally as part of your run '
              'history. Approximate location is also used to fetch the current weather for your area from '
              'OpenWeatherMap. Location access can be denied in your device settings, though route tracking and '
              'weather features will not work without it.',
        ),
        LegalSection(
          heading: 'Advertising & Ad Verification',
          body:
              'Rewarded ads are served through Google AdMob. AdMob may collect device and advertising identifiers to '
              'serve and measure ads, per Google\'s own policies. We use RevenueCat to verify server-side that an ad '
              'was watched to completion before crediting any reward, and to record anonymous ad-performance events. '
              'RevenueCat identifies your device with a randomly generated ID that is not linked to any personal '
              'account, since the App has no login.',
        ),
        LegalSection(
          heading: 'Tree Planting Data Shared with Tree-Nation',
          body:
              'When your accumulated ad-funded value reaches the price of a tree, the App places a real planting order '
              'with Tree-Nation, referencing the same anonymous RevenueCat device ID mentioned above — never your name '
              'or any other personal information. Tree-Nation returns planting details (species, country, project, '
              'and a certificate link), which the App stores locally and displays in your Garden.',
        ),
        LegalSection(
          heading: 'Third-Party Services We Use',
          body:
              'Google Maps & Google AdMob — policies.google.com/privacy\n'
              'RevenueCat — revenuecat.com/privacy\n'
              'Tree-Nation — tree-nation.com/legal/privacy-policy\n'
              'OpenWeatherMap — openweathermap.org/privacy-policy\n\n'
              'Each of these providers processes a limited slice of data (as described above) under their own privacy '
              'policies, linked here for transparency.',
        ),
        LegalSection(
          heading: 'Data Storage & Retention',
          body:
              'Your profile info and run history live only in local storage on your device. We do not operate a '
              'server that stores this data, and there is no cloud backup or sync. Uninstalling the App, or clearing '
              'its storage from your device settings, permanently deletes this local data.',
        ),
        LegalSection(
          heading: 'Children\'s Privacy',
          body:
              'Run4Tree is not directed at children under 13, and we do not knowingly collect personal information '
              'from children.',
        ),
        LegalSection(
          heading: 'Your Choices',
          body:
              'You can deny or revoke location permission at any time in your device settings (core tracking features '
              'will stop working without it). You can also manage ad personalization for your device through your '
              'Android or iOS system settings, independent of this App.',
        ),
        LegalSection(
          heading: 'Changes to this Policy',
          body:
              'We may update this Privacy Policy as the App evolves. Material changes will be reflected by updating '
              'the "Last updated" date above.',
        ),
      ],
    );
  }
}
