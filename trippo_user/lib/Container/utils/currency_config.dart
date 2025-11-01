/// Currency configuration for the BTrips application
/// 
/// This utility provides a centralized way to manage currency settings
/// across the application. Default currency is set to USD.
class CurrencyConfig {
  // Currency code (ISO 4217)
  static const String currencyCode = 'USD';
  
  // Currency symbol
  static const String currencySymbol = '\$';
  
  // Currency name
  static const String currencyName = 'US Dollar';
  
  /// Formats an amount with the currency symbol
  /// 
  /// Example: formatAmount(25.50) returns "$25.50"
  static String formatAmount(double amount) {
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }
  
  /// Formats an amount with currency code
  /// 
  /// Example: formatAmountWithCode(25.50) returns "USD 25.50"
  static String formatAmountWithCode(double amount) {
    return '$currencyCode ${amount.toStringAsFixed(2)}';
  }
  
  /// Formats an amount with custom precision
  /// 
  /// Example: formatAmountPrecision(25.567, 1) returns "$25.6"
  static String formatAmountPrecision(double amount, int precision) {
    return '$currencySymbol${amount.toStringAsFixed(precision)}';
  }
  
  /// Gets the currency symbol for display
  static String get symbol => currencySymbol;
  
  /// Gets the currency code for display
  static String get code => currencyCode;
  
  /// Gets the currency name
  static String get name => currencyName;
}
