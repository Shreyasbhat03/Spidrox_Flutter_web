import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spidrox_reg/river_pod/data_provider.dart';
import 'package:spidrox_reg/service/logout_pulsar/logout_consumer.dart';
import 'package:spidrox_reg/service/pulsar_producer.dart';

class Sidebar extends ConsumerWidget { // Changed to ConsumerWidget
  final bool isSidebarExpanded;
  final VoidCallback toggleSidebar;
  final Function(String) onNavigate;

  const Sidebar({
    Key? key,
    required this.isSidebarExpanded,
    required this.toggleSidebar,
    required this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Added WidgetRef parameter
   PulsarProducerService pulsarProducerService = PulsarProducerService();
    double sidebarWidth = isSidebarExpanded ? 200 : 60;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 0),
      width: sidebarWidth,
      color: const Color(0xff1c1c1c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar header
          InkWell(
            onTap: toggleSidebar,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    isSidebarExpanded ? Icons.menu_open : Icons.menu,
                    color: Color(0xFFDC143C),
                    size: 28,
                  ),
                  if (isSidebarExpanded) ...[
                    const SizedBox(width: 12),
                    const Text(
                      "Menu",
                      style: TextStyle(color: Color(0xFFDC143C), fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(color: Color(0xFFDC143C)),

          // Sidebar items
          _buildSidebarItem(
            icon: Icons.account_circle,
            title: "Profile",
            onTap: () => _onNavigate(context, 'profile'),
          ),
          _buildSidebarItem(
            icon: Icons.chat,
            title: "Messages",
            onTap: () => _onNavigate(context, 'messages'),
          ),
          _buildSidebarItem(
            icon: Icons.group,
            title: "Connections",
            onTap: () => _onNavigate(context, 'connections'),
          ),
          _buildSidebarItem(
            icon: Icons.star,
            title: "Interests",
            onTap: () => _onNavigate(context, 'interests'),
          ),
          _buildSidebarItem(
            icon: Icons.logout, // Logout icon
            title: "Logout",
            onTap: () => _showLogoutDialog(context, ref), // Pass the ref to access providers
          ),
        ],
      ),
    );
  }

  void _onNavigate(BuildContext context, String route) {
    switch (route) {
      case 'profile':
        context.pushNamed("profilePage");
        break;
      case 'messages':
        context.pushNamed("chatPage"); // Example chat ID
        break;
      case 'connections':
        context.pushNamed("ConnectionsPage");
        break;
    // case 'interests':
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(builder: (context) => InterestsPage()),
    //   );
    //   break;
      default:
        break;
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final pulsarProducerService = PulsarProducerService();
    final pulsarLogoutService = PulsarLogoutService();

    // Get user data and login data from Riverpod
    final userData = ref.read(userDataProvider).userData;
    final loginData = ref.read(loginProvider);
    final jwt = loginData.Loginjwt;
    final producerLogoutUrl = loginData.ProducerLogoutUrl;
    final consumerLogoutUrl = loginData.ConsumerLogoutUrl;

    // Extract phone number from user data
    String phoneNumber = userData['phone'] ?? '';
    print("Phone number: $phoneNumber");

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Setup a subscription to handle the response
                  StreamSubscription? subscription;

                  // Set up a timeout to handle no response
                  Timer? timeoutTimer;

                  // Connect to services
                  pulsarLogoutService.connectConsumer(jwt, consumerLogoutUrl);
                  await Future.delayed(Duration(milliseconds: 300));
                  pulsarProducerService.connectProducer(jwt, producerLogoutUrl);
                  await Future.delayed(Duration(milliseconds: 500));

                  // Subscribe to the stream before sending the message
                  subscription = pulsarLogoutService.messagesStream.listen((message) {
                    try {
                      print("Processing message: $message");
                      final parsedMessage = jsonDecode(message);

                      // Check if this is a response message with payload
                      if (parsedMessage.containsKey('payload')) {
                        // Decode the Base64 payload
                        final payloadBase64 = parsedMessage['payload'];
                        final decodedBytes = base64.decode(payloadBase64);
                        final decodedPayload = utf8.decode(decodedBytes);
                        final payloadJson = jsonDecode(decodedPayload);

                        print("Decoded payload: $payloadJson");

                        // Check if this is a logout response
                        if (payloadJson.containsKey('data') &&
                            payloadJson['data'].containsKey('success')) {

                          // Cancel the timeout
                          timeoutTimer?.cancel();

                          if (payloadJson['data']['success'] == true) {
                            print("Logout successful, clearing riverpod data");
                            ref.read(authProvider.notifier).clearData();
                            ref.read(loginProvider.notifier).clearData();
                            ref.read(userDataProvider.notifier).setUserData({});

                            // Cancel subscription and dispose services
                            subscription?.cancel();
                            pulsarLogoutService.dispose();
                            pulsarProducerService.dispose();

                            Navigator.of(dialogContext).pop(); // close dialog
                            context.go('/login'); // route to login
                          } else {
                            subscription?.cancel();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Logout failed. Please try again.")),
                            );
                            Navigator.of(dialogContext).pop(); // close dialog
                          }
                        }
                      }
                    } catch (e) {
                      print("Error processing message: $e");
                    }
                  });

                  // Set timeout for response
                  timeoutTimer = Timer(Duration(seconds: 5), () {
                    print("Timeout waiting for logout response");
                    subscription?.cancel();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Logout request timed out. Please try again.")),
                    );
                    Navigator.of(dialogContext).pop(); // close dialog
                  });

                  // Send the logout message
                  final logoutMessage = jsonEncode({
                    "phone": phoneNumber,
                  });
                  pulsarProducerService.sendMessage(logoutMessage,ref.read(loginProvider).producerLogoutTopic);

                } catch (e) {
                  print("Error in logout process: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Logout failed: $e")),
                  );
                  Navigator.of(dialogContext).pop(); // close dialog
                }
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }
  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: isSidebarExpanded ? 200 : 60, // Set fixed width for ListTile
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 8),
        leading: SizedBox(
          width: 40, // Ensures icon never takes full width
          child: Center(
            child: Icon(icon, color: const Color(0xFFDC143C), size: 28),
          ),
        ),
        title: isSidebarExpanded
            ? Text(title, style: const TextStyle(color: Color(0xFFDC143C)))
            : null, // Hide title when collapsed
        onTap: onTap,
        hoverColor: Colors.grey.shade800,
      ),
    );
  }
}