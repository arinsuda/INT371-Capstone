class HistoryService {
  final int id;
  final String serviceName;
  final String status;
  final int price;
  final int quantity;
  final String image;

  HistoryService({
    required this.id,
    required this.serviceName,
    required this.status,
    required this.price,
    required this.quantity,
    required this.image,
  });
}

List<HistoryService> mockHistoryServices = [
  HistoryService(
    id: 1,
    serviceName: "ทาสีรั้วบ้าน",
    status: "เสร็จสิ้น",
    price: 1500,
    quantity: 1,
  ),
  HistoryService(
    id: 2,
    serviceName: "ซ่อมไฟฟ้า",
    status: "รอดำเนินการ",
    price: 800,
    quantity: 1,
  ),
  HistoryService(
    id: 3,
    serviceName: "ล้างแอร์",
    status: "ยกเลิก",
    price: 1200,
    quantity: 2,
  ),
  HistoryService(
    id: 4,
    serviceName: "ติดตั้งกล้องวงจรปิด",
    status: "เสร็จสิ้น",
    price: 3000,
    quantity: 1,
  ),
  HistoryService(
    id: 5,
    serviceName: "ทำความสะอาดบ้าน",
    status: "รอดำเนินการ",
    price: 2000,
    quantity: 1,
  ),
];
