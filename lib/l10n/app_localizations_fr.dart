// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'SmartPDF';

  @override
  String get navHome => 'Accueil';

  @override
  String get navFiles => 'Fichiers';

  @override
  String get navRecent => 'Récents';

  @override
  String get navFavourite => 'Favoris';

  @override
  String get homeSearchHint => 'Rechercher des documents…';

  @override
  String get homeEmpty => 'Aucun document';

  @override
  String get homeEmptySubtitle =>
      'Appuyez sur le bouton ci-dessous pour scanner ou importer';

  @override
  String get filesTitle => 'Fichiers';

  @override
  String get filesBrowseMore => 'Parcourir plus de fichiers';

  @override
  String get filesSyncDrive => 'Synchroniser avec Google Drive';

  @override
  String get filesEmpty => 'Aucun fichier';

  @override
  String get driveSheetTitle => 'Google Drive';

  @override
  String get driveSheetSubtitle =>
      'Sélectionnez les PDF à importer dans SmartPDF';

  @override
  String get driveSigningIn => 'Connexion…';

  @override
  String get driveLoading => 'Chargement des fichiers…';

  @override
  String get driveEmpty => 'Aucun fichier PDF trouvé dans votre Drive.';

  @override
  String driveImporting(int current, int total) {
    return 'Importation de $current sur $total…';
  }

  @override
  String driveImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers importés',
      one: '1 fichier importé',
    );
    return '$_temp0';
  }

  @override
  String get driveImportButton => 'Importer la sélection';

  @override
  String get driveErrorSignIn =>
      'Impossible de se connecter à Google. Veuillez réessayer.';

  @override
  String get driveErrorLoad =>
      'Impossible de charger les fichiers Drive. Veuillez réessayer.';

  @override
  String get driveErrorImport =>
      'Certains fichiers n\'ont pas pu être importés.';

  @override
  String get driveSelectAll => 'Tout sélectionner';

  @override
  String get driveDeselectAll => 'Tout désélectionner';

  @override
  String get driveSignOut => 'Se déconnecter';

  @override
  String get driveUploadSheetSubtitle =>
      'Sélectionnez des documents locaux à envoyer sur Drive';

  @override
  String driveUploading(int current, int total) {
    return 'Envoi de $current sur $total…';
  }

  @override
  String driveUploadDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers envoyés',
      one: '1 fichier envoyé',
    );
    return '$_temp0';
  }

  @override
  String get driveUploadButton => 'Envoyer la sélection';

  @override
  String get driveErrorUpload =>
      'Certains fichiers n\'ont pas pu être envoyés.';

  @override
  String get driveTabDownload => 'Depuis Drive';

  @override
  String get driveTabUpload => 'Vers Drive';

  @override
  String get filesEmptySubtitle =>
      'Commencez à ajouter des PDF pour constituer votre bibliothèque !';

  @override
  String get recentTitle => 'Récents';

  @override
  String get recentEmpty => 'Aucun document récent';

  @override
  String get collectionsTitle => 'Collections';

  @override
  String get collectionsNewCollection => 'Nouvelle collection';

  @override
  String get collectionsEditCollection => 'Modifier la collection';

  @override
  String get collectionsNameLabel => 'Nom';

  @override
  String get collectionsColourLabel => 'Couleur';

  @override
  String get collectionsIconLabel => 'Icône';

  @override
  String get collectionsEmpty => 'Aucune collection';

  @override
  String get collectionsEmptySubtitle =>
      'Regroupez vos documents en collections pour y accéder plus facilement.';

  @override
  String get collectionsDeleteTitle => 'Supprimer la collection ?';

  @override
  String collectionsDeleteContent(String name) {
    return 'Supprimer « $name » ? Les documents à l\'intérieur ne seront pas supprimés.';
  }

  @override
  String collectionsDocCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
      zero: 'Aucun document',
    );
    return '$_temp0';
  }

  @override
  String get collectionsEdit => 'Modifier';

  @override
  String get collectionsDelete => 'Supprimer';

  @override
  String get collectionsAddDocuments => 'Ajouter des documents';

  @override
  String get collectionsAddNoneAvailable =>
      'Tous les documents sont déjà dans cette collection.';

  @override
  String collectionsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnés',
      one: '1 sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get collectionsAddButton => 'Ajouter';

  @override
  String get collectionsDetailEmpty => 'Aucun document ici';

  @override
  String get collectionsDetailEmptySubtitle =>
      'Ajoutez des documents à cette collection pour les voir ici.';

  @override
  String get collectionsSwipeToRemove => 'Retirer';

  @override
  String get collectionsDocTypeImported => 'Fichier importé';

  @override
  String get collectionsDocTypeScanned => 'Document numérisé';

  @override
  String get navCollections => 'Collections';

  @override
  String get favouritesTitle => 'Favoris';

  @override
  String get favouritesEmpty => 'Aucun favori';

  @override
  String get favouritesEmptySubtitle =>
      'Marquez un document d\'une étoile pour le retrouver ici';

  @override
  String get viewerTitle => 'Visionneuse';

  @override
  String get viewerSearchHint => 'Rechercher dans le document…';

  @override
  String get viewerSearchNoResults => 'Aucun résultat';

  @override
  String viewerSearchOf(int current, int total) {
    return '$current sur $total';
  }

  @override
  String get drawerSettings => 'Paramètres';

  @override
  String get drawerTheme => 'Thème';

  @override
  String get drawerRateApp => 'Noter l\'application';

  @override
  String get drawerLanguage => 'Langue';

  @override
  String get drawerShareApp => 'Partager l\'application';

  @override
  String get drawerFeedback => 'Feedback & Réseaux sociaux';

  @override
  String get drawerPrivacy => 'Politique de confidentialité';

  @override
  String get drawerLicenses => 'Licences open source';

  @override
  String get languageSheetTitle => 'Choisir la langue';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSpanish => 'Espagnol';

  @override
  String get languageArabic => 'Arabe';

  @override
  String get languagePortuguese => 'Portugais';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get themeSheetTitle => 'Choisir le thème';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeDevice => 'Thème de l\'appareil';

  @override
  String get settingsAutoCrop => 'Recadrage auto';

  @override
  String get settingsAutoCropSubtitle =>
      'Détecter et recadrer automatiquement les bords du document à la capture';

  @override
  String get docActionDelete => 'Supprimer';

  @override
  String get docActionRemove => 'Retirer';

  @override
  String get docActionCancel => 'Annuler';

  @override
  String get docActionRename => 'Renommer';

  @override
  String get docActionSave => 'Enregistrer';

  @override
  String get docActionPrint => 'Imprimer';

  @override
  String get docActionShare => 'Partager';

  @override
  String get docActionEdit => 'Modifier';

  @override
  String get docDeleteTitle => 'Supprimer le document ?';

  @override
  String get docRemoveTitle => 'Retirer le document ?';

  @override
  String docDeleteContent(String title) {
    return 'Êtes-vous sûr de vouloir supprimer « $title » ?';
  }

  @override
  String docRemoveContent(String title) {
    return 'Cela retirera « $title » de SmartPDF. Le fichier original sur votre appareil ne sera pas affecté.';
  }

  @override
  String get docRenameTitle => 'Renommer le document';

  @override
  String get docRenameLabel => 'Nom';

  @override
  String get docFavAdded => 'Ajouté aux favoris';

  @override
  String get docFavRemoved => 'Retiré des favoris';

  @override
  String get scannerSave => 'Enregistrer';

  @override
  String get scannerAddPage => 'Ajouter page';

  @override
  String get scannerCrop => 'Rogner';

  @override
  String get scannerColor => 'Couleur';

  @override
  String get scannerRotate => 'Pivoter';

  @override
  String get scannerReorder => 'Réorganiser';

  @override
  String get scannerDelete => 'Supprimer';

  @override
  String get scannerNoPages =>
      'Aucune page.\nUtilisez Ajouter page pour commencer.';

  @override
  String scannerPageOf(int current, int total) {
    return 'Page $current sur $total';
  }

  @override
  String get scannerTakePhoto => 'Prendre une autre photo';

  @override
  String get scannerSelectPhotos => 'Sélectionner depuis les photos';

  @override
  String get scannerScanTypeTitle => 'Type de numérisation';

  @override
  String get scannerScanTypeStandard => 'Page standard';

  @override
  String get scannerScanTypeStandardSub => 'Une image par page';

  @override
  String get scannerScanTypeIdCard => 'Carte d\'identité / Permis';

  @override
  String get scannerScanTypeIdCardSub => 'Recto et verso sur une page';

  @override
  String get scannerIdCardFront => 'Capturer le recto';

  @override
  String get scannerIdCardBack => 'Capturer le verso';

  @override
  String get scannerIdCardSelectFront => 'Sélectionner le recto';

  @override
  String get scannerIdCardSelectBack => 'Sélectionner le verso';

  @override
  String get scannerIdCardInstructions =>
      'Vous allez capturer le recto, puis le verso.\nLes deux seront combinés sur une page.';

  @override
  String get scannerIdCardGalleryInstructions =>
      'Sélectionnez d\'abord le recto, puis le verso.\nLes deux seront combinés sur une page.';

  @override
  String get scannerAddIdCard => 'Ajouter carte d\'identité / permis';

  @override
  String get scannerIdCardLayoutTitle => 'Mise en page';

  @override
  String get scannerIdCardLayoutHorizontal => 'Côte à côte';

  @override
  String get scannerIdCardLayoutVertical => 'Empilé';

  @override
  String get scannerIdCardRotateFront => 'Pivoter recto';

  @override
  String get scannerIdCardRotateBack => 'Pivoter verso';

  @override
  String get scannerIdCardDone => 'Terminer';

  @override
  String get scannerDeletePageTitle => 'Supprimer la page ?';

  @override
  String scannerDeletePageContent(int page) {
    return 'Êtes-vous sûr de vouloir supprimer la page $page ?';
  }

  @override
  String get cropAdjustBorders => 'Ajuster les bords';

  @override
  String get cropAuto => 'Auto';

  @override
  String get cropReset => 'Réinitialiser';

  @override
  String get cropRotate => 'Pivoter';

  @override
  String get cropPreview => 'Aperçu';

  @override
  String get cropEdit => 'Modifier';

  @override
  String get cropDone => 'Terminer';

  @override
  String get cropPreviewLabel => 'Voici ce qui sera enregistré';

  @override
  String get cropPreviewBadge => 'APERÇU';

  @override
  String get reorderPageTitle => 'Réorganiser';

  @override
  String get filterApplyToAll => 'Appliquer à toutes les pages';

  @override
  String get filterApply => 'Appliquer';

  @override
  String get feedbackTitle => 'Nous contacter';

  @override
  String get feedbackSubtitle =>
      'Envoyez un retour ou suivez-nous sur les réseaux sociaux';

  @override
  String get privacyPolicyTitle => 'Politique de confidentialité';

  @override
  String get licensesTitle => 'Licences open source';

  @override
  String get licensesSmartPdf => 'Licence SmartPDF';

  @override
  String get licensesThirdParty => 'Paquets tiers';

  @override
  String get licensesThirdPartyDesc =>
      'Cette application utilise des paquets Flutter open source. Leurs licences peuvent être consultées ci-dessous.';

  @override
  String get licensesViewAll => 'Voir toutes les licences';

  @override
  String get licensesLearnMore => 'En savoir plus sur les licences open source';

  @override
  String couldNotOpenPdf(String error) {
    return 'Impossible d\'ouvrir le PDF :\n$error';
  }
}
