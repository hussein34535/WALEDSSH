import 'package:flutter/material.dart';
import 'package:finevpn/design/images.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fine VPN',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const VPNHomePage(),
    );
  }
}

class VPNHomePage extends StatefulWidget {
  const VPNHomePage({super.key});

  @override
  State<VPNHomePage> createState() => _VPNHomePageState();
}

class _VPNHomePageState extends State<VPNHomePage> {
  bool isConnected = false;
  String connectionTime = "00:00:00";
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    int seconds = 1;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        int hours = seconds ~/ 3600;
        int minutes = (seconds % 3600) ~/ 60;
        int remainingSeconds = seconds % 60;
        connectionTime =
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
      });
      seconds++;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      connectionTime = "00:00:00";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF66CCFF),
        toolbarHeight: 80,
        actions: [_buildTopBar()],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(color: Color(0xFF66CCFF)),
        child: Container(
          padding: EdgeInsets.only(bottom: 50),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            color: Color(0xFFE3EDF7),
          ),
          child: Column(
            children: [
              _buildServerSelection(),
              Expanded(child: Center(child: _buildConnectionButton())),
              _buildIPAddress(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            margin: EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF66CCFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFF85D6FF), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Color(0x691675A4),
                  offset: Offset(4.0, 4.0),
                  blurRadius: 20.0,
                ),
                BoxShadow(
                  color: Color(0x33FFFFFF),
                  offset: Offset(-6.0, -6.0),
                  blurRadius: 12.0,
                ),
                BoxShadow(
                  color: Color(0x1A005A87),
                  offset: Offset(2.0, 2.0),
                  blurRadius: 4.0,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(6),
              child: menuBtnImage,
            )
          ),
          Container(
              width: 50,
              height: 50,
              margin: EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF66CCFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFF85D6FF), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x691675A4),
                    offset: Offset(4.0, 4.0),
                    blurRadius: 20.0,
                  ),
                  BoxShadow(
                    color: Color(0x33FFFFFF),
                    offset: Offset(-6.0, -6.0),
                    blurRadius: 12.0,
                  ),
                  BoxShadow(
                    color: Color(0x1A005A87),
                    offset: Offset(2.0, 2.0),
                    blurRadius: 4.0,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: shareBtnImage,
              )
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 0.0, horizontal: 22.0),
            child: Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    child: Transform.translate(
                      offset: Offset(0, -2),
                      child: Text(
                        'fine',
                        style: const TextStyle(
                          color: Color(0xFF105374),
                          fontWeight: FontWeight.w200,
                          fontStyle: FontStyle.italic,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  TextSpan(
                    text: 'VPN',
                    style: const TextStyle(
                      color: Color(0xFF105374),
                      fontWeight: FontWeight.w700,
                      fontSize: 25,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
              width: 50,
              height: 50,
              margin: EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF66CCFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFF85D6FF), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x691675A4),
                    offset: Offset(4.0, 4.0),
                    blurRadius: 20.0,
                  ),
                  BoxShadow(
                    color: Color(0x33FFFFFF),
                    offset: Offset(-6.0, -6.0),
                    blurRadius: 12.0,
                  ),
                  BoxShadow(
                    color: Color(0x1A005A87),
                    offset: Offset(2.0, 2.0),
                    blurRadius: 4.0,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: crownBtnImage,
              )
          ),
          Container(
              width: 50,
              height: 50,
              margin: EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF66CCFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFF85D6FF), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x691675A4),
                    offset: Offset(4.0, 4.0),
                    blurRadius: 20.0,
                  ),
                  BoxShadow(
                    color: Color(0x33FFFFFF),
                    offset: Offset(-6.0, -6.0),
                    blurRadius: 12.0,
                  ),
                  BoxShadow(
                    color: Color(0x1A005A87),
                    offset: Offset(2.0, 2.0),
                    blurRadius: 4.0,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: settingBtnImage,
              )
          ),
        ],
      ),
    );
  }

  Widget _buildServerSelection() {
    return Container(
      width: MediaQuery.of(context).size.width - 60,
      height: 56,
      margin: EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Color(0xFFE3EDF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Color(0x696F8CB0),
            offset: Offset(6.35, 6.35),
            blurRadius: 31.76,
          ),
          BoxShadow(
            color: Color(0x33FFFFFF),
            offset: Offset(-9.53, -9.53),
            blurRadius: 31.76,
          ),
          BoxShadow(
            color: Color(0x1A728EAB),
            offset: Offset(3.18, 3.18),
            blurRadius: 6.35,
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [Color(0xFFD6E3F3), Color(0xFFFFFFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/italy.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              ),

              ClipOval(
                child: Transform.translate(
                  offset: Offset(0, -11),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.transparent, Color(0x555A6571)],
                        stops: [0.99, 1],
                        center: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          'Самый быстрый (58 м.с.)',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6F7E8C),
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF42BCFF)),
        onTap: () {},
      ),
    );
  }

  Widget _buildConnectionButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isConnected = !isConnected;
          if (isConnected) {
            _startTimer();
          } else {
            _stopTimer();
          }
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 275,
                height: 275,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE3EDF7),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x696F8CB0),
                      offset: Offset(6.35, 6.35),
                      blurRadius: 31.76,
                    ),
                    BoxShadow(
                      color: Color(0x33FFFFFF),
                      offset: Offset(-9.53, -9.53),
                      blurRadius: 31.76,
                    ),
                    BoxShadow(
                      color: Color(0x1A728EAB),
                      offset: Offset(3.18, 3.18),
                      blurRadius: 6.35,
                    ),
                  ],
                ),
              ),
              if (isConnected)
                Container(
                  width: 223,
                  height: 223,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF0478FF), Color(0xFF00B2FF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              Container(
                width: 218,
                height: 218,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE3EDF7),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x696F8CB0),
                      offset: Offset(6.35, 6.35),
                      blurRadius: 31.76,
                    ),
                    BoxShadow(
                      color: Color(0x33FFFFFF),
                      offset: Offset(-9.53, -9.53),
                      blurRadius: 31.76,
                    ),
                    BoxShadow(
                      color: Color(0x1A728EAB),
                      offset: Offset(3.18, 3.18),
                      blurRadius: 6.35,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isConnected)
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              colors: [Color(0xFF0478FF), Color(0xFF00B2FF)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcIn,
                          child: powerBtnImage
                        )
                      else
                        powerBtnImage
                    ],
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100),
              Text(
                isConnected ? connectionTime : 'Нажмите, чтобы подключиться',
                style: TextStyle(
                  color: Color(0xFF6F7E8C),
                  fontFamily: 'Raleway',
                  fontSize: isConnected ? 24 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIPAddress() {
    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width - 40,
      height: 52,
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Color(0xFFE3EDF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 1,
          color: Colors.white,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x696F8CB0),
            offset: Offset(6.35, 6.35),
            blurRadius: 31.76,
          ),
          BoxShadow(
            color: Color(0x33FFFFFF),
            offset: Offset(-9.53, -9.53),
            blurRadius: 31.76,
          ),
          BoxShadow(
            color: Color(0x1A728EAB),
            offset: Offset(3.18, 3.18),
            blurRadius: 6.35,
          ),
        ],
      ),
      child: Text(
        'IP: 192.12.12',
        style: TextStyle(
          color: Color(0xFF6F7E8C),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
