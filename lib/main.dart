import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:WaledNet/data/servers.dart';
import 'package:WaledNet/services/api_service.dart';
import 'package:WaledNet/theme_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const VpnApp(),
    ),
  );
}

class VpnApp extends StatelessWidget {
  const VpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaledNet VPN',
      theme: Provider.of<ThemeProvider>(context).themeData,
      home: const UpdateCheckPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class UpdateCheckPage extends StatefulWidget {
  const UpdateCheckPage({super.key});

  @override
  State<UpdateCheckPage> createState() => _UpdateCheckPageState();
}

class _UpdateCheckPageState extends State<UpdateCheckPage> {
  final String _updateUrl =
      'https://raw.githubusercontent.com/hussein34535/waledupdate/refs/heads/main/update.json';

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      final response = await http.get(Uri.parse(_updateUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['version'] as String;
        final updateUrl = data['update_url'] as String;

        if (_isUpdateRequired(currentVersion, latestVersion)) {
          if (mounted) {
            _showUpdateDialog(updateUrl);
          }
        } else {
          _navigateToHome();
        }
      } else {
        _navigateToHome();
      }
    } catch (e) {
      _navigateToHome();
    }
  }

  bool _isUpdateRequired(String currentVersion, String latestVersion) {
    final currentParts = currentVersion.split('.').map(int.parse).toList();
    final latestParts = latestVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length || currentParts[i] < latestParts[i]) {
        return true;
      }
      if (currentParts[i] > latestParts[i]) {
        return false;
      }
    }
    return false;
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MyHomePage()),
      );
    }
  }

  Future<void> _showUpdateDialog(String url) async {
    final Uri updateUri = Uri.parse(url);
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('تحتاج إلى تحديث'),
            content: const Text(
              'يتوفر إصدار جديد من التطبيق. الرجاء التحديث للمتابعة.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('تحديث الآن'),
                onPressed: () async {
                  if (!await launchUrl(
                    updateUri,
                    mode: LaunchMode.externalApplication,
                  )) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not launch $url')),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final FlutterV2ray _flutterV2ray;
  V2RayStatus? _status;
  String _buttonText = 'اتصال';
  bool _isLoading = true;
  String _remark = '';
  Map<String, dynamic> _config = {};
  List<VpnServer> _vpnServers = [];
  List<SniProfile> _sniProfiles = [];
  VpnServer? _selectedServer;
  SniProfile? _selectedProfile;
  Timer? _timer;
  int _connectionTime = 0;
  bool _isExtendedConnection = false;
  bool _isShowingAd = false;
  bool _isAdLoading = false;
  bool _adLoadAttempted = false;
  int _peakDownloadSpeedBps = 0;
  int _peakUploadSpeedBps = 0;
  final String _gameId = '5833433';
  final String _rewardedPlacementId = 'Rewarded_Android';
  final String _interstitialPlacementId = 'Interstitial_Android';
  bool _isRewardedAdReady = false;
  bool _isInterstitialAdReady = false;
  Timer? _adLoadTimer;
  String _vpnStatus = 'DISCONNECTED';
  bool _isTestingSpeed = false;
  double? _speedTestResultMbps;
  double? _uploadSpeedTestResultMbps;

  final Uri _telegramUrl = Uri.parse('https://t.me/D_S_D_C1');
  final Uri _subscriptionUrl = Uri.parse('https://t.me/D_S_D_Cbot');
  final Uri _developerUrl = Uri.parse('https://t.me/he_s_en');

  @override
  void initState() {
    super.initState();
    _flutterV2ray = FlutterV2ray(onStatusChanged: _onStatusChanged);
    _loadData().then((_) {
      _initializeV2Ray();
      _initializeUnityAds();
      _loadRewardedAd();
      _loadInterstitialAd();

      FirebaseMessaging.instance.getToken().then((token) {
        print("Firebase Messaging Token: $token");
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print(
              'Message also contained a notification: ${message.notification}');
        }
      });
    });
  }

  void _initializeUnityAds() {
    try {
      UnityAds.init(
        gameId: _gameId,
        testMode: false,
        onComplete: () {
          print('Unity Ads initialization complete.');
          _loadRewardedAd();
          _loadInterstitialAd();
        },
        onFailed: (error, message) =>
            print('Unity Ads initialization failed: $error $message'),
      );
    } catch (e) {
      print('Unity Ads initialization failed: $e');
    }
  }

  Future<void> _launchUrl(Uri url) async {
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch ${url.path}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error launching URL: $e')));
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    print("[_loadData] Starting data load process.");

    bool fetchedFromApi = false;
    try {
      print(
        "[_loadData] Attempting to fetch new data from server...",
      );
      final servers = await ApiService.fetchVlessServers();
      final profiles = await ApiService.fetchSniProfiles();

      if (servers.isNotEmpty && profiles.isNotEmpty) {
        setState(() {
          _vpnServers = servers;
          _sniProfiles = profiles;
        });
        await _saveDataToCache();
        await prefs.setInt('last_fetch_time', currentTime);
        print("[_loadData] Data fetched from API and saved to cache.");
        fetchedFromApi = true;
      } else {
        print("[_loadData] API returned empty lists, trying cache.");
      }
    } catch (e) {
      print(
          "[_loadData] Error fetching new data from API: $e. Falling back to cache.");
    }

    if (!fetchedFromApi) {
      await _loadDataFromCache();
      print(
        "[_loadData] After loading from cache: Servers count = ${_vpnServers.length}, SNI profiles count = ${_sniProfiles.length}",
      );
    }

    if (_vpnServers.isEmpty) {
      setState(() {
        _vpnServers = [
          VpnServer(
            name: 'No Servers Available',
            url: 'vless://dummy@placeholder.com:443#No_Servers',
            icon: '',
          ),
        ];
        print("[_loadData] _vpnServers was empty, added placeholder.");
      });
    }
    if (_sniProfiles.isEmpty) {
      setState(() {
        _sniProfiles = [
          SniProfile(name: 'No SNI Profiles Available', sni: '', icon: ''),
        ];
        print("[_loadData] _sniProfiles was empty, added placeholder.");
      });
    }
    print(
      "[_loadData] After ensuring non-empty lists: Servers count = ${_vpnServers.length}, SNI profiles count = ${_sniProfiles.length}",
    );

    await _loadSelections();
    print(
      "[_loadData] After _loadSelections: _selectedServer = ${_selectedServer?.name}, _selectedProfile = ${_selectedProfile?.name}",
    );

    setState(() {
      if (_selectedServer == null && _vpnServers.isNotEmpty) {
        _selectedServer = _vpnServers.first;
        print(
          "[_loadData] Assigned first server as default: ${_selectedServer?.name}",
        );
      }
      if (_selectedProfile == null && _sniProfiles.isNotEmpty) {
        _selectedProfile = _sniProfiles.first;
        print(
          "[_loadData] Assigned first SNI as default: ${_selectedProfile?.name}",
        );
      }
      if (_selectedServer == null) {
        _selectedServer = _vpnServers.first;
        print(
          "[_loadData] _selectedServer still null, fell back to placeholder: ${_selectedServer?.name}",
        );
      }
      if (_selectedProfile == null) {
        _selectedProfile = _sniProfiles.first;
        print(
          "[_loadData] _selectedProfile still null, fell back to placeholder: ${_selectedProfile?.name}",
        );
      }
      _isLoading = false;
    });
    print(
      "[_loadData] Final selected server: ${_selectedServer?.name}, URL: ${_selectedServer?.url}",
    );
    print(
      "[_loadData] Final selected profile: ${_selectedProfile?.name}, SNI: ${_selectedProfile?.sni}",
    );

    if (_selectedServer != null && _getFinalUrl().isNotEmpty) {
      _initializeV2Ray();
      print("[_loadData] Calling _initializeV2Ray after data load.");
    } else {
      print(
        "[_loadData] Not calling _initializeV2Ray because selected server is null or URL is empty.",
      );
    }
  }

  Future<void> _loadDataFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final serversJson = prefs.getString('vpn_servers');
    final profilesJson = prefs.getString('sni_profiles');

    if (serversJson != null) {
      final List<dynamic> serverList = jsonDecode(serversJson);
      setState(() {
        _vpnServers =
            serverList.map((json) => VpnServer.fromJson(json)).toList();
      });
    }

    if (profilesJson != null) {
      final List<dynamic> profileList = jsonDecode(profilesJson);
      setState(() {
        _sniProfiles =
            profileList.map((json) => SniProfile.fromJson(json)).toList();
      });
    }
  }

  Future<void> _saveDataToCache() async {
    final prefs = await SharedPreferences.getInstance();
    final serversJson = jsonEncode(_vpnServers.map((s) => s.toJson()).toList());
    final profilesJson = jsonEncode(
      _sniProfiles.map((p) => p.toJson()).toList(),
    );

    await prefs.setString('vpn_servers', serversJson);
    await prefs.setString('sni_profiles', profilesJson);
  }

  Future<void> _loadSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('selected_server_url');
    final profileSni = prefs.getString('selected_profile_sni');

    print("[_loadSelections] Attempting to load saved selections.");
    print("[_loadSelections] Saved Server URL: $serverUrl");
    print("[_loadSelections] Saved Profile SNI: $profileSni");

    VpnServer? foundServer;
    if (serverUrl != null && _vpnServers.isNotEmpty) {
      try {
        foundServer = _vpnServers.firstWhere((s) => s.url == serverUrl);
        print("[_loadSelections] Found saved server: ${foundServer.name}");
      } catch (e) {
        print(
          "[_loadSelections] Saved server URL not found in current list: $serverUrl. Error: $e",
        );
      }
    }
    _selectedServer = foundServer;
    print("[_loadSelections] _selectedServer set to: ${_selectedServer?.name}");

    SniProfile? foundProfile;
    if (profileSni != null && _sniProfiles.isNotEmpty) {
      try {
        foundProfile = _sniProfiles.firstWhere((p) => p.sni == profileSni);
        print("[_loadSelections] Found saved profile: ${foundProfile.name}");
      } catch (e) {
        print(
          "[_loadSelections] Saved SNI profile not found in current list: $profileSni. Error: $e",
        );
      }
    }
    _selectedProfile = foundProfile;
    print(
      "[_loadSelections] _selectedProfile set to: ${_selectedProfile?.name}",
    );
  }

  Future<void> _saveSelections() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedServer != null) {
      await prefs.setString('selected_server_url', _selectedServer!.url);
    }
    if (_selectedProfile != null) {
      await prefs.setString('selected_profile_sni', _selectedProfile!.sni);
    }
  }

  Future<void> _initializeV2Ray() async {
    final url = _getFinalUrl();
    print("V2Ray - Final URL to initialize: $url");

    if (_selectedServer == null || url.isEmpty) {
      print(
        "V2Ray initialization skipped: selected server is null or URL is invalid.",
      );
      return;
    }

    try {
      await _flutterV2ray.initializeV2Ray();
      final v2rayURL = await FlutterV2ray.parseFromURL(url);
      setState(() {
        _remark = v2rayURL.remark;
        final configString = v2rayURL.getFullConfiguration();
        if (configString != null) {
          _config = jsonDecode(configString) as Map<String, dynamic>;
        }
      });
    } catch (e) {
      print("Error initializing V2Ray: $e");
    }
  }

  void _onStatusChanged(V2RayStatus newStatus) async {
    final previousState = _status?.state;
    final newState = newStatus.state;

    if (newState == 'CONNECTED') {
      if (previousState != 'CONNECTED') {
        _peakDownloadSpeedBps = 0;
        _peakUploadSpeedBps = 0;
      }

      if ((newStatus.downloadSpeed ?? 0) > _peakDownloadSpeedBps) {
        _peakDownloadSpeedBps = newStatus.downloadSpeed ?? 0;
      }
      if ((newStatus.uploadSpeed ?? 0) > _peakUploadSpeedBps) {
        _peakUploadSpeedBps = newStatus.uploadSpeed ?? 0;
      }
    }

    if (mounted) {
      setState(() {
        _status = newStatus;
        _vpnStatus = newStatus.state;
        _updateButtonState();
      });
    }

    if (newState == 'CONNECTED' && previousState != 'CONNECTED') {
      _startTimer();
      // تأخير عرض الإعلان البيني وبدء فحص السرعة
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _status?.state == 'CONNECTED') {
          _showInterstitialAd(); // سيحاول عرض الإعلان إذا كان جاهزاً
          _runSpeedTest(); // سيبدأ فحص السرعة في كل الأحوال بعد المحاولة
        }
      });
    } else if (newState == 'DISCONNECTED' && previousState != 'DISCONNECTED') {
      _stopTimer();
      _isExtendedConnection = false;
      // Removed _loadRewardedAd();
      // Removed _loadInterstitialAd();
      if (mounted) {
        setState(() {
          _peakDownloadSpeedBps = 0;
          _peakUploadSpeedBps = 0;
        });
      }
    }
  }

  void _updateButtonState() {
    switch (_status?.state) {
      case 'CONNECTED':
        _buttonText = 'متصل';
        break;
      case 'CONNECTING':
        _buttonText = 'جاري الاتصال...';
        break;
      case 'DISCONNECTED':
        _buttonText = 'اتصال';
        break;
      default:
        _buttonText = 'اتصال';
        break;
    }
  }

  Future<void> _toggleVpn() async {
    if (_status?.state == 'CONNECTED') {
      await _flutterV2ray.stopV2Ray();
    } else {
      if (_isRewardedAdReady) {
        _showRewardedAd();
      } else {
        setState(() {
          _isAdLoading = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('جاري تحميل الإعلان...'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadRewardedAd();

        // Start a 20-second timer for ad loading
        _adLoadTimer?.cancel();
        _adLoadTimer = Timer(const Duration(seconds: 20), () {
          if (mounted && !_isRewardedAdReady && _status?.state != 'CONNECTED') {
            setState(() {
              _isAdLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('فشل تحميل الإعلان، جاري الاتصال مباشرة...'),
                backgroundColor: Colors.green,
              ),
            );
            _connectToVpn();
          }
        });
      }
    }
  }

  String _getFinalUrl() {
    if (_selectedServer == null) return '';
    String finalUrl = _selectedServer!.url;
    if (_selectedProfile != null) {
      try {
        Uri originalUri = Uri.parse(finalUrl);
        var queryParams = Map<String, String>.from(originalUri.queryParameters);
        queryParams['host'] = _selectedProfile!.sni;
        queryParams['sni'] = _selectedProfile!.sni;
        finalUrl = originalUri.replace(queryParameters: queryParams).toString();
      } catch (e) {
        print(
          "Error parsing or replacing URL parts in _getFinalUrl: $e",
        );
        return _selectedServer!.url;
      }
    }
    print("V2Ray - Constructed final URL: $finalUrl");
    return finalUrl;
  }

  void _handleSelectionChange<T>(T? value) {
    setState(() {
      if (value is VpnServer) {
        _selectedServer = value;
      } else if (value is SniProfile) {
        _selectedProfile = value;
      }
      _isLoading = true;
    });
    _saveSelections();
    _initializeV2Ray().then((_) => setState(() => _isLoading = false));
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_connectionTime > 0) {
        setState(() {
          _connectionTime--;
        });
      } else {
        timer.cancel();
        if (_status?.state == 'CONNECTED') {
          _toggleVpn();
        }
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _connectionTime = 0;
    });
  }

  String _formatSpeed(int? bps) {
    if (bps == null || bps < 0) return '0.0 KB/s';
    if (_vpnStatus != 'CONNECTED') return '---';
    if (bps == 0 && _connectionTime < 3) return '...';

    double speedInMbps = (bps / (1024 * 1024) * 8);

    if (speedInMbps < 0.1) {
      return '${(bps / 1024).toStringAsFixed(2)} KB/s';
    } else {
      return '${speedInMbps.toStringAsFixed(2)} MB/s';
    }
  }

  void _loadRewardedAd() {
    _isRewardedAdReady = false;
    UnityAds.load(
      placementId: _rewardedPlacementId,
      onComplete: (placementId) {
        print('Load Complete: $placementId');
        if (mounted) {
          setState(() {
            _isRewardedAdReady = true;
          });
          _adLoadTimer?.cancel(); // Cancel the timer if ad loads successfully
          if (_isAdLoading) {
            _showRewardedAd();
            setState(() {
              _isAdLoading = false;
            });
          }
        }
      },
      onFailed: (placementId, error, message) {
        print('Load Failed $placementId: $error $message');
        _isRewardedAdReady = false;
        if (mounted) {
          setState(() {
            _isAdLoading = false;
          });
          if (_adLoadTimer != null && _adLoadTimer!.isActive) {
            _adLoadTimer?.cancel();
            print('Ad load failed, connecting directly...');
            _connectToVpn();
          }
        }
        _handleAdFailure('فشل تحميل الإعلان، يرجى المحاولة مرة أخرى.');
      },
    );
  }

  void _loadInterstitialAd() {
    _isInterstitialAdReady = false;
    UnityAds.load(
      placementId: _interstitialPlacementId,
      onComplete: (placementId) {
        print('Load Complete: $placementId');
        setState(() {
          _isInterstitialAdReady = true;
        });
      },
      onFailed: (placementId, error, message) {
        print('Load Failed $placementId: $error $message');
        _isInterstitialAdReady = false;
      },
    );
  }

  void _showInterstitialAd() {
    if (!_isInterstitialAdReady) {
      print('Interstitial Ad not ready, skipping show.');
      // No need to call _loadInterstitialAd here, it will be handled by the main logic.
      return;
    }

    UnityAds.showVideoAd(
      placementId: _interstitialPlacementId,
      onComplete: (placementId) {
        print('Video Ad ($placementId) completed');
        // Removed _loadInterstitialAd();
      },
      onFailed: (placementId, error, message) {
        print('Video Ad ($placementId) failed: $error $message');
        // Removed _loadInterstitialAd();
      },
      onStart: (placementId) => print('Video Ad ($placementId) start'),
      onClick: (placementId) => print('Video Ad ($placementId) click'),
      onSkipped: (placementId) {
        print('Video Ad ($placementId) skipped');
        // Removed _loadInterstitialAd();
      },
    );
  }

  void _showRewardedAd() {
    if (!_isRewardedAdReady) {
      _handleAdFailure('الإعلان غير جاهز بعد، يرجى المحاولة مرة أخرى.');
      // Removed _loadRewardedAd(); // This was already handled in a previous commit, but ensuring it's not re-added.
      return;
    }

    UnityAds.showVideoAd(
      placementId: _rewardedPlacementId,
      onComplete: (placementId) async {
        print('Video Ad ($placementId) completed');
        setState(() {
          _isExtendedConnection = true;
          _connectionTime = 24 * 60 * 60;
          _isAdLoading = false;
        });
        _connectToVpn();
      },
      onFailed: (placementId, error, message) {
        print('Video Ad ($placementId) failed: $error - $message');
        _handleAdFailure('فشل عرض الإعلان، يرجى المحاولة مرة أخرى');
      },
      onStart: (placementId) => print('Video Ad ($placementId) start'),
      onClick: (placementId) => print('Video Ad ($placementId) click'),
      onSkipped: (placementId) {
        print('Video Ad ($placementId) skipped');
        _handleAdFailure('يجب مشاهدة الإعلان بالكامل للاتصال');
        // Removed _loadRewardedAd();
      },
    );
  }

  void _handleAdFailure(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      setState(() {
        _isAdLoading =
            false; // Set to false to indicate no active ad loading attempt
      });
      // Removed _loadRewardedAd() here to prevent continuous loading attempts
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.themeData;
    return Scaffold(
      appBar: _buildAppBar(themeProvider),
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          gradient: theme.brightness == Brightness.dark &&
                  theme.primaryColor != const Color(0xFFAD1457)
              ? null
              : LinearGradient(
                  colors: [const Color(0xFF1A0A3A), const Color(0xFF2E1B4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(),
                _buildConnectButton(),
                const Spacer(),
                _buildConnectionDetails(),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(ThemeProvider themeProvider) {
    final theme = themeProvider.themeData;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'contact_us') {
            _launchUrl(_telegramUrl);
          } else if (value == 'subscribe') {
            _launchUrl(_subscriptionUrl);
          } else if (value == 'developer') {
            _launchUrl(_developerUrl);
          }
        },
        icon: Icon(Icons.menu, color: theme.iconTheme.color, size: 30),
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(
              color: Colors.blueAccent, width: 2), // Added border color
        ),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'contact_us',
            child: Row(
              children: [
                Icon(
                  Icons.contact_support_outlined,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Text('Contact Us', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'subscribe',
            child: Row(
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Text(
                  'Subscription (No Ads)',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'developer',
            child: Row(
              children: [
                Icon(
                  Icons.code,
                  color: Colors.purpleAccent, // Changed icon color
                ),
                const SizedBox(width: 12),
                Text('7𝖊\$𝖊𝒏 :المطور', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
      title: Text(
        'WaledNet',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onBackground,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.telegram, color: Colors.blueAccent),
          iconSize: 30,
          onPressed: () => _launchUrl(_telegramUrl),
        ),
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          iconSize: 30,
          color: theme.iconTheme.color,
          onPressed: () => themeProvider.toggleTheme(),
        ),
      ],
    );
  }

  Widget _buildConnectButton() {
    final isConnected = _status?.state == 'CONNECTED';
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    const Color connectedBlueColor = Color(0xFF007BFF);
    const Color disconnectedGlowColor = Color(0xFF007BFF);
    final Color disconnectedColor = theme.colorScheme.onSurface;
    final Color connectedColor = connectedBlueColor;

    String buttonTextToShow = _buttonText;
    if (_status?.state != 'CONNECTED' && _isAdLoading) {
      buttonTextToShow = 'جاري تحميل الإعلان...';
    }

    return Column(
      children: [
        GestureDetector(
          onTap: (_status?.state == 'CONNECTING' || _isAdLoading || _isLoading)
              ? null
              : _toggleVpn,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 180, // Smaller button
            height: 180, // Smaller button
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface,
              border: Border.all(
                color: isConnected ? connectedBlueColor : Colors.transparent,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: isConnected
                      ? connectedBlueColor.withOpacity(0.5)
                      : disconnectedGlowColor.withOpacity(0.5),
                  blurRadius: isConnected ? 30 : 20,
                  spreadRadius: isConnected ? 10 : 7,
                ),
              ],
            ),
            child: Center(
              child: (_isLoading || (_isAdLoading && !isConnected))
                  ? const CircularProgressIndicator()
                  : Icon(
                      Icons.power_settings_new_rounded,
                      size: 70, // Smaller icon
                      color: isConnected ? connectedColor : disconnectedColor,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24), // Reduced space
        Text(
          buttonTextToShow,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isConnected ? connectedColor : disconnectedColor,
            letterSpacing: 1.5,
            fontSize: 20, // Smaller text
          ),
        ),
        const SizedBox(height: 16.0), // Reduced space
        if (isConnected)
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                _buildTimeColumn(
                    (_connectionTime ~/ 3600).toString().padLeft(2, '0'),
                    'ساعة',
                    theme,
                    isConnected,
                    connectedColor,
                    disconnectedColor),
                _buildTimeSeparator(theme),
                _buildTimeColumn(
                    ((_connectionTime % 3600) ~/ 60).toString().padLeft(2, '0'),
                    'دقايق',
                    theme,
                    isConnected,
                    connectedColor,
                    disconnectedColor),
                _buildTimeSeparator(theme),
                _buildTimeColumn(
                    (_connectionTime % 60).toString().padLeft(2, '0'),
                    'ثواني',
                    theme,
                    isConnected,
                    connectedColor,
                    disconnectedColor),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimeSeparator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        ':',
        style: TextStyle(
          fontFamily: 'Montserrat', // Use local font
          fontSize: 40,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildTimeColumn(String timeValue, String label, ThemeData theme,
      bool isConnected, Color connectedColor, Color disconnectedColor) {
    return Column(
      children: [
        Text(
          timeValue,
          style: TextStyle(
            fontFamily: 'Montserrat', // Use local font
            fontSize: 40,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isConnected ? connectedColor : disconnectedColor,
            letterSpacing: 1.5,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionDetails() {
    return Column(
      children: [
        _buildSelectionMenus(),
        const SizedBox(height: 24),
        _buildStatusDetails(),
      ],
    );
  }

  Widget _buildSelectionMenus() {
    return Column(
      children: [
        _buildDropdown<VpnServer>(
          hint: 'Select Server',
          icon: Icons.dns_rounded,
          value: _selectedServer,
          items: _vpnServers,
          onChanged: (value) => _handleSelectionChange<VpnServer>(value),
          itemBuilder: (VpnServer server) {
            return DropdownMenuItem<VpnServer>(
              value: server,
              child: Text(server.name),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown<SniProfile>(
          hint: 'Select SNI Profile',
          icon: Icons.shield_outlined,
          value: _selectedProfile,
          items: _sniProfiles,
          onChanged: (value) => _handleSelectionChange<SniProfile>(value),
          itemBuilder: (SniProfile profile) {
            return DropdownMenuItem<SniProfile>(
              value: profile,
              child: Text(profile.name),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required IconData icon,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required DropdownMenuItem<T> Function(T) itemBuilder,
  }) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final Color highContrastIconColor = themeProvider.isDarkMode
        ? theme.colorScheme.primary
        : theme.colorScheme.primary;
    final bool isDisabled = _isLoading ||
        items.isEmpty ||
        (items.length == 1 && (items.first as dynamic).name == 'Loading...');

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: themeProvider.isDarkMode &&
                theme.primaryColor == const Color(0xFFAD1457)
            ? Border.all(
                color: theme.colorScheme.secondary.withOpacity(0.3),
                width: 1.5,
              )
            : null,
        boxShadow: theme.brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: highContrastIconColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                hint: Text(
                  _isLoading ? 'Loading...' : hint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                dropdownColor: theme.cardTheme.color,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: highContrastIconColor,
                ),
                items: items.map<DropdownMenuItem<T>>(itemBuilder).toList(),
                onChanged: isDisabled ? null : onChanged,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDetails() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final theme = themeProvider.themeData;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: _buildInfoCard(
            icon: Icons.arrow_downward,
            label: 'Download',
            color: themeProvider.isDarkMode
                ? Colors.blueAccent
                : theme.colorScheme.primary,
          ),
        ),
        const Spacer(flex: 2),
        if (_vpnStatus == 'CONNECTED') _buildSpeedTestButton(),
        const Spacer(flex: 2),
        Expanded(
          flex: 5,
          child: _buildInfoCard(
            icon: Icons.arrow_upward,
            label: 'Upload',
            color: themeProvider.isDarkMode
                ? Colors.pinkAccent
                : theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedTestButton() {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          iconSize: 36,
          splashRadius: 28,
          tooltip: 'إعادة فحص السرعة',
          onPressed: _isTestingSpeed ? null : _runSpeedTest,
          icon: _isTestingSpeed
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.primary,
                  ),
                )
              : Icon(
                  Icons.speed_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          'فحص السرعة',
          style: theme.textTheme.labelMedium,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Set text color to white in light mode, otherwise use theme default
    final Color? textColor = !themeProvider.isDarkMode ? Colors.white : null;

    // Removed Card widget for no background
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28.0, color: color), // Slightly smaller icon
          const SizedBox(height: 8.0),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
          ),
          const SizedBox(height: 4.0),
          _buildSpeedInfoWidget(label, themeProvider.isDarkMode),
        ],
      ),
    );
  }

  Widget _buildSpeedInfoWidget(String label, bool isDarkMode) {
    final theme = Theme.of(context);

    if (_isTestingSpeed) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2.0),
      );
    }

    String textToShow = "-"; // Changed from "N/A Mbps" to "-"
    double? result;
    // Set text color to white in light mode for both download and upload
    final Color? textColor = !isDarkMode ? Colors.white : null;

    if (label == 'Download') {
      result = _speedTestResultMbps;
    } else if (label == 'Upload') {
      result = _uploadSpeedTestResultMbps;
    }

    if (result != null) {
      if (result == -1) {
        textToShow = "Error";
      } else {
        textToShow = '${result.toStringAsFixed(2)} Mbps';
      }
    }

    return Text(
      textToShow,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: textColor,
      ), // Smaller font for speed
    );
  }

  Future<void> _connectToVpn() async {
    if (!mounted) return;

    if (await _flutterV2ray.requestPermission()) {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String packageName = packageInfo.packageName;

      setState(() {
        _isExtendedConnection = true;
        _connectionTime =
            24 * 60 * 60; // Set to 24 hours (or desired extended time)
      });

      await _flutterV2ray.startV2Ray(
        remark: _remark,
        config: jsonEncode(_config),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('VPN permission not granted')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _adLoadTimer?.cancel();
    super.dispose();
  }

  Future<void> _runSpeedTest() async {
    if (_isTestingSpeed) return;

    setState(() {
      _isTestingSpeed = true;
      _speedTestResultMbps = null;
      _uploadSpeedTestResultMbps = null;
    });

    final dio = Dio();

    // --- DOWNLOAD TEST ---
    try {
      const downloadUrl = 'http://cachefly.cachefly.net/10mb.test';
      final downloadStopwatch = Stopwatch()..start();
      final response = await dio.get(downloadUrl,
          options: Options(responseType: ResponseType.bytes));
      downloadStopwatch.stop();
      final duration = downloadStopwatch.elapsed;
      final contentLength = response.data.length;

      if (duration.inMilliseconds > 0 && contentLength > 0) {
        final speedBps = (contentLength * 8) / (duration.inMilliseconds / 1000);
        final speedMbps = speedBps / (1024 * 1024);
        if (mounted) setState(() => _speedTestResultMbps = speedMbps);
      }
    } catch (e) {
      print('[DownloadSpeedTest] Error: $e');
      if (mounted) setState(() => _speedTestResultMbps = -1);
    }

    // --- UPLOAD TEST ---
    try {
      final payloadSize = 2 * 1024 * 1024; // 2MB
      final dummyPayload = Uint8List(payloadSize);
      const uploadUrl = 'https://httpbin.org/post';
      final uploadStopwatch = Stopwatch()..start();

      await dio.post(uploadUrl, data: dummyPayload);

      uploadStopwatch.stop();
      final uploadDuration = uploadStopwatch.elapsed;

      if (uploadDuration.inMilliseconds > 0) {
        final uploadSpeedBps =
            (payloadSize * 8) / (uploadDuration.inMilliseconds / 1000);
        final uploadSpeedMbps = uploadSpeedBps / (1024 * 1024);
        if (mounted)
          setState(() => _uploadSpeedTestResultMbps = uploadSpeedMbps);
      }
    } catch (e) {
      print('[UploadSpeedTest] Error: $e');
      if (mounted) setState(() => _uploadSpeedTestResultMbps = -1);
    } finally {
      if (mounted) setState(() => _isTestingSpeed = false);
    }
  }
}
