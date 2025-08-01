import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../gloable_urls/gloable_urls.dart';
import 'data_provider.dart';

// FutureProvider for fetching Pulsar URLs
final pulsarUrlProvider = FutureProvider<Map<String, String>>((ref) async {
  final loginUrl = ref.read(loginProvider).Loginurl;
  print("loginUrl: $loginUrl");
  if (loginUrl.isEmpty) {
    throw Exception("No URL found in Riverpod state.");
  }

  final response = await http.get(Uri.parse('${AppConfig().getRestApiUrl("quarkus_get")}$loginUrl'));

  if (response.statusCode == 200) {
    final jsonMap = jsonDecode(response.body);
    print("✅ URL: ${response.body}");
    final String consumerProfileUrl = jsonMap["consumerprofileUrl"] ?? "";
    final String producerProfileUrl = jsonMap["producerprofileUrl"] ?? "";
    final String producerConnectionUrl = jsonMap["producerconnectionUrl"] ?? "";
    final String consumerConnectionUrl = jsonMap["consumerconnectionUrl"] ?? "";
    final String consumerConnectUrl=jsonMap["consumerconnectUrl"] ?? "";
    final String producerConnectUrl=jsonMap["producerconnectUrl"] ?? "";
    final String producerLogoutUrl=jsonMap["producerlogoutUrl"] ?? "";
    final String consumerLogoutUrl=jsonMap["consumerlogoutUrl"] ?? "";
   final String producerConnectTopic= RegExp(r"default/(.*)").firstMatch(producerConnectUrl)?.group(1) ?? "";
    final String producerProfileTopic =
        RegExp(r"default/(.*)").firstMatch(producerProfileUrl)?.group(1) ?? "";
    final String producerConnectionTopic =
        RegExp(r"default/(.*)").firstMatch(producerConnectionUrl)?.group(1) ?? "";
    final String producerRequestUrl = jsonMap["producerrequestUrl"] ?? "";
    print("producerRequestUrl: $producerRequestUrl");
    final String consumerRequestUrl = jsonMap["consumerrequestUrl"] ?? "";
    print("consumerRequestUrl: $consumerRequestUrl");
    final String producerRequestTopic =
        RegExp(r"default/(.*)").firstMatch(producerRequestUrl)?.group(1) ?? "";
    final String producerLogoutUrlTopic =
        RegExp(r"default/(.*)").firstMatch(producerLogoutUrl)?.group(1) ?? "";

    ref.read(loginProvider.notifier).updatePulsarURLs(
      profileConsumerUrl: consumerProfileUrl,
      profileProducerUrl: producerProfileUrl,
      connectionConsumerUrl: consumerConnectionUrl,
      connectionProducerUrl: producerConnectionUrl,
      consumerConnectUrl: consumerConnectUrl,
      producerConnectUrl: producerConnectUrl,
      producerConnectTopic: producerConnectTopic ,
      producerRequestUrl: producerRequestUrl,
      consumerRequestUrl: consumerRequestUrl,
      producerRequestTopic: producerRequestTopic,
      consumerLogoutUrl: consumerLogoutUrl,
      producerLogoutUrl: producerLogoutUrl,
      producerLogoutTopic: producerLogoutUrlTopic,

    );
    return {
      "consumerUrl": consumerProfileUrl,
      "producerUrl": producerProfileUrl,
      "producerTopic": producerProfileTopic,
      "producerConnectionUrl": producerConnectionUrl,
      "consumerConnectionUrl": consumerConnectionUrl,
      "producerConnectionTopic": producerConnectionTopic,

    };
  } else {
    throw Exception("Failed to fetch Pulsar URL: ${response.statusCode}");
  }
});
