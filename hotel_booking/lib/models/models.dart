typedef Json = Map<String, dynamic>;

class Room {
  final int id, typeId, price, capacity;
  final String number, type, description;
  final String usageStatus;
  bool get inUse => usageStatus == 'DANG_SU_DUNG';
  final List<Json> images, amenities;
  Room.fromJson(Json json)
    : id = json['ma_phong'] as int,
      typeId = json['ma_lp'] as int,
      price = (json['gia_co_ban'] as num).toInt(),
      capacity = json['suc_chua'] as int,
      number = json['so_phong'] as String,
      type = json['ten_loai'] as String,
      description = json['mo_ta'] as String? ?? '',
      usageStatus = json['trang_thai_su_dung'] as String? ?? 'CON_TRONG',
      images = (json['hinh_anh'] as List? ?? []).cast<Json>(),
      amenities = (json['tien_nghi'] as List? ?? []).cast<Json>();
  Json toJson() => {
    'ma_phong': id,
    'ma_lp': typeId,
    'gia_co_ban': price,
    'suc_chua': capacity,
    'so_phong': number,
    'ten_loai': type,
    'mo_ta': description,
    'trang_thai_su_dung': usageStatus,
    'hinh_anh': images,
    'tien_nghi': amenities,
  };
}

class Booking {
  final Json data;
  Booking.fromJson(this.data);
  String get id => data['ma_pdp'] as String;
  String get status => data['trang_thai'] as String;
  String get number => data['so_phong'] as String;
  int get total => (data['tong_tien'] as num).toInt();
  Json toJson() => Map.of(data);
}

class BookingRequest {
  final int roomId, guests;
  final String start, end, name, phone;
  final int? expectedPrice;
  final String? note;
  BookingRequest({
    required this.roomId,
    required this.guests,
    required this.start,
    required this.end,
    required this.name,
    required this.phone,
    this.expectedPrice,
    this.note,
  });
  Json toJson() => {
    'ma_phong': roomId,
    'so_khach': guests,
    'ngay_nhan': start,
    'ngay_tra': end,
    'ten_lien_he': name.trim(),
    'sdt_lien_he': phone.trim(),
    if (expectedPrice != null) 'expected_don_gia_moi_dem': expectedPrice,
    if (note != null && note!.trim().isNotEmpty) 'ghi_chu': note!.trim(),
  };
}

class PageData<T> {
  final List<T> items;
  final int total, page;
  PageData.fromJson(Json json, T Function(Json) parse)
    : items = (json['items'] as List).map((e) => parse(e as Json)).toList(),
      total = json['total'] as int,
      page = json['page'] as int;
}
