import 'package:url_launcher/url_launcher.dart';

Future<void> openExternalLink(String url) async {
  final uri = Uri.parse(url);
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) await launchUrl(uri);
  } catch (_) {
    // Sin navegador disponible: no interrumpimos la app.
  }
}
