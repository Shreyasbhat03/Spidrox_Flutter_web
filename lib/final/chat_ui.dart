import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:spidrox_reg/bloc/chat_bloc/chatbloc_bloc.dart';
import 'package:spidrox_reg/river_pod/data_provider.dart';
import '../bloc/chat_bloc/chatbloc_event.dart';
import '../bloc/chat_bloc/chatbloc_state.dart';
import '../model&repo/message_model.dart';
import '../model&repo/repo/hive_repo.dart';
import '../sidebar.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(MessageAdapter());
  runApp(chatApp());
}

class chatApp extends ConsumerWidget {
  final String? selectedUser;
  const chatApp({super.key, this.selectedUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataState = ref.watch(userDataProvider);
    // Access the userData Map inside the state
    final userData = userDataState.userData;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (context) => ChatBloc(
          repository: MessageRepository(),
          currentUserId: userData['phone'] ?? '',
          jwt:ref.watch(loginProvider).Loginjwt,
        ),
        child: ChatAppPage(selectedUser: selectedUser),
      ),
    );
  }
}

class ChatAppPage extends StatefulWidget {
  final String? selectedUser;

  const ChatAppPage({
    Key? key,
    this.selectedUser,
  }) : super(key: key);

  @override
  _ChatAppPageState createState() => _ChatAppPageState();
}

class _ChatAppPageState extends State<ChatAppPage> {
  bool isSidebarExpanded = false;
  String currentSection = 'chat';
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _showEmojiPicker = false;
  late String _selectedUser;
  List<Map<String, dynamic>> _userList = [];
  List<Message> _chatMessages = [];
  bool _isUsersLoading = true;

  late ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _chatBloc = BlocProvider.of<ChatBloc>(context);

    // Initialize _selectedUser with the value from widget.selectedUser or empty string
    _selectedUser = widget.selectedUser ?? '';

    // Fetch users when the app starts
    _chatBloc.add(FetchUsers());

    // If selectedUser is provided, load the messages for that user
    if (_selectedUser.isNotEmpty) {
      // Small delay to ensure the bloc is properly initialized
      Future.delayed(Duration(milliseconds: 100), () {
        _chatBloc.add(LoadMessages(_selectedUser));
      });
    }
  }

  void _toggleSidebar() {
    setState(() {
      isSidebarExpanded = !isSidebarExpanded;
    });
  }

  void _navigateToSection(String section) {
    setState(() {
      currentSection = section;
    });
  }

  void _selectUser(String userId) {
    setState(() {
      _selectedUser = userId;
    });

    _chatBloc.add(LoadMessages(userId));
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty && _selectedUser.isNotEmpty) {
      _chatBloc.add(SendMessage(
        receiverId: _selectedUser,
        content: content,
      ));
      print("✅ Message sent from ui to $_selectedUser: $content");
      _messageController.clear();
    }
  }
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getUserAvatarText(Map<String, dynamic> user) {
    // Extract first letter from name or use first digit from phone if available
    if (user.containsKey('name') && user['name'].toString().isNotEmpty) {
      return user['name'].toString().substring(0, 1).toUpperCase();
    } else if (user.containsKey('phone') && user['phone'].toString().isNotEmpty) {
      return user['phone'].toString().substring(0, 1);
    }
    return "?";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Row(
              children: [
                // Left panel - User List
                Container(
                  width: 400,
                  color: Colors.white,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Messages', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                            SizedBox(height: 10),
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.search, color: Color(0xFFDC143C)),
                                    onPressed: () {},
                                  ),
                                ),
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        // BlocBuilder to listen for users state changes only
                        child: BlocBuilder<ChatBloc, ChatState>(
                          buildWhen: (previous, current) {
                            // Only rebuild when users state changes
                            return current is UsersLoading ||
                                current is UsersLoaded ||
                                current is UsersError;
                          },
                          builder: (context, state) {
                            if (state is UsersLoading) {
                              return Center(child: CircularProgressIndicator());
                            } else if (state is UsersLoaded) {
                              // Store the users list for future reference
                              _userList = state.users;

                              return ListView.builder(
                                itemCount: _userList.length,
                                itemBuilder: (context, index) {
                                  final user = _userList[index];
                                  final bool isSelected = _selectedUser == user['phone']; // Using phone as userId

                                  // Filter users if search text is entered
                                  if (_searchController.text.isNotEmpty &&
                                      !user['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) &&
                                      !user['phone'].toString().contains(_searchController.text)) {
                                    return SizedBox.shrink();
                                  }

                                  return InkWell(
                                    onTap: () => _selectUser(user['phone']),
                                    child: Container(
                                      color: isSelected ? Color(0xFFF6F6F7) : Colors.white,
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          radius: 25,
                                          backgroundColor: Colors.grey.shade700,
                                            backgroundImage: user['profile'] != null && user['profile'] != 'null'
                                                ? MemoryImage(
                                              base64Decode(user['profile'] as String),
                                            )
                                                : null,
                                          child: (user['profile'] == null || user['profile'] == 'null')
                                              ? Text(_getUserAvatarText(user),
                                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                              : null,
                                        ),
                                        title: Text(user['name'] ?? 'Unknown',
                                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(user['lastMessage'] ?? 'Tap to start chatting',
                                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis),
                                            Text(user['college'] ?? '',
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                        trailing: user['unread'] != null && user['unread'] > 0
                                            ? Container(
                                          padding: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFDC143C),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            user['unread'].toString(),
                                            style: TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        )
                                            : Text(user['time'] ?? '', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else if (state is UsersError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                                    SizedBox(height: 16),
                                    Text("Failed to load users", style: TextStyle(color: Colors.red)),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => _chatBloc.add(FetchUsers()),
                                      child: Text("Retry"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFDC143C),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            // If we have cached user list, show it even if state changes
                            if (_userList.isNotEmpty) {
                              return ListView.builder(
                                itemCount: _userList.length,
                                itemBuilder: (context, index) {
                                  final user = _userList[index];
                                  final bool isSelected = _selectedUser == user['phone'];

                                  // Filter logic (same as above)
                                  if (_searchController.text.isNotEmpty &&
                                      !user['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) &&
                                      !user['phone'].toString().contains(_searchController.text)) {
                                    return SizedBox.shrink();
                                  }

                                  return InkWell(
                                    onTap: () => _selectUser(user['phone']),
                                    child: Container(
                                      color: isSelected ? Color(0xFFF6F6F7) : Colors.white,
                                      child: ListTile(
                                        // Same ListTile content as above
                                        leading: CircleAvatar(
                                          radius: 25,
                                          backgroundColor: Colors.grey.shade700,
                                          backgroundImage: user['profile'] != null && user['profile'] != 'null'
                                              ? MemoryImage(
                                            base64Decode(user['profile'] as String),
                                          )
                                              : null,
                                          child: (user['profile'] == null || user['profile'] == 'null')
                                              ? Text(_getUserAvatarText(user),
                                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                              : null,
                                        ),
                                        title: Text(user['name'] ?? 'Unknown',
                                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(user['lastMessage'] ?? 'Tap to start chatting',
                                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis),
                                            Text(user['college'] ?? '',
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                        trailing: user['unread'] != null && user['unread'] > 0
                                            ? Container(
                                          padding: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFDC143C),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            user['unread'].toString(),
                                            style: TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        )
                                            : Text(user['time'] ?? '', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                            return Center(child: Text("No users found"));
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Right panel - Chat area
                Expanded(
                  child: Container(
                    color: Color(0xFFF6F6F7),
                    child: Column(
                      children: [
                        // Chat header
                        Container(
                          height: 60,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          color: Colors.white,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  BlocBuilder<ChatBloc, ChatState>(
                                    buildWhen: (previous, current) {
                                      // Only rebuild when users state changes or when needed
                                      return current is UsersLoaded;
                                    },
                                    builder: (context, state) {
                                      String avatarText = '?';
                                      String userName = _selectedUser.isEmpty ? 'Select a user' : _selectedUser;

                                      // Find selected user in our cached user list
                                      if (_userList.isNotEmpty && _selectedUser.isNotEmpty) {
                                        for (var user in _userList) {
                                          if (user['phone'] == _selectedUser) {
                                            avatarText = _getUserAvatarText(user);
                                            userName = user['name'] ?? _selectedUser;
                                            break;
                                          }
                                        }
                                      }

                                      return Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 25,
                                            backgroundColor: Color(0xFF673AB7),
                                            backgroundImage: _userList.isNotEmpty && _selectedUser.isNotEmpty
                                                ? MemoryImage(
                                              base64Decode(_userList.firstWhere((user) => user['phone'] == _selectedUser)['profile'] as String),
                                            )
                                                : null,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            userName,
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.search, color: Color(0xFFDC143C)),
                                    onPressed: () {},
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) => print(value),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(value: 'view_profile', child: Text('View Profile')),
                                      PopupMenuItem(value: 'report', child: Text('Report')),
                                      PopupMenuItem(value: 'block', child: Text('Block')),
                                    ],
                                    icon: Icon(Icons.more_vert, color: Color(0xFFDC143C)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Chat body (dynamic messages) - Separate BlocBuilder for chat messages
                        Expanded(
                          child: _selectedUser.isEmpty
                              ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(radius: 40, backgroundColor: Color(0xFF673AB7),
                                    child: Icon(Icons.chat, size: 40, color: Colors.white)),
                                SizedBox(height: 16),
                                Text('Select a user', style: TextStyle(fontSize: 18, color: Colors.black54)),
                              ],
                            ),
                          )
                              : BlocConsumer<ChatBloc, ChatState>(
                            listener: (context, state) {
                              if (state is ChatLoaded) {
                                setState(() {
                                  _chatMessages = state.messages;
                                });
                              }
                            },
                            buildWhen: (previous, current) {
                              // Only rebuild for chat-related states
                              return current is ChatLoading ||
                                  current is ChatLoaded ||
                                  current is ChatError;
                            },
                            builder: (context, state) {
                              if (state is ChatLoading) {
                                return Center(child: CircularProgressIndicator());
                              } else if (state is ChatLoaded) {
                                return ListView.builder(
                                  reverse: true,
                                  itemCount: state.messages.length,
                                  itemBuilder: (context, index) {
                                    final msg = state.messages[state.messages.length - index - 1];
                                    final isMe = msg.senderId == _chatBloc.currentUserId;

                                    return Align(
                                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isMe ? Color(0xFFDC143C) : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(msg.content,
                                            style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                                      ),
                                    );
                                  },
                                );
                              } else if (state is ChatError) {
                                return Center(child: Text("❌ ${state.message}"));
                              }

                              // If we have cached messages, show them
                              if (_chatMessages.isNotEmpty) {
                                return ListView.builder(
                                  reverse: true,
                                  itemCount: _chatMessages.length,
                                  itemBuilder: (context, index) {
                                    final msg = _chatMessages[_chatMessages.length - index - 1];
                                    final isMe = msg.senderId == _chatBloc.currentUserId;

                                    return Align(
                                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isMe ? Color(0xFFDC143C) : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(msg.content,
                                            style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                                      ),
                                    );
                                  },
                                );
                              }

                              return Center(child: Text("No messages yet"));
                            },
                          ),
                        ),

                        // Message input
                        Container(
                          color: Colors.white,
                          child: Column(
                            children: [
                              Container(
                                height: 60,
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.emoji_emotions_outlined, color: Color(0xFFDC143C)),
                                      onPressed: () {
                                        setState(() {
                                          _showEmojiPicker = !_showEmojiPicker;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _messageController,
                                        style: TextStyle(color: Colors.black),
                                        decoration: InputDecoration(
                                          hintText: 'Type a message',
                                          hintStyle: TextStyle(color: Colors.grey),
                                          border: InputBorder.none,
                                        ),
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.send, color: Color(0xFFDC143C)),
                                      onPressed: _sendMessage,
                                    ),
                                  ],
                                ),
                              ),
                              if (_showEmojiPicker)
                                SizedBox(
                                  height: 250,
                                  child: EmojiPicker(
                                    onEmojiSelected: (category, emoji) {
                                      setState(() {
                                        _messageController.text += emoji.emoji;
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sidebar
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: Container(
              width: 60,
              color: Color(0xFF1c1c1c),
              child: Sidebar(
                isSidebarExpanded: false,
                toggleSidebar: _toggleSidebar,
                onNavigate: _navigateToSection,
              ),
            ),
          ),
          if (isSidebarExpanded)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: Container(
                width: 250,
                color: Color(0xFF1c1c1c),
                child: Sidebar(
                  isSidebarExpanded: true,
                  toggleSidebar: _toggleSidebar,
                  onNavigate: _navigateToSection,
                ),
              ),
            ),
        ],
      ),
    );
  }
}