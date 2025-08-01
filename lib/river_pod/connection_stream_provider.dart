// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:spidrox_reg/service/pulsar_consumer.dart';
//
// import 'data_provider.dart';
//
// /// **Riverpod StreamProvider for Connection Messages**
// final connectionStreamProvider = StreamProvider<String>((ref) {
//   final pulsarService = PulsarService();
//   print("connect_consumer started");
//   final jwt = ref.watch(loginProvider).Loginjwt;
//   final consumerUrl = ref.watch(loginProvider).ConnectionConsumerUrl;
//
//   if (jwt.isNotEmpty && consumerUrl.isNotEmpty) {
//     print("connecting over stream");
//   pulsarService.connectConsumer(jwt, consumerUrl);
//   } else {
//     print("JWT or Consumer URL is empty. Cannot connect.");
//   }
//
//   ref.onDispose(() {
//     pulsarService.Consumerdisconnect();
//   });
//
//   return pulsarService.messagesStream;
// });
