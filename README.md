# 🗨️ spidrox_reg — A Flutter-Based Chat Application

**spidrox_reg** is a modern, real-time chat application built with Flutter. Designed with clean architecture and scalable state management, it provides a robust foundation for building interactive messaging platforms.

---

## 🚀 Features

- 💬 **Real-Time Chat** — Instant message delivery using Apache Pulsar.
- 👥 **User Authentication** — Secure registration & login flow.
- 🔄 **Sidebar Navigation** — Effortlessly switch between chat, profile, and connections.
- 🧑 **User Profiles** — View and manage user details in a dedicated profile page.
- 🔗 **Connections Management** — Add or remove connections and explore contacts.
- 😀 **Emoji Support** — Integrated emoji picker for richer conversations.
- 💾 **Offline Storage** — Fast, persistent local storage using Hive.

---

## 🛠️ Tech Stack

| Technology       | Purpose                                     |
|------------------|---------------------------------------------|
| **Flutter**      | UI development framework                    |
| **go_router**    | Declarative routing                         |
| **flutter_bloc** | UI logic & event-driven state management    |
| **flutter_riverpod** | App-wide state & dependency injection  |
| **Hive**         | Lightweight local key-value storage         |
| **Apache Pulsar**| Real-time messaging backend                 |

---

## 📁 Project Structure

```

lib/
├── bloc/           → BLoC logic for state management
├── model\&repo/     → Data models & repository implementations
├── river\_pod/      → Riverpod providers for app-wide state
├── service/        → External services (e.g., Pulsar WebSocket)
├── final/          → Core UI pages & widgets
└── main.dart       → Application entry point

````

---

## ⚙️ Getting Started

### ✅ Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Code editor: VS Code, Android Studio, etc.

### 🧑‍💻 Installation

1. **Clone the repository:**

```bash
git clone https://github.com/your-username/spidrox_reg.git
cd spidrox_reg
````

2. **Install dependencies:**

```bash
flutter pub get
```

3. **Run the app:**

```bash
flutter run
```

---

## 🤝 Contributing

Contributions are welcome! If you spot bugs, ideas, or improvements:

* Open an [Issue](https://github.com/your-username/spidrox_reg/issues)
* Submit a [Pull Request](https://github.com/your-username/spidrox_reg/pulls)

Please follow best practices and provide clear commit messages. ❤️

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 📬 Contact

For any queries, suggestions, or feedback, feel free to reach out:

* ✉️ Email: `your-email@example.com`
* 📌 GitHub: [@your-username](https://github.com/your-username)

---

> Built with 💙 using Flutter
