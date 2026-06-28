import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SmartPDF'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get navFiles;

  /// No description provided for @navRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get navRecent;

  /// No description provided for @navFavourite.
  ///
  /// In en, this message translates to:
  /// **'Favourite'**
  String get navFavourite;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search documents…'**
  String get homeSearchHint;

  /// No description provided for @homeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get homeEmpty;

  /// No description provided for @homeEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to scan or import'**
  String get homeEmptySubtitle;

  /// No description provided for @filesTitle.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get filesTitle;

  /// No description provided for @filesBrowseMore.
  ///
  /// In en, this message translates to:
  /// **'Browse more files'**
  String get filesBrowseMore;

  /// No description provided for @filesSyncDrive.
  ///
  /// In en, this message translates to:
  /// **'Sync with Google Drive'**
  String get filesSyncDrive;

  /// No description provided for @filesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No files yet'**
  String get filesEmpty;

  /// No description provided for @filesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start adding PDF files to build your digital library!'**
  String get filesEmptySubtitle;

  /// No description provided for @recentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentTitle;

  /// No description provided for @recentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent documents'**
  String get recentEmpty;

  /// No description provided for @favouritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favouritesTitle;

  /// No description provided for @favouritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favourites yet'**
  String get favouritesEmpty;

  /// No description provided for @favouritesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Star a document to see it here'**
  String get favouritesEmptySubtitle;

  /// No description provided for @viewerTitle.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get viewerTitle;

  /// No description provided for @drawerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// No description provided for @drawerTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get drawerTheme;

  /// No description provided for @drawerRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate app'**
  String get drawerRateApp;

  /// No description provided for @drawerLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get drawerLanguage;

  /// No description provided for @drawerShareApp.
  ///
  /// In en, this message translates to:
  /// **'Share this app'**
  String get drawerShareApp;

  /// No description provided for @drawerFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Social'**
  String get drawerFeedback;

  /// No description provided for @drawerPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get drawerPrivacy;

  /// No description provided for @drawerLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get drawerLicenses;

  /// No description provided for @languageSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get languageSheetTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @docActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get docActionDelete;

  /// No description provided for @docActionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get docActionRemove;

  /// No description provided for @docActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get docActionCancel;

  /// No description provided for @docActionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get docActionRename;

  /// No description provided for @docActionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get docActionSave;

  /// No description provided for @docActionPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get docActionPrint;

  /// No description provided for @docActionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get docActionShare;

  /// No description provided for @docActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get docActionEdit;

  /// No description provided for @docDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete document?'**
  String get docDeleteTitle;

  /// No description provided for @docRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove document?'**
  String get docRemoveTitle;

  /// No description provided for @docDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String docDeleteContent(String title);

  /// No description provided for @docRemoveContent.
  ///
  /// In en, this message translates to:
  /// **'This will remove \"{title}\" from SmartPDF. The original file on your device will not be affected.'**
  String docRemoveContent(String title);

  /// No description provided for @docRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename document'**
  String get docRenameTitle;

  /// No description provided for @docRenameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get docRenameLabel;

  /// No description provided for @docFavAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to favourites'**
  String get docFavAdded;

  /// No description provided for @docFavRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from favourites'**
  String get docFavRemoved;

  /// No description provided for @scannerSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get scannerSave;

  /// No description provided for @scannerAddPage.
  ///
  /// In en, this message translates to:
  /// **'Add page'**
  String get scannerAddPage;

  /// No description provided for @scannerCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get scannerCrop;

  /// No description provided for @scannerColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get scannerColor;

  /// No description provided for @scannerRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get scannerRotate;

  /// No description provided for @scannerReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get scannerReorder;

  /// No description provided for @scannerDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get scannerDelete;

  /// No description provided for @scannerNoPages.
  ///
  /// In en, this message translates to:
  /// **'No pages yet.\nUse Add page to get started.'**
  String get scannerNoPages;

  /// No description provided for @scannerPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String scannerPageOf(int current, int total);

  /// No description provided for @scannerTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take another photo'**
  String get scannerTakePhoto;

  /// No description provided for @scannerSelectPhotos.
  ///
  /// In en, this message translates to:
  /// **'Select from photos'**
  String get scannerSelectPhotos;

  /// No description provided for @scannerDeletePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete page?'**
  String get scannerDeletePageTitle;

  /// No description provided for @scannerDeletePageContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete page {page}?'**
  String scannerDeletePageContent(int page);

  /// No description provided for @cropAdjustBorders.
  ///
  /// In en, this message translates to:
  /// **'Adjust borders'**
  String get cropAdjustBorders;

  /// No description provided for @cropAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get cropAuto;

  /// No description provided for @cropReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get cropReset;

  /// No description provided for @cropRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get cropRotate;

  /// No description provided for @cropPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get cropPreview;

  /// No description provided for @cropEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get cropEdit;

  /// No description provided for @cropDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cropDone;

  /// No description provided for @cropPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'This is what will be saved'**
  String get cropPreviewLabel;

  /// No description provided for @cropPreviewBadge.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW'**
  String get cropPreviewBadge;

  /// No description provided for @reorderPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorderPageTitle;

  /// No description provided for @filterApplyToAll.
  ///
  /// In en, this message translates to:
  /// **'Apply to all pages'**
  String get filterApplyToAll;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Get in touch'**
  String get feedbackTitle;

  /// No description provided for @feedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send feedback or follow us on social media'**
  String get feedbackSubtitle;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @licensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get licensesTitle;

  /// No description provided for @licensesSmartPdf.
  ///
  /// In en, this message translates to:
  /// **'SmartPDF License'**
  String get licensesSmartPdf;

  /// No description provided for @licensesThirdParty.
  ///
  /// In en, this message translates to:
  /// **'Third-party Packages'**
  String get licensesThirdParty;

  /// No description provided for @licensesThirdPartyDesc.
  ///
  /// In en, this message translates to:
  /// **'This app uses open-source Flutter packages. Their licenses can be viewed below.'**
  String get licensesThirdPartyDesc;

  /// No description provided for @licensesViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all package licenses'**
  String get licensesViewAll;

  /// No description provided for @licensesLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more about Open Source licenses'**
  String get licensesLearnMore;

  /// No description provided for @couldNotOpenPdf.
  ///
  /// In en, this message translates to:
  /// **'Could not open PDF:\n{error}'**
  String couldNotOpenPdf(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
