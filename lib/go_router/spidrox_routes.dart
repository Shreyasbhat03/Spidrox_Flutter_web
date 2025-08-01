import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../final/1login_page.dart';
import '../final/2reg_page1.dart';
import '../final/3placeholder_registrartion.dart';
import '../final/4Register_qr.dart';
import '../final/chat_ui.dart';
import '../final/connections_page.dart';
import '../final/profile_manasacode.dart';

class myRuotes {
  final GoRouter router = GoRouter(
    initialLocation: "/login",
    routes: [
      GoRoute(
        name: "LoginPage",
        path: "/login",
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        name: "registerPage",
        path: '/register',
        builder: (context, state) => ParabolicEdgePage(),
      ),
      GoRoute(
        name: "placeholderPage",
        path: "/placeholder",
        builder: (context, state) => PlaceholderRegistrartion(),
      ),
      GoRoute(
        name: "registrationQR",
        path: "/registrationQR",
        builder: (context, state) => ParabolicBackgroundApp(),
      ),
      GoRoute(
        name: "profilePage",
        path: "/profile",
        builder: (context, state) => ProfilePage(),
      ),
      GoRoute(
        name: "ConnectionsPage",
        path: "/connections",
        builder: (context, state) => Connections(),
      ),
      GoRoute(
        name: "chatPage",
        path: "/chat/:chatId",
        builder: (context, state) {
          final chatId = state.pathParameters['chatId'] ?? ''; // Get chatId from the URL
          return chatApp(selectedUser: chatId); // Pass to your widget
        },
      ),
    ],
    // Set this to false to ensure URL updates are visible
    routerNeglect: false,
    // Add redirect functionality if needed
    redirect: (BuildContext context, GoRouterState state) {
      // Add logic for redirects if needed
      return null;
    },
    // Add observers to debug navigation
    observers: [
      NavigationObserver(),
    ],
  );
}

// Custom observer to debug navigation events
class NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Navigation: Pushed ${route.settings.name}');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Navigation: Popped ${route.settings.name}');
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    print('Navigation: Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}