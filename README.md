spidrox_reg: A Flutter-based Chat Application
spidrox_reg is a mobile application built with Flutter that provides a seamless and interactive chat experience. This project serves as a comprehensive example of building a real-time messaging platform, complete with user authentication, chat functionality, and state management.

Features
Real-time Chat: Instantly send and receive messages with other users.

Sidebar Navigation: Easy-to-use sidebar for navigating between different sections of the app, such as Profile, Messages, and Connections.

User Authentication: The app provides secure user registration and login functionality.

Connections: You can manage your connections from a dedicated connections page.

User Profiles: There is a profile page to view and manage user information.

Technical Stack
Flutter: The primary framework for building the application.

go_router: Used for declarative navigation within the app.

flutter_bloc: Utilized for state management, particularly for handling chat-related states and user data.

flutter_riverpod: Used for dependency injection and managing application-wide state.

Hive: A lightweight and fast key-value database used for local data storage.

Pulsar: An integrated messaging system for real-time communication.

Emoji Picker: A package for adding emoji functionality to the chat input.

Getting Started
Prerequisites
Flutter SDK: Installation Guide

A code editor like VS Code or Android Studio.

Installation
Clone the repository:

git clone https://github.com/your-username/spidrox_reg.git
cd spidrox_reg
Install dependencies:

flutter pub get
Run the application:

flutter run
Project Structure
lib/: Main application code.

bloc/: Contains the BLoC (Business Logic Component) for state management.

model&repo/: Data models and repositories for handling data.

river_pod/: Riverpod providers for managing application state.

service/: Services for external communication (e.g., Pulsar).

final/: Contains the main UI pages and widgets.

main.dart: Entry point of the application.

Contributing
Contributions are welcome! If you find a bug or have a feature request, please open an issue.

License
This project is licensed under the MIT License.

Contact
For any questions or suggestions, please feel free to reach out.
