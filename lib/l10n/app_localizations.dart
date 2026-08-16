import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Hand-written app localizations (English + Thai).
///
/// There's no Flutter SDK available in the environment this was built in
/// to run `flutter gen-l10n`, so this plays the same role as the generated
/// `AppLocalizations` class would: a [LocalizationsDelegate] plus a lookup
/// table per locale, with typed getters/methods so call sites read as
/// `AppLocalizations.of(context).save` instead of raw string keys.
///
/// A key missing from a non-English table falls back to the English value
/// (see [_t]) instead of throwing, so an incomplete translation degrades
/// gracefully rather than crashing the screen.
class AppLocalizations {
  AppLocalizations(this._values);

  final Map<String, String> _values;

  static const supportedLocales = [Locale('en'), Locale('th')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String _t(String key) => _values[key] ?? _en[key] ?? key;

  String _p(String key, Map<String, String> params) {
    var value = _t(key);
    for (final entry in params.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }

  // ---------------------------------------------------------------------
  // Common
  // ---------------------------------------------------------------------
  String get appTitle => _t('appTitle');
  String get save => _t('save');
  String get cancel => _t('cancel');
  String get delete => _t('delete');
  String get remove => _t('remove');
  String get edit => _t('edit');
  String get add => _t('add');
  String get addManually => _t('addManually');
  String get scanDocument => _t('scanDocument');
  String get scanDocumentSubtitle => _t('scanDocumentSubtitle');
  String get chooseFromGallery => _t('chooseFromGallery');
  String documentScanFailed(String error) =>
      _p('documentScanFailed', {'error': error});
  String get saved => _t('saved');

  // ---------------------------------------------------------------------
  // Home / navigation
  // ---------------------------------------------------------------------
  String get navLibrary => _t('navLibrary');
  String get navCategories => _t('navCategories');
  String get navSettings => _t('navSettings');

  // ---------------------------------------------------------------------
  // Library screen
  // ---------------------------------------------------------------------
  String get myLibrary => _t('myLibrary');
  String get viewModeListLabel => _t('viewModeListLabel');
  String get viewModeShelfCoverLabel => _t('viewModeShelfCoverLabel');
  String get viewModeShelfSpineLabel => _t('viewModeShelfSpineLabel');
  String switchToViewMode(String mode) =>
      _p('switchToViewMode', {'mode': mode});
  String get searchHint => _t('searchHint');
  String get scanToSearch => _t('scanToSearch');
  String get openSearch => _t('openSearch');
  String get closeSearch => _t('closeSearch');
  String get filterAll => _t('filterAll');
  String get emptyLibrary => _t('emptyLibrary');
  String get noBooksYet => _t('noBooksYet');
  String get scanIsbnBarcode => _t('scanIsbnBarcode');
  String get enterIsbnNumber => _t('enterIsbnNumber');
  String get filterStatusLabel => _t('filterStatusLabel');
  String get filterCategoryLabel => _t('filterCategoryLabel');
  String get sortByLabel => _t('sortByLabel');
  String get sortByDateAdded => _t('sortByDateAdded');
  String get sortByAuthor => _t('sortByAuthor');
  String get noSeriesGroupLabel => _t('noSeriesGroupLabel');

  // ---------------------------------------------------------------------
  // Reading-status filters (LibraryStatusFilter) / stamps (StampType)
  // ---------------------------------------------------------------------
  String get statusNotStarted => _t('statusNotStarted');
  String get statusReading => _t('statusReading');
  String get statusFinished => _t('statusFinished');
  String get statusDropped => _t('statusDropped');
  String get statusPaused => _t('statusPaused');

  // ---------------------------------------------------------------------
  // Shelf display mode / cover slots
  // ---------------------------------------------------------------------
  String get shelfModeCover => _t('shelfModeCover');
  String get shelfModeSpine => _t('shelfModeSpine');
  String get coverSlotFront => _t('coverSlotFront');
  String get coverSlotSpine => _t('coverSlotSpine');
  String get coverSlotBack => _t('coverSlotBack');

  // ---------------------------------------------------------------------
  // Scan screen
  // ---------------------------------------------------------------------
  String get scanIsbnTitle => _t('scanIsbnTitle');
  String get scanToSearchTitle => _t('scanToSearchTitle');
  String lookingUpIsbn(String isbn) => _p('lookingUpIsbn', {'isbn': isbn});
  String noBookWithIsbn(String isbn) => _p('noBookWithIsbn', {'isbn': isbn});
  String noMetadataAddManually(String isbn) =>
      _p('noMetadataAddManually', {'isbn': isbn});
  String get scanAgain => _t('scanAgain');
  String get addToLibrary => _t('addToLibrary');
  String get scanToSearchHint => _t('scanToSearchHint');
  String get scanIsbnHint => _t('scanIsbnHint');

  // ---------------------------------------------------------------------
  // Page scan screen (Saved pages)
  // ---------------------------------------------------------------------
  String get savePageTitle => _t('savePageTitle');
  String get savePageHint => _t('savePageHint');
  String get pageLabelField => _t('pageLabelField');
  String get pageLabelHint => _t('pageLabelHint');
  String get noteField => _t('noteField');

  // ---------------------------------------------------------------------
  // Cover scan screen
  // ---------------------------------------------------------------------
  String get editCoverPresetTitle => _t('editCoverPresetTitle');
  String get scanCoverTitle => _t('scanCoverTitle');
  String get coverSlotsHint => _t('coverSlotsHint');
  String get useApiCoverForFront => _t('useApiCoverForFront');
  String get presetLabelField => _t('presetLabelField');
  String get presetLabelHint => _t('presetLabelHint');
  String get replaceTooltip => _t('replaceTooltip');

  // ---------------------------------------------------------------------
  // Reading timeline (stamp_timeline.dart)
  // ---------------------------------------------------------------------
  String get readingTimelineTitle => _t('readingTimelineTitle');
  String get addStamp => _t('addStamp');
  String get editStamp => _t('editStamp');
  String get noStampsYet => _t('noStampsYet');
  String get deleteStampTitle => _t('deleteStampTitle');
  String removeStampConfirm(String statusLabel) =>
      _p('removeStampConfirm', {'status': statusLabel});
  String get whenField => _t('whenField');

  // ---------------------------------------------------------------------
  // Settings screen
  // ---------------------------------------------------------------------
  String get settingsTitle => _t('settingsTitle');
  String get ocrSectionTitle => _t('ocrSectionTitle');
  String get ocrSectionBody => _t('ocrSectionBody');
  String get cloudVisionKeyField => _t('cloudVisionKeyField');
  String get languageSectionTitle => _t('languageSectionTitle');
  String get languageSectionBody => _t('languageSectionBody');
  String get appUpdateSectionTitle => _t('appUpdateSectionTitle');
  String get appUpdateSectionBody => _t('appUpdateSectionBody');
  String get checkForUpdates => _t('checkForUpdates');
  String get downloadAndInstall => _t('downloadAndInstall');
  String downloading(String percent) => _p('downloading', {'percent': percent});
  String upToDate(String version) => _p('upToDate', {'version': version});
  String updateAvailable(String version) =>
      _p('updateAvailable', {'version': version});
  String couldNotCheckForUpdates(String error) =>
      _p('couldNotCheckForUpdates', {'error': error});
  String updateFailed(String error) => _p('updateFailed', {'error': error});
  String currentVersion(String version) =>
      _p('currentVersion', {'version': version});

  // ---------------------------------------------------------------------
  // Language names (AppLocale)
  // ---------------------------------------------------------------------
  String get localeSystemDefault => _t('localeSystemDefault');
  String get localeEnglish => _t('localeEnglish');
  String get localeThai => _t('localeThai');

  // ---------------------------------------------------------------------
  // ISBN entry screen (isbn_entry_screen.dart)
  // ---------------------------------------------------------------------
  String get enterIsbnTitle => _t('enterIsbnTitle');
  String get enterIsbnBody => _t('enterIsbnBody');
  String get isbnField => _t('isbnField');
  String invalidIsbnError(String raw) => _p('invalidIsbnError', {'raw': raw});
  String get lookUp => _t('lookUp');

  // ---------------------------------------------------------------------
  // Category manager screen (category_manager_screen.dart)
  // ---------------------------------------------------------------------
  String get categoryManagerTitle => _t('categoryManagerTitle');
  String get newCategoryTitle => _t('newCategoryTitle');
  String get categoryNameField => _t('categoryNameField');
  String get renameCategoryTitle => _t('renameCategoryTitle');
  String get noCategoriesYet => _t('noCategoriesYet');

  // ---------------------------------------------------------------------
  // Book pages screen (book_pages_screen.dart)
  // ---------------------------------------------------------------------
  String get savedPagesTitle => _t('savedPagesTitle');
  String get addPageLabel => _t('addPageLabel');
  String get noSavedPagesYet => _t('noSavedPagesYet');
  String get editNoteTitle => _t('editNoteTitle');
  String get editNoteField => _t('editNoteField');
  String get deletePageTitle => _t('deletePageTitle');
  String get deletePageBody => _t('deletePageBody');
  String get savedPageFallbackTitle => _t('savedPageFallbackTitle');

  // ---------------------------------------------------------------------
  // Cover presets screen (cover_presets_screen.dart)
  // ---------------------------------------------------------------------
  String get bookCoversTitle => _t('bookCoversTitle');
  String get scanNewPresetLabel => _t('scanNewPresetLabel');
  String get noCoversYet => _t('noCoversYet');
  String get renamePresetTitle => _t('renamePresetTitle');
  String get renamePresetLabelField => _t('renamePresetLabelField');
  String get deletePresetTitle => _t('deletePresetTitle');
  String deletePresetConfirm(String label) =>
      _p('deletePresetConfirm', {'label': label});
  String get thisCoverPreset => _t('thisCoverPreset');
  String get onShelfLabel => _t('onShelfLabel');
  String get untitledPresetLabel => _t('untitledPresetLabel');
  String get coverThumbFront => _t('coverThumbFront');
  String get coverThumbSpine => _t('coverThumbSpine');
  String get coverThumbBack => _t('coverThumbBack');
  String get tapPhotosHint => _t('tapPhotosHint');
  String get useOnShelfLabel => _t('useOnShelfLabel');
  String get renameTooltip => _t('renameTooltip');
  String get editPhotosTooltip => _t('editPhotosTooltip');

  // ---------------------------------------------------------------------
  // Book detail screen (book_detail_screen.dart)
  // ---------------------------------------------------------------------
  String get bookRemovedMessage => _t('bookRemovedMessage');
  String get removeBookTitle => _t('removeBookTitle');
  String deleteBookConfirm(String title) =>
      _p('deleteBookConfirm', {'title': title});
  String get scanCoverLabel => _t('scanCoverLabel');
  String get manageCoversLabel => _t('manageCoversLabel');
  String get readingStatusLabel => _t('readingStatusLabel');
  String get categoriesLabel => _t('categoriesLabel');
  String get editCategoriesTooltip => _t('editCategoriesTooltip');
  String get noCategoriesAssignedHint => _t('noCategoriesAssignedHint');
  String get selectCategoriesTitle => _t('selectCategoriesTitle');
  String get savedPagesLabel => _t('savedPagesLabel');
  String get viewAllLabel => _t('viewAllLabel');
  String get descriptionLabel => _t('descriptionLabel');
  String get myNotesLabel => _t('myNotesLabel');
  String illustratedBy(String names) => _p('illustratedBy', {'names': names});
  String isbnLabel(String isbn) => _p('isbnLabel', {'isbn': isbn});
  String seriesWithVolume(String series, String volume) =>
      _p('seriesWithVolume', {'series': series, 'volume': volume});
  String sourceLabel(String source) => _p('sourceLabel', {'source': source});
  String get book3DPreviewTitle => _t('book3DPreviewTitle');
  String get book3DFlipHint => _t('book3DFlipHint');

  // ---------------------------------------------------------------------
  // Book edit screen (book_edit_screen.dart)
  // ---------------------------------------------------------------------
  String get editBookTitle => _t('editBookTitle');
  String get addBookTitle => _t('addBookTitle');
  String get titleField => _t('titleField');
  String get titleRequiredError => _t('titleRequiredError');
  String get authorsField => _t('authorsField');
  String get illustratorsField => _t('illustratorsField');
  String get seriesField => _t('seriesField');
  String get seriesVolumeField => _t('seriesVolumeField');
  String get seriesVolumeHint => _t('seriesVolumeHint');
  String get isbn13Field => _t('isbn13Field');
  String get publisherField => _t('publisherField');
  String get publishedDateField => _t('publishedDateField');
  String get pageCountField => _t('pageCountField');
  String get descriptionField => _t('descriptionField');
  String get myNotesField => _t('myNotesField');
  String scanFieldTooltip(String field) =>
      _p('scanFieldTooltip', {'field': field});
  String textScanFailed(String error) =>
      _p('textScanFailed', {'error': error});
  String reviewScannedTitle(String field) =>
      _p('reviewScannedTitle', {'field': field});
  String get ocrNoTextRecognized => _t('ocrNoTextRecognized');
  String ocrEditAndFill(String field) =>
      _p('ocrEditAndFill', {'field': field});
  String get useThisTextLabel => _t('useThisTextLabel');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    final values = locale.languageCode == 'th' ? _th : _en;
    return SynchronousFuture(AppLocalizations(values));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const _en = <String, String>{
  // Common
  'appTitle': 'QuetzaLib',
  'save': 'Save',
  'cancel': 'Cancel',
  'delete': 'Delete',
  'remove': 'Remove',
  'edit': 'Edit',
  'add': 'Add',
  'addManually': 'Add manually',
  'scanDocument': 'Scan document',
  'scanDocumentSubtitle': 'Auto-crops and straightens the page',
  'chooseFromGallery': 'Choose from gallery',
  'documentScanFailed': 'Document scan failed: {error}',
  'saved': 'Saved.',

  // Home / navigation
  'navLibrary': 'Library',
  'navCategories': 'Categories',
  'navSettings': 'Settings',

  // Library screen
  'myLibrary': 'My Library',
  'viewModeListLabel': 'List view',
  'viewModeShelfCoverLabel': 'Shelf view (covers)',
  'viewModeShelfSpineLabel': 'Shelf view (spines)',
  'switchToViewMode': 'Switch to {mode}',
  'searchHint': 'Search title, author, ISBN',
  'scanToSearch': 'Scan to search',
  'openSearch': 'Search',
  'closeSearch': 'Close search',
  'filterAll': 'All',
  'emptyLibrary':
      'No books yet. Scan a barcode or add one manually to get started.',
  'noBooksYet': 'No books yet.',
  'scanIsbnBarcode': 'Scan ISBN barcode',
  'enterIsbnNumber': 'Enter ISBN number',
  'filterStatusLabel': 'Status',
  'filterCategoryLabel': 'Category',
  'sortByLabel': 'Sort by',
  'sortByDateAdded': 'Date added',
  'sortByAuthor': 'Author',
  'noSeriesGroupLabel': 'No series',

  // Reading status
  'statusNotStarted': 'Not started',
  'statusReading': 'Reading',
  'statusFinished': 'Finished',
  'statusDropped': 'Dropped',
  'statusPaused': 'Paused',

  // Shelf mode / cover slots
  'shelfModeCover': 'Cover',
  'shelfModeSpine': 'Spine',
  'coverSlotFront': 'Front cover',
  'coverSlotSpine': 'Spine',
  'coverSlotBack': 'Back cover',

  // Scan screen
  'scanIsbnTitle': 'Scan ISBN',
  'scanToSearchTitle': 'Scan to search',
  'lookingUpIsbn': 'Looking up {isbn}...',
  'noBookWithIsbn': 'No book with ISBN {isbn} in your library.',
  'noMetadataAddManually':
      'No metadata found for {isbn}. You can still add it manually.',
  'scanAgain': 'Scan again',
  'addToLibrary': 'Add to library',
  'scanToSearchHint': 'Scan a book already on your shelf to jump to it.',
  'scanIsbnHint': 'Point the camera at the barcode on the back of the book.',

  // Page scan screen
  'savePageTitle': 'Save a page',
  'savePageHint':
      'Photograph a page or illustration to keep as a reminder inside the app.',
  'pageLabelField': 'Page label (optional)',
  'pageLabelHint': 'e.g. p.128 or "map illustration"',
  'noteField': 'Note (optional)',

  // Cover scan screen
  'editCoverPresetTitle': 'Edit cover preset',
  'scanCoverTitle': 'Scan cover',
  'coverSlotsHint':
      'Front cover, spine, and back cover are all optional — skip any of '
          'them for now and come back to scan the rest into this same preset '
          'later.',
  'useApiCoverForFront': 'Use existing API cover for front',
  'presetLabelField': 'Preset label (optional)',
  'presetLabelHint': 'e.g. Hardcover 2020',
  'replaceTooltip': 'Replace photo',

  // Reading timeline
  'readingTimelineTitle': 'Reading timeline',
  'addStamp': 'Add stamp',
  'editStamp': 'Edit stamp',
  'noStampsYet':
      'No stamps yet. Add one when you start, pause, drop, or finish this '
          'book.',
  'deleteStampTitle': 'Delete stamp?',
  'removeStampConfirm': 'Remove this "{status}" stamp from the timeline?',
  'whenField': 'When',

  // Settings screen
  'settingsTitle': 'Settings',
  'ocrSectionTitle': 'Text scanning (OCR)',
  'ocrSectionBody':
      'The camera-scan buttons next to Title, Authors, Illustrators, ISBN, '
          'and Publisher in the book editor use on-device text recognition by '
          'default — free and offline, but Latin-script only, so Thai text '
          'won\'t be read correctly. Enter a Google Cloud Vision API key here '
          'to use it instead: it reads Thai as well as Latin text, at the '
          'cost of a network request per scan billed to your Cloud account. '
          'Leave it blank to keep using on-device recognition.',
  'cloudVisionKeyField': 'Cloud Vision API key (optional)',
  'languageSectionTitle': 'Language',
  'languageSectionBody':
      'Choose the app\'s display language, or follow your device\'s system '
          'language.',
  'appUpdateSectionTitle': 'App update',
  'appUpdateSectionBody':
      'QuetzaLib isn\'t distributed through the Play Store, so updates are '
          'installed the same way as the first install: downloading the '
          'latest APK and installing it over this app. Your books and '
          'settings are kept.',
  'checkForUpdates': 'Check for updates',
  'downloadAndInstall': 'Download & install',
  'downloading': 'Downloading… {percent}%',
  'upToDate': "You're up to date (v{version}).",
  'updateAvailable': 'Update available: v{version}',
  'couldNotCheckForUpdates': 'Could not check for updates: {error}',
  'updateFailed': 'Update failed: {error}',
  'currentVersion': 'Current version: {version}',

  // Language names
  'localeSystemDefault': 'System default',
  'localeEnglish': 'English',
  'localeThai': 'ไทย (Thai)',

  // ISBN entry screen (isbn_entry_screen.dart)
  'enterIsbnTitle': 'Enter ISBN',
  'enterIsbnBody':
      'Type or paste the ISBN printed near the barcode on the back '
          'of the book.',
  'isbnField': 'ISBN-10 or ISBN-13',
  'invalidIsbnError': '"{raw}" doesn\'t look like a valid ISBN-10/13.',
  'lookUp': 'Look up',

  // Category manager screen (category_manager_screen.dart)
  'categoryManagerTitle': 'Categories',
  'newCategoryTitle': 'New category',
  'categoryNameField': 'Name',
  'renameCategoryTitle': 'Rename category',
  'noCategoriesYet': 'No categories yet. Tap + to add one.',

  // Book pages screen (book_pages_screen.dart)
  'savedPagesTitle': 'Saved pages',
  'addPageLabel': 'Add page',
  'noSavedPagesYet':
      'No saved pages yet. Photograph a page or illustration you '
          'want to remember.',
  'editNoteTitle': 'Edit note',
  'editNoteField': 'Note',
  'deletePageTitle': 'Delete this page?',
  'deletePageBody': 'This saved page and its photo will be removed.',
  'savedPageFallbackTitle': 'Saved page',

  // Cover presets screen (cover_presets_screen.dart)
  'bookCoversTitle': 'Book covers',
  'scanNewPresetLabel': 'Scan new preset',
  'noCoversYet':
      'No scanned covers yet. Scan the front cover and spine to '
          'show this book as artwork on your shelf.',
  'renamePresetTitle': 'Rename preset',
  'renamePresetLabelField': 'Label',
  'deletePresetTitle': 'Delete preset?',
  'deletePresetConfirm':
      'Delete "{label}"? Its photos will be removed too.',
  'thisCoverPreset': 'this cover preset',
  'onShelfLabel': 'On shelf',
  'untitledPresetLabel': 'Untitled preset',
  'coverThumbFront': 'Front',
  'coverThumbSpine': 'Spine',
  'coverThumbBack': 'Back',
  'tapPhotosHint':
      'Tap a photo to view it full-size, or use the edit button below to '
          'add, replace, or scan new ones.',
  'useOnShelfLabel': 'Use on shelf',
  'renameTooltip': 'Rename',
  'editPhotosTooltip': 'Edit photos',

  // Book detail screen (book_detail_screen.dart)
  'bookRemovedMessage': 'This book was removed.',
  'removeBookTitle': 'Remove book?',
  'deleteBookConfirm': 'Delete "{title}" from your library?',
  'scanCoverLabel': 'Scan cover',
  'manageCoversLabel': 'Manage covers',
  'readingStatusLabel': 'Reading status',
  'categoriesLabel': 'Categories',
  'editCategoriesTooltip': 'Edit categories',
  'noCategoriesAssignedHint': 'No categories yet. Tap the icon above to add some.',
  'selectCategoriesTitle': 'Select categories',
  'savedPagesLabel': 'Saved pages',
  'viewAllLabel': 'View all',
  'descriptionLabel': 'Description',
  'myNotesLabel': 'My notes',
  'illustratedBy': 'Illustrated by {names}',
  'isbnLabel': 'ISBN {isbn}',
  'sourceLabel': 'Source: {source}',
  'book3DPreviewTitle': '3D preview',
  'book3DFlipHint': 'Tap the cover to flip it around.',
  'seriesWithVolume': '{series} · Vol. {volume}',

  // Book edit screen (book_edit_screen.dart)
  'editBookTitle': 'Edit Book',
  'addBookTitle': 'Add Book',
  'titleField': 'Title',
  'titleRequiredError': 'Title is required',
  'authorsField': 'Authors (comma-separated)',
  'illustratorsField': 'Illustrators (comma-separated)',
  'seriesField': 'Series',
  'seriesVolumeField': 'Volume #',
  'seriesVolumeHint': 'e.g. 3 or 4.5',
  'isbn13Field': 'ISBN-13',
  'publisherField': 'Publisher',
  'publishedDateField': 'Published date',
  'pageCountField': 'Page count',
  'descriptionField': 'Description',
  'myNotesField': 'My notes',
  'scanFieldTooltip': 'Scan {field}',
  'textScanFailed': 'Text scan failed: {error}',
  'reviewScannedTitle': 'Review scanned {field}',
  'ocrNoTextRecognized':
      'No text was recognized in the photo. You can type it '
          'in manually below, or cancel and try again.',
  'ocrEditAndFill':
      'Edit if needed, then use this text to fill in {field}.',
  'useThisTextLabel': 'Use this text',
};

const _th = <String, String>{
  // Common
  'appTitle': 'QuetzaLib',
  'save': 'บันทึก',
  'cancel': 'ยกเลิก',
  'delete': 'ลบ',
  'remove': 'นำออก',
  'edit': 'แก้ไข',
  'add': 'เพิ่ม',
  'addManually': 'เพิ่มด้วยตนเอง',
  'scanDocument': 'สแกนเอกสาร',
  'scanDocumentSubtitle': 'ครอบตัดและจัดภาพให้ตรงโดยอัตโนมัติ',
  'chooseFromGallery': 'เลือกจากคลังภาพ',
  'documentScanFailed': 'สแกนเอกสารไม่สำเร็จ: {error}',
  'saved': 'บันทึกแล้ว',

  // Home / navigation
  'navLibrary': 'คลังหนังสือ',
  'navCategories': 'หมวดหมู่',
  'navSettings': 'ตั้งค่า',

  // Library screen
  'myLibrary': 'คลังหนังสือของฉัน',
  'viewModeListLabel': 'มุมมองรายการ',
  'viewModeShelfCoverLabel': 'มุมมองชั้นหนังสือ (ปก)',
  'viewModeShelfSpineLabel': 'มุมมองชั้นหนังสือ (สัน)',
  'switchToViewMode': 'สลับไปที่{mode}',
  'searchHint': 'ค้นหาชื่อเรื่อง ผู้แต่ง หรือ ISBN',
  'scanToSearch': 'สแกนเพื่อค้นหา',
  'openSearch': 'ค้นหา',
  'closeSearch': 'ปิดการค้นหา',
  'filterAll': 'ทั้งหมด',
  'emptyLibrary': 'ยังไม่มีหนังสือ สแกนบาร์โค้ดหรือเพิ่มด้วยตนเองเพื่อเริ่มต้น',
  'noBooksYet': 'ยังไม่มีหนังสือ',
  'scanIsbnBarcode': 'สแกนบาร์โค้ด ISBN',
  'enterIsbnNumber': 'กรอกหมายเลข ISBN',
  'filterStatusLabel': 'สถานะ',
  'filterCategoryLabel': 'หมวดหมู่',
  'sortByLabel': 'เรียงตาม',
  'sortByDateAdded': 'วันที่เพิ่ม',
  'sortByAuthor': 'ผู้แต่ง',
  'noSeriesGroupLabel': 'ไม่มีซีรีย์',

  // Reading status
  'statusNotStarted': 'ยังไม่เริ่มอ่าน',
  'statusReading': 'กำลังอ่าน',
  'statusFinished': 'อ่านจบแล้ว',
  'statusDropped': 'เลิกอ่าน',
  'statusPaused': 'หยุดพักไว้',

  // Shelf mode / cover slots
  'shelfModeCover': 'ปกหนังสือ',
  'shelfModeSpine': 'สันหนังสือ',
  'coverSlotFront': 'ปกหน้า',
  'coverSlotSpine': 'สันหนังสือ',
  'coverSlotBack': 'ปกหลัง',

  // Scan screen
  'scanIsbnTitle': 'สแกน ISBN',
  'scanToSearchTitle': 'สแกนเพื่อค้นหา',
  'lookingUpIsbn': 'กำลังค้นหา {isbn}...',
  'noBookWithIsbn': 'ไม่พบหนังสือที่มี ISBN {isbn} ในคลังของคุณ',
  'noMetadataAddManually': 'ไม่พบข้อมูลของ {isbn} คุณยังสามารถเพิ่มด้วยตนเองได้',
  'scanAgain': 'สแกนอีกครั้ง',
  'addToLibrary': 'เพิ่มเข้าคลังหนังสือ',
  'scanToSearchHint': 'สแกนหนังสือที่มีอยู่แล้วในชั้นเพื่อไปยังหนังสือเล่มนั้น',
  'scanIsbnHint': 'เล็งกล้องไปที่บาร์โค้ดด้านหลังของหนังสือ',

  // Page scan screen
  'savePageTitle': 'บันทึกหน้าหนังสือ',
  'savePageHint': 'ถ่ายภาพหน้าหนังสือหรือภาพประกอบเพื่อเก็บไว้เป็นสิ่งเตือนความจำในแอป',
  'pageLabelField': 'ป้ายกำกับหน้า (ไม่บังคับ)',
  'pageLabelHint': 'เช่น หน้า 128 หรือ "ภาพประกอบแผนที่"',
  'noteField': 'บันทึกช่วยจำ (ไม่บังคับ)',

  // Cover scan screen
  'editCoverPresetTitle': 'แก้ไขชุดปกหนังสือ',
  'scanCoverTitle': 'สแกนปกหนังสือ',
  'coverSlotsHint':
      'ปกหน้า สันหนังสือ และปกหลัง ล้วนไม่บังคับ — ข้ามส่วนใดไว้ก่อนได้ '
          'แล้วกลับมาสแกนส่วนที่เหลือเพิ่มในชุดเดิมนี้ภายหลัง',
  'useApiCoverForFront': 'ใช้ปกจาก API ที่มีอยู่แล้วสำหรับปกหน้า',
  'presetLabelField': 'ป้ายกำกับชุดปก (ไม่บังคับ)',
  'presetLabelHint': 'เช่น ปกแข็ง 2020',
  'replaceTooltip': 'เปลี่ยนรูปภาพ',

  // Reading timeline
  'readingTimelineTitle': 'ไทม์ไลน์การอ่าน',
  'addStamp': 'เพิ่มสถานะ',
  'editStamp': 'แก้ไขสถานะ',
  'noStampsYet': 'ยังไม่มีสถานะ เพิ่มเมื่อคุณเริ่มอ่าน หยุดพัก เลิกอ่าน หรืออ่านจบหนังสือเล่มนี้',
  'deleteStampTitle': 'ลบสถานะนี้หรือไม่?',
  'removeStampConfirm': 'นำสถานะ "{status}" นี้ออกจากไทม์ไลน์หรือไม่?',
  'whenField': 'เมื่อไหร่',

  // Settings screen
  'settingsTitle': 'ตั้งค่า',
  'ocrSectionTitle': 'การสแกนข้อความ (OCR)',
  'ocrSectionBody':
      'ปุ่มสแกนด้วยกล้องข้างช่องชื่อเรื่อง ผู้แต่ง ผู้วาดภาพประกอบ ISBN และสำนักพิมพ์ '
          'ในหน้าแก้ไขหนังสือจะใช้การรู้จำข้อความบนอุปกรณ์เป็นค่าเริ่มต้น — ฟรีและใช้งานได้แบบออฟไลน์ '
          'แต่รองรับเฉพาะอักษรละติน ทำให้อ่านข้อความภาษาไทยไม่ถูกต้อง กรอกคีย์ Google Cloud '
          'Vision API ที่นี่เพื่อใช้แทน: อ่านได้ทั้งภาษาไทยและอักษรละติน แต่มีค่าใช้จ่ายจากคำขอเครือข่าย '
          'ต่อการสแกนหนึ่งครั้งซึ่งจะเรียกเก็บจากบัญชี Cloud ของคุณ เว้นว่างไว้เพื่อใช้การรู้จำบนอุปกรณ์ต่อไป',
  'cloudVisionKeyField': 'คีย์ Cloud Vision API (ไม่บังคับ)',
  'languageSectionTitle': 'ภาษา',
  'languageSectionBody': 'เลือกภาษาที่แสดงในแอป หรือใช้ตามภาษาระบบของอุปกรณ์',
  'appUpdateSectionTitle': 'การอัปเดตแอป',
  'appUpdateSectionBody':
      'QuetzaLib ไม่ได้เผยแพร่ผ่าน Play Store การอัปเดตจึงติดตั้งด้วยวิธีเดียวกับการติดตั้งครั้งแรก '
          'คือดาวน์โหลด APK ล่าสุดแล้วติดตั้งทับแอปเดิม หนังสือและการตั้งค่าของคุณจะยังคงอยู่',
  'checkForUpdates': 'ตรวจสอบการอัปเดต',
  'downloadAndInstall': 'ดาวน์โหลดและติดตั้ง',
  'downloading': 'กำลังดาวน์โหลด… {percent}%',
  'upToDate': 'คุณใช้เวอร์ชันล่าสุดแล้ว (v{version})',
  'updateAvailable': 'มีอัปเดตใหม่: v{version}',
  'couldNotCheckForUpdates': 'ตรวจสอบการอัปเดตไม่สำเร็จ: {error}',
  'updateFailed': 'อัปเดตไม่สำเร็จ: {error}',
  'currentVersion': 'เวอร์ชันปัจจุบัน: {version}',

  // Language names
  'localeSystemDefault': 'ค่าเริ่มต้นของระบบ',
  'localeEnglish': 'English',
  'localeThai': 'ไทย (Thai)',

  // ISBN entry screen (isbn_entry_screen.dart)
  'enterIsbnTitle': 'กรอก ISBN',
  'enterIsbnBody': 'พิมพ์หรือวางหมายเลข ISBN ที่พิมพ์อยู่ใกล้บาร์โค้ดด้านหลังของหนังสือ',
  'isbnField': 'ISBN-10 หรือ ISBN-13',
  'invalidIsbnError': '"{raw}" ดูไม่เหมือน ISBN-10/13 ที่ถูกต้อง',
  'lookUp': 'ค้นหา',

  // Category manager screen (category_manager_screen.dart)
  'categoryManagerTitle': 'หมวดหมู่',
  'newCategoryTitle': 'หมวดหมู่ใหม่',
  'categoryNameField': 'ชื่อ',
  'renameCategoryTitle': 'เปลี่ยนชื่อหมวดหมู่',
  'noCategoriesYet': 'ยังไม่มีหมวดหมู่ แตะ + เพื่อเพิ่ม',

  // Book pages screen (book_pages_screen.dart)
  'savedPagesTitle': 'หน้าที่บันทึกไว้',
  'addPageLabel': 'เพิ่มหน้า',
  'noSavedPagesYet': 'ยังไม่มีหน้าที่บันทึกไว้ ถ่ายภาพหน้าหรือภาพประกอบที่ต้องการจดจำ',
  'editNoteTitle': 'แก้ไขบันทึกช่วยจำ',
  'editNoteField': 'บันทึกช่วยจำ',
  'deletePageTitle': 'ลบหน้านี้หรือไม่?',
  'deletePageBody': 'หน้าที่บันทึกไว้นี้และรูปภาพจะถูกลบ',
  'savedPageFallbackTitle': 'หน้าที่บันทึกไว้',

  // Cover presets screen (cover_presets_screen.dart)
  'bookCoversTitle': 'ปกหนังสือ',
  'scanNewPresetLabel': 'สแกนชุดปกใหม่',
  'noCoversYet':
      'ยังไม่มีปกที่สแกนไว้ สแกนปกหน้าและสันหนังสือเพื่อแสดงหนังสือเล่มนี้เป็นภาพบนชั้นหนังสือของคุณ',
  'renamePresetTitle': 'เปลี่ยนชื่อชุดปก',
  'renamePresetLabelField': 'ป้ายกำกับ',
  'deletePresetTitle': 'ลบชุดปกนี้หรือไม่?',
  'deletePresetConfirm': 'ลบ "{label}" หรือไม่? รูปภาพของชุดปกนี้จะถูกลบไปด้วย',
  'thisCoverPreset': 'ชุดปกนี้',
  'onShelfLabel': 'อยู่บนชั้น',
  'untitledPresetLabel': 'ชุดปกไม่มีชื่อ',
  'coverThumbFront': 'ปกหน้า',
  'coverThumbSpine': 'สันหนังสือ',
  'coverThumbBack': 'ปกหลัง',
  'tapPhotosHint': 'แตะที่รูปภาพเพื่อดูแบบเต็ม หรือใช้ปุ่มแก้ไขด้านล่างเพื่อเพิ่ม แทนที่ หรือสแกนรูปใหม่',
  'useOnShelfLabel': 'ใช้บนชั้นหนังสือ',
  'renameTooltip': 'เปลี่ยนชื่อ',
  'editPhotosTooltip': 'แก้ไขรูปภาพ',

  // Book detail screen (book_detail_screen.dart)
  'bookRemovedMessage': 'หนังสือเล่มนี้ถูกลบไปแล้ว',
  'removeBookTitle': 'นำหนังสือออกหรือไม่?',
  'deleteBookConfirm': 'ลบ "{title}" ออกจากคลังหนังสือของคุณหรือไม่?',
  'scanCoverLabel': 'สแกนปก',
  'manageCoversLabel': 'จัดการปกหนังสือ',
  'readingStatusLabel': 'สถานะการอ่าน',
  'categoriesLabel': 'หมวดหมู่',
  'editCategoriesTooltip': 'แก้ไขหมวดหมู่',
  'noCategoriesAssignedHint': 'ยังไม่มีหมวดหมู่ แตะไอคอนด้านบนเพื่อเพิ่ม',
  'selectCategoriesTitle': 'เลือกหมวดหมู่',
  'savedPagesLabel': 'หน้าที่บันทึกไว้',
  'viewAllLabel': 'ดูทั้งหมด',
  'descriptionLabel': 'คำอธิบาย',
  'myNotesLabel': 'บันทึกของฉัน',
  'illustratedBy': 'ภาพประกอบโดย {names}',
  'isbnLabel': 'ISBN {isbn}',
  'sourceLabel': 'ที่มา: {source}',
  'book3DPreviewTitle': 'ภาพจำลอง 3 มิติ',
  'book3DFlipHint': 'แตะที่ปกหนังสือเพื่อพลิกดูอีกด้าน',
  'seriesWithVolume': '{series} เล่มที่ {volume}',

  // Book edit screen (book_edit_screen.dart)
  'editBookTitle': 'แก้ไขหนังสือ',
  'addBookTitle': 'เพิ่มหนังสือ',
  'titleField': 'ชื่อเรื่อง',
  'titleRequiredError': 'กรุณากรอกชื่อเรื่อง',
  'authorsField': 'ผู้แต่ง (คั่นด้วยจุลภาค)',
  'illustratorsField': 'ผู้วาดภาพประกอบ (คั่นด้วยจุลภาค)',
  'seriesField': 'ซีรีย์',
  'seriesVolumeField': 'เล่มที่',
  'seriesVolumeHint': 'เช่น 3 หรือ 4.5',
  'isbn13Field': 'ISBN-13',
  'publisherField': 'สำนักพิมพ์',
  'publishedDateField': 'วันที่เผยแพร่',
  'pageCountField': 'จำนวนหน้า',
  'descriptionField': 'คำอธิบาย',
  'myNotesField': 'บันทึกของฉัน',
  'scanFieldTooltip': 'สแกน{field}',
  'textScanFailed': 'สแกนข้อความไม่สำเร็จ: {error}',
  'reviewScannedTitle': 'ตรวจสอบ{field}ที่สแกนได้',
  'ocrNoTextRecognized': 'ไม่พบข้อความในภาพ คุณสามารถพิมพ์เองด้านล่าง หรือยกเลิกแล้วลองใหม่',
  'ocrEditAndFill': 'แก้ไขหากจำเป็น แล้วใช้ข้อความนี้กรอกลงใน{field}',
  'useThisTextLabel': 'ใช้ข้อความนี้',
};
