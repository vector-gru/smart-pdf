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
  String get filesEmptySubtitle =>
      'Commencez à ajouter des PDF pour constituer votre bibliothèque !';

  @override
  String get recentTitle => 'Récents';

  @override
  String get recentEmpty => 'Aucun document récent';

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
