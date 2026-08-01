// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'SmartPDF';

  @override
  String get navHome => 'होम';

  @override
  String get navFiles => 'फ़ाइलें';

  @override
  String get navRecent => 'हाल के';

  @override
  String get navFavourite => 'पसंदीदा';

  @override
  String get homeSearchHint => 'दस्तावेज़ खोजें…';

  @override
  String get homeEmpty => 'कोई दस्तावेज़ नहीं';

  @override
  String get homeEmptySubtitle =>
      'स्कैन या आयात करने के लिए नीचे दिए बटन पर टैप करें';

  @override
  String get filesTitle => 'फ़ाइलें';

  @override
  String get filesBrowseMore => 'अधिक फ़ाइलें देखें';

  @override
  String get filesSyncDrive => 'Google Drive से सिंक करें';

  @override
  String get filesEmpty => 'कोई फ़ाइल नहीं';

  @override
  String get driveSheetTitle => 'Google Drive';

  @override
  String get driveSheetSubtitle =>
      'SmartPDF में आयात करने के लिए PDF फ़ाइलें चुनें';

  @override
  String get driveSigningIn => 'साइन इन हो रहा है…';

  @override
  String get driveLoading => 'फ़ाइलें लोड हो रही हैं…';

  @override
  String get driveEmpty => 'आपके Drive में कोई PDF फ़ाइल नहीं मिली।';

  @override
  String driveImporting(int current, int total) {
    return '$total में से $current आयात हो रहा है…';
  }

  @override
  String driveImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count फ़ाइलें आयात हुईं',
      one: '1 फ़ाइल आयात हुई',
    );
    return '$_temp0';
  }

  @override
  String get driveImportButton => 'चयनित आयात करें';

  @override
  String get driveErrorSignIn =>
      'Google में साइन इन नहीं हो सका। कृपया पुनः प्रयास करें।';

  @override
  String get driveErrorLoad =>
      'Drive फ़ाइलें लोड करने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get driveErrorImport => 'कुछ फ़ाइलें आयात नहीं हो सकीं।';

  @override
  String get driveSelectAll => 'सभी चुनें';

  @override
  String get driveDeselectAll => 'सभी हटाएँ';

  @override
  String get driveSignOut => 'साइन आउट';

  @override
  String get driveUploadSheetSubtitle =>
      'Drive पर अपलोड करने के लिए स्थानीय दस्तावेज़ चुनें';

  @override
  String driveUploading(int current, int total) {
    return '$total में से $current अपलोड हो रहा है…';
  }

  @override
  String driveUploadDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count फ़ाइलें अपलोड हुईं',
      one: '1 फ़ाइल अपलोड हुई',
    );
    return '$_temp0';
  }

  @override
  String get driveUploadButton => 'चयनित अपलोड करें';

  @override
  String get driveErrorUpload => 'कुछ फ़ाइलें अपलोड नहीं हो सकीं।';

  @override
  String get driveTabDownload => 'Drive से';

  @override
  String get driveTabUpload => 'Drive पर';

  @override
  String get filesEmptySubtitle =>
      'अपनी डिजिटल लाइब्रेरी बनाने के लिए PDF फ़ाइलें जोड़ना शुरू करें!';

  @override
  String get recentTitle => 'हाल के';

  @override
  String get recentEmpty => 'कोई हालिया दस्तावेज़ नहीं';

  @override
  String get favouritesTitle => 'पसंदीदा';

  @override
  String get favouritesEmpty => 'अभी कोई पसंदीदा नहीं';

  @override
  String get favouritesEmptySubtitle =>
      'यहाँ देखने के लिए किसी दस्तावेज़ पर स्टार लगाएँ';

  @override
  String get viewerTitle => 'व्यूअर';

  @override
  String get viewerSearchHint => 'दस्तावेज़ में खोजें…';

  @override
  String get viewerSearchNoResults => 'कोई परिणाम नहीं';

  @override
  String viewerSearchOf(int current, int total) {
    return '$total में से $current';
  }

  @override
  String get drawerSettings => 'सेटिंग्स';

  @override
  String get drawerTheme => 'थीम';

  @override
  String get drawerRateApp => 'ऐप रेट करें';

  @override
  String get drawerLanguage => 'भाषा';

  @override
  String get drawerShareApp => 'यह ऐप शेयर करें';

  @override
  String get drawerFeedback => 'फ़ीडबैक और सोशल मीडिया';

  @override
  String get drawerPrivacy => 'गोपनीयता नीति';

  @override
  String get drawerLicenses => 'ओपन सोर्स लाइसेंस';

  @override
  String get languageSheetTitle => 'भाषा चुनें';

  @override
  String get languageEnglish => 'अंग्रेज़ी';

  @override
  String get languageFrench => 'फ्रेंच';

  @override
  String get languageSpanish => 'स्पेनिश';

  @override
  String get languageArabic => 'अरबी';

  @override
  String get languagePortuguese => 'पुर्तगाली';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get themeSheetTitle => 'थीम चुनें';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get themeDevice => 'डिवाइस थीम';

  @override
  String get settingsAutoCrop => 'ऑटो-क्रॉप';

  @override
  String get settingsAutoCropSubtitle =>
      'कैप्चर के समय दस्तावेज़ की सीमाएँ स्वचालित रूप से पहचानें और क्रॉप करें';

  @override
  String get docActionDelete => 'हटाएँ';

  @override
  String get docActionRemove => 'निकालें';

  @override
  String get docActionCancel => 'रद्द करें';

  @override
  String get docActionRename => 'नाम बदलें';

  @override
  String get docActionSave => 'सहेजें';

  @override
  String get docActionPrint => 'प्रिंट करें';

  @override
  String get docActionShare => 'शेयर करें';

  @override
  String get docActionEdit => 'संपादित करें';

  @override
  String get docDeleteTitle => 'दस्तावेज़ हटाएँ?';

  @override
  String get docRemoveTitle => 'दस्तावेज़ निकालें?';

  @override
  String docDeleteContent(String title) {
    return 'क्या आप वाकई \"$title\" हटाना चाहते हैं?';
  }

  @override
  String docRemoveContent(String title) {
    return 'इससे \"$title\" को SmartPDF से निकाल दिया जाएगा। आपके डिवाइस की मूल फ़ाइल प्रभावित नहीं होगी।';
  }

  @override
  String get docRenameTitle => 'दस्तावेज़ का नाम बदलें';

  @override
  String get docRenameLabel => 'नाम';

  @override
  String get docFavAdded => 'पसंदीदा में जोड़ा गया';

  @override
  String get docFavRemoved => 'पसंदीदा से हटाया गया';

  @override
  String get scannerSave => 'सहेजें';

  @override
  String get scannerAddPage => 'पृष्ठ जोड़ें';

  @override
  String get scannerCrop => 'क्रॉप करें';

  @override
  String get scannerColor => 'रंग';

  @override
  String get scannerRotate => 'घुमाएँ';

  @override
  String get scannerReorder => 'क्रम बदलें';

  @override
  String get scannerDelete => 'हटाएँ';

  @override
  String get scannerNoPages =>
      'अभी कोई पृष्ठ नहीं।\nशुरू करने के लिए पृष्ठ जोड़ें।';

  @override
  String scannerPageOf(int current, int total) {
    return 'पृष्ठ $current / $total';
  }

  @override
  String get scannerTakePhoto => 'एक और फ़ोटो लें';

  @override
  String get scannerSelectPhotos => 'फ़ोटो से चुनें';

  @override
  String get scannerDeletePageTitle => 'पृष्ठ हटाएँ?';

  @override
  String scannerDeletePageContent(int page) {
    return 'क्या आप वाकई पृष्ठ $page हटाना चाहते हैं?';
  }

  @override
  String get cropAdjustBorders => 'सीमाएँ समायोजित करें';

  @override
  String get cropAuto => 'ऑटो';

  @override
  String get cropReset => 'रीसेट';

  @override
  String get cropRotate => 'घुमाएँ';

  @override
  String get cropPreview => 'पूर्वावलोकन';

  @override
  String get cropEdit => 'संपादित करें';

  @override
  String get cropDone => 'हो गया';

  @override
  String get cropPreviewLabel => 'यही सहेजा जाएगा';

  @override
  String get cropPreviewBadge => 'पूर्वावलोकन';

  @override
  String get reorderPageTitle => 'क्रम बदलें';

  @override
  String get filterApplyToAll => 'सभी पृष्ठों पर लागू करें';

  @override
  String get filterApply => 'लागू करें';

  @override
  String get feedbackTitle => 'संपर्क करें';

  @override
  String get feedbackSubtitle =>
      'फ़ीडबैक भेजें या हमें सोशल मीडिया पर फॉलो करें';

  @override
  String get privacyPolicyTitle => 'गोपनीयता नीति';

  @override
  String get licensesTitle => 'ओपन सोर्स लाइसेंस';

  @override
  String get licensesSmartPdf => 'SmartPDF लाइसेंस';

  @override
  String get licensesThirdParty => 'थर्ड-पार्टी पैकेज';

  @override
  String get licensesThirdPartyDesc =>
      'यह ऐप ओपन-सोर्स Flutter पैकेज का उपयोग करता है। उनके लाइसेंस नीचे देखे जा सकते हैं।';

  @override
  String get licensesViewAll => 'सभी पैकेज लाइसेंस देखें';

  @override
  String get licensesLearnMore => 'ओपन सोर्स लाइसेंस के बारे में अधिक जानें';

  @override
  String couldNotOpenPdf(String error) {
    return 'PDF नहीं खुल सका:\n$error';
  }
}
