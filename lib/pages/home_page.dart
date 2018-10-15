import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xkcd/blocs/comic_bloc.dart';
import 'package:xkcd/data/comic.dart';
import 'package:xkcd/pages/favorites_page.dart';
import 'package:xkcd/pages/settings_page.dart';
import 'package:xkcd/providers/comic_bloc_provider.dart';
import 'package:xkcd/providers/preferences.dart';
import 'package:xkcd/utils/app_localizations.dart';
import 'package:xkcd/utils/constants.dart';
import 'package:xkcd/widgets/comic_view.dart';

class HomePage extends StatefulWidget {
  static final String homePageRoute = '/home-page';

  @override
  HomePageState createState() => new HomePageState();
}

class HomePageState extends State<HomePage> {
  final SharedPreferences prefs = Preferences.prefs;
  bool _firstLoad = true;
  List<Comic> comics;
  Random random;

  double scrollPercent = 0.0;

  @override
  Widget build(BuildContext context) {
    ComicBloc bloc = ComicBlocProvider.of(context).bloc;

    if (_firstLoad) {
      bloc.fetchLatestComics();
      _firstLoad = false;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder(
        initialData: bloc.getCurrentState(),
        stream: bloc.comicStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(AppLocalizations.of(context).get('something_wrong')),
            );
          }
          if (snapshot.data.loading) {
            return Center();
          }
          comics = snapshot.data.comics;
          return ComicsView(
              comics: comics,
              onScroll: (double scrollPercent) {
                setState(() {
                  this.scrollPercent = scrollPercent;
                });
              });
        },
      ),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  _buildFab() {
    ComicBloc bloc = ComicBlocProvider.of(context).bloc;
    return StreamBuilder(
      initialData: bloc.getCurrentState(),
      stream: bloc.comicStream,
      builder: (context, snapshot) {
        return FloatingActionButton.extended(
          icon: Icon(Icons.autorenew),
          label: Text(AppLocalizations.of(context).get('random')),
          onPressed: () {
            bloc.fetchRandomComics();
          },
        );
      },
    );
  }

  _buildBottomAppBar() {
    ComicBloc bloc = ComicBlocProvider.of(context).bloc;

    return StreamBuilder(
      initialData: bloc.getCurrentState(),
      stream: bloc.comicStream,
      builder: (context, snapshot) {
        List<Widget> buttons = [
          Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return _buildBottomSheet();
                    },
                  );
                },
              ),
            ],
          ),
          _buildFavoriteButton(),
        ];

        return BottomAppBar(
          color: Theme.of(context).primaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: buttons,
          ),
        );
      },
    );
  }

  _buildBottomSheet() {
    ComicBloc bloc = ComicBlocProvider.of(context).bloc;
    var themeData = Theme.of(context);
    var appLocalizations = AppLocalizations.of(context);

    final widgets = [
      ListTile(
        leading: Icon(Icons.home, color: Colors.white),
        title: Text(appLocalizations.get('latest_comic'),
            style: TextStyle(color: Colors.white)),
        onTap: () {
          Navigator.pop(context);
          bloc.fetchLatestComics();
        },
      ),
      ListTile(
        leading: Icon(Icons.info_outline, color: Colors.white),
        title: Text(appLocalizations.get('explain_current'),
            style: TextStyle(color: Colors.white)),
        onTap: () {
          Navigator.pop(context);
          bloc.explainCurrentComic();
        },
      ),
      ListTile(
        leading: Icon(Icons.favorite, color: Colors.white),
        title: Text(appLocalizations.get('my_favorites'),
            style: TextStyle(color: Colors.white)),
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).pushNamed(FavoritesPage.favoritesPageRoute);
        },
      ),
      ListTile(
        leading: Icon(Icons.settings, color: Colors.white),
        title: Text(appLocalizations.get('settings'),
            style: TextStyle(color: Colors.white)),
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).pushNamed(SettingsPage.settingsPageRoute);
        },
      ),
    ];

    return Container(
      color: themeData.primaryColor,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widgets.length,
        physics: ClampingScrollPhysics(),
        itemBuilder: (context, index) {
          return widgets[index];
        },
      ),
    );
  }

  _buildFavoriteButton() {
    Comic comic = _getCurrentComic();

    bool isFavorite = false;
    if (comics != null) {
      var favorites = prefs.getStringList(Constants.favorites);
      var num = comic.num.toString();
      isFavorite = favorites?.contains(num) ?? false;
    }

    return GestureDetector(
      onTap: () {
        _handleFavoriteAction();
      },
      onLongPress: () {
        Navigator.of(context).pushNamed(FavoritesPage.favoritesPageRoute);
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: Colors.white,
        ),
      ),
    );
  }

  _handleFavoriteAction() {
    Comic comic = _getCurrentComic();
    if (comics == null) {
      return;
    }

    var num = comic.num.toString();
    List<String> favorites = prefs.getStringList(Constants.favorites);
    if (favorites == null || favorites.isEmpty) {
      favorites = [num];
    } else if (favorites.contains(num)) {
      favorites.remove(num);
    } else {
      favorites.add(num);
    }
    prefs.setStringList(Constants.favorites, favorites);
    setState(() {});
  }

  _getCurrentComic() {
    ComicBloc bloc = ComicBlocProvider.of(context).bloc;
    if (comics == null) return null;
    return bloc
        .getCurrentState()
        .comics[(scrollPercent * comics.length).floor()];
  }
}
