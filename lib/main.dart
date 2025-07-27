import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vpn_client/data/servers.dart';
import 'package:vpn_client/services/api_service.dart';
import 'package:vpn_client/theme_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

void main() {
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
      title: 'WALEDSSH VPN',
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
  String _buttonText = 'Connect';
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

  // -- متغيرات تسجيل أعلى سرعة --
  int _peakDownloadSpeedBps = 0;
  int _peakUploadSpeedBps = 0;
  // --------------------------------

  final String _gameId = '5833433';
  final String _rewardedPlacementId = 'Rewarded_Android';
  final String _interstitialPlacementId = 'Interstitial_Android';

  bool _isRewardedAdReady = false;
  bool _isInterstitialAdReady = false;

  Timer? _adLoadTimer;

  final Uri _telegramUrl = Uri.parse('https://t.me/D_S_D_C1');
  final Uri _subscriptionUrl = Uri.parse('https://t.me/D_S_D_Cbot');

  @override
  void initState() {
    super.initState();
    _flutterV2ray = FlutterV2ray(onStatusChanged: _onStatusChanged);
    _loadData().then((_) {
      _initializeV2Ray();
      _initializeUnityAds();
      _loadRewardedAd();
      _loadInterstitialAd();
    });
  }

  void _initializeUnityAds() {
    try {
      UnityAds.init(
        gameId: _gameId,
        testMode: false, // Enable test mode for debugging
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
    final lastFetchTime = prefs.getInt('last_fetch_time') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final oneDay = 24 * 60 * 60 * 1000;

    print("[_loadData] Starting data load process.");

    // Load cached data first
    await _loadDataFromCache();
    print(
      "[_loadData] After loading from cache: Servers count = ${_vpnServers.length}, SNI profiles count = ${_sniProfiles.length}",
    );

    if (currentTime - lastFetchTime > oneDay ||
        _vpnServers.isEmpty ||
        _sniProfiles.isEmpty) {
      print(
        "[_loadData] Fetching new data from server (cache expired or empty lists)...",
      );
      try {
        final servers = await ApiService.fetchVlessServers();
        final profiles = await ApiService.fetchSniProfiles();

        setState(() {
          _vpnServers = servers;
          _sniProfiles = profiles;
        });
        // Save data to cache only if fetched successfully
        if (servers.isNotEmpty && profiles.isNotEmpty) {
          await _saveDataToCache();
          await prefs.setInt('last_fetch_time', currentTime);
          print("[_loadData] Data fetched from API and saved to cache.");
        }
      } catch (e) {
        print(
          "[_loadData] Error fetching new data, using cached data if available: $e",
        );
      }
    } else {
      print("[_loadData] Using cached data (cache not expired).");
    }

    // Ensure _vpnServers and _sniProfiles are never empty
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

    await _loadSelections(); // This will try to load saved selections first
    print(
      "[_loadData] After _loadSelections: _selectedServer = ${_selectedServer?.name}, _selectedProfile = ${_selectedProfile?.name}",
    );

    setState(() {
      // Ensure a default server/profile is selected if none or invalid saved
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
      // If still null, means no data was available at all, even default placeholder
      if (_selectedServer == null) {
        _selectedServer =
            _vpnServers.first; // Fallback to the 'No Servers' placeholder
        print(
          "[_loadData] _selectedServer still null, fell back to placeholder: ${_selectedServer?.name}",
        );
      }
      if (_selectedProfile == null) {
        _selectedProfile =
            _sniProfiles.first; // Fallback to the 'No SNI' placeholder
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

    // Re-initialize V2Ray after ensuring a valid server is selected
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
    // Do NOT set state here. Let _loadData handle final selection assignment.
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
    // Do NOT set state here. Let _loadData handle final selection assignment.
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
    print("V2Ray - Final URL to initialize: $url"); // Added logging

    if (_selectedServer == null || url.isEmpty) {
      print(
        "V2Ray initialization skipped: selected server is null or URL is invalid.",
      );
      // No SnackBar here, as it might be normal if no servers are available
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

    // --- منطق تسجيل أعلى سرعة ---
    if (newState == 'CONNECTED') {
      // إذا كان الاتصال قد بدأ للتو، قم بتصفير العدادات
      if (previousState != 'CONNECTED') {
        _peakDownloadSpeedBps = 0;
        _peakUploadSpeedBps = 0;
      }

      // قم بتحديث أعلى سرعة إذا كانت السرعة الحالية أكبر
      if ((newStatus.downloadSpeed ?? 0) > _peakDownloadSpeedBps) {
        _peakDownloadSpeedBps = newStatus.downloadSpeed ?? 0;
      }
      if ((newStatus.uploadSpeed ?? 0) > _peakUploadSpeedBps) {
        _peakUploadSpeedBps = newStatus.uploadSpeed ?? 0;
      }
    }
    // -------------------------

    if (mounted) {
      setState(() {
        _status = newStatus;
        _updateButtonState();
      });
    }

    // --- منطق الإعلانات والمؤقت ---
    if (newState == 'CONNECTED' && previousState != 'CONNECTED') {
      _startTimer();
      // تأخير عرض الإعلان البيني
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _status?.state == 'CONNECTED') {
          _showInterstitialAd();
        }
      });
    } else if (newState == 'DISCONNECTED' && previousState != 'DISCONNECTED') {
      _stopTimer();
      _isExtendedConnection = false;
      _loadRewardedAd();
      _loadInterstitialAd();
      // إعادة تصفير العدادات عند قطع الاتصال
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
        _buttonText = 'Disconnect'; // تغيير النص هنا ليكون أوضح
        break;
      case 'CONNECTING':
        _buttonText = 'Connecting...';
        break;
      case 'DISCONNECTED':
        _buttonText = 'Connect';
        break;
      default:
        _buttonText = 'Connect';
        break;
    }
  }

  Future<void> _toggleVpn() async {
    if (_status?.state == 'CONNECTED') {
      await _flutterV2ray.stopV2Ray();
    } else {
      // إذا كان الإعلان جاهزاً، اعرضه
      if (_isRewardedAdReady) {
        _showRewardedAd();
      } else {
        // الإعلان ليس جاهزاً، ابدأ مؤقت الـ 20 ثانية
        setState(() {
          _isAdLoading = true;
        });
        _loadRewardedAd(); // حاول تحميل الإعلان مرة أخرى

        _adLoadTimer?.cancel(); // ألغِ أي مؤقت قديم
        _adLoadTimer = Timer(const Duration(seconds: 20), () {
          print('Ad load timeout. Connecting directly...');
          if (mounted && _status?.state != 'CONNECTED') {
            setState(() {
              _isAdLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('فشل تحميل الإعلان. جاري الاتصال مباشرة...'),
                backgroundColor: Colors.green,
              ),
            );
            _connectToVpn(); // <-- اتصل مباشرة بعد 20 ثانية
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
        queryParams['sni'] =
            _selectedProfile!.sni; // Also update sni if present
        finalUrl = originalUri.replace(queryParameters: queryParams).toString();
      } catch (e) {
        print(
          "Error parsing or replacing URL parts in _getFinalUrl: $e",
        ); // Added logging
        return _selectedServer!.url; // Fallback to original URL
      }
    }
    print("V2Ray - Constructed final URL: $finalUrl"); // Added logging
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
    // This function is now only called after successfully watching an ad.
    // _connectionTime is already set to 24 hours in _showRewardedAd.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_connectionTime > 0) {
        setState(() {
          _connectionTime--;
        });
      } else {
        // Time is up, disconnect.
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

  String _formatSpeed(int? speedInBytes) {
    if (_status?.state != 'CONNECTED' || speedInBytes == null) return '---';
    if (speedInBytes == 0 && _connectionTime < 3) return '...';

    double speedInMbps = (speedInBytes /
        (1024 * 1024) *
        8); // Convert Bps to Mbps (1 Byte = 8 bits)

    if (speedInMbps < 0.1) {
      // If less than 0.1 Mbps, show in KB/s for more precision
      return '${(speedInBytes / 1024).toStringAsFixed(2)} KB/s';
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

          // --- التعديل هنا ---
          // لا تقم بعرض الإعلان تلقائياً من هنا.
          // فقط قم بتحديث الحالة، ودالة _toggleVpn هي المسؤولة عن العرض.
          // if (_isAdLoading) {
          //   _adLoadTimer?.cancel();
          //   _showRewardedAd();
          // }
          // ------------------
        }
      },
      onFailed: (placementId, error, message) {
        print('Load Failed $placementId: $error $message');
        _isRewardedAdReady = false;
        if (mounted) {
          setState(() {
            _isAdLoading = false;
          });
        }
      },
    );
  }

  void _loadInterstitialAd() {
    _isInterstitialAdReady = false; // إعادة التعيين عند بدء التحميل
    UnityAds.load(
      placementId: _interstitialPlacementId,
      onComplete: (placementId) {
        print('Load Complete: $placementId');
        setState(() {
          _isInterstitialAdReady = true; // الإعلان أصبح جاهزاً
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
      _loadInterstitialAd(); // حاول تحميله مرة أخرى بهدوء
      return;
    }

    UnityAds.showVideoAd(
      placementId: _interstitialPlacementId,
      onComplete: (placementId) {
        print('Video Ad ($placementId) completed');
        _loadInterstitialAd();
      },
      onFailed: (placementId, error, message) {
        print('Video Ad ($placementId) failed: $error $message');
        _loadInterstitialAd();
      },
      onStart: (placementId) => print('Video Ad ($placementId) start'),
      onClick: (placementId) => print('Video Ad ($placementId) click'),
      onSkipped: (placementId) {
        print('Video Ad ($placementId) skipped');
        _loadInterstitialAd();
      },
    );
  }

  void _showRewardedAd() {
    if (!_isRewardedAdReady) {
      _handleAdFailure('الإعلان غير جاهز بعد، يرجى المحاولة مرة أخرى.');
      _loadRewardedAd();
      return;
    }

    UnityAds.showVideoAd(
      placementId: _rewardedPlacementId,
      onComplete: (placementId) async {
        print('Video Ad ($placementId) completed');
        _adLoadTimer?.cancel(); // <-- ألغِ المؤقت عند مشاهدة الإعلان
        setState(() {
          _isExtendedConnection = true;
          _connectionTime = 24 * 60 * 60;
          _isAdLoading = false;
        });
        _connectToVpn(); // <-- استخدم الدالة الجديدة للاتصال
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
      },
    );
  }

  void _handleAdFailure(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );

      // إظهار للمستخدم أننا نحاول تحميل الإعلان مجدداً
      setState(() {
        _isAdLoading = true;
      });
      _loadRewardedAd();
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
                const Spacer(flex: 2),
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
          } else if (value == 'telegram') {
            _launchUrl(_telegramUrl);
          } else if (value == 'subscribe') {
            _launchUrl(_subscriptionUrl);
          }
        },
        icon: Icon(Icons.menu, color: theme.iconTheme.color, size: 30),
        color: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
          PopupMenuItem<String>(
            value: 'telegram',
            child: Row(
              children: [
                const Icon(Icons.telegram, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Text('Join Telegram', style: theme.textTheme.bodyMedium),
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
        ],
      ),
      title: Text(
        'WALEDSSH',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onBackground,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.telegram, color: Colors.blueAccent),
          iconSize: 30, // Increased size
          onPressed: () => _launchUrl(_telegramUrl),
        ),
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode
                ? Icons
                    .light_mode_outlined // In Dark mode, show Sun to switch to Light/Colorful
                : Icons
                    .dark_mode_outlined, // In Light/Colorful mode, show Moon to switch to Dark
          ),
          iconSize: 30, // Increased size
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

    // --- تحديث منطق نص الزر ---
    String buttonTextToShow = _buttonText;
    if (_status?.state != 'CONNECTED' && _isAdLoading) {
      buttonTextToShow = 'جاري تحميل الإعلان...';
    }
    // --------------------------

    return Column(
      children: [
        GestureDetector(
          onTap: (_status?.state == 'CONNECTING' ||
                  _isAdLoading ||
                  _isLoading) // <-- تعطيل الزر أثناء التحميل
              ? null
              : _toggleVpn,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 220,
            height: 220,
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
                  ? const CircularProgressIndicator() // إظهار مؤشر تحميل
                  : Icon(
                      Icons.power_settings_new_rounded,
                      size: 80,
                      color: isConnected ? connectedColor : disconnectedColor,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          buttonTextToShow, // <-- استخدام النص المحدث
          style: theme.textTheme.labelLarge?.copyWith(
            color: isConnected ? connectedColor : disconnectedColor,
            letterSpacing: 1.5,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 50.0), // Use a fixed SizedBox for spacing
        if (isConnected) // Conditionally display the time unit
          Center(
            child: Column(
              children: [
                const SizedBox(height: 8), // Padding above the unit text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hours
                    Column(
                      children: [
                        Text(
                          (_connectionTime ~/ 3600)
                              .toString()
                              .padLeft(2, '0'), // Hours
                          style: GoogleFonts.montserrat(
                            fontSize: 52, // Make it large
                            fontWeight: FontWeight.w500, // Not bold
                            color: Colors.grey, // Set color to grey
                          ),
                        ),
                        Text(
                          'ساعة',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isConnected
                                ? connectedColor
                                : disconnectedColor,
                            letterSpacing: 1.5,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      ':',
                      style: GoogleFonts.montserrat(
                        fontSize: 52, // Make it large
                        fontWeight: FontWeight.w500, // Not bold
                        color: Colors.grey, // Set color to grey
                      ),
                    ),
                    // Minutes
                    Column(
                      children: [
                        Text(
                          ((_connectionTime % 3600) ~/ 60)
                              .toString()
                              .padLeft(2, '0'), // Minutes
                          style: GoogleFonts.montserrat(
                            fontSize: 52, // Make it large
                            fontWeight: FontWeight.w500, // Not bold
                            color: Colors.grey, // Set color to grey
                          ),
                        ),
                        Text(
                          'دقايق',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isConnected
                                ? connectedColor
                                : disconnectedColor,
                            letterSpacing: 1.5,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      ':',
                      style: GoogleFonts.montserrat(
                        fontSize: 52, // Make it large
                        fontWeight: FontWeight.w500, // Not bold
                        color: Colors.grey, // Set color to grey
                      ),
                    ),
                    // Seconds
                    Column(
                      children: [
                        Text(
                          (_connectionTime % 60)
                              .toString()
                              .padLeft(2, '0'), // Seconds
                          style: GoogleFonts.montserrat(
                            fontSize: 52, // Make it large
                            fontWeight: FontWeight.w500, // Not bold
                            color: Colors.grey, // Set color to grey
                          ),
                        ),
                        Text(
                          'ثواني',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isConnected
                                ? connectedColor
                                : disconnectedColor,
                            letterSpacing: 1.5,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
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

    // --- GUARANTEED HIGH CONTRAST COLORS ---
    final Color highContrastIconColor = themeProvider.isDarkMode
        ? theme.colorScheme.primary
        : theme.colorScheme.primary;
    final bool isDisabled = _isLoading ||
        items.isEmpty ||
        (items.length == 1 && (items.first as dynamic).name == 'Loading...');

    return Container(
      height: 60, // Increased height for a better feel
      padding: const EdgeInsets.symmetric(horizontal: 20), // Adjusted padding
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: themeProvider.isDarkMode &&
                theme.primaryColor ==
                    const Color(0xFFAD1457) // Colorful mode only
            ? Border.all(
                color: theme.colorScheme.secondary.withOpacity(0.3),
                width: 1.5,
              )
            : null, // No border in classic dark or light mode
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
          ), // GUARANTEED CONTRAST
          const SizedBox(width: 16), // Increased spacing
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
                dropdownColor:
                    theme.cardTheme.color, // Dropdown is same color as card
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: highContrastIconColor,
                ), // GUARANTEED CONTRAST
                items: items.map<DropdownMenuItem<T>>(itemBuilder).toList(),
                onChanged: isDisabled ? null : onChanged, // تعطيل القائمة
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
    final theme = themeProvider.themeData; // Ensure theme is accessible

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.arrow_downward,
            label: 'Download',
            value: _formatSpeed(_peakDownloadSpeedBps), // <-- استخدام أعلى سرعة
            color: themeProvider.isDarkMode
                ? Colors.blueAccent
                : theme.colorScheme.primary,
          ),
        ),
        if (_status?.state ==
            'CONNECTED') // Show refresh button only when connected
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.onBackground),
            onPressed: () {
              setState(() {
                _peakDownloadSpeedBps = 0;
                _peakUploadSpeedBps = 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إعادة ضبط قراءات السرعة.')),
              );
            },
          ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.arrow_upward,
            label: 'Upload',
            value: _formatSpeed(_peakUploadSpeedBps), // <-- استخدام أعلى سرعة
            color: themeProvider.isDarkMode
                ? Colors.pinkAccent
                : theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Card(
      // No need for SizedBox with width anymore
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(
              label.toUpperCase(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurface.withOpacity(
                  0.6,
                ), // Standard secondary text
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode
                    ? const Color(0xFFFFC107) // RESTORED Gold for Dark Mode
                    : theme
                        .colorScheme.onSurface, // Standard primary text on card
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectToVpn() async {
    if (!mounted) return;

    if (await _flutterV2ray.requestPermission()) {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String packageName = packageInfo.packageName;

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
}
