import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_pt.dart';

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
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('pt'),
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

  /// No description provided for @driveSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get driveSheetTitle;

  /// No description provided for @driveSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select PDF files to import into SmartPDF'**
  String get driveSheetSubtitle;

  /// No description provided for @driveSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get driveSigningIn;

  /// No description provided for @driveLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading files…'**
  String get driveLoading;

  /// No description provided for @driveEmpty.
  ///
  /// In en, this message translates to:
  /// **'No PDF files found in your Drive.'**
  String get driveEmpty;

  /// No description provided for @driveImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing {current} of {total}…'**
  String driveImporting(int current, int total);

  /// No description provided for @driveImportDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file imported} other{{count} files imported}}'**
  String driveImportDone(int count);

  /// No description provided for @driveImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import selected'**
  String get driveImportButton;

  /// No description provided for @driveErrorSignIn.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in to Google. Please try again.'**
  String get driveErrorSignIn;

  /// No description provided for @driveErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load Drive files. Please try again.'**
  String get driveErrorLoad;

  /// No description provided for @driveErrorImport.
  ///
  /// In en, this message translates to:
  /// **'Some files could not be imported.'**
  String get driveErrorImport;

  /// No description provided for @driveSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get driveSelectAll;

  /// No description provided for @driveDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get driveDeselectAll;

  /// No description provided for @driveSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get driveSignOut;

  /// No description provided for @driveUploadSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select local documents to upload to Drive'**
  String get driveUploadSheetSubtitle;

  /// No description provided for @driveUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {current} of {total}…'**
  String driveUploading(int current, int total);

  /// No description provided for @driveUploadDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file uploaded} other{{count} files uploaded}}'**
  String driveUploadDone(int count);

  /// No description provided for @driveUploadButton.
  ///
  /// In en, this message translates to:
  /// **'Upload selected'**
  String get driveUploadButton;

  /// No description provided for @driveErrorUpload.
  ///
  /// In en, this message translates to:
  /// **'Some files could not be uploaded.'**
  String get driveErrorUpload;

  /// No description provided for @driveTabDownload.
  ///
  /// In en, this message translates to:
  /// **'From Drive'**
  String get driveTabDownload;

  /// No description provided for @driveTabUpload.
  ///
  /// In en, this message translates to:
  /// **'To Drive'**
  String get driveTabUpload;

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

  /// No description provided for @collectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collectionsTitle;

  /// No description provided for @collectionsNewCollection.
  ///
  /// In en, this message translates to:
  /// **'New collection'**
  String get collectionsNewCollection;

  /// No description provided for @collectionsEditCollection.
  ///
  /// In en, this message translates to:
  /// **'Edit collection'**
  String get collectionsEditCollection;

  /// No description provided for @collectionsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get collectionsNameLabel;

  /// No description provided for @collectionsColourLabel.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get collectionsColourLabel;

  /// No description provided for @collectionsIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get collectionsIconLabel;

  /// No description provided for @collectionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No collections yet'**
  String get collectionsEmpty;

  /// No description provided for @collectionsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Group your documents into collections for easier access.'**
  String get collectionsEmptySubtitle;

  /// No description provided for @collectionsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete collection?'**
  String get collectionsDeleteTitle;

  /// No description provided for @collectionsDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? Documents inside will not be deleted.'**
  String collectionsDeleteContent(String name);

  /// No description provided for @collectionsDocCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No documents} =1{1 document} other{{count} documents}}'**
  String collectionsDocCount(int count);

  /// No description provided for @collectionsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get collectionsEdit;

  /// No description provided for @collectionsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get collectionsDelete;

  /// No description provided for @collectionsAddDocuments.
  ///
  /// In en, this message translates to:
  /// **'Add documents'**
  String get collectionsAddDocuments;

  /// No description provided for @collectionsAddNoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'All documents are already in this collection.'**
  String get collectionsAddNoneAvailable;

  /// No description provided for @collectionsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String collectionsSelectedCount(int count);

  /// No description provided for @collectionsAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get collectionsAddButton;

  /// No description provided for @collectionsDetailEmpty.
  ///
  /// In en, this message translates to:
  /// **'No documents here'**
  String get collectionsDetailEmpty;

  /// No description provided for @collectionsDetailEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add documents to this collection to see them here.'**
  String get collectionsDetailEmptySubtitle;

  /// No description provided for @collectionsSwipeToRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get collectionsSwipeToRemove;

  /// No description provided for @collectionsDocTypeImported.
  ///
  /// In en, this message translates to:
  /// **'Imported file'**
  String get collectionsDocTypeImported;

  /// No description provided for @collectionsDocTypeScanned.
  ///
  /// In en, this message translates to:
  /// **'Scanned document'**
  String get collectionsDocTypeScanned;

  /// No description provided for @navCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get navCollections;

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

  /// No description provided for @viewerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search in document…'**
  String get viewerSearchHint;

  /// No description provided for @viewerSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get viewerSearchNoResults;

  /// No description provided for @viewerSearchOf.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String viewerSearchOf(int current, int total);

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

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get languagePortuguese;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get languageHindi;

  /// No description provided for @themeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Select theme'**
  String get themeSheetTitle;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeDevice.
  ///
  /// In en, this message translates to:
  /// **'Device theme'**
  String get themeDevice;

  /// No description provided for @settingsAutoCrop.
  ///
  /// In en, this message translates to:
  /// **'Auto-crop'**
  String get settingsAutoCrop;

  /// No description provided for @settingsAutoCropSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically detect and crop document edges on capture'**
  String get settingsAutoCropSubtitle;

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

  /// No description provided for @scannerScanTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan type'**
  String get scannerScanTypeTitle;

  /// No description provided for @scannerScanTypeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard page'**
  String get scannerScanTypeStandard;

  /// No description provided for @scannerScanTypeStandardSub.
  ///
  /// In en, this message translates to:
  /// **'Single image per page'**
  String get scannerScanTypeStandardSub;

  /// No description provided for @scannerScanTypeIdCard.
  ///
  /// In en, this message translates to:
  /// **'ID Card / Licence'**
  String get scannerScanTypeIdCard;

  /// No description provided for @scannerScanTypeIdCardSub.
  ///
  /// In en, this message translates to:
  /// **'Front & back on one page'**
  String get scannerScanTypeIdCardSub;

  /// No description provided for @scannerIdCardFront.
  ///
  /// In en, this message translates to:
  /// **'Capture front side'**
  String get scannerIdCardFront;

  /// No description provided for @scannerIdCardBack.
  ///
  /// In en, this message translates to:
  /// **'Capture back side'**
  String get scannerIdCardBack;

  /// No description provided for @scannerIdCardSelectFront.
  ///
  /// In en, this message translates to:
  /// **'Select front side'**
  String get scannerIdCardSelectFront;

  /// No description provided for @scannerIdCardSelectBack.
  ///
  /// In en, this message translates to:
  /// **'Select back side'**
  String get scannerIdCardSelectBack;

  /// No description provided for @scannerIdCardInstructions.
  ///
  /// In en, this message translates to:
  /// **'You\'ll capture the front, then the back.\nBoth will be combined into one page.'**
  String get scannerIdCardInstructions;

  /// No description provided for @scannerIdCardGalleryInstructions.
  ///
  /// In en, this message translates to:
  /// **'Select the front image first, then the back.\nBoth will be combined into one page.'**
  String get scannerIdCardGalleryInstructions;

  /// No description provided for @scannerAddIdCard.
  ///
  /// In en, this message translates to:
  /// **'Add ID Card / Licence'**
  String get scannerAddIdCard;

  /// No description provided for @scannerIdCardLayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'ID Card Layout'**
  String get scannerIdCardLayoutTitle;

  /// No description provided for @scannerIdCardLayoutHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Side by side'**
  String get scannerIdCardLayoutHorizontal;

  /// No description provided for @scannerIdCardLayoutVertical.
  ///
  /// In en, this message translates to:
  /// **'Stacked'**
  String get scannerIdCardLayoutVertical;

  /// No description provided for @scannerIdCardRotateFront.
  ///
  /// In en, this message translates to:
  /// **'Rotate front'**
  String get scannerIdCardRotateFront;

  /// No description provided for @scannerIdCardRotateBack.
  ///
  /// In en, this message translates to:
  /// **'Rotate back'**
  String get scannerIdCardRotateBack;

  /// No description provided for @scannerIdCardDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get scannerIdCardDone;

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
  bool isSupported(Locale locale) => <String>[
    'ar',
    'en',
    'es',
    'fr',
    'hi',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
