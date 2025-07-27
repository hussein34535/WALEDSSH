import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vpn_client/design/colors.dart';
import 'package:vpn_client/design/dimensions.dart';
import 'package:vpnclient_engine_flutter/vpnclient_engine_flutter.dart';

class MainBtn extends StatefulWidget {
  const MainBtn({super.key});

  @override
  State<MainBtn> createState() => MainBtnState();
}

class MainBtnState extends State<MainBtn> with SingleTickerProviderStateMixin {
  String connectionStatus = connectionStatusDisconnected;
  String connectionTime = "00:00:00";
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _sizeAnimation = Tween<double>(begin: 0, end: 150).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.ease),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void startTimer() {
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

  void stopTimer() {
    _timer?.cancel();
    setState(() {
      connectionTime = "00:00:00";
      connectionStatus = connectionStatusDisconnected;
    });
  }

  Future<void> _handleConnection() async {
    print('Connect button pressed. Current status: $connectionStatus');
    setState(() {
      if (connectionStatus == connectionStatusConnected) {
        connectionStatus = connectionStatusDisconnecting;
      }
      if (connectionStatus == connectionStatusDisconnected) {
        connectionStatus = connectionStatusConnecting;
      }
    });

    if (connectionStatus == connectionStatusConnecting) {
      print('Initiating VPN connection...');
      _animationController.repeat(reverse: true);
      await VPNclientEngine.connect(subscriptionIndex: 0, serverIndex: 0);
      startTimer();
      setState(() {
        connectionStatus = connectionStatusConnected;
        print('VPN tunnel started successfully!');
      });
      await _animationController.forward();
      _animationController.stop();
    } else if (connectionStatus == connectionStatusDisconnecting) {
      print('Initiating VPN disconnection...');
      _animationController.repeat(reverse: true);
      stopTimer();
      await VPNclientEngine.disconnect();
      setState(() {
        connectionStatus = connectionStatusDisconnected;
        print('VPN disconnected.');
      });
      await _animationController.reverse();
      _animationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          connectionTime,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: connectionStatus == connectionStatusConnected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 70),
        GestureDetector(
          onTap: _handleConnection,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              AnimatedBuilder(
                animation: _sizeAnimation,
                builder: (context, child) {
                  return Container(
                    width: _sizeAnimation.value,
                    height: _sizeAnimation.value,
                    decoration: BoxDecoration(
                      gradient: mainGradient,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              Container(
                alignment: Alignment.center,
                width: 150,
                height: 150,
                child: const Icon(
                  Icons.power_settings_new_rounded,
                  color: Colors.white,
                  size: 70,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          connectionStatus,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(body: Center(child: MainBtn())),
    ),
  );
}
