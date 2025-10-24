// lib/services/interaction_service.dart

import 'package:url_launcher/url_launcher.dart';

class InteractionService {
  
  // 1. Mở bất kỳ URL web nào
  Future<bool> launchWebUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  // 2. Mở Bản đồ để dẫn đường đến một tọa độ
  Future<bool> launchMapDirection(double latitude, double longitude) async {
    // Sử dụng schema tiêu chuẩn của Google Maps, hỗ trợ tốt trên cả Android và iOS
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude');
    
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  // 3. Mở ứng dụng gọi điện thoại
  Future<bool> launchPhone(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  // 4. Mở ứng dụng Email
  Future<bool> launchEmail({
    required String email, 
    String subject = '', 
    String body = ''
  }) async {
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }
}