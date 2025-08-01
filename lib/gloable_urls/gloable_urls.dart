class AppConfig {
  static final AppConfig _instance = AppConfig._internal();

  // **Maps to store multiple Pulsar & REST URLs**
  final Map<String, String> _pulsarUrls = {};
  final Map<String, String> _restApiUrls = {};

  // Private Constructor
  AppConfig._internal();

  // Factory Constructor (returns the same instance every time)
  factory AppConfig() {
    return _instance;
  }

  // **✅ Setter Methods to add/update URLs**
  void setPulsarUrl(String key, String url) {
    _pulsarUrls[key] = url;
  }

  void setRestApiUrl(String key, String url) {
    _restApiUrls[key] = url;
  }

  // **✅ Getter Methods to retrieve URLs**
  String? getPulsarUrl(String key) => _pulsarUrls[key];
  String? getRestApiUrl(String key) => _restApiUrls[key];

  // **✅ Method to get all stored URLs (Optional)**
  Map<String, String> get allPulsarUrls => _pulsarUrls;
  Map<String, String> get allRestApiUrls => _restApiUrls;
}

void initializeAppConfig() {
  var config = AppConfig();

  config.setRestApiUrl("login_qr", "http://192.168.1.90:8081/generate-token");//http://192.168.0.106:8081/generate-token
  config.setRestApiUrl("register_post", "http://192.168.1.90:8081/register");
  config.setRestApiUrl("quarkus_get", "http://192.168.1.90:8081");//http://192.168.0.106:8081
  config.setRestApiUrl("get_colleges", "http://192.168.1.90:8081/collegename");

  config.setPulsarUrl("login_topic","ws://192.168.1.91:8080/ws/v2/consumer/persistent/public/default/loginflutter9/subscriptionType=KeyShared");//ws://192.168.210.251:8080/ws/v2/consumer/persistent/public/default/loginflutter4/subscriptionType=KeyShared
  config.setPulsarUrl("register_topic","ws://192.168.1.91:8080/ws/v2/consumer/persistent/public/default/flutter16/subscriptionType=KeyShared");
  config.setPulsarUrl("producerBaseUrl","ws://192.168.1.91:8080/ws/v2/producer/persistent/public/chats");//"ws://192.168.0.106:8080/ws/v2/consumer/persistent/public/default/flutter9/subscriptionType=KeyShared"
  config.setPulsarUrl("consumerBaseUrl","ws://192.168.1.91:8080/ws/v2/consumer/persistent/public/chats");ws://192.168.0.106:8080/ws/v2/producer/persistent/public/default/flutter


  print("✅ AppConfig Initialized with URLs");
}