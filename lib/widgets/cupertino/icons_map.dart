import 'package:flutter/cupertino.dart';

class CupIconHelper {
  /// Returns a CupertinoIcon OR an Image widget if the source is a URL/Path
  static Widget getIcon(String? name, {double size = 24, Color? color}) {
    if (name == null) return SizedBox();

    // 1. Custom Image Support (Network/Asset)
    if (name.startsWith('http') || name.startsWith('assets/')) {
      return Image.network(
        name,
        width: size,
        height: size,
        color: color, // Applies tint if provided
      );
    }

    // 2. Standard Cupertino Icons Mapping
    final IconData iconData = _iconMap[name] ?? CupertinoIcons.question;
    return Icon(iconData, size: size, color: color);
  }

  static final Map<String, IconData> _iconMap = {
    'home': CupertinoIcons.home,
    'settings': CupertinoIcons.settings,
    'person': CupertinoIcons.person,
    'person_solid': CupertinoIcons.person_solid,
    'info': CupertinoIcons.info,
    'search': CupertinoIcons.search,
    'shopping_cart': CupertinoIcons.shopping_cart,
    'add': CupertinoIcons.add,
    'add_circled': CupertinoIcons.add_circled,
    'delete': CupertinoIcons.delete,
    'trash': CupertinoIcons.trash,
    'edit': CupertinoIcons.pencil,
    'share': CupertinoIcons.share,
    'wifi': CupertinoIcons.wifi,
    'bluetooth': CupertinoIcons.bluetooth,
    'camera': CupertinoIcons.camera,
    'photo': CupertinoIcons.photo,
    'video_camera': CupertinoIcons.video_camera,
    'mic': CupertinoIcons.mic,
    'phone': CupertinoIcons.phone,
    'mail': CupertinoIcons.mail,
    'map': CupertinoIcons.map,
    'location': CupertinoIcons.location,
    'star': CupertinoIcons.star,
    'star_fill': CupertinoIcons.star_fill,
    'heart': CupertinoIcons.heart,
    'heart_fill': CupertinoIcons.heart_fill,
    'chat_bubble': CupertinoIcons.chat_bubble,
    'conversation_bubble': CupertinoIcons.conversation_bubble,
    'bell': CupertinoIcons.bell,
    'clock': CupertinoIcons.clock,
    'calendar': CupertinoIcons.calendar,
    'check_mark': CupertinoIcons.check_mark,
    'check_mark_circled': CupertinoIcons.check_mark_circled,
    'xmark': CupertinoIcons.xmark,
    'xmark_circle': CupertinoIcons.xmark_circle,
    'arrow_left': CupertinoIcons.arrow_left,
    'arrow_right': CupertinoIcons.arrow_right,
    'chevron_left': CupertinoIcons.chevron_left,
    'chevron_right': CupertinoIcons.chevron_right,
    'back': CupertinoIcons.back,
    'forward': CupertinoIcons.forward,
    'refresh': CupertinoIcons.refresh,
    'download': CupertinoIcons.arrow_down_to_line,
    'upload': CupertinoIcons.arrow_up_to_line,
    'folder': CupertinoIcons.folder,
    'doc': CupertinoIcons.doc,
    'gear': CupertinoIcons.gear,
    'game_controller': CupertinoIcons.game_controller,
    'music_note': CupertinoIcons.music_note,
    'play': CupertinoIcons.play_arrow,
    'pause': CupertinoIcons.pause,
    'stop': CupertinoIcons.stop,
    'battery_full': CupertinoIcons.battery_100,
    'battery_empty': CupertinoIcons.battery_0,
  };
}
