// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../service/pulsar_consumer.dart';
// import 'data_provider.dart';
// /// **Riverpod StreamProvider for Pulsar Messages**
// final pulsarStreamProvider = StreamProvider.autoDispose<String>((ref) {
//   final pulsarService = PulsarService();
//   final jwt = ref.watch(loginProvider).Loginjwt;
//   final consumerUrl = ref.watch(loginProvider).ProfileConsumerUrl;
//
//   if (jwt.isNotEmpty && consumerUrl.isNotEmpty) {
//     pulsarService.connectConsumer(jwt, consumerUrl);
//   }
//
//   ref.onDispose(() {
//     pulsarService.Consumerdisconnect();
//     print("🧹closing the pulsar profile connection");
//   });
//
//   return pulsarService.messagesStream;
// });
//
