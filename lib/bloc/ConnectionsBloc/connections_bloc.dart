import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:spidrox_reg/service/pulsar_consumer.dart';
import 'package:spidrox_reg/service/pulsar_producer.dart';
import 'connections_event.dart';
import 'connections_state.dart';

class ConnectionsBloc extends Bloc<ConnectionsEvent, ConnectionsState> {
  final String jwt;
  final String userPhone;
  final Map<String, String> pulsarUrls;
  final PulsarService pulsarService;
  final PulsarProducerService pulsarProducerService;

  StreamSubscription? _pulsarSubscription;
  late final String _producerTopic;
  late final String _connectTopic;
  List<dynamic> _connectionsList = []; // Store connections locally
  String _currentConsumerUrl = "";
  String _currentTabName = "People"; // Track current tab

  ConnectionsBloc({
    required this.jwt,
    required this.userPhone,
    required this.pulsarUrls,
    required this.pulsarService,
    required this.pulsarProducerService,
  }) : super(ConnectionsInitial()) {
    _producerTopic = "graphsender2";
    _connectTopic = pulsarUrls["producerConnectTopic"] ?? "";

    on<FetchConnections>(_fetchConnections);
    on<UpdateConnectionStatus>(_updateConnectionStatus);
    on<PulsarMessageReceived>(_handlePulsarMessage);
    on<ChangeSubscriptionTopic>(_changeSubscriptionTopic);

    // Initial connection setup with default topic
    _setupConsumerConnection(pulsarUrls["consumerconnectionUrl"] ?? "");
  }

  // New method to set up consumer connection
  void _setupConsumerConnection(String consumerUrl) {
    // Cancel existing subscription if any
    _cleanupCurrentSubscription();

    if (consumerUrl.isEmpty) {
      emit(ConnectionsError("Consumer URL is empty"));
      return;
    }

    _currentConsumerUrl = consumerUrl;
    print("🔄 Connecting to consumer URL: $consumerUrl");

    try {
      pulsarService.connectConsumer(jwt, consumerUrl);

      _pulsarSubscription = pulsarService.messagesStream.listen(
              (message) {
            add(PulsarMessageReceived(message));
          },
          onError: (error) {
            print("❌ Error in consumer stream: $error");
            emit(ConnectionsError("Consumer stream error: $error"));
          }
      );
    } catch (e) {
      print("❌ Failed to connect consumer: $e");
      emit(ConnectionsError("Failed to connect consumer: $e"));
    }
  }

  // New method to handle topic changes
  Future<void> _changeSubscriptionTopic(
      ChangeSubscriptionTopic event,
      Emitter<ConnectionsState> emit
      ) async {
    emit(ConnectionsLoading());

    print("🔄 Switching to topic for tab: ${event.tabName}");
    _currentTabName = event.tabName;

    // Determine which consumer URL to use based on tab
    String? consumerUrl;

    switch (event.tabName) {
      case "People":
        consumerUrl = pulsarUrls["consumerconnectionUrl"];
        break;
      case "My Connections":
        consumerUrl = pulsarUrls["consumerMyConnectionsUrl"] ?? pulsarUrls["consumerconnectionUrl"];
        break;
      case "Connections Sent":
        consumerUrl = pulsarUrls["consumerRequestUrl"];
        print("🔄 Using consumerRequestUrl: ${pulsarUrls["consumerRequestUrl"]}");
        break;
      case "Connections Received":
        consumerUrl = pulsarUrls["consumerRequestUrl"];
        print("🔄 Using consumerRequestUrl for Connections Received : ${pulsarUrls["consumerRequestUrl"]}");

        break;
      default:
        consumerUrl = pulsarUrls["consumerConnectUrl"];
    }

    if (consumerUrl == null || consumerUrl.isEmpty) {
      emit(ConnectionsError("No consumer URL available for ${event.tabName}"));
      return;
    }

    // Only reconnect if URL has changed
    if (_currentConsumerUrl != consumerUrl) {
      _setupConsumerConnection(consumerUrl);
    }

    // Fetch new data with appropriate query
    _fetchDataForTab(event.tabName, emit);
  }

  // Helper method to fetch appropriate data based on tab
  Future<void> _fetchDataForTab(String tabName, Emitter<ConnectionsState> emit) async {

    try {
      if (jwt.isEmpty) throw Exception("JWT missing. Cannot fetch connections.");

      String query;
      String producerUrl ;
      String producerTopic;
      String requestType;

      // Construct appropriate query based on tab
      switch (tabName) {
        case "People":
          query = "SELECT string_agg('name: ' || name || ', college: ' || collegename || ', phone: ' || phone || ', profile: ' || profile || ',', '\n') FROM cypher('my_graph', \$\$ MATCH (n:registeredUser) RETURN n.name AS name, n.collegename AS collegename, n.phone AS phone, n.profile AS profile \$\$) AS (name text, collegename text, phone text, profile text);";
          producerUrl = pulsarUrls["producerconnectionUrl"] ?? "";
          producerTopic =_producerTopic;
          requestType= "People";
          break;
        case "My Connections":
          query = "SELECT string_agg('name: ' || name || ', college: ' || collegename || ', phone: ' || phone || ', profile: ' || profile, E'\n') FROM cypher('my_graph', \$\$ MATCH (me {phone: '$userPhone'})-[:FRIEND]->(friend) RETURN friend.name AS name, friend.collegename AS collegename, friend.phone AS phone, friend.profile AS profile \$\$) AS (name text, collegename text, phone text, profile text);";
          producerUrl = pulsarUrls["producerconnectionUrl"] ?? "";
          producerTopic = _producerTopic;
          requestType= "My Connections";
          break;
        case "Connections Sent":
          query = "select to_phone from connection_requests where from_phone='${userPhone}';";
          producerUrl = pulsarUrls["producerRequestUrl"] ?? "";
          producerTopic = pulsarUrls["producerRequestTopic"] ?? "";
          requestType= "Connections Sent";
          break;
        case "Connections Received":
          query = "select from_phone from connection_requests where to_phone='${userPhone}';";
          producerUrl= pulsarUrls["producerRequestUrl"] ?? "";
          producerTopic = pulsarUrls["producerRequestTopic"] ?? "";
          requestType= "Connections Received";
          break;
        default:
          query = "SELECT string_agg('name: ' || name || ', college: ' || collegename || ', phone: ' || phone || ', profile: ' || profile || ',', '\n') FROM cypher('my_graph', \$\$ MATCH (n:registeredUser) RETURN n.name AS name, n.collegename AS collegename, n.phone AS phone, n.profile AS profile \$\$) AS (name text, collegename text, phone text, profile text);";
          producerUrl = pulsarUrls["producerRequestUrl"] ?? "";
          producerTopic = _producerTopic;
          requestType= "";

      }

      final requestJson = jsonEncode({
        "query": query,
        "properties": {
          "topic": producerTopic,
          "queryType": requestType,
        }
      });
      print("Query: $query");
      print("url in the pulsar topic:${pulsarUrls["producerRequestUrl"]}");
      print("connectiong topulsar producer: $producerUrl");

      pulsarProducerService.connectProducer(jwt, producerUrl);
      await Future.delayed(const Duration(milliseconds: 250));
      pulsarProducerService.sendConnectionMessage(requestJson, producerTopic,requestType);
      await Future.delayed(const Duration(milliseconds: 1300));
      pulsarProducerService.Producerdisconnect();

    } catch (e) {
      print("❌ Error fetching data for tab $tabName: $e");
      emit(ConnectionsError("Failed to fetch data for $tabName: $e"));
    }
  }

  // Clean up the existing subscription
  void _cleanupCurrentSubscription() {
    if (_pulsarSubscription != null) {
      _pulsarSubscription!.cancel();
      _pulsarSubscription = null;
      pulsarService.Consumerdisconnect();
      print("🧹 Cleaned up previous subscription");
    }
  }

  // Other methods remain largely the same...
  // void _handlePulsarMessage(PulsarMessageReceived event, Emitter<ConnectionsState> emit) {
  //   try {
  //     final responseData = jsonDecode(event.message);
  //
  //     if (!responseData.containsKey("payload")) {
  //       throw Exception("Missing 'payload' field");
  //     }
  //
  //     final base64Payload = responseData["payload"];
  //     final decodedPayloadString = utf8.decode(base64.decode(base64Payload));
  //     print("📦 Decoded Payload JSON: $decodedPayloadString");
  //
  //     final decodedPayload = jsonDecode(decodedPayloadString);
  //
  //     if (!decodedPayload.containsKey("data") || decodedPayload["data"] is! List) {
  //       throw Exception("Invalid or missing 'data' field");
  //     }
  //
  //     final List<dynamic> dataList = decodedPayload["data"];
  //     final List<Map<String, String>> connections = [];
  //
  //     for (final item in dataList) {
  //       final result = item["result"];
  //       if (result is String) {
  //         final userChunks = result.split(RegExp(r'\bname:')).where((e) => e.trim().isNotEmpty);
  //
  //         for (final chunk in userChunks) {
  //           final parts = ('name:' + chunk).split(',').map((e) => e.trim()).toList();
  //           final Map<String, String> parsed = {};
  //
  //           for (var part in parts) {
  //             final kv = part.split(':');
  //             if (kv.length == 2) {
  //               final key = kv[0].trim().toLowerCase();
  //               final value = kv[1].trim();
  //               parsed[key] = value;
  //             }
  //           }
  //
  //           // ✅ Only require essential fields
  //           if (parsed.containsKey("name") &&
  //               parsed.containsKey("college") &&
  //               parsed.containsKey("phone")) {
  //             // For specific tabs, ensure status is included
  //             if (_currentTabName != "People" && !parsed.containsKey("status")) {
  //               parsed["status"] = _currentTabName == "My Connections" ? "ACCEPTED" :
  //               _currentTabName == "Connections Sent" ? "SENT" : "RECEIVED";
  //             }
  //             connections.add(parsed);
  //           }
  //         }
  //       }
  //     }
  //
  //     _connectionsList = connections;
  //     print("✅ Parsed Multiple Users for $_currentTabName: ${connections.length} records");
  //     emit(ConnectionsLoaded(List.from(_connectionsList)));
  //
  //     if (responseData.containsKey("messageId")) {
  //       pulsarService.acknowledgeMessage(responseData["messageId"]);
  //     } else {
  //       print("⚠️ No messageId found for acknowledgment");
  //     }
  //   } catch (e, stackTrace) {
  //     print("❌ Error processing Pulsar message: $e\n$stackTrace");
  //     emit(ConnectionsError("Error processing message: $e"));
  //   }
  // }
  Future<void>  _handlePulsarMessage(PulsarMessageReceived event, Emitter<ConnectionsState> emit)async {
    try {
      final responseData = jsonDecode(event.message);

      if (!responseData.containsKey("payload")) {
        throw Exception("Missing 'payload' field");
      }

      final base64Payload = responseData["payload"];
      final decodedPayloadString = utf8.decode(base64.decode(base64Payload));
      print("📦 Decoded Payload JSON: $decodedPayloadString");

      final decodedPayload = jsonDecode(decodedPayloadString);
      print("📦 Decoded Payload: $decodedPayload");
      final data = decodedPayload["data"];

      if (data is List && data.isNotEmpty && data.first is Map) {
        final Map<String, dynamic> firstItem = data.first;

        if (firstItem.containsKey("name")) {
          _handleUserDetailsResponse(decodedPayload, emit);
        } else if (firstItem.containsKey("to_phone")||firstItem.containsKey("from_phone")) {
          await _handleConnectionRequestsPayload(decodedPayload, emit);
        } else {
          _handleRegularConnectionsResponse(decodedPayload, emit);
        }
      } else {
        print("⚠️ Unexpected data structure, falling back to regular response handler.");
        _handleRegularConnectionsResponse(decodedPayload, emit);
      }


      if (responseData.containsKey("messageId")) {
        pulsarService.acknowledgeMessage(responseData["messageId"]);
      } else {
        print("⚠️ No messageId found for acknowledgment");
      }
    } catch (e, stackTrace) {
      print("❌ Error processing Pulsar message: $e\n$stackTrace");
      emit(ConnectionsError("Error processing message: $e"));
    }
  }

  Future<void> _handleConnectionRequestsPayload(
      Map<String, dynamic> payload, Emitter<ConnectionsState> emit) // ✅ correct
  async {
    try {
      final List<dynamic> data = payload["data"] ?? [];
      final List<String> phoneNumbers = [];

      for (final item in data) {
        if (item is Map && item.containsKey("to_phone")) {
          phoneNumbers.add(item["to_phone"].toString());
        }
      }
      for (final item in data) {
        if (item is Map && item.containsKey("from_phone")) {
          phoneNumbers.add(item["from_phone"].toString());
        }
      }

      if (phoneNumbers.isEmpty) {
        print("⚠️ No phone numbers found in connection requests");
        _connectionsList = [];
        // if (!emit.isDone) {
        //   emit(ConnectionsLoaded([]));
        // }
        return;
      }

      print("📱 Found ${phoneNumbers.length} phone numbers: $phoneNumbers");

      final String phoneList = phoneNumbers.map((p) => "'$p'").join(',');
      final String userDetailsQuery =
          "select name, profile, collegename, phone from registereduser where phone IN ($phoneList);";

      final requestJson = jsonEncode({
        "query": userDetailsQuery,
        "properties": {
          "topic": pulsarUrls["producerRequestTopic"] ?? "",
          "queryType": "ConnectionSent",
        }
      });

      final producerUrl = pulsarUrls["producerRequestUrl"]?? "";
      pulsarProducerService.connectProducer(jwt, producerUrl);
      await Future.delayed(const Duration(milliseconds: 250));
      final topic = pulsarUrls["producerRequestTopic"] ?? "";
      pulsarProducerService.sendMessage(requestJson, topic);
      print("📤 Sent user details query to Pulsar: $requestJson, url: $producerUrl");
      print("📤 Using topic: $topic");
    } catch (e, stackTrace) {
      print("❌ Error in connection requests handler: $e\n$stackTrace");
    }
  }


  void _handleUserDetailsResponse(Map<String, dynamic> payload, Emitter<ConnectionsState> emit) {
    try {
      final sqlResult = payload["data"] ?? [];
      final List<Map<String, String>> connections = [];

      for (final row in sqlResult) {
        final Map<String, String> userInfo = {
          "name": row["name"]?.toString() ?? "",
          "profile": row["profile"]?.toString() ?? "",
          "college": row["collegename"]?.toString() ?? "",
          "phone": row["phone"]?.toString() ?? "",
          "status": "SENT"
        };
        connections.add(userInfo);
      }

      _connectionsList = connections;
      print("✅ Parsed User Details: ${connections.length} records");
      emit(ConnectionsLoaded(List.from(_connectionsList)));
    } catch (e) {
      print("❌ Error handling user details response: $e");
      emit(ConnectionsError("Failed to process user details: $e"));
    }
  }


  void _handleRegularConnectionsResponse(Map<String, dynamic> decodedPayload, Emitter<ConnectionsState> emit) {
    if (!decodedPayload.containsKey("data") || decodedPayload["data"] is! List) {
      throw Exception("Invalid or missing 'data' field");
    }

    final List<dynamic> dataList = decodedPayload["data"];
    final List<Map<String, String>> connections = [];

    for (final item in dataList) {
      final result = item["result"];
      if (result is String) {
        final userChunks = result.split(RegExp(r'\bname:')).where((e) => e.trim().isNotEmpty);

        for (final chunk in userChunks) {
          final parts = ('name:' + chunk).split(',').map((e) => e.trim()).toList();
          final Map<String, String> parsed = {};

          for (var part in parts) {
            final kv = part.split(':');
            if (kv.length == 2) {
              final key = kv[0].trim().toLowerCase();
              final value = kv[1].trim();
              parsed[key] = value;
            }
          }

          if (parsed.containsKey("name") &&
              parsed.containsKey("college") &&
              parsed.containsKey("phone")) {
            if (!parsed.containsKey("status")) {
              parsed["status"] = _currentTabName == "My Connections"
                  ? "ACCEPTED"
                  : _currentTabName == "Connections Sent"
                  ? "SENT"
                  : "RECEIVED";
            }
            connections.add(parsed);
          }
        }
      }
    }

    _connectionsList = connections;
    print("✅ Parsed Multiple Users for $_currentTabName: ${connections.length} records");
    emit(ConnectionsLoaded(List.from(_connectionsList)));
  }


  Future<void> _fetchConnections(FetchConnections event,
      Emitter<ConnectionsState> emit) async {
    emit(ConnectionsLoading());

    // Use the new method to handle the request
    _fetchDataForTab(_currentTabName, emit);

    // If we have cached connections, show them while waiting for fresh data
    if (_connectionsList.isNotEmpty) {
      emit(ConnectionsLoaded(List.from(_connectionsList)));
    }
  }

  Future<void> _updateConnectionStatus(UpdateConnectionStatus event,
      Emitter<ConnectionsState> emit) async {
    try {
      if (jwt.isEmpty) throw Exception(
          "JWT missing. Cannot update connection.");

      final requestJson = jsonEncode({
        "fromPhone": event.fromConnectionId,
        "toPhone": event.toConnectionId,
        "status": event.status,
      });

      if (_connectTopic.isEmpty) throw Exception(
          "Producer topic is empty. Cannot send update.");

      final pulsarUrl = pulsarUrls["producerConnectUrl"] ?? "";
      pulsarProducerService.connectProducer(jwt, pulsarUrl);
      await Future.delayed(const Duration(milliseconds: 500));
      print("📤 Sending connection update: $requestJson, to: $pulsarUrl");

      pulsarProducerService.sendMessage(requestJson, _connectTopic);
      await Future.delayed(const Duration(seconds: 1));

      pulsarProducerService.Producerdisconnect();

      // ✅ Update local list
      _connectionsList = _connectionsList.map((connection) {
        if (connection['phone'] == event.toConnectionId) {
          return {...connection, "status": event.status}; // Update status
        }
        return connection;
      }).toList();

      emit(ConnectionsLoaded(List.from(_connectionsList)));

      // Refresh the data after status update
      _fetchDataForTab(_currentTabName, emit);
    } catch (e) {
      emit(ConnectionsError("Failed to update connection: $e"));
    }
  }

  @override
  Future<void> close() async {
    print("🧹 Cleaning up ConnectionsBloc");
    _cleanupCurrentSubscription();
    pulsarProducerService.Producerdisconnect();

    return super.close();
  }
}