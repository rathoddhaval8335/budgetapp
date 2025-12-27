class ApiService {
  // Define your base URL
  //static const String baseUrl = "http://192.168.29.192/BUDGET_APP";
  static const String baseUrl = "https://prakrutitech.xyz/dhaval";


  static String getUrl(String endpoint) {
    return "$baseUrl/$endpoint";
  }
}
