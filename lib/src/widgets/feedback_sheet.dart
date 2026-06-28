import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

Future<void> showFeedbackSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppConstants.feedbackSheetBorderRadius),
      ),
    ),
    builder: (_) => const _FeedbackSheet(),
  );
}

class _FeedbackSheet extends StatelessWidget {
  const _FeedbackSheet();

  static const _options = [
    _FeedbackOption(
      svgIcon: _SvgIcons.email,
      label: 'Email',
      url: 'mailto:popelouis1@outlook.com',
      color: Color(0xFF0078D4),
    ),
    _FeedbackOption(
      svgIcon: _SvgIcons.whatsapp,
      label: 'WhatsApp',
      url: 'https://wa.me/message/BNEQO6RPUJFMM1',
      color: Color(0xFF25D366),
    ),
    _FeedbackOption(
      svgIcon: _SvgIcons.xTwitter,
      label: 'X (Twitter)',
      url: 'https://x.com/PopeLukong',
      color: Color(0xFF000000),
    ),
    _FeedbackOption(
      svgIcon: _SvgIcons.facebook,
      label: 'Facebook',
      url: 'https://www.facebook.com/vector2gru',
      color: Color(0xFF1877F2),
    ),
    _FeedbackOption(
      svgIcon: _SvgIcons.linkedin,
      label: 'LinkedIn',
      url: 'https://www.linkedin.com/in/lukong-louis-7b2a7520b/',
      color: Color(0xFF0A66C2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.feedbackSheetPaddingH,
          AppConstants.feedbackSheetPaddingTop,
          AppConstants.feedbackSheetPaddingH,
          AppConstants.feedbackSheetPaddingBottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: AppConstants.feedbackHandleWidth,
                height: AppConstants.feedbackHandleHeight,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(AppConstants.feedbackHandleRadius),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Get in touch',
              style: TextStyle(
                fontSize: AppConstants.feedbackTitleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Send feedback or follow us on social media',
              style: TextStyle(
                fontSize: AppConstants.feedbackSubtitleFontSize,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ..._options.map((o) => _OptionTile(option: o)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final _FeedbackOption option;
  const _OptionTile({required this.option});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: AppConstants.feedbackIconSize,
        height: AppConstants.feedbackIconSize,
        decoration: BoxDecoration(
          color: option.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.feedbackIconRadius),
        ),
        child: Center(
          child: SvgPicture.string(
            option.svgIcon,
            width: AppConstants.feedbackIconSvgSize,
            height: AppConstants.feedbackIconSvgSize,
            colorFilter: ColorFilter.mode(option.color, BlendMode.srcIn),
          ),
        ),
      ),
      title: Text(
        option.label,
        style: const TextStyle(fontSize: AppConstants.feedbackItemFontSize),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
        size: AppConstants.feedbackChevronSize,
      ),
      onTap: () => launchUrl(Uri.parse(option.url), mode: LaunchMode.externalApplication),
    );
  }
}

class _FeedbackOption {
  final String svgIcon;
  final String label;
  final String url;
  final Color color;
  const _FeedbackOption({required this.svgIcon, required this.label, required this.url, required this.color});
}

class _SvgIcons {
  _SvgIcons._();

  static const email =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">'
      '<path d="M20 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2z'
      'm0 4-8 5-8-5V6l8 5 8-5v2z"/></svg>';

  static const whatsapp =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">'
      '<path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15'
      '-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475'
      '-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52'
      '.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207'
      '-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372'
      '-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2'
      ' 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719'
      ' 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>'
      '<path d="M12 0C5.373 0 0 5.373 0 12c0 2.123.554 4.112 1.522 5.84L.057 23.492'
      'a.5.5 0 0 0 .614.614l5.653-1.465A11.945 11.945 0 0 0 12 24c6.627 0 12-5.373 12-12S18.627 0 12 0z'
      'm0 21.818a9.794 9.794 0 0 1-5.006-1.374l-.358-.213-3.712.963.988-3.607-.234-.372'
      'A9.818 9.818 0 1 1 12 21.818z"/></svg>';

  static const xTwitter =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">'
      '<path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-4.714-6.231-5.401 6.231H2.747'
      'l7.73-8.835L1.254 2.25H8.08l4.26 5.632 5.904-5.632zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>';

  static const facebook =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">'
      '<path d="M24 12.073C24 5.405 18.627 0 12 0S0 5.405 0 12.073C0 18.1 4.388 23.094 10.125 24v-8.437'
      'H7.078v-3.49h3.047V9.41c0-3.025 1.792-4.697 4.533-4.697 1.312 0 2.686.236 2.686.236v2.97h-1.513'
      'c-1.491 0-1.956.93-1.956 1.886v2.268h3.328l-.532 3.49h-2.796V24C19.612 23.094 24 18.1 24 12.073z"/></svg>';

  static const linkedin =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">'
      '<path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136'
      ' 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267'
      ' 5.455v6.286zM5.337 7.433a2.062 2.062 0 0 1-2.063-2.065 2.064 2.064 0 1 1 2.063 2.065zm1.782'
      ' 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24'
      ' 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/></svg>';
}
