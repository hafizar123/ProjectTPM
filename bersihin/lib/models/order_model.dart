class OrderModel {
  final int id;
  final String userEmail;
  final String serviceName;
  final int totalAmount;
  final String paymentMethod;
  final String? vaNumber;
  final String? qrisUrl;
  final String status;
  final String? address;
  final String? houseType;
  final String? patokan;
  final String? scheduleDate;
  final String? scheduleTime;
  final String? waktuTransaksi;

  OrderModel({
    required this.id,
    required this.userEmail,
    required this.serviceName,
    required this.totalAmount,
    required this.paymentMethod,
    this.vaNumber,
    this.qrisUrl,
    required this.status,
    this.address,
    this.houseType,
    this.patokan,
    this.scheduleDate,
    this.scheduleTime,
    this.waktuTransaksi,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      userEmail: json['user_email'] ?? '',
      serviceName: json['service_name'] ?? '',
      totalAmount: json['total_amount'] ?? 0,
      paymentMethod: json['payment_method'] ?? '',
      vaNumber: json['va_number'],
      qrisUrl: json['qris_url'],
      status: json['status'] ?? 'menunggu_pembayaran',
      address: json['address'],
      houseType: json['house_type'],
      patokan: json['patokan'],
      scheduleDate: json['schedule_date'],
      scheduleTime: json['schedule_time'],
      waktuTransaksi: json['waktu_transaksi'],
    );
  }
}
