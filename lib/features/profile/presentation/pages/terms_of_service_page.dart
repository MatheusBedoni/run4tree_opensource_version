import 'package:flutter/material.dart';

import '../widgets/legal_text_page.dart';

/// Termos de Serviço do Run4Tree.
///
/// ATENÇÃO: este é um rascunho funcional cobrindo o que o app realmente faz
/// hoje (rastreio de corrida, anúncios recompensados, plantio via
/// Tree-Nation). Não é aconselhamento jurídico — a seção "Governing Law"
/// tem um placeholder que precisa ser preenchido (idealmente com revisão de
/// um advogado) antes de tratar isso como texto legal final.
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalTextPage(
      title: 'Terms of Service',
      lastUpdated: 'Last updated: September 2026',
      sections: [
        LegalSection(
          heading: '1. Acceptance of these Terms',
          body:
              'By downloading, installing, or using Run4Tree ("the App"), you agree to these Terms of Service. '
              'If you do not agree, please do not use the App.',
        ),
        LegalSection(
          heading: '2. What Run4Tree Does',
          body:
              'Run4Tree lets you track runs, walks, and bike rides using your device\'s GPS, and lets you watch short '
              'rewarded ads to fund the planting of real trees through our partner Tree-Nation. The App does not '
              'currently offer any paid subscription or in-app purchase — all tree planting is funded entirely by ad '
              'revenue.',
        ),
        LegalSection(
          heading: '3. Not Medical Advice',
          body:
              'Run4Tree is a fitness-tracking and environmental-impact tool, not a medical device or a substitute for '
              'professional medical advice. Consult a doctor before starting any new exercise routine, especially if '
              'you have a pre-existing health condition.',
        ),
        LegalSection(
          heading: '4. Location and Sensor Data',
          body:
              'To track your route, distance, and pace, the App needs access to your device\'s location while a run '
              'is active. You are responsible for using the App safely — including staying aware of your surroundings '
              'and traffic while exercising with your phone in hand or in a pocket/armband.',
        ),
        LegalSection(
          heading: '5. Advertising',
          body:
              'The App shows rewarded video ads (served through Google AdMob) that you can choose to watch in the '
              'Garden tab. Ad availability is not guaranteed at all times and depends on Google\'s ad network. We use '
              'RevenueCat to verify, server-side, that an ad was genuinely watched to completion before crediting any '
              'reward — this protects the integrity of the tree-planting mechanism for everyone.',
        ),
        LegalSection(
          heading: '6. Tree Planting via Tree-Nation',
          body:
              'When enough ad-funded value has accumulated, the App places a real tree-planting order with Tree-Nation, '
              'an independent third-party reforestation platform. Tree-Nation — not Run4Tree — determines the specific '
              'planting location, species, and timeline, and issues the planting certificate. We do our best to reflect '
              'accurate, up-to-date information from Tree-Nation inside the App, but we do not control their planting '
              'operations and cannot guarantee specific delivery timelines.',
        ),
        LegalSection(
          heading: '7. Your Data Stays On Your Device',
          body:
              'Run4Tree does not require an account, a password, or an email address to use. Your profile info (name, '
              'age, body metrics, weekly goal) and your run history are stored locally on your device only. There is no '
              'cloud backup — uninstalling the App or clearing its storage permanently deletes this data.',
        ),
        LegalSection(
          heading: '8. Intellectual Property',
          body:
              'The App\'s design, branding, and original content are owned by the Run4Tree developer. Third-party SDKs '
              '(Google Maps, Google AdMob, RevenueCat, OpenWeatherMap, Tree-Nation) remain the property of their '
              'respective owners and are used under their own terms of service.',
        ),
        LegalSection(
          heading: '9. Disclaimer of Warranties; Limitation of Liability',
          body:
              'The App is provided "as is," without warranties of any kind, express or implied. We do not guarantee '
              'uninterrupted, error-free operation, or that any specific number of trees will be planted within any '
              'particular timeframe. To the maximum extent permitted by law, the developer is not liable for any '
              'indirect, incidental, or consequential damages arising from your use of the App.',
        ),
        LegalSection(
          heading: '10. Changes to the App or these Terms',
          body:
              'We may update the App and these Terms from time to time to reflect new features or legal requirements. '
              'Continued use of the App after an update constitutes acceptance of the revised Terms.',
        ),
        LegalSection(
          heading: '11. Governing Law',
          body:
              'These Terms are governed by the laws of [insert your country/state here], without regard to conflict-of-'
              'law principles. This section is a placeholder and should be completed — ideally with legal review — '
              'before being treated as final.',
        ),
      ],
    );
  }
}
