import 'package:intl/intl.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  // The installed development app normally uses Wi-Fi. USB/emulator launch
  // profiles override this explicitly; an IDE run without defines stays on LAN.
  defaultValue: 'http://192.168.31.112:8000',
);
const demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: false);
String dateOnly(DateTime value) => DateFormat('yyyy-MM-dd').format(value);
String money(num value) => NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
).format(value);
String localDate(String value) =>
    DateFormat('dd/MM/yyyy').format(DateTime.parse(value));
String vietnamTime(String value) =>
    DateFormat('dd/MM/yyyy HH:mm')
        .format(DateTime.parse(value).toUtc().add(const Duration(hours: 7)));
const statuses = {
  'CHO_XAC_NHAN': 'Chờ xác nhận',
  'DA_XAC_NHAN': 'Đã xác nhận',
  'DA_HUY': 'Đã hủy',
  'DA_TU_CHOI': 'Đã từ chối',
};
