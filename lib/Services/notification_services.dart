import 'dart:io';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../Screens/message_screen.dart';

class NotificationServices{
  FirebaseMessaging messaging = FirebaseMessaging.instance;
 final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();


  void requestNotificationPermission() async{
    NotificationSettings notificationSettings = await messaging.requestPermission(
      alert: true,
      badge: true,
      announcement: true,
      provisional: true,
      carPlay: true,
      criticalAlert: true,
      sound: true,
    );

    if(notificationSettings.authorizationStatus == AuthorizationStatus.authorized){
      print("User granted permissions");
    }
    else if(notificationSettings.authorizationStatus == AuthorizationStatus.provisional){
      print("User granted permissions");
    }
    else {
      AppSettings.openNotificationSettings();
      print("User denied permissions");
    }
  }

  Future<String> getDeviceToken() async{
    String? token = await messaging.getToken();
    return token!;
  }

  void isTokenRefresh() {
    messaging.onTokenRefresh.listen((event) {
      event.toString();
      print("Token refreshed");
    });
  }

  void firebaseInit(BuildContext context){
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        print(message.notification!.title.toString());
        print(message.notification!.body.toString());
        print(message.data.toString());
      }
     if(Platform.isAndroid){
       initLocalNotifications(context, message);
       showNotification(message);
     }
     else {
       showNotification(message);
     }
    });
  }

  void initLocalNotifications(BuildContext context, RemoteMessage message) async{
    var androidInitializationSettings =  const AndroidInitializationSettings("@mipmap/ic_launcher");
    var iosInitializationSettings =  const DarwinInitializationSettings();

    var initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,

    );

    await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
    onDidReceiveNotificationResponse: (payload){
          handleMessage(context, message);
    }
    );
  }

  Future<void> showNotification(RemoteMessage message) async{

    AndroidNotificationChannel channel = AndroidNotificationChannel(
        Random.secure().nextInt(100000).toString(),
      "High Importance Notifications",
      importance: Importance.max
    );

    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        channel.id.toString(),
      channel.name.toString(),
      channelDescription: "Channel Description",
      importance: Importance.high,
      priority: Priority.high,
      ticker: "ticker",
    );

    DarwinNotificationDetails darwinNotificationDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    Future.delayed(Duration.zero, (){
      _flutterLocalNotificationsPlugin.show(
        1,
        message.notification!.title.toString(),
        message.notification!.body.toString(),
        notificationDetails,
      );
    });
  }


  Future<void> setUpInteractMessage(BuildContext context) async{
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if(initialMessage != null){
      handleMessage(context, initialMessage);
    }

    // when app in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleMessage(context, message);
    });
  }



  void handleMessage(BuildContext context, RemoteMessage message){
    if(message.data['type'] == "msg"){
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => MessageScreen(id: message.data['id'],)));
    }
  }


}