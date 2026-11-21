import 'dart:convert';

/// The café's details printed on receipts. From the cloud, kept in the local DB.
class BusinessInfo {
  static const kvKey = 'business';

  final String businessName;
  final String? taxId, address, phone, receiptFooter;

  /// The café's loyalty program is on: receipts carry a QR to earn points.
  final bool loyaltyEnabled;
  const BusinessInfo({
    required this.businessName,
    this.taxId,
    this.address,
    this.phone,
    this.receiptFooter,
    this.loyaltyEnabled = false,
  });

  factory BusinessInfo.fromJson(Map<String, dynamic> j) => BusinessInfo(
    businessName: (j['businessName'] as String?) ?? '',
    taxId: j['taxId'] as String?,
    address: j['address'] as String?,
    phone: j['phone'] as String?,
    receiptFooter: j['receiptFooter'] as String?,
    loyaltyEnabled: j['loyaltyEnabled'] == true,
  );

  static BusinessInfo? decode(String? s) =>
      s == null ? null : BusinessInfo.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
