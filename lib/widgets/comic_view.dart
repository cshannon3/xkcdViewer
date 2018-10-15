import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibrate/vibrate.dart';
import 'package:xkcd/api/comic_api_client.dart';
import 'package:xkcd/data/comic.dart';
import 'package:xkcd/providers/preferences.dart';

import 'dart:ui' as ui;

class ComicsView extends StatefulWidget {
  final List<Comic> comics;
  final Function(double scrollPercent) onScroll;

  ComicsView({
    this.comics,
    this.onScroll,
  });

  @override
  _ComicsViewState createState() => new _ComicsViewState();
}

class _ComicsViewState extends State<ComicsView> with TickerProviderStateMixin {
  double scrollPercent = 0.0;
  Offset startDrag;
  double startDragPercentScroll;
  double finishScrollStart;
  double finishScrollEnd;
  AnimationController finishScrollController;

  @override
  void initState() {
    super.initState();

    finishScrollController = new AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    ) // AnimationController
      ..addListener(() {
        setState(() {
          scrollPercent = ui.lerpDouble(
              finishScrollStart, finishScrollEnd, finishScrollController.value);

          if (widget.onScroll != null) {
            widget.onScroll(scrollPercent);
          }
        });
      });
  }

  @override
  void dispose() {
    finishScrollController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    startDrag = details.globalPosition;
    startDragPercentScroll = scrollPercent;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final currDrag = details.globalPosition;
    final dragDistance = currDrag.dx - startDrag.dx;
    final singleCardDragPercent = dragDistance / (context.size.width);

    setState(() {
      scrollPercent = (startDragPercentScroll +
              (-singleCardDragPercent / widget.comics.length))
          .clamp(0.0, 1.0 - (1 / widget.comics.length));
      if (widget.onScroll != null) {
        widget.onScroll(scrollPercent);
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    finishScrollStart = scrollPercent;
    finishScrollEnd =
        (scrollPercent * (widget.comics.length)).round() / widget.comics.length;
    finishScrollController.forward(from: 0.0);

    setState(() {
      startDrag = null;
      startDragPercentScroll = null;

      if (widget.onScroll != null) {
        widget.onScroll(scrollPercent);
      }
    });
  }

  List<Widget> _buildCards() {
    final cardCount = widget.comics.length;
    int index = -1;
    return widget.comics.map((Comic viewModel) {
      ++index;
      return _buildCard(viewModel, index, cardCount, scrollPercent);
    }).toList();
  }

  Widget _buildCard(
      Comic viewModel, int cardIndex, int cardCount, double scrollPercent) {
    final cardScrollPercent = scrollPercent / (1 / cardCount);
    final parallax = scrollPercent - (cardIndex / cardCount);

    return new FractionalTranslation(
        translation: Offset(cardIndex - cardScrollPercent, 0.0),
        child: new Padding(
          padding: const EdgeInsets.all(16.0),

          child: ComicCard(comic: viewModel, parallaxPercent: parallax),
          //    ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onLongPress: () {
        _vibrate();
        print("hey");
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return AlertDialog(
              contentPadding: EdgeInsets.all(0.0),
              content: Container(
                color: Theme.of(context).primaryColor,
                padding: EdgeInsets.all(20.0),
                child: Text(_currentComic().alt,
                    style: TextStyle(color: Colors.white)),
              ),
            );
          },
        );
      },
      behavior: HitTestBehavior.translucent,
      child: new Stack(
        children: _buildCards(),
      ),
    );
  }

  Comic _currentComic() {
    return widget.comics[(scrollPercent * widget.comics.length).floor()];
  }

  _shareComic() {
    String url = '${ComicApiClient.baseUrl}${_currentComic().num}/';
    Share.share(url);
  }

  void _vibrate() async {
    if (await Vibrate.canVibrate) {
      Vibrate.feedback(FeedbackType.light);
    }
  }
}

class ComicCard extends StatelessWidget {
  final Comic comic;
  final double parallaxPercent;
  final SharedPreferences _prefs = Preferences.prefs;

  final no2xVersion = [1193, 1446, 1667, 1735, 1739, 1744, 1778];

  ComicCard({
    this.comic,
    this.parallaxPercent,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    return new Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 50.0),
      child: new Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Hero(
            tag: 'hero-${comic.num}',
            child: PhotoViewInline(
              maxScale: PhotoViewComputedScale.covered * 1.5,
              minScale: PhotoViewComputedScale.contained * 0.5,
              backgroundColor: Colors.white,
              gaplessPlayback: true,
              imageProvider: NetworkImage(_getImageUrl()),
              loadingChild: Center(child: CircularProgressIndicator()),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 80.0,
              color: Colors.white,
              padding: EdgeInsets.only(
                right: 10.0,
                bottom: 10.0,
                left: 10.0,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      '${comic.num}: ${comic.title}',
                      style: themeData.textTheme.title,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${comic.year}-${comic.month}-${comic.day}',
                      style:
                          themeData.textTheme.caption.copyWith(fontSize: 14.0),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      padding: EdgeInsets.all(0.0),
                      icon: Icon(Icons.share),
                      onPressed: () {
                        _shareComic();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _getImageUrl() {
    final num = comic.num;
    final dataSaver = _prefs.getBool('data_saver') ?? false;
    if (dataSaver || no2xVersion.contains(num)) {
      return comic.img;
    }
    if (num >= 1084) {
      var img = comic.img;
      return img.substring(0, img.lastIndexOf('.')) + "_2x.png";
    }
    return comic.img;
  }

  _shareComic() {
    String url = '${ComicApiClient.baseUrl}${comic.num}/';
    Share.share(url);
  }
}
