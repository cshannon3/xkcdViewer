import 'package:flutter/material.dart';
import 'package:xkcd/data/comic.dart';

import 'package:xkcd/widgets/comic_view.dart';

class ComicPage extends StatelessWidget {
  final List<Comic> comics;

  ComicPage({this.comics});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: ComicsView(comics: comics),
      ),
    );
  }
}

