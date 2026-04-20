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
}
