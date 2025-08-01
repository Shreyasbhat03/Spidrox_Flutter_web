import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:spidrox_reg/go_router/spidrox_routes.dart';
import '../gloable_urls/gloable_urls.dart';
import '../model&repo/message_model.dart';
import '../model&repo/repo/hive_repo.dart';

Future<void> main() async {
  initializeAppConfig();
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<Message>('message');
  Hive.registerAdapter(MessageAdapter());
  await MessageRepository().initialize();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  runApp(ProviderScope(child:  mainPage()))  ;
}

class mainPage extends StatelessWidget {
  const mainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Parabolic Edge Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig:myRuotes().router,
    );
  }
}
