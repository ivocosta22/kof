class TableSession {
  final String serverUrl;
  final String shopName;
  final String fulfillmentType; // 'table' or 'counter_pickup'
  final String tableLabel;
  final String tableToken;
  final String customerLabel; // used for counter_pickup

  const TableSession({
    required this.serverUrl,
    required this.shopName,
    this.fulfillmentType = 'table',
    this.tableLabel = '',
    this.tableToken = '',
    this.customerLabel = '',
  });

  Map<String, dynamic> toJson() => {
        'serverUrl': serverUrl,
        'shopName': shopName,
        'fulfillmentType': fulfillmentType,
        'tableLabel': tableLabel,
        'tableToken': tableToken,
        'customerLabel': customerLabel,
      };

  factory TableSession.fromJson(Map<String, dynamic> json) {
    return TableSession(
      serverUrl: json['serverUrl'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      fulfillmentType: json['fulfillmentType'] as String? ?? 'table',
      tableLabel: json['tableLabel'] as String? ?? '',
      tableToken: json['tableToken'] as String? ?? '',
      customerLabel: json['customerLabel'] as String? ?? '',
    );
  }
}
