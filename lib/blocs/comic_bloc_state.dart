import 'package:xkcd/data/comic.dart';

class ComicBlocState {
  bool loading;
  List<Comic> comics;

  ComicBlocState(
    this.loading,
    this.comics,
  );

  ComicBlocState.empty() {
    loading = false;
    comics = [];
  }
}
