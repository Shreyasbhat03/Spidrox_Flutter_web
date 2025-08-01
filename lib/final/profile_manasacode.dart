import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:image_picker_web/image_picker_web.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spidrox_reg/bloc/profile_bloc/profile_bloc.dart';
import 'package:spidrox_reg/bloc/profile_bloc/profile_event.dart';
import 'package:spidrox_reg/bloc/profile_bloc/profile_state.dart';
import 'package:spidrox_reg/river_pod/future_provider.dart';
import 'package:spidrox_reg/service/pulsar_consumer.dart';
import 'package:spidrox_reg/service/pulsar_producer.dart';
import 'package:spidrox_reg/sidebar.dart';
import 'package:image/image.dart' as img;
import '../../river_pod/data_provider.dart';

void main() {
  runApp(ProviderScope(child: ProfilePage()));
}

class ProfilePage extends ConsumerStatefulWidget {
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool hasListenedToStream = false;

  @override
  Widget build(BuildContext context) {
    final jwt = ref.watch(loginProvider).Loginjwt;
    final userDataNotifier = ref.read(userDataProvider.notifier);
    final pulsarService = PulsarService();
    final pulsarProducer = PulsarProducerService();

    return FutureBuilder<Map<String, String>>(
      future: ref.watch(pulsarUrlProvider.future),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final urls = snapshot.data!;

        return BlocProvider(
          create: (context) => ProfileBloc(
            jwt: jwt,
            pulsarUrls: urls,
            userDataNotifier: userDataNotifier,
            pulsarService: pulsarService,
            pulsarProducerService: pulsarProducer,
          )..add(FetchUserData()),
          child: ProfilePageContent(),
        );
      },
    );
  }
}

class ProfilePageContent extends StatefulWidget {
  @override
  _ProfilePageContentState createState() => _ProfilePageContentState();
}

class _ProfilePageContentState extends State<ProfilePageContent> {

  // State variables that were previously controlled by providers
  bool isSidebarExpanded = false;
  String currentSection = 'profile';

  // Keys for scrolling to different sections.
  final GlobalKey aboutKey = GlobalKey();
  final GlobalKey educationKey = GlobalKey();
  final GlobalKey skillsKey = GlobalKey();
  final GlobalKey hobbiesKey = GlobalKey();
  final GlobalKey interestsKey = GlobalKey();

  // Scroll controller.
  final ScrollController scrollController = ScrollController();

  // Helper method to scroll to a specific section.
  void _scrollToSection(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        print("Error: Section not found in widget tree!");
      }
    });
  }

  // Toggle sidebar method
  void toggleSidebar() {
    setState(() {
      isSidebarExpanded = !isSidebarExpanded;
    });
  }

  // Navigation method
  void onNavigate(String section) {
    setState(() {
      currentSection = section;
    });
  }
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  // Pick image method.
  Uint8List compressImage(Uint8List imageBytes, {int width = 100, int quality = 100}) {
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    // Resize Image to a smaller width
    img.Image resizedImage = img.copyResize(image, width: width);

    // Encode as JPEG with very low quality
    return Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
  }

  Future<void> _pickImage(BuildContext context) async {
    String? base64String;
    final ImagePicker picker = ImagePicker();
    Uint8List? pickedImage;

    if (kIsWeb) {
      pickedImage = await ImagePickerWeb.getImageAsBytes();
    } else {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        pickedImage = await File(pickedFile.path).readAsBytes();
      }
    }

    if (pickedImage != null) {
      // 🔥 Apply extreme compression & resizing
      Uint8List compressedImage = compressImage(pickedImage, width: 100, quality: 100);

      // 🔥 Convert to Base64
      base64String = base64Encode(compressedImage);
      if(base64String.length > 64000) {
        print("❌ Image size too large: ${base64String.length}, the file should be below 45 kb");
        return;
      }
      // 🔄 Store image in userDataProvider
      final profileBloc = BlocProvider.of<ProfileBloc>(context);
      profileBloc.add(UpdateUserData({"profile": base64String}));
      print(" the lenght of the image blob:${base64String.length}");

      print("✅ Profile picture updated with compressed base64.");
    }
  }

  // Build a small info box for quick navigation.
  Widget buildInfoBox(String title, GlobalKey key, double width, double height, bool isTablet, bool isMobile) {
    return GestureDetector(
      onTap: () => _scrollToSection(key),
      child: Container(
        width: width * 0.18,
        height: height * 0.1,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Color(0xFFDC143C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 12 : isTablet ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // Modified method to show tag editing dialog
  void _showTagEditDialog(BuildContext context, String title, List<String> currentTags) {
    final profileBloc = BlocProvider.of<ProfileBloc>(context);
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Edit $title"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Text field to add new tags
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Enter new tag",
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          if (controller.text.isNotEmpty) {
                            setState(() {
                              if (!currentTags.contains(controller.text.trim())) {
                                currentTags.add(controller.text.trim());
                                controller.clear();
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Display existing tags with option to remove
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: currentTags.map((tag) => Chip(
                      label: Text(tag),
                      deleteIcon: Icon(Icons.close),
                      onDeleted: () {
                        setState(() {
                          currentTags.remove(tag);
                        });
                      },
                    )).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final updatedData = {title.toLowerCase(): [currentTags]};
                    profileBloc.add(UpdateUserData(updatedData));
                    print("✅ Updated $title Tags: $currentTags");
                    Navigator.pop(context);
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Modified buildEditableBox to handle tags
  Widget buildEditableTagBox(String title, dynamic content, GlobalKey key, double width, double height, bool isMobile, bool isTablet, BuildContext context) {
    // Convert content to List<String> if it's not already
    List<String> tags = content is List ? List<String>.from(content) : [];
    return Center(
      child: Container(
        key: key,
        width: isTablet ? width * 1.9 : width * 0.8,
        height: isTablet ? height * 0.25 : height * 0.2,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              spreadRadius: 1,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: isTablet ? 16 : (isMobile ? 14 : 18),
                        fontWeight: FontWeight.bold
                    )
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: isTablet ? 24 : 20, color: Color(0xFFDC143C)),
                  onPressed: () => _showTagEditDialog(context, title, tags),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Display tags in a wrap layout
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: tags.map((tag) => Chip(
                label: Text(tag,
                    style: TextStyle(
                        fontSize: isTablet ? 12 : (isMobile ? 10 : 14)
                    )
                ),
                backgroundColor: Color(0xFFDC143C).withOpacity(0.1),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Build an editable information box.
  Widget buildEditableBox(String title, String content, GlobalKey key, double width, double height, bool isMobile, bool isTablet, BuildContext context) {
    return Center(
      child: Container(
        key: key,
        width: isTablet ? width * 1.9 : width * 0.8,
        height: isTablet ? height * 0.25 : height * 0.12,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              spreadRadius: 1,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$title: ",
                    style: TextStyle(
                        fontSize: isTablet ? 14 : (isMobile ? 12 : 16),
                        fontWeight: FontWeight.bold)),
                Text(content,
                    style: TextStyle(
                        fontSize: isTablet ? 14 : (isMobile ? 12 : 16))),
              ],
            ),
            IconButton(
              icon: Icon(Icons.edit, size: isTablet ? 24 : 20, color: Color(0xFFDC143C)),
              onPressed: () => _showEditDialog(context, title, content),
            ),
          ],
        ),
      ),
    );
  }

  // Show a dialog for editing a text field.
  void _showEditDialog(BuildContext context, String title, String currentText) {
    final profileBloc = BlocProvider.of<ProfileBloc>(context);
    TextEditingController controller = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit $title"),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Enter new $title",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedData = {title.toLowerCase(): controller.text};
                profileBloc.add(UpdateUserData(updatedData));
                print("✅ Updated $title: ${controller.text}");
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Show an edit profile dialog for name and bio.
  void _showEditProfileDialog(Map<String, dynamic> userData) {
    final profileBloc = BlocProvider.of<ProfileBloc>(context);
    TextEditingController nameController = TextEditingController(text: userData['name']);
    TextEditingController bioController = TextEditingController(text: userData['bio']);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          width: MediaQuery.of(context).size.width * 0.5,
          child: AlertDialog(
            title: Text("Edit Profile"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Name"),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: "Bio"),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  profileBloc.add(UpdateUserData({
                    "name": nameController.text,
                    "bio": bioController.text,
                  }));
                  Navigator.pop(context);
                },
                child: Text("Save"),
              ),
            ],
          ),
        );
      },
    );
  }

  // Placeholder UI using Shimmer.
  Widget _buildPlaceholderUI(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 30),
        Container(
          width: width * 0.95,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(0, 5))
            ],
          ),
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[300]),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(width: 150, height: 20),
                    const SizedBox(height: 4),
                    _buildShimmerBox(width: 250, height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildShimmerBox({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    bool isMobile = width < 600;
    bool isTablet = width >= 600 && width <= 1200;

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFFF6F6F7),
              child: SingleChildScrollView(
                controller: scrollController,
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, state) {
                    if (state is UserDataLoading) {
                      return _buildPlaceholderUI(width);
                    } else if (state is ProfileError) {
                      return Center(child: Text("❌ Error: ${state.message}"));
                    } else if (state is UserDataLoaded) {
                      final userData = state.userData;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          // Profile Section.
                          Container(
                            width: width * 0.9,
                            height: height * 0.25,
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2, offset: Offset(0, 5)),
                              ],
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _pickImage(context),
                                  child: CircleAvatar(
                                      radius: 70,
                                      backgroundColor: Colors.grey[300],
                                      backgroundImage:  (userData["profile"] != null)
                                          ? MemoryImage(base64Decode(userData["profile"]))
                                          : null
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(userData['name'] ?? "John Doe",
                                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(userData['bio'] ?? "Flutter Developer | Tech Enthusiast",
                                          style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 32, color: Color(0xFFDC143C)),
                                  onPressed: () => _showEditProfileDialog(userData),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Quick Navigation Info Boxes.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              buildInfoBox("About", aboutKey, width, height, isTablet, isMobile),
                              buildInfoBox("Education", educationKey, width, height, isTablet, isMobile),
                              buildInfoBox("Skills", skillsKey, width, height, isTablet, isMobile),
                              buildInfoBox("Interests", interestsKey, width, height, isTablet, isMobile),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Editable Content Sections
                          Column(
                            children: [
                              buildEditableBox("About", userData['about'] ?? "Short Bio Here", aboutKey, width, height, isMobile, isTablet, context),
                              buildEditableBox("Education", userData['education'] ?? "Short Bio Here", educationKey, width, height, isMobile, isTablet, context),

                              // New row for Hobbies and Interests with tag support
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  buildEditableTagBox(
                                      "Hobbies",
                                      userData['hobbies'] ?? [], // Default to empty list if not exists
                                      hobbiesKey,
                                      width / 2.05,
                                      height,
                                      isMobile,
                                      isTablet,
                                      context
                                  ),
                                  buildEditableTagBox(
                                      "Interests",
                                      userData['interests'] ?? [], // Default to empty list if not exists
                                      interestsKey,
                                      width / 2.05,
                                      height,
                                      isMobile,
                                      isTablet,
                                      context
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
          ),
          // Sidebar overlaps the main content.
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: Sidebar(
              isSidebarExpanded: isSidebarExpanded,
              toggleSidebar: toggleSidebar,
              onNavigate: onNavigate,
            ),
          ),
        ],
      ),
    );
  }
}