import 'package:flutter/material.dart';
import 'sidebar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red, fontFamily: 'Arial'),
      home: const ProfilePage(),
    );
  }
}

// ---------------------- PROFILE PAGE ----------------------

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  // ---------------------- PROFILE HEADER WIDGET ----------------------
  Widget _buildProfileHeader() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E4E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF0F0F0),
                border: Border.all(color: const Color(0xFFE1E4E8), width: 2),
              ),
            ),
            const SizedBox(width: 20),

            // User Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 10),
                Text(
                  'Test User',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Test Bio',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),

            Expanded(child: Container()),

            // Edit Button
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF8F9FA),
                border: Border.all(color: const Color(0xFFE1E4E8)),
              ),
              child: const Center(
                child: Text(
                  '✎',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- NAVIGATION TABS WIDGET ----------------------
  Widget _buildNavigationTabs() {
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal, // ✅ Added horizontal scroll for overflow prevention
        child: Row(
          children: [
            _buildTab('About', isSelected: true),
            const SizedBox(width: 10),
            _buildTab('Education'),
            const SizedBox(width: 10),
            _buildTab('Skills'),
            const SizedBox(width: 10),
            _buildTab('Interests'),
          ],
        )
    );
  }

  Widget _buildTab(String title, {bool isSelected = false}) {
    return Container(
      width: 150,
      height: 60,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE74C3C) : const Color(0xFFF8F9FA), // Highlight logic
        borderRadius: BorderRadius.circular(22.5),
        border: Border.all(
          color: isSelected ? const Color(0xFFE74C3C) : const Color(0xFFE1E4E8), // Dynamic border color
        ),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: const Color(0xFFE74C3C).withOpacity(0.3), // Soft shadow for active tab
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ]
            : [],
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: isSelected ? Colors.white : const Color(0xFF333333),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, // Highlighted text styling
          ),
        ),
      ),
    );
  }

  // ---------------------- INFO CARD WIDGET ----------------------
  Widget _buildInfoCard(String title, String content) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E4E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),

            Expanded(child: Container()),

            // Edit Button
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF8F9FA),
                border: Border.all(color: const Color(0xFFE1E4E8)),
              ),
              child: const Center(
                child: Text(
                  '✎',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ---------------------- SKILLS & INTERESTS SECTION ----------------------
  Widget _buildSkillsInterestsSection() {
    return Row(
      children: [
        // Skills Section
        Expanded(
          flex: 315,
          child: _buildTagCard(
            title: 'Skills',
            tags: ['Flutter', 'Dart'],
            tagBackgroundColor: const Color(0xFFF0F7FF),
            tagBorderColor: const Color(0xFFC0D8F0),
            tagTextColor: const Color(0xFF0366D6),
          ),
        ),
        const SizedBox(width: 15),

        // Interests Section
        Expanded(
          flex: 320,
          child: _buildTagCard(
            title: 'Interests',
            tags: ['Coding', 'Music'],
            tagBackgroundColor: const Color(0xFFFEF0F7),
            tagBorderColor: const Color(0xFFF0C0D8),
            tagTextColor: const Color(0xFFD63384),
          ),
        ),
      ],
    );
  }

// ---------------------- REUSABLE TAG CARD WIDGET ----------------------
  Widget _buildTagCard({
    required String title,
    required List<String> tags,
    required Color tagBackgroundColor,
    required Color tagBorderColor,
    required Color tagTextColor,
  }) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E4E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Title and Edit Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF8F9FA),
                    border: Border.all(color: const Color(0xFFE1E4E8)),
                  ),
                  child: const Center(
                    child: Text(
                      '✎',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Tags Section
            Row(
              children: tags.map((tag) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: tagBackgroundColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: tagBorderColor),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(fontSize: 14, color: tagTextColor),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }


  // ---------------------- MAIN BUILD METHOD ----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 247, 246, 246),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(60),
            child: Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding:const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white60,  // ✅ Color moved inside BoxDecoration
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 20),
                    _buildNavigationTabs(),
                    const SizedBox(height: 20),
                    _buildInfoCard('About', 'This is a test about section'),
                    const SizedBox(height: 15),
                    _buildInfoCard('Education', 'Test Education'),
                    const SizedBox(height: 15),
                    _buildSkillsInterestsSection(),
                  ],
                ),
              ),
            ),
            ),
        );
  }
}
