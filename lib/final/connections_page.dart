import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spidrox_reg/bloc/ConnectionsBloc/connections_bloc.dart';
import 'package:spidrox_reg/bloc/ConnectionsBloc/connections_event.dart';
import 'package:spidrox_reg/bloc/ConnectionsBloc/connections_state.dart';
import 'package:spidrox_reg/final/chat_ui.dart';
import 'package:spidrox_reg/river_pod/data_provider.dart';
import 'package:spidrox_reg/service/pulsar_consumer.dart';
import 'package:spidrox_reg/service/pulsar_producer.dart';
import 'package:spidrox_reg/sidebar.dart';

void main() {
  runApp(ProviderScope(child: Connections()));
}

class Connections extends ConsumerStatefulWidget {
  const Connections({super.key});

  @override
  ConsumerState<Connections> createState() => _ConnectionsState();
}

class _ConnectionsState extends ConsumerState<Connections> {
  @override
  Widget build(BuildContext context) {
   final loginData = ref.watch(loginProvider);
    final jwt = ref.watch(loginProvider).Loginjwt;

    final pulsarService = PulsarService();
    final pulsarProducer = PulsarProducerService();

    if (loginData.Loginjwt.isEmpty || loginData.ConnectionConsumerUrl.isEmpty) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final  urls = {
      "consumerconnectionUrl": loginData.ConnectionConsumerUrl,
      "producerconnectionUrl": loginData.ConnectionProducerUrl,
      "producerTopic": loginData.ProducerConnectTopic,
      "consumerConnectUrl":loginData.ConsumerConnectUrl,
      "producerConnectUrl":loginData.ProducerConnectUrl,
      "producerConnectTopic":loginData.ProducerConnectTopic,
      "producerRequestUrl": loginData.ProducerRequestUrl,
      "consumerRequestUrl": loginData.ConsumerRequestUrl,
      "producerRequestTopic": loginData.ProducerRequestTopic,
    };


    return BlocProvider(
      create: (context) => ConnectionsBloc(
        jwt: jwt,
        pulsarUrls: urls,
        pulsarService: pulsarService,
        pulsarProducerService:pulsarProducer,
        userPhone: ref.read(userDataProvider).userData['phone'] ?? "",
      )..add(FetchConnections("People")),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ConnectionsPage(),
      ),
    );
  }
}

class ConnectionsPage extends ConsumerStatefulWidget {
  ConnectionsPage({Key? key}) : super(key: key);

  @override
  ConsumerState createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends ConsumerState<ConnectionsPage> {
  bool isSidebarExpanded = false;
  String currentPage = "Connections";
  String selectedTab = "People";
  String selectedFilter = "All";
  void _toggleSidebar() {
    setState(() {
      isSidebarExpanded = !isSidebarExpanded;
    });
  }

  void _navigateToSection(String section) {
    setState(() {
      currentPage = section;
    });
  }
  void dispose() {
    super.dispose();
    // Close the Pulsar connection when the widget is disposed
    final connectionsBloc = BlocProvider.of<ConnectionsBloc>(context);
    connectionsBloc.pulsarService.Consumerdisconnect();
    connectionsBloc.pulsarProducerService.Producerdisconnect();
  }
  @override

  Widget _buildTab(String title) {
    bool isActive = selectedTab == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = title;
        });

        // Dispatch event to change topic based on tab
        context.read<ConnectionsBloc>().add(ChangeSubscriptionTopic(title, title));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xff1c1c1c) : const Color(0xFFDC143C),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: _getTextWidth(title, 16, FontWeight.bold),
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFDC143C) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
  double _getTextWidth(String text, double fontSize, FontWeight fontWeight) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width + 6; // Add slight padding
  }

  Widget _buildSearchAndFilter(width) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Search Box
          Container(
            width: width*0.6,
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F7),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 1,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Connections...",
                hintStyle: TextStyle(fontSize: width*0.012),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Color(0xFFDC143C)),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Filter Dropdown
          Container(
            width: width*0.1,
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F7),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 1,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedFilter,
                items: const [
                  DropdownMenuItem(value: "All", child: Text("All")),
                  DropdownMenuItem(value: "Friends", child: Text("Friends")),
                  DropdownMenuItem(value: "Colleagues", child: Text("Colleagues")),
                  DropdownMenuItem(value: "Others", child: Text("Others")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedFilter = value!;
                  });
                },
                icon: const Icon(Icons.filter_list, color: Color(0xFFDC143C)),
                style: const TextStyle(color: Colors.black87),
                dropdownColor: Colors.grey[200],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    if (currentPage == "Connections") {
      return Container(
        color: const Color(0xFFF6F6F7),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Container(
              width: MediaQuery.of(context).size.width*0.8,
              height: MediaQuery.of(context).size.height*0.07,
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2, offset: Offset(0, 5)),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTab("People"),
                  _buildTab("My Connections"),
                  _buildTab("Connections Sent"),
                  _buildTab("Connections Received"),
                ],
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width*0.8,
              height: MediaQuery.of(context).size.height*0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2, offset: Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchAndFilter(MediaQuery.of(context).size.width),
                  const SizedBox(height: 20),
                  if (selectedTab == "People")
                    _buildConnections()
                  else if (selectedTab == "My Connections")
                    _buildMyConnections()
                  else if (selectedTab == "Connections Sent")
                      _buildConnectionsSent()
                    else if (selectedTab == "Connections Received")
                        _buildConnectionsReceived()
                      else
                        const Center(child: Text("No Data Found")),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return const Center(
        child: Text(
          "Section not found!",
          style: TextStyle(fontSize: 20, color: Colors.red),
        ),
      );
    }
  }

  Widget _buildConnections() {
    final connectionsBloc = BlocProvider.of<ConnectionsBloc>(context);
    final userDataState = ref.watch(userDataProvider);
    // Access the userData Map inside the state
    final userData = userDataState.userData;
    return BlocBuilder<ConnectionsBloc, ConnectionsState>(
      builder: (context, state) {
        if (state is ConnectionsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        else if (state is ConnectionsError) {
          // Show SnackBar
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading the data: ${state.error}')),
            );
          });

          // ✅ Return an error message widget
          return const Center(
            child: Text("Failed to load connections", style: TextStyle(color: Colors.red)),
          );
        }
        else if (state is ConnectionsLoaded) {
          return Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: state.connections.length, // ✅ Use dynamic count
              itemBuilder: (context, index) {
                var connection = state.connections[index];
                return _buildConnectionTile(
                  profileName: connection['name'] ?? "Unknown",
                  buttonLabel: "Connect",
                  context: context,
                  onPressed: () {

                    connectionsBloc.add(UpdateConnectionStatus(
                        fromConnectionId: userData['phone']?? "",
                        toConnectionId: connection['phone'] ?? "",
                        status: 'requested'
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Connection request sent to ${connection['name'] ?? "Unknown"}')),
                    );
                  }, profileImageBase64: connection['profile'], collegeName: connection['college'],
                );
              },
            ),
          );
        }
        else {
          // ✅ Return default empty state
          return const Center(child: Text("No connections available"));
        }
      },
    );
  }

  Widget _buildMyConnections() {
    final userDataState = ref.watch(userDataProvider);
    // Access the userData Map inside the state
    final userData = userDataState.userData;
    return BlocBuilder<ConnectionsBloc, ConnectionsState>(
      builder: (context, state) {
        if (state is ConnectionsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        else if (state is ConnectionsError) {
          // Show SnackBar
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading the data: ${state.error}')),
            );
          });

          // ✅ Return an error message widget
          return const Center(
            child: Text("Failed to load connections", style: TextStyle(color: Colors.red)),
          );
        }
        else if (state is ConnectionsLoaded) {
          final connections = state.connections.where((conn) =>
          conn['status'] == 'ACCEPTED').toList();

          if (connections.isEmpty) {
            return const Center(child: Text("No accepted connections yet"));
          }

          return Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: connections.length,
              itemBuilder: (context, index) {
                var connection = connections[index];
                return _buildConnectionTile(
                  profileName: connection['name'] ?? "Unknown",
                  buttonLabel: "Message",
                  context: context,
                  onPressed: () {

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Messaging ${connection['name'] ?? "Unknown"}')),
                    );
                    context.pushNamed(
                      "chatPage",
                      pathParameters: {
                        "chatId": connection['phone'] ?? "",
                      },
                    );
                  }, profileImageBase64: connection['profile'], collegeName: connection['college'],
                );
              },
            ),
          );
        }
        else {
          // ✅ Return default empty state
          return const Center(child: Text("No connections available"));
        }
      },
    );
  }


  // Connections Sent List
  Widget _buildConnectionsSent() {
    final userDataState = ref.watch(userDataProvider);
    // Access the userData Map inside the state
    final userData = userDataState.userData;
    return BlocBuilder<ConnectionsBloc, ConnectionsState>(
        builder: (context, state) {
          if (state is ConnectionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          else if (state is ConnectionsError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading the data: ${state.error}')),
              );
            });

            return const Center(
              child: Text("Failed to load connections", style: TextStyle(color: Colors.red)),
            );
          }
          else if (state is ConnectionsLoaded) {
            final connections = state.connections.where((conn) =>
            conn['status'] == 'SENT').toList();

            if (connections.isEmpty) {
              return const Center(child: Text("No pending sent requests"));
            }

            return Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: connections.length,
                itemBuilder: (context, index) {
                  var connection = connections[index];
                  return _buildConnectionTile(
                    profileName: connection['name'] ?? "Unknown",
                    buttonLabel: "Cancel Request",
                    context: context,
                    onPressed: () {
                      final connectionsBloc = BlocProvider.of<ConnectionsBloc>(context);
                      connectionsBloc.add(UpdateConnectionStatus(
                          fromConnectionId: userData['phone'] ?? "",
                          toConnectionId: connection['phone'] ?? "",
                          status: "rejected"
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Cancelled request to ${connection['name'] ?? "Unknown"}')),
                      );
                    }, profileImageBase64: connection['profile'], collegeName: connection['college'],
                  );
                },
              ),
            );
          }
          else {
            return const Center(child: Text("No connections available"));
          }
        }
    );
  }

  // Connections Received List
  Widget _buildConnectionsReceived() {
    final userDataState = ref.watch(userDataProvider);
    // Access the userData Map inside the state
    final userData = userDataState.userData;
    return BlocBuilder<ConnectionsBloc, ConnectionsState>(
      builder: (context, state) {
        if (state is ConnectionsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        else if (state is ConnectionsError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading the data: ${state.error}')),
            );
          });

          return const Center(
            child: Text("Failed to load connections", style: TextStyle(color: Colors.red)),
          );
        }
        else if (state is ConnectionsLoaded) {
          final connections = state.connections.toList();

          if (connections.isEmpty) {
            return const Center(child: Text("No pending received requests"));
          }

          return Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: connections.length,
              itemBuilder: (context, index) {
                var connection = connections[index];
                return _buildConnectionTile(
                  profileName: connection['name'] ?? "Unknown",
                  buttonLabel: "Accept",
                  context: context,
                  onPressed: () {
                    final connectionsBloc = BlocProvider.of<ConnectionsBloc>(context);
                    connectionsBloc.add(UpdateConnectionStatus(
                        fromConnectionId: userData["phone"] ?? "",
                        toConnectionId: connection['phone'] ?? "",
                        status: "approved"
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Accepted request from ${connection['name'] ?? "Unknown"}')),
                    );
                  }, profileImageBase64: connection['profile'], collegeName: connection['college'],
                );
              },
            ),
          );
        }
        else {
          return const Center(child: Text("No connections available"));
        }
      },
    );
  }

  Widget _buildConnectionTile({
    required String profileName,
    required String buttonLabel,
    required VoidCallback onPressed,
    required BuildContext context,
    required String? profileImageBase64,
    required String? collegeName
  }) {
    // Decode base64 image if available
    ImageProvider profileImage;
    if (profileImageBase64 != null && profileImageBase64.isNotEmpty) {
      try {
        final imageBytes = base64.decode(profileImageBase64);
        // print("Decoded image bytes: $imageBytes");
        profileImage = MemoryImage(Uint8List.fromList(imageBytes));
      } catch (e) {
        profileImage = const NetworkImage('https://www.pngarts.com/files/10/Default-Profile-Picture-PNG-Download-Image.png');
      }
    } else {
      profileImage = const NetworkImage('https://www.pngarts.com/files/10/Default-Profile-Picture-PNG-Download-Image.png');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: profileImage,
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profileName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (collegeName != null && collegeName.isNotEmpty)
                    Text(
                      collegeName,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC143C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text(buttonLabel, style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$value for $profileName')),
                  );
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'View Profile', child: Text('View Profile')),
                  const PopupMenuItem(value: 'Block User', child: Text('Block User')),
                  const PopupMenuItem(value: 'Report', child: Text('Report')),
                ],
                icon: const Icon(Icons.more_vert, color: Color(0xFFDC143C)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            isSidebarExpanded: isSidebarExpanded,
            toggleSidebar: _toggleSidebar,
            onNavigate: _navigateToSection,
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildPageContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}