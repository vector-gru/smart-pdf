// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'SmartPDF';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navFiles => 'الملفات';

  @override
  String get navRecent => 'الأخيرة';

  @override
  String get navFavourite => 'المفضلة';

  @override
  String get homeSearchHint => 'البحث في المستندات…';

  @override
  String get homeEmpty => 'لا توجد مستندات';

  @override
  String get homeEmptySubtitle => 'اضغط على الزر أدناه للمسح أو الاستيراد';

  @override
  String get filesTitle => 'الملفات';

  @override
  String get filesBrowseMore => 'تصفح المزيد من الملفات';

  @override
  String get filesSyncDrive => 'مزامنة مع Google Drive';

  @override
  String get filesEmpty => 'لا توجد ملفات';

  @override
  String get driveSheetTitle => 'Google Drive';

  @override
  String get driveSheetSubtitle => 'حدد ملفات PDF لاستيرادها إلى SmartPDF';

  @override
  String get driveSigningIn => 'جارٍ تسجيل الدخول…';

  @override
  String get driveLoading => 'جارٍ تحميل الملفات…';

  @override
  String get driveEmpty => 'لم يتم العثور على ملفات PDF في Drive الخاص بك.';

  @override
  String driveImporting(int current, int total) {
    return 'جارٍ استيراد $current من $total…';
  }

  @override
  String driveImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم استيراد $count ملفات',
      one: 'تم استيراد ملف واحد',
    );
    return '$_temp0';
  }

  @override
  String get driveImportButton => 'استيراد المحدد';

  @override
  String get driveErrorSignIn =>
      'تعذّر تسجيل الدخول إلى Google. يرجى المحاولة مرة أخرى.';

  @override
  String get driveErrorLoad => 'فشل تحميل ملفات Drive. يرجى المحاولة مرة أخرى.';

  @override
  String get driveErrorImport => 'تعذّر استيراد بعض الملفات.';

  @override
  String get driveSelectAll => 'تحديد الكل';

  @override
  String get driveDeselectAll => 'إلغاء تحديد الكل';

  @override
  String get driveSignOut => 'تسجيل الخروج';

  @override
  String get driveUploadSheetSubtitle =>
      'حدد المستندات المحلية لرفعها إلى Drive';

  @override
  String driveUploading(int current, int total) {
    return 'جارٍ رفع $current من $total…';
  }

  @override
  String driveUploadDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم رفع $count ملفات',
      one: 'تم رفع ملف واحد',
    );
    return '$_temp0';
  }

  @override
  String get driveUploadButton => 'رفع المحدد';

  @override
  String get driveErrorUpload => 'تعذّر رفع بعض الملفات.';

  @override
  String get driveTabDownload => 'من Drive';

  @override
  String get driveTabUpload => 'إلى Drive';

  @override
  String get filesEmptySubtitle =>
      'ابدأ بإضافة ملفات PDF لبناء مكتبتك الرقمية!';

  @override
  String get recentTitle => 'الأخيرة';

  @override
  String get recentEmpty => 'لا توجد مستندات حديثة';

  @override
  String get collectionsTitle => 'المجموعات';

  @override
  String get collectionsNewCollection => 'مجموعة جديدة';

  @override
  String get collectionsEditCollection => 'تعديل المجموعة';

  @override
  String get collectionsNameLabel => 'الاسم';

  @override
  String get collectionsColourLabel => 'اللون';

  @override
  String get collectionsIconLabel => 'الأيقونة';

  @override
  String get collectionsEmpty => 'لا توجد مجموعات بعد';

  @override
  String get collectionsEmptySubtitle =>
      'رتّب مستنداتك في مجموعات للوصول إليها بسهولة.';

  @override
  String get collectionsDeleteTitle => 'حذف المجموعة؟';

  @override
  String collectionsDeleteContent(String name) {
    return 'حذف \"$name\"؟ لن يتم حذف المستندات الموجودة بداخلها.';
  }

  @override
  String collectionsDocCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مستندات',
      one: 'مستند واحد',
      zero: 'لا توجد مستندات',
    );
    return '$_temp0';
  }

  @override
  String get collectionsEdit => 'تعديل';

  @override
  String get collectionsDelete => 'حذف';

  @override
  String get collectionsAddDocuments => 'إضافة مستندات';

  @override
  String get collectionsAddNoneAvailable =>
      'جميع المستندات موجودة بالفعل في هذه المجموعة.';

  @override
  String collectionsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تحديد $count',
      one: 'تم تحديد 1',
    );
    return '$_temp0';
  }

  @override
  String get collectionsAddButton => 'إضافة';

  @override
  String get collectionsDetailEmpty => 'لا توجد مستندات هنا';

  @override
  String get collectionsDetailEmptySubtitle =>
      'أضف مستندات إلى هذه المجموعة لعرضها هنا.';

  @override
  String get collectionsSwipeToRemove => 'إزالة';

  @override
  String get collectionsDocTypeImported => 'ملف مستورد';

  @override
  String get collectionsDocTypeScanned => 'مستند ممسوح ضوئيًا';

  @override
  String get navCollections => 'المجموعات';

  @override
  String get favouritesTitle => 'المفضلة';

  @override
  String get favouritesEmpty => 'لا توجد مفضلات بعد';

  @override
  String get favouritesEmptySubtitle => 'ضع نجمة على مستند لرؤيته هنا';

  @override
  String get viewerTitle => 'العارض';

  @override
  String get viewerSearchHint => 'البحث في المستند…';

  @override
  String get viewerSearchNoResults => 'لا توجد نتائج';

  @override
  String viewerSearchOf(int current, int total) {
    return '$current من $total';
  }

  @override
  String get drawerSettings => 'الإعدادات';

  @override
  String get drawerTheme => 'المظهر';

  @override
  String get drawerRateApp => 'تقييم التطبيق';

  @override
  String get drawerLanguage => 'اللغة';

  @override
  String get drawerShareApp => 'مشاركة هذا التطبيق';

  @override
  String get drawerFeedback => 'الملاحظات والتواصل الاجتماعي';

  @override
  String get drawerPrivacy => 'سياسة الخصوصية';

  @override
  String get drawerLicenses => 'تراخيص المصدر المفتوح';

  @override
  String get languageSheetTitle => 'اختر اللغة';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get languageFrench => 'الفرنسية';

  @override
  String get languageSpanish => 'الإسبانية';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languagePortuguese => 'البرتغالية';

  @override
  String get languageHindi => 'الهندية';

  @override
  String get themeSheetTitle => 'اختر المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeDevice => 'مظهر الجهاز';

  @override
  String get settingsAutoCrop => 'القص التلقائي';

  @override
  String get settingsAutoCropSubtitle =>
      'اكتشاف حواف المستند وقصها تلقائيًا عند التقاطها';

  @override
  String get docActionDelete => 'حذف';

  @override
  String get docActionRemove => 'إزالة';

  @override
  String get docActionCancel => 'إلغاء';

  @override
  String get docActionRename => 'إعادة تسمية';

  @override
  String get docActionSave => 'حفظ';

  @override
  String get docActionPrint => 'طباعة';

  @override
  String get docActionShare => 'مشاركة';

  @override
  String get docActionEdit => 'تعديل';

  @override
  String get docDeleteTitle => 'حذف المستند؟';

  @override
  String get docRemoveTitle => 'إزالة المستند؟';

  @override
  String docDeleteContent(String title) {
    return 'هل أنت متأكد أنك تريد حذف \"$title\"؟';
  }

  @override
  String docRemoveContent(String title) {
    return 'سيؤدي هذا إلى إزالة \"$title\" من SmartPDF. لن يتأثر الملف الأصلي على جهازك.';
  }

  @override
  String get docRenameTitle => 'إعادة تسمية المستند';

  @override
  String get docRenameLabel => 'الاسم';

  @override
  String get docFavAdded => 'تمت الإضافة إلى المفضلة';

  @override
  String get docFavRemoved => 'تمت الإزالة من المفضلة';

  @override
  String get scannerSave => 'حفظ';

  @override
  String get scannerAddPage => 'إضافة صفحة';

  @override
  String get scannerCrop => 'قص';

  @override
  String get scannerColor => 'اللون';

  @override
  String get scannerRotate => 'تدوير';

  @override
  String get scannerReorder => 'إعادة الترتيب';

  @override
  String get scannerDelete => 'حذف';

  @override
  String get scannerNoPages => 'لا توجد صفحات بعد.\nاستخدم إضافة صفحة للبدء.';

  @override
  String scannerPageOf(int current, int total) {
    return 'صفحة $current من $total';
  }

  @override
  String get scannerTakePhoto => 'التقاط صورة أخرى';

  @override
  String get scannerSelectPhotos => 'اختر من الصور';

  @override
  String get scannerDeletePageTitle => 'حذف الصفحة؟';

  @override
  String scannerDeletePageContent(int page) {
    return 'هل أنت متأكد أنك تريد حذف الصفحة $page؟';
  }

  @override
  String get cropAdjustBorders => 'ضبط الحدود';

  @override
  String get cropAuto => 'تلقائي';

  @override
  String get cropReset => 'إعادة تعيين';

  @override
  String get cropRotate => 'تدوير';

  @override
  String get cropPreview => 'معاينة';

  @override
  String get cropEdit => 'تعديل';

  @override
  String get cropDone => 'تم';

  @override
  String get cropPreviewLabel => 'هذا ما سيتم حفظه';

  @override
  String get cropPreviewBadge => 'معاينة';

  @override
  String get reorderPageTitle => 'إعادة الترتيب';

  @override
  String get filterApplyToAll => 'تطبيق على جميع الصفحات';

  @override
  String get filterApply => 'تطبيق';

  @override
  String get feedbackTitle => 'تواصل معنا';

  @override
  String get feedbackSubtitle =>
      'أرسل ملاحظاتك أو تابعنا على وسائل التواصل الاجتماعي';

  @override
  String get privacyPolicyTitle => 'سياسة الخصوصية';

  @override
  String get licensesTitle => 'تراخيص المصدر المفتوح';

  @override
  String get licensesSmartPdf => 'ترخيص SmartPDF';

  @override
  String get licensesThirdParty => 'الحزم الخارجية';

  @override
  String get licensesThirdPartyDesc =>
      'يستخدم هذا التطبيق حزم Flutter مفتوحة المصدر. يمكن الاطلاع على تراخيصها أدناه.';

  @override
  String get licensesViewAll => 'عرض جميع تراخيص الحزم';

  @override
  String get licensesLearnMore => 'تعرّف على المزيد حول تراخيص المصدر المفتوح';

  @override
  String couldNotOpenPdf(String error) {
    return 'تعذّر فتح ملف PDF:\n$error';
  }
}
