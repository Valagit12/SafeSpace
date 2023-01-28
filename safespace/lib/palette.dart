//palette.dart
import 'package:flutter/material.dart'; 
class Palette { 
  static const MaterialColor turqouise =  MaterialColor( 
    0xff40E0D0, // 0% comes in here, this will be color picked if no shade is selected when defining a Color property which doesn’t require a swatch. 
    <int, Color>{ 
      50:  Color(0xffecfcfa),//10% 
      100:  Color(0xffd9f9f6),//20% 
      200:  Color(0xffc6f6f1),//30% 
      300:  Color(0xffb3f3ec),//40% 
      400:  Color(0xffa0f0e8),//50% 
      500:  Color(0xff8cece3),//60% 
      600:  Color(0xff79e9de),//70% 
      700:  Color(0xff66e6d9),//80% 
      800:  Color(0xff53e3d5),//90% 
      900:  Color(0xff40e0d0),//100% 
    }, 
  ); 
} // you can define define int 500 as the default shade and add your lighter tints above and darker tints below. 
