/// Global content configuration: where remote content lives and how long the
/// app waits for the network.
///
/// The GitHub fields are placeholders until the public content repository
/// exists. The repository must be publicly readable — the app fetches raw
/// files over HTTPS and never embeds credentials.
class ContentConfig {
  const ContentConfig({
    this.githubOwner = 'YOUR_GITHUB_USERNAME',
    this.githubRepository = 'my-algeria-bac-content',
    this.githubBranch = 'main',
    this.contentPath = 'content',
    this.networkTimeout = const Duration(seconds: 15),
    this.manifestFile = 'manifest.json',
    this.cacheDirectory = 'my_algeria_bac_content',
  });

  /// GitHub account that owns the content repository.
  final String githubOwner;

  /// Name of the content repository.
  final String githubRepository;

  /// Branch serving the content bundle.
  final String githubBranch;

  /// Directory inside the repository that holds the bundle files.
  final String contentPath;

  /// How long a single remote request may take before it counts as a failure.
  final Duration networkTimeout;

  /// Name of the manifest file at the root of the bundle.
  final String manifestFile;

  /// Directory name used for the on-device content cache.
  final String cacheDirectory;

  /// Raw URL for one content-relative file (e.g. `subjects.json`).
  Uri rawUrlFor(String path) {
    return Uri.parse(
      'https://raw.githubusercontent.com/$githubOwner/$githubRepository/'
      '$githubBranch/$contentPath/$path',
    );
  }
}
