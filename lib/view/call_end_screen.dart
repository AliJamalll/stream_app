import 'package:flutter/material.dart';
import 'package:stream_app/view/video_call_screen.dart';

class CallEndedScreen extends StatelessWidget {
  const CallEndedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.call_end,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Call Ended',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Thank you for using our video call app!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const VideoCallScreen()),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Join New Call'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}