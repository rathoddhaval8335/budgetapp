class ApiService {
  // Define your base URL
  static const String baseUrl = "http://192.168.43.192/BUDGET_APP";


  static String getUrl(String endpoint) {
    return "$baseUrl/$endpoint";
  }
}
