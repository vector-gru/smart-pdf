// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SmartPDF';

  @override
  String get navHome => 'Home';

  @override
  String get navFiles => 'Files';

  @override
  String get navRecent => 'Recent';

  @override
  String get navFavourite => 'Favourite';

  @override
  String get homeSearchHint => 'Search documents…';

  @override
  String get homeEmpty => 'No documents yet';

  @override
  String get homeEmptySubtitle => 'Tap the button below to scan or import';

  @override
  String get filesTitle => 'Files';

  @override
  String get filesBrowseMore => 'Browse more files';

  @override
  String get filesSyncDrive => 'Sync with Google Drive';

  @override
  String get filesEmpty => 'No files yet';

  @override
  String get filesEmptySubtitle =>
      'Start adding PDF files to build your digital library!';

  @override
  String get recentTitle => 'Recent';

  @override
  String get recentEmpty => 'No recent documents';

  @override
  String get favouritesTitle => 'Favourites';

  @override
  String get favouritesEmpty => 'No favourites yet';

  @override
  String get favouritesEmptySubtitle => 'Star a document to see it here';

  @override
  String get viewerTitle => 'Viewer';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerTheme => 'Theme';

  @override
  String get drawerRateApp => 'Rate app';

  @override
  String get drawerLanguage => 'Language';

  @override
  String get drawerShareApp => 'Share this app';

  @override
  String get drawerFeedback => 'Feedback & Social';

  @override
  String get drawerPrivacy => 'Privacy policy';

  @override
  String get drawerLicenses => 'Open Source Licenses';

  @override
  String get languageSheetTitle => 'Select language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'French';

  @override
  String get docActionDelete => 'Delete';

  @override
  String get docActionRemove => 'Remove';

  @override
  String get docActionCancel => 'Cancel';

  @override
  String get docActionRename => 'Rename';

  @override
  String get docActionSave => 'Save';

  @override
  String get docActionPrint => 'Print';

  @override
  String get docActionShare => 'Share';

  @override
  String get docActionEdit => 'Edit';

  @override
  String get docDeleteTitle => 'Delete document?';

  @override
  String get docRemoveTitle => 'Remove document?';

  @override
  String docDeleteContent(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String docRemoveContent(String title) {
    return 'This will remove \"$title\" from SmartPDF. The original file on your device will not be affected.';
  }

  @override
  String get docRenameTitle => 'Rename document';

  @override
  String get docRenameLabel => 'Name';

  @override
  String get docFavAdded => 'Added to favourites';

  @override
  String get docFavRemoved => 'Removed from favourites';

  @override
  String get scannerSave => 'Save';

  @override
  String get scannerAddPage => 'Add page';

  @override
  String get scannerCrop => 'Crop';

  @override
  String get scannerColor => 'Color';

  @override
  String get scannerRotate => 'Rotate';

  @override
  String get scannerReorder => 'Reorder';

  @override
  String get scannerDelete => 'Delete';

  @override
  String get scannerNoPages => 'No pages yet.\nUse Add page to get started.';

  @override
  String scannerPageOf(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get scannerTakePhoto => 'Take another photo';

  @override
  String get scannerSelectPhotos => 'Select from photos';

  @override
  String get scannerDeletePageTitle => 'Delete page?';

  @override
  String scannerDeletePageContent(int page) {
    return 'Are you sure you want to delete page $page?';
  }

  @override
  String get cropAdjustBorders => 'Adjust borders';

  @override
  String get cropAuto => 'Auto';

  @override
  String get cropReset => 'Reset';

  @override
  String get cropRotate => 'Rotate';

  @override
  String get cropPreview => 'Preview';

  @override
  String get cropEdit => 'Edit';

  @override
  String get cropDone => 'Done';

  @override
  String get cropPreviewLabel => 'This is what will be saved';

  @override
  String get cropPreviewBadge => 'PREVIEW';

  @override
  String get reorderPageTitle => 'Reorder';

  @override
  String get filterApplyToAll => 'Apply to all pages';

  @override
  String get filterApply => 'Apply';

  @override
  String get feedbackTitle => 'Get in touch';

  @override
  String get feedbackSubtitle => 'Send feedback or follow us on social media';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get licensesTitle => 'Open Source Licenses';

  @override
  String get licensesSmartPdf => 'SmartPDF License';

  @override
  String get licensesThirdParty => 'Third-party Packages';

  @override
  String get licensesThirdPartyDesc =>
      'This app uses open-source Flutter packages. Their licenses can be viewed below.';

  @override
  String get licensesViewAll => 'View all package licenses';

  @override
  String get licensesLearnMore => 'Learn more about Open Source licenses';

  @override
  String couldNotOpenPdf(String error) {
    return 'Could not open PDF:\n$error';
  }
}
