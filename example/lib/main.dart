import 'package:flutter/material.dart';
import 'package:multi_ads_sdk/multi_ads_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi Ads SDK Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AdsExamplePage(),
    );
  }
}

class AdsExamplePage extends StatefulWidget {
  const AdsExamplePage({super.key});

  @override
  State<AdsExamplePage> createState() => _AdsExamplePageState();
}

class _AdsExamplePageState extends State<AdsExamplePage> {
  AdProviderType _selectedProvider = AdProviderType.admob;
  bool _isInitialized = false;
  String _statusMessage = 'Not initialized';

  @override
  void initState() {
    super.initState();
    _initializeSDK();
  }

  Future<void> _initializeSDK() async {
    try {
      await MultiAdsManager.init(_selectedProvider);
      setState(() {
        _isInitialized = true;
        _statusMessage = 'Initialized with ${_selectedProvider.name}';
      });
      _log('SDK initialized with ${_selectedProvider.name}');
    } catch (e) {
      setState(() {
        _statusMessage = 'Initialization failed: $e';
      });
      _log('Initialization error: $e');
    }
  }

  void _log(String message) {
    debugPrint('[Example] $message');
  }

  Future<void> _loadInterstitial() async {
    try {
      _log('Loading interstitial...');
      // Use test ad unit ID - replace with your own
      await MultiAdsManager.loadInterstitial(
        adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      );
      setState(() {
        _statusMessage = 'Interstitial loaded';
      });
      _log('Interstitial loaded successfully');
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to load interstitial: $e';
      });
      _log('Error loading interstitial: $e');
    }
  }

  Future<void> _showInterstitial() async {
    try {
      _log('Showing interstitial...');
      await MultiAdsManager.showInterstitial();
      _log('Interstitial shown');
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to show interstitial: $e';
      });
      _log('Error showing interstitial: $e');
    }
  }

  Future<void> _loadRewarded() async {
    try {
      _log('Loading rewarded ad...');
      // Use test ad unit ID - replace with your own
      await MultiAdsManager.loadRewarded(
        adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      );
      setState(() {
        _statusMessage = 'Rewarded ad loaded';
      });
      _log('Rewarded ad loaded successfully');
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to load rewarded: $e';
      });
      _log('Error loading rewarded: $e');
    }
  }

  Future<void> _showRewarded() async {
    try {
      _log('Showing rewarded ad...');
      await MultiAdsManager.showRewarded(
        onReward: () {
          _log('User earned reward!');
          setState(() {
            _statusMessage = 'Reward earned!';
          });
        },
      );
      _log('Rewarded ad shown');
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to show rewarded: $e';
      });
      _log('Error showing rewarded: $e');
    }
  }

  Future<void> _loadAppOpen() async {
    try {
      _log('Loading app open ad...');
      // Use test ad unit ID - replace with your own
      await MultiAdsManager.loadAppOpen(
        adUnitId: 'ca-app-pub-3940256099942544/3419835294',
      );
      setState(() {
        _statusMessage = 'App open ad loaded';
      });
      _log('App open ad loaded successfully');
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to load app open: $e';
      });
      _log('Error loading app open: $e');
    }
  }

  Future<void> _showAppOpen() async {
    try {
      _log('Showing app open ad...');
      await MultiAdsManager.showAppOpen();
      _log('App open ad shown');
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to show app open: $e';
      });
      _log('Error showing app open: $e');
    }
  }

  Future<void> _loadBanner() async {
    try {
      _log('Loading banner ad...');
      // Use test ad unit ID - replace with your own
      await MultiAdsManager.loadBanner(
        adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      );
      setState(() {
        _statusMessage = 'Banner ad loaded';
      });
      _log('Banner ad loaded successfully');
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to load banner: $e';
      });
      _log('Error loading banner: $e');
    }
  }

  Future<void> _showBanner() async {
    try {
      _log('Showing banner ad...');
      await MultiAdsManager.showBanner();
      _log('Banner ad shown');
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to show banner: $e';
      });
      _log('Error showing banner: $e');
    }
  }

  Future<void> _loadRewardedInterstitial() async {
    try {
      _log('Loading rewarded interstitial...');
      // Use test ad unit ID - replace with your own
      await MultiAdsManager.loadRewardedInterstitial(
        adUnitId: 'ca-app-pub-3940256099942544/5354046379',
      );
      setState(() {
        _statusMessage = 'Rewarded interstitial loaded';
      });
      _log('Rewarded interstitial loaded successfully');
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to load rewarded interstitial: $e';
      });
      _log('Error loading rewarded interstitial: $e');
    }
  }

  Future<void> _showRewardedInterstitial() async {
    try {
      _log('Showing rewarded interstitial...');
      await MultiAdsManager.showRewardedInterstitial(
        onReward: () {
          _log('User earned reward from rewarded interstitial!');
          setState(() {
            _statusMessage = 'Reward earned!';
          });
        },
      );
      _log('Rewarded interstitial shown');
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to show rewarded interstitial: $e';
      });
      _log('Error showing rewarded interstitial: $e');
    }
  }

  Future<void> _loadNative() async {
    try {
      _log('Loading native ad...');
      // Use test ad unit ID - replace with your own
      await MultiAdsManager.loadNative(
        adUnitId: 'ca-app-pub-3940256099942544/2247696110',
      );
      setState(() {
        _statusMessage = 'Native ad loaded';
      });
      _log('Native ad loaded successfully');
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to load native: $e';
      });
      _log('Error loading native: $e');
    }
  }

  Future<void> _showNative() async {
    try {
      _log('Showing native ad...');
      await MultiAdsManager.showNative();
      _log('Native ad shown');
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to show native: $e';
      });
      _log('Error showing native: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Multi Ads SDK Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    // Provider Selection
                    Text(
                      'Provider',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<AdProviderType>(
                      segments: const [
                        ButtonSegment<AdProviderType>(
                          value: AdProviderType.admob,
                          label: Text('AdMob'),
                        ),
                        ButtonSegment<AdProviderType>(
                          value: AdProviderType.adx,
                          label: Text('AdX'),
                        ),
                        ButtonSegment<AdProviderType>(
                          value: AdProviderType.facebook,
                          label: Text('Facebook'),
                        ),
                      ],
                      selected: {_selectedProvider},
                      onSelectionChanged: (Set<AdProviderType> newSelection) {
                        setState(() {
                          _selectedProvider = newSelection.first;
                          _isInitialized = false;
                          _statusMessage = 'Reinitializing...';
                        });
                        _initializeSDK();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Interstitial Ads
            _buildSection(
              context,
              'Interstitial Ads',
              [
                _buildButton(
                  context,
                  'Load Interstitial',
                  _loadInterstitial,
                  enabled: _isInitialized,
                ),
                _buildButton(
                  context,
                  'Show Interstitial',
                  _showInterstitial,
                  enabled: _isInitialized,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Rewarded Ads
            _buildSection(
              context,
              'Rewarded Ads',
              [
                _buildButton(
                  context,
                  'Load Rewarded',
                  _loadRewarded,
                  enabled: _isInitialized,
                ),
                _buildButton(
                  context,
                  'Show Rewarded',
                  _showRewarded,
                  enabled: _isInitialized,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Rewarded Interstitial Ads
            _buildSection(
              context,
              'Rewarded Interstitial Ads',
              [
                _buildButton(
                  context,
                  'Load Rewarded Interstitial',
                  _loadRewardedInterstitial,
                  enabled: _isInitialized,
                ),
                _buildButton(
                  context,
                  'Show Rewarded Interstitial',
                  _showRewardedInterstitial,
                  enabled: _isInitialized,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // App Open Ads
            _buildSection(
              context,
              'App Open Ads',
              [
                _buildButton(
                  context,
                  'Load App Open',
                  _loadAppOpen,
                  enabled: _isInitialized,
                ),
                _buildButton(
                  context,
                  'Show App Open',
                  _showAppOpen,
                  enabled: _isInitialized,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Banner Ads
            _buildSection(
              context,
              'Banner Ads',
              [
                _buildButton(
                  context,
                  'Load Banner',
                  _loadBanner,
                  enabled: _isInitialized,
                ),
                _buildButton(
                  context,
                  'Show Banner',
                  _showBanner,
                  enabled: _isInitialized,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Native Ads
            _buildSection(
              context,
              'Native Ads',
              [
                _buildButton(
                  context,
                  'Load Native',
                  _loadNative,
                  enabled: _isInitialized,
                ),
                _buildButton(
                  context,
                  'Show Native',
                  _showNative,
                  enabled: _isInitialized,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String label,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        child: Text(label),
      ),
    );
  }
}
