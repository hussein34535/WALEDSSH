import 'package:flutter/material.dart';
import 'package:vpn_client/design/custom_icons.dart';
import 'package:vpn_client/design/images.dart';
import 'package:vpn_client/design/colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VPN Client'),
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 24,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Connection stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(CustomIcons.download, '0 Mb/s', context),
              _buildStatItem(CustomIcons.upload, '0 Mb/s', context),
              _buildStatItem(CustomIcons.ping, '0 ms', context),
            ],
          ),
          const SizedBox(height: 40),
          // Timer
          Text(
            '00:00:00',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 40),
          // Connect button
          GestureDetector(
            onTap: () {
              // Add connection logic here
            },
            child: AnimatedContainer(
              duration: Duration(seconds: 0),
              child: Stack(
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: mainGradient,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    width: 150,
                    height: 150,
                    child:  const Icon(
                      Icons.power_settings_new_rounded,
                      color: Colors.white,
                      size: 70,
                    ),
                  )
                ],
              )
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ОТКЛЮЧЕН',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Spacer(),
          // Location selector
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ваша локация',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    Text(
                      'Германия',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text('🇩🇪'),
              ],
            ),
          ),
          _buildBottomBar(context)
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width,
      height: 60,
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          appIcon,
          serverIcon,
          homeIcon,
          speedIcon,
          settingsIcon
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text, BuildContext context) {
    return Container(
      width: 100,
      height: 75,
      decoration: BoxDecoration(
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x1A9CB2C2),
            offset: Offset(0.0, 1.0),
            blurRadius: 32.0,
          ),
        ],
      ),
      child: FloatingActionButton(
        elevation: 0,
        onPressed: () {},
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(6.0)
              ),
              child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
