import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  static Future<bool> hasStoragePermission() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  static Future<bool> hasPhotosPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  static String getPermissionErrorMessage(PermissionStatus status) {
    if (status.isDenied) {
      return '权限被拒绝，请在设置中手动开启权限';
    } else if (status.isPermanentlyDenied) {
      return '权限被永久拒绝，请在设置中手动开启权限';
    } else if (status.isRestricted) {
      return '权限受到限制，无法使用该功能';
    } else if (status.isLimited) {
      return '权限受限，部分功能可能无法正常使用';
    }
    return '未知权限错误';
  }
}
