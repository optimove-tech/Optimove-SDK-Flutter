
enum OptimoveDeepLinkResolution { LookupFailed, LinkNotFound, LinkExpired, LimitExceeded, LinkMatched }

class OptimoveDeepLinkContent {
  final String? title;
  final String? description;

  OptimoveDeepLinkContent(this.title, this.description);
}

class OptimoveDeepLinkOutcome {
  final OptimoveDeepLinkResolution resolution;
  final String url;
  final OptimoveDeepLinkContent? content;
  final Map<String, dynamic>? linkData;

  OptimoveDeepLinkOutcome(this.resolution, this.url, this.content, this.linkData);

  OptimoveDeepLinkOutcome.fromMap(Map<String, dynamic> map)
      : resolution = OptimoveDeepLinkResolution.values[map['resolution']],
        url = map['url'],
        content = map['link']?['content'] != null ? OptimoveDeepLinkContent(map['link']['content']['title'], map['link']['content']['description']) : null,
        linkData = map['link']?['data'] != null ? Map<String, dynamic>.from(map['link']['data']) : null;
}