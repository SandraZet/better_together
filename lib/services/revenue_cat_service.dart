import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  bool _isConfigured = false;

  /// Initialize Revenue Cat
  Future<void> initialize() async {
    if (_isConfigured) return;

    try {
      // RevenueCat API keys
      final apiKey = Platform.isIOS
          ? 'appl_YOUR_IOS_API_KEY' // TODO: Replace with your iOS key when ready
          : 'goog_IXLleYBVrHOuTFGnDrAkKaYuQxC'; // Android production key

      await Purchases.configure(PurchasesConfiguration(apiKey));

      _isConfigured = true;
      print('✅ RevenueCat initialized');
    } catch (e) {
      print('❌ Error initializing RevenueCat: $e');
    }
  }

  /// Get available offerings
  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings;
    } catch (e) {
      print('❌ Error getting offerings: $e');
      return null;
    }
  }

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      // Purchase successful (works for both consumables and non-consumables)
      print('✅ Purchase successful!');
      return true;
    } on PlatformException catch (e) {
      print('❌ Purchase error - Code: ${e.code}, Message: ${e.message}');
      print('❌ Full error: $e');
      return false;
    } catch (e) {
      print('❌ Error purchasing: $e');
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    try {
      final purchaserInfo = await Purchases.restorePurchases();

      if (purchaserInfo.entitlements.active.isNotEmpty) {
        print('✅ Purchases restored!');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error restoring purchases: $e');
      return false;
    }
  }

  /// Check if user is a supporter
  Future<bool> isSupporter() async {
    try {
      final purchaserInfo = await Purchases.getCustomerInfo();
      // Check specifically for "supporter" entitlement
      return purchaserInfo.entitlements.active.containsKey('supporter') ||
          purchaserInfo.entitlements.active.containsKey('now_supporter');
    } catch (e) {
      print('❌ Error checking supporter status: $e');
      return false;
    }
  }
}
