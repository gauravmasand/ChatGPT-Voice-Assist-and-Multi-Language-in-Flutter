import 'package:shared_preferences/shared_preferences.dart';

class UserSimplePreferences {
  static String _keyLanguage = "LANGUAGE";
  static String _keyLanguageCode = "LANGUAGE_CODE";
  static String _keyURLDalle = "URL_DALEE";
  static String _keyCommandDalle = "COMMAND_DALLE";
  static String _keyTimeDalle = "TIME_DALLE";
  static String _keyOpenAiApi = "OPENAI_API_KEY";
  static String _keyMaxToken = "MAX_TOKEN";
  static String _keyChatGPTVersion = "CHATGPT_VERSION";
  static String _keyDalle2Res = "DALLE_2_RESOLUTION";


  static late SharedPreferences _preferences;

  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

  /// Set Language
  static Future setLang(String value) async =>
      await _preferences.setString(_keyLanguage, value);
  static String? getLang() => _preferences.getString(_keyLanguage);

  /// Set Language code
  static Future setLangCode(String value) async =>
      await _preferences.setString(_keyLanguageCode, value);
  static String? getLangCode() => _preferences.getString(_keyLanguageCode);

  /// Set dalle URL
  static Future setUrlDalle(List<String> value) async =>
      await _preferences.setStringList(_keyURLDalle, value);
  static List<String>? getUrlDalle() => _preferences.getStringList(_keyURLDalle);

  /// Set dalle Command
  static Future setCommandDalle(List<String> value) async =>
      await _preferences.setStringList(_keyCommandDalle, value);
  static List<String>? getCommandDalle() => _preferences.getStringList(_keyCommandDalle);

  /// Set dalle time
  static Future setTimeDalle(List<String> value) async =>
      await _preferences.setStringList(_keyTimeDalle, value);
  static List<String>? getTimeDalle() => _preferences.getStringList(_keyTimeDalle);

  /// Set OpenAI Api key
  static Future setOpenAiApi(String value) async =>
      await _preferences.setString(_keyOpenAiApi, value);
  static String? getOpenAiApi() => _preferences.getString(_keyOpenAiApi);

  /// Set Token limit
  static Future setMaxToken(int value) async =>
      await _preferences.setInt(_keyMaxToken, value);
  static int? getMaxToken() => _preferences.getInt(_keyMaxToken);

  /// Set Chatgpt version
  static Future setChatGPTVersion(String value) async =>
      await _preferences.setString(_keyChatGPTVersion, value);
  static String? getChatGPTVersion() => _preferences.getString(_keyChatGPTVersion);

  /// Set Dalle 2 version
  static Future setDalle2Res(String value) async =>
      await _preferences.setString(_keyDalle2Res, value);
  static String? getDalle2Res() => _preferences.getString(_keyDalle2Res);

  static addDalleImage(String commandNw, String urlNw, String timeNw) {
    List<String> url = UserSimplePreferences.getUrlDalle()!;
    List<String> command = UserSimplePreferences.getCommandDalle()!;
    List<String> time = UserSimplePreferences.getTimeDalle()!;

    url.add(urlNw);
    command.add(commandNw);
    time.add(timeNw);

    UserSimplePreferences.setUrlDalle(url);
    UserSimplePreferences.setCommandDalle(command);
    UserSimplePreferences.setTimeDalle(time);

  }

  static DalleImageModel getAllDalleImages() {
    return DalleImageModel(UserSimplePreferences.getUrlDalle()!, UserSimplePreferences.getCommandDalle()!, UserSimplePreferences.getTimeDalle()!);
  }

  static Future deleteByKey(String value) async {
    await _preferences.remove(value);
  }

  static Future deleteAllData() async {
    await _preferences.clear();
  }

}

class DalleImageModel {

  late List<String> url, command, time;

  DalleImageModel(this.url, this.command, this.time);

}