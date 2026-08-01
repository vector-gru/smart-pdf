// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'SmartPDF';

  @override
  String get navHome => 'Inicio';

  @override
  String get navFiles => 'Archivos';

  @override
  String get navRecent => 'Recientes';

  @override
  String get navFavourite => 'Favoritos';

  @override
  String get homeSearchHint => 'Buscar documentos…';

  @override
  String get homeEmpty => 'Sin documentos';

  @override
  String get homeEmptySubtitle =>
      'Toca el botón de abajo para escanear o importar';

  @override
  String get filesTitle => 'Archivos';

  @override
  String get filesBrowseMore => 'Ver más archivos';

  @override
  String get filesSyncDrive => 'Sincronizar con Google Drive';

  @override
  String get filesEmpty => 'Sin archivos';

  @override
  String get driveSheetTitle => 'Google Drive';

  @override
  String get driveSheetSubtitle =>
      'Selecciona los archivos PDF para importar en SmartPDF';

  @override
  String get driveSigningIn => 'Iniciando sesión…';

  @override
  String get driveLoading => 'Cargando archivos…';

  @override
  String get driveEmpty => 'No se encontraron archivos PDF en tu Drive.';

  @override
  String driveImporting(int current, int total) {
    return 'Importando $current de $total…';
  }

  @override
  String driveImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos importados',
      one: '1 archivo importado',
    );
    return '$_temp0';
  }

  @override
  String get driveImportButton => 'Importar selección';

  @override
  String get driveErrorSignIn =>
      'No se pudo iniciar sesión en Google. Inténtalo de nuevo.';

  @override
  String get driveErrorLoad =>
      'Error al cargar los archivos de Drive. Inténtalo de nuevo.';

  @override
  String get driveErrorImport => 'Algunos archivos no pudieron importarse.';

  @override
  String get driveSelectAll => 'Seleccionar todo';

  @override
  String get driveDeselectAll => 'Deseleccionar todo';

  @override
  String get driveSignOut => 'Cerrar sesión';

  @override
  String get driveUploadSheetSubtitle =>
      'Selecciona documentos locales para subir a Drive';

  @override
  String driveUploading(int current, int total) {
    return 'Subiendo $current de $total…';
  }

  @override
  String driveUploadDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos subidos',
      one: '1 archivo subido',
    );
    return '$_temp0';
  }

  @override
  String get driveUploadButton => 'Subir selección';

  @override
  String get driveErrorUpload => 'Algunos archivos no pudieron subirse.';

  @override
  String get driveTabDownload => 'Desde Drive';

  @override
  String get driveTabUpload => 'A Drive';

  @override
  String get filesEmptySubtitle =>
      '¡Empieza a agregar archivos PDF para construir tu biblioteca digital!';

  @override
  String get recentTitle => 'Recientes';

  @override
  String get recentEmpty => 'Sin documentos recientes';

  @override
  String get favouritesTitle => 'Favoritos';

  @override
  String get favouritesEmpty => 'Sin favoritos aún';

  @override
  String get favouritesEmptySubtitle =>
      'Marca un documento con estrella para verlo aquí';

  @override
  String get viewerTitle => 'Visor';

  @override
  String get viewerSearchHint => 'Buscar en el documento…';

  @override
  String get viewerSearchNoResults => 'Sin resultados';

  @override
  String viewerSearchOf(int current, int total) {
    return '$current de $total';
  }

  @override
  String get drawerSettings => 'Ajustes';

  @override
  String get drawerTheme => 'Tema';

  @override
  String get drawerRateApp => 'Valorar la app';

  @override
  String get drawerLanguage => 'Idioma';

  @override
  String get drawerShareApp => 'Compartir esta app';

  @override
  String get drawerFeedback => 'Comentarios y redes sociales';

  @override
  String get drawerPrivacy => 'Política de privacidad';

  @override
  String get drawerLicenses => 'Licencias de código abierto';

  @override
  String get languageSheetTitle => 'Seleccionar idioma';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageFrench => 'Francés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageArabic => 'Árabe';

  @override
  String get languagePortuguese => 'Portugués';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get themeSheetTitle => 'Seleccionar tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeDevice => 'Tema del dispositivo';

  @override
  String get settingsAutoCrop => 'Recorte automático';

  @override
  String get settingsAutoCropSubtitle =>
      'Detectar y recortar automáticamente los bordes del documento al capturar';

  @override
  String get docActionDelete => 'Eliminar';

  @override
  String get docActionRemove => 'Quitar';

  @override
  String get docActionCancel => 'Cancelar';

  @override
  String get docActionRename => 'Renombrar';

  @override
  String get docActionSave => 'Guardar';

  @override
  String get docActionPrint => 'Imprimir';

  @override
  String get docActionShare => 'Compartir';

  @override
  String get docActionEdit => 'Editar';

  @override
  String get docDeleteTitle => '¿Eliminar documento?';

  @override
  String get docRemoveTitle => '¿Quitar documento?';

  @override
  String docDeleteContent(String title) {
    return '¿Seguro que quieres eliminar \"$title\"?';
  }

  @override
  String docRemoveContent(String title) {
    return 'Esto quitará \"$title\" de SmartPDF. El archivo original en tu dispositivo no se verá afectado.';
  }

  @override
  String get docRenameTitle => 'Renombrar documento';

  @override
  String get docRenameLabel => 'Nombre';

  @override
  String get docFavAdded => 'Añadido a favoritos';

  @override
  String get docFavRemoved => 'Eliminado de favoritos';

  @override
  String get scannerSave => 'Guardar';

  @override
  String get scannerAddPage => 'Añadir página';

  @override
  String get scannerCrop => 'Recortar';

  @override
  String get scannerColor => 'Color';

  @override
  String get scannerRotate => 'Rotar';

  @override
  String get scannerReorder => 'Reordenar';

  @override
  String get scannerDelete => 'Eliminar';

  @override
  String get scannerNoPages =>
      'Sin páginas aún.\nUsa Añadir página para comenzar.';

  @override
  String scannerPageOf(int current, int total) {
    return 'Página $current de $total';
  }

  @override
  String get scannerTakePhoto => 'Tomar otra foto';

  @override
  String get scannerSelectPhotos => 'Seleccionar de fotos';

  @override
  String get scannerDeletePageTitle => '¿Eliminar página?';

  @override
  String scannerDeletePageContent(int page) {
    return '¿Seguro que quieres eliminar la página $page?';
  }

  @override
  String get cropAdjustBorders => 'Ajustar bordes';

  @override
  String get cropAuto => 'Auto';

  @override
  String get cropReset => 'Restablecer';

  @override
  String get cropRotate => 'Rotar';

  @override
  String get cropPreview => 'Vista previa';

  @override
  String get cropEdit => 'Editar';

  @override
  String get cropDone => 'Listo';

  @override
  String get cropPreviewLabel => 'Esto es lo que se guardará';

  @override
  String get cropPreviewBadge => 'VISTA PREVIA';

  @override
  String get reorderPageTitle => 'Reordenar';

  @override
  String get filterApplyToAll => 'Aplicar a todas las páginas';

  @override
  String get filterApply => 'Aplicar';

  @override
  String get feedbackTitle => 'Contáctanos';

  @override
  String get feedbackSubtitle =>
      'Envía comentarios o síguenos en redes sociales';

  @override
  String get privacyPolicyTitle => 'Política de privacidad';

  @override
  String get licensesTitle => 'Licencias de código abierto';

  @override
  String get licensesSmartPdf => 'Licencia SmartPDF';

  @override
  String get licensesThirdParty => 'Paquetes de terceros';

  @override
  String get licensesThirdPartyDesc =>
      'Esta app usa paquetes Flutter de código abierto. Sus licencias se pueden ver a continuación.';

  @override
  String get licensesViewAll => 'Ver todas las licencias de paquetes';

  @override
  String get licensesLearnMore =>
      'Más información sobre licencias de código abierto';

  @override
  String couldNotOpenPdf(String error) {
    return 'No se pudo abrir el PDF:\n$error';
  }
}
