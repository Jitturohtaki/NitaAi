import 'driver.dart';
import 'order.dart';
import 'vendor.dart';

class TrackingViewData {
  const TrackingViewData({
    required this.order,
    required this.vendor,
    required this.driver,
  });

  final Order order;
  final Vendor? vendor;
  final Driver? driver;
}
