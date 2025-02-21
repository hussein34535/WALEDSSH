import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VPN Client'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Connection stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(Icons.download, '23.1 Mb/s'),
              _buildStatItem(Icons.upload, '15.7 Mb/s'),
              _buildStatItem(Icons.network_check, '16 ms'),
            ],
          ),
          const SizedBox(height: 40),
          // Timer
          const Text(
            '00:00:00',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          // Connect button
          GestureDetector(
            onTap: () {
              // Add connection logic here
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.power_settings_new,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ОТКЛЮЧЕН',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Location selector
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Ваша локация',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'Германия',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                      '🇩🇪'
                    ),
              ],
            ),
          ),
          // Bottom navigation
          BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.apps),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.location_on_outlined),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt_outlined),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.hexagon_outlined),
                label: '',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[700]),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}