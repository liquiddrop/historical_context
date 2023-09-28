import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:historical_context/single_timeline.dart';
import 'package:historical_context/top_level_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'database_helper.dart';
import 'dual_timeline.dart';
import 'model/events.dart';

void main() {
  runApp(ProviderScope(
    child: ContextApp(),
  ));
}

class ContextApp extends StatelessWidget {
  const ContextApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    MobileAds.instance.initialize();
    return MaterialApp(
      title: 'Context',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Historical Context'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {super.key,
      required this.title,
      this.inputList = const [],
      this.oldTitle = ''});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final List<HistoricalEvent> inputList;
  final String oldTitle;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool initialized = false;
  TextEditingController _searchCountryController = TextEditingController();
  TextEditingController _searchCityController = TextEditingController();
  int searchYear = 0;
  String searchEvent = '';
  String titleStringToPush = 'World History';
  List<String> countriesInDatabase = [];
  List<String> citiesInDatabase = [];

  void setCountries(Set<String> inputCountries){
    countriesInDatabase=inputCountries.toList();
  }

  void setCities(Set<String> inputCities){
    citiesInDatabase=inputCities.toList();
  }

  Future<List<HistoricalEvent>> getSearchedEvents(
      DatabaseHelper sqlDatabase) async {
    List<HistoricalEvent> tempList = [];
    //The order of search is Event, country, city, then Year
    if (searchEvent != '') {
      tempList = await sqlDatabase.findByEvent(searchEvent);
      titleStringToPush = '${searchEvent}';
    } else if (searchYear != 0) {
      tempList = await sqlDatabase.findByYear(searchYear);
      titleStringToPush = '${searchYear}';
    } else if ((_searchCityController?.text??'') != '') {
      tempList = await sqlDatabase.findByCity(_searchCityController.text);
      titleStringToPush = '${_searchCityController.text}';
    } else if ((_searchCountryController?.text??'') != '') {
      tempList = await sqlDatabase.findByCountry(_searchCountryController.text);
      titleStringToPush = '${_searchCountryController.text}';
    }else {
      //nothing entered just show all
      tempList = await sqlDatabase.getAll();
      titleStringToPush = '';
    }
    //sort the list
    tempList.sort((a,b) => a.year.compareTo(b.year));
    return tempList;
  }

  void _togglePlatform() {
    TargetPlatform _getOppositePlatform() {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return TargetPlatform.android;
      } else {
        return TargetPlatform.iOS;
      }
    }

    debugDefaultTargetPlatformOverride = _getOppositePlatform();
    // This rebuilds the application. This should obviously never be
    // done in a real app but it's done here since this app
    // unrealistically toggles the current platform for demonstration
    // purposes.
    WidgetsBinding.instance.reassembleApplication();
  }

  List<String> getSuggestionsCountries(String searchString) {
    List<String> _tempCountries = <String>[];
    if (countriesInDatabase == null) {
      return _tempCountries;
    }
    if (!(searchString.isEmpty)) {
      for (int i = 0; i < countriesInDatabase.length; i++) {
        if (countriesInDatabase[i].toLowerCase().contains(searchString.toLowerCase())) {
          _tempCountries.add(countriesInDatabase[i]);
        }
      }
      return _tempCountries;
    }
    return _tempCountries;
  }

  List<String> getSuggestionsCities(String searchString) {
    List<String> _tempCities = <String>[];
    if (citiesInDatabase == null) {
      return _tempCities;
    }
    if (!(searchString.isEmpty)) {
      for (int i = 0; i < citiesInDatabase.length; i++) {
        if (citiesInDatabase[i].toLowerCase().contains(searchString.toLowerCase())) {
          _tempCities.add(citiesInDatabase[i]);
        }
      }
      return _tempCities;
    }
    return _tempCities;
  }

  @override
  Widget build(BuildContext context) {
    //make sure to init providers
    var sqlDatabase = context.read(sqlDatabaseProvider);
    sqlDatabase.getAllCountries().then((value) => setCountries(value));
    sqlDatabase.getAllCities().then((value) => setCities(value));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          (kDebugMode)
              ? IconButton(
                  icon: Icon(Icons.shuffle),
                  onPressed: _togglePlatform,
                )
              : Container(),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: Column(children: [
        SizedBox(
          height: 6,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Row(children: [
            Expanded(
              child: ElevatedButton(
                  child: Text('World History'),
                  onPressed: () async {
                    var tempEvents = await sqlDatabase.findByImportance(5);
                    titleStringToPush = 'World History';
                    if (widget.inputList.isNotEmpty) {
                      titleStringToPush += ' vs ${widget.oldTitle}';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DualTimeline(
                                leftHistEvents: tempEvents,
                                rightHistEvents: widget.inputList,
                                titleString: titleStringToPush)),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SingleTimeline(
                                histEvents: tempEvents,
                                titleString: titleStringToPush)),
                      );
                    }
                  }),
            ),
          ]),
        ),
        Padding(
          padding: EdgeInsets.all(6),
          child: Card(
            color: Colors.white70,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      width: 1,
                      color: Colors.black),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(3),
                    child: TextFormField(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        filled: true,
                        hintText: 'Enter a Event to Search',
                        labelText: 'Event',
                      ),
                      onChanged: (value) {
                        searchEvent = value;
                      },
                      maxLines: 1,
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(3), child:
                  TypeAheadFormField(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _searchCountryController,
                      decoration: InputDecoration(
                        hintText: 'Enter a Country to Search',
                        labelText: 'Country',
                        border: const OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                    suggestionsCallback: (search) {
                      return getSuggestionsCountries(search);
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(suggestion),
                      );
                    },
                    transitionBuilder: (context, suggestionsBox, controller) {
                      return suggestionsBox;
                    },
                    onSuggestionSelected: (suggestion) async {
                      this._searchCountryController.text = suggestion;
                    },
                  ),),
                  Padding(padding: EdgeInsets.all(3), child:
                  TypeAheadFormField(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _searchCityController,
                      decoration: InputDecoration(
                        hintText: 'Enter a City to Search',
                        labelText: 'City',
                        border: const OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                    suggestionsCallback: (search) {
                      return getSuggestionsCities(search);
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(suggestion),
                      );
                    },
                    transitionBuilder: (context, suggestionsBox, controller) {
                      return suggestionsBox;
                    },
                    onSuggestionSelected: (suggestion) async {
                      this._searchCityController.text = suggestion;
                    },
                  ),),
                  Padding(
                    padding: EdgeInsets.all(3),
                    child: TextFormField(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        filled: true,
                        hintText: 'Enter a Year to Search',
                        labelText: 'Year',
                      ),
                      onChanged: (value) {
                        searchYear = int.parse(value);
                      },
                      maxLines: 1,
                    ),
                  ),
                  ElevatedButton(
                      child: Text('Search'),
                      onPressed: () async {
                        var tempEvents = await getSearchedEvents(sqlDatabase);
                        if (tempEvents.isEmpty) {
                          print('There are no events');
                          FocusScopeNode currentFocus = FocusScope.of(context);
                          if (!currentFocus.hasPrimaryFocus) {
                            currentFocus.unfocus();
                          }
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('There are no events that match your search'),
                            duration: const Duration(seconds: 3),
                            backgroundColor: Colors.blue,
                          ));
                        } else {
                          if (widget.inputList.isNotEmpty) {
                            titleStringToPush += ' vs ${widget.oldTitle}';
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DualTimeline(
                                      leftHistEvents: tempEvents,
                                      rightHistEvents: widget.inputList,
                                      titleString: titleStringToPush)),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SingleTimeline(
                                      histEvents: tempEvents,
                                      titleString: titleStringToPush)),
                            );
                          }
                        }
                      }),
                ],
              ),
            ),
          ),),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: new BoxDecoration(
                image: new DecorationImage(
                  image: new AssetImage("asset/context_app_background.png"),
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),
        )
      ]), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
