/// Whether [path] should be loaded as a network image (`Image.network`)
/// rather than as a locally-stored one.
///
/// Covers both a book's remote API thumbnail (`http(s)://`) and, on web, the
/// browser-native `blob:` URL an [XFile] briefly holds right after it's
/// picked/captured but before [ImageStorageService] has persisted its bytes
/// — `blob:` URLs never occur on native platforms, so this doesn't change
/// any non-web behavior.
bool isRemoteImagePath(String path) =>
    path.startsWith('http://') ||
    path.startsWith('https://') ||
    path.startsWith('blob:');
