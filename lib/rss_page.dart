import 'package:flutter/material.dart';
import 'package:flutter_rss_agregator/provider.dart';
import 'package:provider/provider.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share/share.dart';
import 'provider.dart';

class RssHomePage extends StatefulWidget {
  RssHomePage({Key key}) : super(key: key);

  @override
  _RssHomePageState createState() => _RssHomePageState();
}

class _RssHomePageState extends State<RssHomePage> {
  RssFeed _feed;
  String rssurl = 'https://tygodnik.interia.pl/feed'; // Adres URL witryny rss, z której będziemy korzystać
  GlobalKey<RefreshIndicatorState> _refreshKey; // Klucz, którego użyjemy do odświeżenia strony
  static const String placeholderImg = 'assets/rss.png';//   ścieżka obrazu, która będzie wyświetlana do momentu przesłania obrazów

  Future<void> load() async {
    await loadFeed().then((result) async {
      if (null == result || result.toString().isEmpty) {
        return;
      }
      setState(() {
        _feed = result;
      });
    });
  }

  Future<RssFeed> loadFeed() async {
    try {
      final client = http.Client();
      final response = await client.get(rssurl);
      final responseBody = utf8.decode(response.bodyBytes);
      return RssFeed.parse(responseBody);
    } on Exception {}
    return null;
  }

  @override
  void initState() {
    super.initState();
    _refreshKey = GlobalKey<RefreshIndicatorState>();
    load();
  }

  Widget list() { // Interfejs listy - wyswietlanie artykulow
    return ListView.builder(
      padding: const EdgeInsets.only(left: 1, right: 1, top: 5),
      shrinkWrap: true, //zmniejszenie zajmowanego miejsca, gdyby bylo mniej artykulow
      itemCount: _feed.items.length, //liczba artykułow
      itemBuilder: (BuildContext context, int index) {
        final item = _feed.items[index];
        return Column(
          children: [
            GestureDetector( // Klikniecie w wiadomosc
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ShowNews(item: item)), // Przejscie do ShowNews
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: ListTile(
                    leading: CachedNetworkImage(
                      placeholder: (context, url) =>
                          Image.asset(placeholderImg),
                      imageUrl: item.enclosure.url,
                      alignment: Alignment.center,
                      fit: BoxFit.fill,
                    ),
                    title: Text(
                      item.title ?? "Tytuł informacji", // Zabezpieczenie, brak tytulu
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16,
                          // color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    // subtitle: Text(item.pubDate),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool isFeedEmpty() { // Sprawdza, czy są wiadomości
    return null == _feed || null == _feed.items;
  }

  Widget body() {
    return isFeedEmpty() // sprawdzenie czy są artykuły
        ? Center(child: CircularProgressIndicator()) // Odświeżanie wiadomości, znak w środku
        : RefreshIndicator(
      key: _refreshKey,
      child: list(),
      onRefresh: () async =>
          load(), //Załadowanie nowymi wiadomościami naszego ekranu.
    );
  }

  @override
  Widget build(BuildContext context) { // Interfejs
    final text = MediaQuery.of(context).platformBrightness == Brightness.dark
        ? 'DarkTheme'
        : 'LightTheme';
    return Scaffold(
      appBar: AppBar(
        title: Text('RSS Agregator'),
        centerTitle: true,
        actions: [
          ChangeThemeButtonWidget(),
        ],
      ),
      body: body(),
    );
  }
}

class ChangeThemeButtonWidget extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Switch.adaptive(
      value: themeProvider.IsDarkMode,
      onChanged: (value) {
        final provider = Provider.of<ThemeProvider>(context, listen: false);
        provider.toggleTheme(value);
      },
    );
  }
}


class ShowNews extends StatelessWidget {
  final item;
  const ShowNews({Key key, this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) { // Udostepnianie
    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        actions: [
          IconButton(
            icon: Icon(
              Icons.share,
              color: Colors.black,
            ),
            onPressed: () {
              Share.share(item.link);
            },
          )
        ],
      ),
      body: WebView(
        initialUrl: item.link,
      ),
    );
  }
}
