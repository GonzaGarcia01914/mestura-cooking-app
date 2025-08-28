import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Lightweight interstitial ads manager with retry and safe logging.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  InterstitialAd? _ad;
  bool _isLoading = false;
  int _retryAttempt = 0;
  Timer? _retryTimer;

  // Test IDs for Interstitial
  static const _androidUnit = 'ca-app-pub-3940256099942544/1033173712';
  static const _iosUnit = 'ca-app-pub-3940256099942544/4411468910';
  String get _unitId => Platform.isIOS ? _iosUnit : _androidUnit;

  static const AdRequest _request = AdRequest(
    nonPersonalizedAds: true,
    keywords: ['cooking', 'recipes', 'food'],
  );

  Future<void> preload() async {
    if (_isLoading || _ad != null) return;
    _isLoading = true;

    _log('Loading interstitial... unit=$_unitId');
    await InterstitialAd.load(
      adUnitId: _unitId,
      request: _request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _retryAttempt = 0;
          _ad = ad;
          _isLoading = false;
          _attachLifecycle(ad);
          _log('onAdLoaded');
          _dumpResponseInfo(ad.responseInfo);
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _isLoading = false;
          _logLoadError('onAdFailedToLoad', error);
          _dumpResponseInfo(error.responseInfo);
          if (!_isFormatMismatch(error)) {
            _scheduleRetry();
          } else {
            _log(
              'The provided adUnitId does not match Interstitial format. '
              'Use the correct test ID '
              '(${Platform.isAndroid ? _androidUnit : _iosUnit}) '
              'and in production create an Interstitial unit in AdMob.',
            );
          }
        },
      ),
    );
  }

  /// Shows the interstitial if ready. Returns true if it was displayed.
  Future<bool> showIfAvailable() async {
    final ad = _ad;
    if (ad == null) {
      _log('showIfAvailable: no ad -> preload()');
      unawaited(preload());
      return false;
    }

    final completer = Completer<bool>();
    var didShow = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        didShow = true;
        _log('onAdShowedFullScreenContent');
      },
      onAdImpression: (_) => _log('onAdImpression'),
      onAdFailedToShowFullScreenContent: (a, e) {
        _logFsError('onAdFailedToShowFullScreenContent', e);
        a.dispose();
        _ad = null;
        unawaited(preload());
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdDismissedFullScreenContent: (a) {
        _log('onAdDismissedFullScreenContent');
        a.dispose();
        _ad = null;
        unawaited(preload());
        if (!completer.isCompleted) completer.complete(didShow);
      },
    );

    ad.setImmersiveMode(true);
    ad.show();
    return completer.future;
  }

  // --- Internals ---
  void _attachLifecycle(InterstitialAd ad) {
    ad.setImmersiveMode(true);
    ad.fullScreenContentCallback ??= FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        _log('(default) onAdDismissedFullScreenContent');
        a.dispose();
        _ad = null;
        unawaited(preload());
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        _logFsError('(default) onAdFailedToShowFullScreenContent', e);
        a.dispose();
        _ad = null;
        unawaited(preload());
      },
    );
  }

  void _scheduleRetry() {
    _retryAttempt = (_retryAttempt + 1).clamp(1, 6);
    final seconds = (1 << _retryAttempt).clamp(2, 64);
    _log('Retry in ${seconds}s (attempt=$_retryAttempt)');
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: seconds), () {
      if (_ad == null && !_isLoading) unawaited(preload());
    });
  }

  // --- Logging & helpers ---
  void _log(String msg) {
    if (kDebugMode) debugPrint('[Ads] $msg');
  }

  void _logLoadError(String where, LoadAdError e) {
    _log(
      '$where failed: code=${e.code} domain=${e.domain} message=${e.message}',
    );
    _log(_explainLoadAdErrorCode(e.code));
  }

  bool _isFormatMismatch(LoadAdError e) {
    final m = (e.message).toLowerCase();
    return m.contains("doesn't match format") ||
        m.contains('does not match format');
  }

  void _logFsError(String where, AdError e) {
    _log('$where: code=${e.code} domain=${e.domain} message=${e.message}');
    _log(_explainAdErrorCode(e.code));
  }

  void _dumpResponseInfo(ResponseInfo? info) {
    if (!kDebugMode) return;
    if (info == null) {
      _log('responseInfo: <null>');
      return;
    }
    _log(
      'responseInfo: id=${info.responseId}; mediationAdapter=${info.mediationAdapterClassName}',
    );
    final loaded = info.loadedAdapterResponseInfo;
    if (loaded != null) {
      _log(
        '   LOADED by ${loaded.adapterClassName} '
        'source=${loaded.adSourceName}(${loaded.adSourceId}) '
        'instance=${loaded.adSourceInstanceName}(${loaded.adSourceInstanceId}) '
        'latencyMs=${loaded.latencyMillis}',
      );
    }
    final list = info.adapterResponses;
    if (list == null || list.isEmpty) {
      _log('   adapterResponses: []');
      return;
    }
    _log('   adapterResponses (${list.length}):');
    for (final a in list) {
      final err = a.adError;
      if (err == null) {
        _log(
          '      ${a.adapterClassName} '
          '[source=${a.adSourceName}/${a.adSourceId} '
          'inst=${a.adSourceInstanceName}/${a.adSourceInstanceId}] '
          'latencyMs=${a.latencyMillis} => FILL',
        );
      } else {
        _log(
          '      ${a.adapterClassName} '
          '[source=${a.adSourceName}/${a.adSourceId} '
          'inst=${a.adSourceInstanceName}/${a.adSourceInstanceId}] '
          'latencyMs=${a.latencyMillis} => NO-FILL '
          'code=${err.code} domain=${err.domain} msg=${err.message}',
        );
      }
    }
  }

  String _explainLoadAdErrorCode(int code) {
    switch (code) {
      case 0:
        return 'INTERNAL_ERROR: retry later.';
      case 1:
        return 'INVALID_REQUEST: check adUnitId/parameters.';
      case 2:
        return 'NETWORK_ERROR: network/Play Services issue.';
      case 3:
        return 'NO_FILL: no inventory right now; retry later.';
      default:
        return 'Load error code $code';
    }
  }

  String _explainAdErrorCode(int code) {
    switch (code) {
      case 0:
        return 'INTERNAL_ERROR while showing.';
      case 1:
        return 'INVALID_REQUEST (expired ad, etc.). Reload.';
      case 3:
        return 'NO_FILL while showing. Reload.';
      default:
        return 'Show error code $code';
    }
  }

  void dispose() {
    _retryTimer?.cancel();
    _ad?.dispose();
    _ad = null;
  }
}
