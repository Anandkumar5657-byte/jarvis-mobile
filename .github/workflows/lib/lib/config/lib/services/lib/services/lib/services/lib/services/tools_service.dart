import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:battery_plus/battery_plus.dart';

class ToolsService {
  static final Map<String, String> _appPackages = {
    'youtube': 'com.google.android.youtube',
    'instagram': 'com.instagram.android',
    'facebook': 'com.facebook.katana',
    'whatsapp': 'com.whatsapp',
    'chrome': 'com.android.chrome',
    'gmail': 'com.google.android.gm',
    'spotify': 'com.spotify.music',
    'camera': 'com.android.camera',
    'gallery': 'com.google.android.apps.photos',
    'settings': 'com.android.settings',
    'calculator': 'com.google.android.calculator',
    'clock': 'com.google.android.deskclock',
    'maps': 'com.google.android.apps.maps',
    'phone': 'com.google.android.dialer',
    'twitter': 'com.twitter.android',
    'telegram': 'org.telegram.messenger',
    'paytm': 'net.one97.paytm',
    'phonepe': 'com.phonepe.app',
    'gpay': 'com.google.android.apps.nbu.paisa.user',
  };

  static final Map<String, String> _websites = {
    'youtube': 'https://m.youtube.com',
    'instagram': 'https://instagram.com',
    'facebook': 'https://facebook.com',
    'google': 'https://google.com',
    'gmail': 'https://mail.google.com',
    'whatsapp': 'https://web.whatsapp.com',
    'chatgpt': 'https://chat.openai.com',
    'twitter': 'https://twitter.com',
  };

  static Future<String> execute(String name, Map<String, dynamic> args) async {
    try {
      switch (name) {
        case 'open_app':
          return await openApp(args['app']?.toString().toLowerCase() ?? '');
        case 'open_website':
          return await openWebsite(args['url']?.toString() ?? '');
        case 'web_search':
          return await webSearch(args['query']?.toString() ?? '');
        case 'play_youtube':
          return await playYoutube(args['query']?.toString() ?? '');
        case 'make_call':
          return await makeCall(args['number']?.toString() ?? args['contact']?.toString() ?? '');
        case 'send_sms':
          return await sendSms(args['number']?.toString() ?? '', args['message']?.toString() ?? '');
        case 'send_whatsapp':
          return await sendWhatsapp(args['number']?.toString() ?? '', args['message']?.toString() ?? '');
        case 'tell_time':
          return tellTime();
        case 'tell_date':
          return tellDate();
        case 'battery_status':
          return await batteryStatus();
        case 'set_alarm':
          return await setAlarm(
            (args['hour'] ?? 7) is int ? args['hour'] : int.parse(args['hour'].toString()),
            (args['minute'] ?? 0) is int ? args['minute'] : int.parse(args['minute'].toString()),
            args['label']?.toString() ?? 'Jarvis Alarm',
          );
        case 'set_timer':
          return await setTimer((args['minutes'] ?? 5) is int ? args['minutes'] : int.parse(args['minutes'].toString()));
        default:
          return "Unknown tool: $name";
      }
    } catch (e) {
      return "Tool error: $e";
    }
  }

  static Future<String> openApp(String app) async {
    final pkg = _appPackages[app];
    if (pkg != null) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: pkg,
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
        return "$app khol diya";
      } catch (e) {
        if (_websites.containsKey(app)) return await openWebsite(_websites[app]!);
        return "App install nahi hai: $app";
      }
    }
    if (_websites.containsKey(app)) return await openWebsite(_websites[app]!);
    return "App nahi mila: $app";
  }

  static Future<String> openWebsite(String url) async {
    if (!url.startsWith('http')) url = 'https://$url';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    return "Khol diya";
  }

  static Future<String> webSearch(String query) async {
    await launchUrl(Uri.parse("https://www.google.com/search?q=${Uri.encodeComponent(query)}"), mode: LaunchMode.externalApplication);
    return "Search: $query";
  }

  static Future<String> playYoutube(String query) async {
    await launchUrl(Uri.parse("https://m.youtube.com/results?search_query=${Uri.encodeComponent(query)}"), mode: LaunchMode.externalApplication);
    return "YouTube play: $query";
  }

  static Future<String> makeCall(String number) async {
    if (number.isEmpty) return "Number missing";
    final ok = await FlutterPhoneDirectCaller.callNumber(number);
    return ok == true ? "Calling $number" : "Call fail";
  }

  static Future<String> sendSms(String number, String message) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.SENDTO',
      data: 'smsto:$number',
      arguments: {'sms_body': message},
    );
    await intent.launch();
    return "SMS draft khol diya";
  }

  static Future<String> sendWhatsapp(String number, String message) async {
    await launchUrl(Uri.parse("https://wa.me/$number?text=${Uri.encodeComponent(message)}"), mode: LaunchMode.externalApplication);
    return "WhatsApp khol diya";
  }

  static String tellTime() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? "PM" : "AM";
    return "Abhi time hai $h:$m $ampm";
  }

  static String tellDate() {
    final now = DateTime.now();
    final months = ['','January','February','March','April','May','June','July','August','September','October','November','December'];
    final days = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
    return "Aaj hai ${days[now.weekday % 7]}, ${now.day} ${months[now.month]} ${now.year}";
  }

  static Future<String> batteryStatus() async {
    final level = await Battery().batteryLevel;
    return "Battery hai $level percent";
  }

  static Future<String> setAlarm(int hour, int minute, String label) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      arguments: {
        'android.intent.extra.alarm.HOUR': hour,
        'android.intent.extra.alarm.MINUTES': minute,
        'android.intent.extra.alarm.MESSAGE': label,
        'android.intent.extra.alarm.SKIP_UI': true,
      },
    );
    await intent.launch();
    return "Alarm set: $hour:${minute.toString().padLeft(2, '0')}";
  }

  static Future<String> setTimer(int minutes) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.SET_TIMER',
      arguments: {
        'android.intent.extra.alarm.LENGTH': minutes * 60,
        'android.intent.extra.alarm.MESSAGE': 'Jarvis Timer',
        'android.intent.extra.alarm.SKIP_UI': true,
      },
    );
    await intent.launch();
    return "$minutes min timer set";
  }
}
