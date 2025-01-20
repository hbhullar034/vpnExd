import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart';

import '../models/ips_detail_model.dart';
import 'package:get/get.dart';


class APIs {
  

  static Future<void> getIPDetails({required Rx<IPDetails> ipData}) async {
    try {
      final res = await get(Uri.parse('http://ip-api.com/json/'));
      final data = jsonDecode(res.body);
      log(data.toString());
      ipData.value = IPDetails.fromJson(data);
    } catch (e) {
      log('\ngetIPDetailsE: $e');
    }
  }
}



