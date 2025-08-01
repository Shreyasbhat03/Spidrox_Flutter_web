import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:spidrox_reg/bloc/profile_bloc/profile_event.dart';
import 'package:spidrox_reg/bloc/profile_bloc/profile_state.dart';
import 'package:spidrox_reg/service/pulsar_producer.dart';
import '../../service/pulsar_consumer.dart';
import '../../river_pod/data_provider.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final String jwt;
  final Map<String, String> pulsarUrls;
  final UserDataNotifier userDataNotifier;
  final PulsarService pulsarService;
  final PulsarProducerService pulsarProducerService;

  late final StreamSubscription _pulsarSubscription;
  late final String _producerTopic;

  ProfileBloc({
    required this.jwt,
    required this.pulsarUrls,
    required this.userDataNotifier,
    required this.pulsarService,
    required this.pulsarProducerService,
  }) : super(ProfileInitial()) {
    _producerTopic = pulsarUrls["producerTopic"] ?? "";
    on<FetchUserData>(_fetchUserData);
    on<UpdateUserData>(_updateUserData);
    on<PulsarMessageReceived>(_handlePulsarMessage);
    // ✅ Connect Pulsar Consumer & listen to incoming stream
    final consumerUrl = pulsarUrls["consumerUrl"] ?? "";
    print("Connecting to consumer URL: $consumerUrl");
    pulsarService.connectConsumer(jwt, consumerUrl);

    _pulsarSubscription = pulsarService.messagesStream.listen(
          (message) {
        add(PulsarMessageReceived(message));
      },
      onError: (error) {
        print("❌ Error in consumer stream: $error");
      },
    );
  }



  void _handlePulsarMessage(PulsarMessageReceived event, Emitter<ProfileState> emit) {
    try {
      final responseData = jsonDecode(event.message);
      final base64Payload = responseData["payload"];
      final decodedJson = utf8.decode(base64.decode(base64Payload));
      final payloadData = jsonDecode(decodedJson);

      if (payloadData.containsKey("message")) {
        final userData = jsonDecode(payloadData["message"]);
        userDataNotifier.setUserData(userData);
        print("📥 User data received: $userData");
        emit(UserDataLoaded(userData));
        pulsarService.acknowledgeMessage(responseData["messageId"]);
      } else {
        print("❌ Invalid response: 'message' field missing");
      }
    } catch (e) {
      print("❌ Error decoding Pulsar message: $e");
    }
  }

  Future<void> _fetchUserData(FetchUserData event, Emitter<ProfileState> emit) async {
    emit(UserDataLoading());
    try {
      final requestJson = jsonEncode({
        "action": "GET",
        "jwt": jwt,
      });


      pulsarProducerService.connectProducer(jwt, pulsarUrls["producerUrl"]!);
      await Future.delayed(Duration(milliseconds: 300));
      pulsarProducerService.sendMessage(requestJson, _producerTopic);
     // pulsarProducerService.sendUriMessage(requestJson, properties);
      emit(UserDataLoaded(userDataNotifier.state.userData));
    } catch (e) {
      emit(ProfileError("❌ Failed to fetch user data: $e"));
    }
  }

  Future<void> _updateUserData(UpdateUserData event, Emitter<ProfileState> emit) async {
    try {
      userDataNotifier.updateUserData(event.userData);

      final requestJson = jsonEncode({
        "action": "POST",
        "userData": event.userData,
        "jwt": jwt,
      });

      pulsarProducerService.connectProducer(jwt, pulsarUrls["producerUrl"]!);
      await Future.delayed(Duration(milliseconds: 500));
      pulsarProducerService.sendMessage(requestJson, _producerTopic);
      await Future.delayed(Duration(seconds: 1));
      pulsarProducerService.Producerdisconnect();

      emit(UserDataLoaded(userDataNotifier.state.userData));
    } catch (e) {
      emit(ProfileError("❌ Failed to update user data: $e"));
    }
  }

  @override
  @override
  Future<void> close() async {
    print("🧹 Cleaning up ProfileBloc");
    await _pulsarSubscription.cancel();
    pulsarService.Consumerdisconnect();
    pulsarProducerService.Producerdisconnect();
    return super.close();
  }

}
