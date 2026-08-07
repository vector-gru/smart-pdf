// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'SmartPDF';

  @override
  String get navHome => 'Início';

  @override
  String get navFiles => 'Ficheiros';

  @override
  String get navRecent => 'Recentes';

  @override
  String get navFavourite => 'Favoritos';

  @override
  String get homeSearchHint => 'Pesquisar documentos…';

  @override
  String get homeEmpty => 'Sem documentos';

  @override
  String get homeEmptySubtitle =>
      'Toque no botão abaixo para digitalizar ou importar';

  @override
  String get filesTitle => 'Ficheiros';

  @override
  String get filesBrowseMore => 'Ver mais ficheiros';

  @override
  String get filesSyncDrive => 'Sincronizar com o Google Drive';

  @override
  String get filesEmpty => 'Sem ficheiros';

  @override
  String get driveSheetTitle => 'Google Drive';

  @override
  String get driveSheetSubtitle =>
      'Selecione ficheiros PDF para importar para o SmartPDF';

  @override
  String get driveSigningIn => 'A iniciar sessão…';

  @override
  String get driveLoading => 'A carregar ficheiros…';

  @override
  String get driveEmpty => 'Nenhum ficheiro PDF encontrado no seu Drive.';

  @override
  String driveImporting(int current, int total) {
    return 'A importar $current de $total…';
  }

  @override
  String driveImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ficheiros importados',
      one: '1 ficheiro importado',
    );
    return '$_temp0';
  }

  @override
  String get driveImportButton => 'Importar selecionados';

  @override
  String get driveErrorSignIn =>
      'Não foi possível iniciar sessão no Google. Tente novamente.';

  @override
  String get driveErrorLoad =>
      'Falha ao carregar ficheiros do Drive. Tente novamente.';

  @override
  String get driveErrorImport => 'Alguns ficheiros não puderam ser importados.';

  @override
  String get driveSelectAll => 'Selecionar tudo';

  @override
  String get driveDeselectAll => 'Desselecionar tudo';

  @override
  String get driveSignOut => 'Terminar sessão';

  @override
  String get driveUploadSheetSubtitle =>
      'Selecione documentos locais para enviar para o Drive';

  @override
  String driveUploading(int current, int total) {
    return 'A enviar $current de $total…';
  }

  @override
  String driveUploadDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ficheiros enviados',
      one: '1 ficheiro enviado',
    );
    return '$_temp0';
  }

  @override
  String get driveUploadButton => 'Enviar selecionados';

  @override
  String get driveErrorUpload => 'Alguns ficheiros não puderam ser enviados.';

  @override
  String get driveTabDownload => 'Do Drive';

  @override
  String get driveTabUpload => 'Para o Drive';

  @override
  String get filesEmptySubtitle =>
      'Comece a adicionar ficheiros PDF para construir a sua biblioteca digital!';

  @override
  String get recentTitle => 'Recentes';

  @override
  String get recentEmpty => 'Sem documentos recentes';

  @override
  String get collectionsTitle => 'Coleções';

  @override
  String get collectionsNewCollection => 'Nova coleção';

  @override
  String get collectionsEditCollection => 'Editar coleção';

  @override
  String get collectionsNameLabel => 'Nome';

  @override
  String get collectionsColourLabel => 'Cor';

  @override
  String get collectionsIconLabel => 'Ícone';

  @override
  String get collectionsEmpty => 'Sem coleções ainda';

  @override
  String get collectionsEmptySubtitle =>
      'Agrupe os seus documentos em coleções para acesso mais fácil.';

  @override
  String get collectionsDeleteTitle => 'Eliminar coleção?';

  @override
  String collectionsDeleteContent(String name) {
    return 'Eliminar \"$name\"? Os documentos dentro não serão eliminados.';
  }

  @override
  String collectionsDocCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documentos',
      one: '1 documento',
      zero: 'Sem documentos',
    );
    return '$_temp0';
  }

  @override
  String get collectionsEdit => 'Editar';

  @override
  String get collectionsDelete => 'Eliminar';

  @override
  String get collectionsAddDocuments => 'Adicionar documentos';

  @override
  String get collectionsAddNoneAvailable =>
      'Todos os documentos já estão nesta coleção.';

  @override
  String collectionsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selecionados',
      one: '1 selecionado',
    );
    return '$_temp0';
  }

  @override
  String get collectionsAddButton => 'Adicionar';

  @override
  String get collectionsDetailEmpty => 'Sem documentos aqui';

  @override
  String get collectionsDetailEmptySubtitle =>
      'Adicione documentos a esta coleção para os ver aqui.';

  @override
  String get collectionsSwipeToRemove => 'Remover';

  @override
  String get collectionsDocTypeImported => 'Ficheiro importado';

  @override
  String get collectionsDocTypeScanned => 'Documento digitalizado';

  @override
  String get navCollections => 'Coleções';

  @override
  String get favouritesTitle => 'Favoritos';

  @override
  String get favouritesEmpty => 'Sem favoritos ainda';

  @override
  String get favouritesEmptySubtitle =>
      'Marque um documento com estrela para vê-lo aqui';

  @override
  String get viewerTitle => 'Visualizador';

  @override
  String get viewerSearchHint => 'Pesquisar no documento…';

  @override
  String get viewerSearchNoResults => 'Sem resultados';

  @override
  String viewerSearchOf(int current, int total) {
    return '$current de $total';
  }

  @override
  String get drawerSettings => 'Definições';

  @override
  String get drawerTheme => 'Tema';

  @override
  String get drawerRateApp => 'Avaliar app';

  @override
  String get drawerLanguage => 'Idioma';

  @override
  String get drawerShareApp => 'Partilhar esta app';

  @override
  String get drawerFeedback => 'Comentários e redes sociais';

  @override
  String get drawerPrivacy => 'Política de privacidade';

  @override
  String get drawerLicenses => 'Licenças de código aberto';

  @override
  String get languageSheetTitle => 'Selecionar idioma';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get languageFrench => 'Francês';

  @override
  String get languageSpanish => 'Espanhol';

  @override
  String get languageArabic => 'Árabe';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get themeSheetTitle => 'Selecionar tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeDevice => 'Tema do dispositivo';

  @override
  String get settingsAutoCrop => 'Recorte automático';

  @override
  String get settingsAutoCropSubtitle =>
      'Detetar e recortar automaticamente as bordas do documento ao capturar';

  @override
  String get docActionDelete => 'Eliminar';

  @override
  String get docActionRemove => 'Remover';

  @override
  String get docActionCancel => 'Cancelar';

  @override
  String get docActionRename => 'Renomear';

  @override
  String get docActionSave => 'Guardar';

  @override
  String get docActionPrint => 'Imprimir';

  @override
  String get docActionShare => 'Partilhar';

  @override
  String get docActionEdit => 'Editar';

  @override
  String get docDeleteTitle => 'Eliminar documento?';

  @override
  String get docRemoveTitle => 'Remover documento?';

  @override
  String docDeleteContent(String title) {
    return 'Tem a certeza de que quer eliminar \"$title\"?';
  }

  @override
  String docRemoveContent(String title) {
    return 'Isto irá remover \"$title\" do SmartPDF. O ficheiro original no seu dispositivo não será afetado.';
  }

  @override
  String get docRenameTitle => 'Renomear documento';

  @override
  String get docRenameLabel => 'Nome';

  @override
  String get docFavAdded => 'Adicionado aos favoritos';

  @override
  String get docFavRemoved => 'Removido dos favoritos';

  @override
  String get scannerSave => 'Guardar';

  @override
  String get scannerAddPage => 'Adicionar página';

  @override
  String get scannerCrop => 'Recortar';

  @override
  String get scannerColor => 'Cor';

  @override
  String get scannerRotate => 'Rodar';

  @override
  String get scannerReorder => 'Reordenar';

  @override
  String get scannerDelete => 'Eliminar';

  @override
  String get scannerNoPages =>
      'Sem páginas ainda.\nUse Adicionar página para começar.';

  @override
  String scannerPageOf(int current, int total) {
    return 'Página $current de $total';
  }

  @override
  String get scannerTakePhoto => 'Tirar outra foto';

  @override
  String get scannerSelectPhotos => 'Selecionar das fotos';

  @override
  String get scannerScanTypeTitle => 'Tipo de digitalização';

  @override
  String get scannerScanTypeStandard => 'Página normal';

  @override
  String get scannerScanTypeStandardSub => 'Uma imagem por página';

  @override
  String get scannerScanTypeIdCard =>
      'Bilhete de identidade / Carta de condução';

  @override
  String get scannerScanTypeIdCardSub => 'Frente e verso numa só página';

  @override
  String get scannerIdCardFront => 'Capturar frente';

  @override
  String get scannerIdCardBack => 'Capturar verso';

  @override
  String get scannerIdCardSelectFront => 'Selecionar frente';

  @override
  String get scannerIdCardSelectBack => 'Selecionar verso';

  @override
  String get scannerIdCardInstructions =>
      'Vai capturar a frente e depois o verso.\nAmbos serão combinados numa só página.';

  @override
  String get scannerIdCardGalleryInstructions =>
      'Selecione primeiro a frente e depois o verso.\nAmbos serão combinados numa só página.';

  @override
  String get scannerAddIdCard => 'Adicionar BI / Carta de condução';

  @override
  String get scannerIdCardLayoutTitle => 'Disposição do cartão';

  @override
  String get scannerIdCardLayoutHorizontal => 'Lado a lado';

  @override
  String get scannerIdCardLayoutVertical => 'Empilhado';

  @override
  String get scannerIdCardRotateFront => 'Rodar frente';

  @override
  String get scannerIdCardRotateBack => 'Rodar verso';

  @override
  String get scannerIdCardDone => 'Concluído';

  @override
  String get scannerDeletePageTitle => 'Eliminar página?';

  @override
  String scannerDeletePageContent(int page) {
    return 'Tem a certeza de que quer eliminar a página $page?';
  }

  @override
  String get cropAdjustBorders => 'Ajustar bordas';

  @override
  String get cropAuto => 'Auto';

  @override
  String get cropReset => 'Repor';

  @override
  String get cropRotate => 'Rodar';

  @override
  String get cropPreview => 'Pré-visualização';

  @override
  String get cropEdit => 'Editar';

  @override
  String get cropDone => 'Concluído';

  @override
  String get cropPreviewLabel => 'Isto é o que será guardado';

  @override
  String get cropPreviewBadge => 'PRÉ-VISUALIZAÇÃO';

  @override
  String get reorderPageTitle => 'Reordenar';

  @override
  String get filterApplyToAll => 'Aplicar a todas as páginas';

  @override
  String get filterApply => 'Aplicar';

  @override
  String get feedbackTitle => 'Entre em contacto';

  @override
  String get feedbackSubtitle =>
      'Envie comentários ou siga-nos nas redes sociais';

  @override
  String get privacyPolicyTitle => 'Política de privacidade';

  @override
  String get licensesTitle => 'Licenças de código aberto';

  @override
  String get licensesSmartPdf => 'Licença SmartPDF';

  @override
  String get licensesThirdParty => 'Pacotes de terceiros';

  @override
  String get licensesThirdPartyDesc =>
      'Esta app utiliza pacotes Flutter de código aberto. As suas licenças podem ser vistas abaixo.';

  @override
  String get licensesViewAll => 'Ver todas as licenças de pacotes';

  @override
  String get licensesLearnMore => 'Saiba mais sobre licenças de código aberto';

  @override
  String couldNotOpenPdf(String error) {
    return 'Não foi possível abrir o PDF:\n$error';
  }
}
