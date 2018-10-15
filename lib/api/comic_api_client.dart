import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:xkcd/data/comic.dart';

class ComicApiClient {
  static final baseUrl = 'https://www.xkcd.com/';
  static final _baseApiUrl = 'https://www.xkcd.com/info.0.json';
  static final _subApiUrl = 'https://www.xkcd.com/{0}/info.0.json';
  static final _explainXkcdUrl = 'https://www.explainxkcd.com/wiki/index.php/';

  int _latestComicNum = -1;
  int _currentComicNum = -1;

  Future<Comic> fetchLatestComic() async {
    final response = await http.get(_baseApiUrl);
    if (response.statusCode == 200) {
      var comic = Comic.fromJson(json.decode(response.body));
      if (_latestComicNum < 0) {
        _latestComicNum = comic.num;
      }
      _currentComicNum = _latestComicNum;
      return comic;
    } else {
      debugPrint('${response.statusCode}: ${response.toString()}');
    }
    return null;
  }

  Future<List<Comic>> fetchLatestComics() async {
    final response = await http.get(_baseApiUrl);
    if (response.statusCode == 200) {
      var comic = Comic.fromJson(json.decode(response.body));
      if (_latestComicNum < 0) {
        _latestComicNum = comic.num;
      }
      List<String> latestComicIds = List.generate((5), (index) {
        return (_latestComicNum - (index + 1)).toString();
      });
      final responses = await Future.wait(latestComicIds.map((comicId) {
        String url = _subApiUrl.replaceAll('{0}', comicId);
        return http.get(url);
      }));
      var list = responses.map((response) {
        return Comic.fromJson(json.decode(response.body));
      }).toList();
      list.insert(0, comic);
      _currentComicNum = _latestComicNum;
      return list;
    } else {
      debugPrint('${response.statusCode}: ${response.toString()}');
    }
    return null;
  }

  Future<Comic> fetchRandomComic() async {
    if (_latestComicNum > 0) {
      final randomNumber = Random().nextInt(_latestComicNum);
      String randomUrl = _subApiUrl.replaceAll('{0}', randomNumber.toString());

      final response = await http.get(randomUrl);
      if (response.statusCode == 200) {
        var comic = Comic.fromJson(json.decode(response.body));
        _currentComicNum = comic.num;
        return comic;
      } else {
        debugPrint('${response.statusCode}: ${response.toString()}');
      }
    }
    return fetchLatestComic();
  }

  Future<List<Comic>> fetchRandomComics() async {
    List<String> comicIds = List.generate((5), (index) {
      return Random().nextInt(_latestComicNum).toString();
    });

    final responses = await Future.wait(comicIds.map((comicId) {
      String url = _subApiUrl.replaceAll('{0}', comicId);
      return http.get(url);
    }));
    var list = responses.map((response) {
      return Comic.fromJson(json.decode(response.body));
    }).toList();
    return list;
  }

  void explainCurrentComic() async {
    final String explainUrl = _explainXkcdUrl + _currentComicNum.toString();
    if (await canLaunch(explainUrl)) {
      FlutterWebBrowser.openWebPage(
          url: explainUrl, androidToolbarColor: Colors.white);
    }
  }

  static Future<List<Comic>> fetchComics(List<String> comicIds) async {
    print(comicIds);
    final responses = await Future.wait(comicIds.map((comicId) {
      String url = _subApiUrl.replaceAll('{0}', comicId);
      return http.get(url);
    }));
    var list = responses.map((response) {
      return Comic.fromJson(json.decode(response.body));
    }).toList();
    return list;
  }
}
