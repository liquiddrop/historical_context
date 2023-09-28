import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:historical_context/main.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:historical_context/model/events.dart';
import 'ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'event_dialog.dart';

class SingleTimeline extends StatefulWidget {
  const SingleTimeline({
    required List<HistoricalEvent> histEvents,
    required String titleString,
  })  : _histEvents = histEvents,
        _titleString = titleString;

  final String _titleString;
  final List<HistoricalEvent> _histEvents;

  @override
  State<SingleTimeline> createState() => SingleTimelineState();
}

class SingleTimelineState extends State<SingleTimeline> {
  ItemScrollController _timelineScrollController = ItemScrollController();
  String searchString = '';
  int eventInFocus = 0;
  BannerAd? _bannerAd;

  @override
  void initState() {
    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  bool isNumeric(String str) {
    RegExp _numeric = RegExp(r'^-?[0-9]+$');
    return _numeric.hasMatch(str.toUpperCase().replaceAll('BC', ''));
  }

  int findMatchingEvent(String searchString) {
    int offset = 0;
    int seachYears = 0;
    int count = 0;
    bool onlyCheckNumbers = false;
    if (isNumeric(searchString)) {
      onlyCheckNumbers = true;
      seachYears = int.parse(searchString.toUpperCase().replaceAll('BC', ''));
      if (searchString.toUpperCase().contains('BC')) {
        seachYears = -seachYears;
      }
    }
    for (var element in widget._histEvents) {
      if (onlyCheckNumbers) {
        if (seachYears <= element.year) {
          offset = count;
          break;
        }
      } else {
        if (element.summary.contains(
                RegExp("\\b($searchString)\\b", caseSensitive: false)) ||
            element.full_summary.contains(
                RegExp("\\b($searchString)\\b", caseSensitive: false))) {
          offset = count;
          break;
        }
      }
      count++;
    }
    return offset;
  }

  double getMinHeight(
    int yearOfEvent,
    int yearOfNextEvent,
  ) {
    double yearDifference = 0;
    //calculate the year difference then have a multiplier to make it more noticeable
    yearDifference = (yearOfNextEvent - yearOfEvent).toDouble() * 2;
    //make sure to bound the year difference so we don't just have blank screen
    if (yearDifference > 300) {
      yearDifference = 300;
    } else if(yearDifference < 0)
      {
        yearDifference=0;
      }
    return yearDifference;
  }

  Widget getSummaryDisplay(int indexInput, double minHeight){
    String tempPicString = widget._histEvents[indexInput].picture ?? "";
    bool useSvgPicture = false;
    if (tempPicString != '' && tempPicString.length > 3) {
      if (tempPicString.substring(tempPicString.length - 3) == 'JPG') {
        tempPicString =
            tempPicString.substring(0, tempPicString.length - 3) + 'jpg';
      }else if(tempPicString.toLowerCase().substring(tempPicString.length - 3) == 'svg'){
        useSvgPicture = true;
      }else if(tempPicString.toLowerCase().substring(tempPicString.length - 3) == 'png'){
        //converted these from png to jpg
        tempPicString =
            tempPicString.substring(0, tempPicString.length - 3) + 'jpg';
      }
    }
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding:
                      EdgeInsets.fromLTRB(8, 0, 8, 8),
                      tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '${widget._histEvents[indexInput].summary}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () async {
                      setState(() {
                        eventInFocus = indexInput;
                      });
                      await showDialog<void>(
                        context: context,
                        builder: (_) => DisplayEventDialog(
                            histEvent:
                            widget._histEvents[indexInput]),
                      );
                    },
                  ),
                ),
              ]),
          (tempPicString != '' && minHeight > 100)
              ? Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: (useSvgPicture)?SvgPicture.asset(
                  'asset/photos/${tempPicString}',
                ):Image.asset(
                  'asset/photos/${tempPicString}',
                ),
                iconSize: 100,
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (_) => Center(
                      child: (useSvgPicture)?SvgPicture.asset(
                        'asset/photos/${tempPicString}',
                      ):Image.asset(
                        'asset/photos/${tempPicString}',
                      ),
                    ),
                  );
                },
              ))
              : Container(),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    print('Enter Single timeline');
    return Scaffold(
      appBar: AppBar(
        title: Text((widget._titleString != '')
            ? (widget._titleString != 'World History')
                ? 'History of ${widget._titleString}'
                : '${widget._titleString}'
            : 'History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () async {
              print('Pressed search');
              await showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                    title: Text('Search Events'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('Enter a year or search for a specific event'),
                      SizedBox(
                        height: 18,
                      ),
                      TextFormField(
                        autofocus: true,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          filled: true,
                        ),
                        onChanged: (value) {
                          searchString = value;
                        },
                        maxLines: 1,
                      ),
                    ]),
                    actions: [
                      ElevatedButton(
                        child: const Text('Search'),
                        onPressed: () {
                          int searchOffset = findMatchingEvent(searchString);
                          setState(() {
                            eventInFocus = searchOffset;
                            _timelineScrollController.scrollTo(
                                index: searchOffset,
                                duration: Duration(seconds: 1));
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ]),
              );
            },
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ScrollablePositionedList.builder(
              padding: const EdgeInsets.all(8),
              itemScrollController: _timelineScrollController,
              physics: AlwaysScrollableScrollPhysics(),
              scrollDirection: Axis.vertical,
              itemCount: widget._histEvents.length,
              itemBuilder: (BuildContext context, int index) {
                double calcMinHeight = ((index < widget._histEvents.length - 1)
                    ? getMinHeight(widget._histEvents[index].year,
                    widget._histEvents[index + 1].year)
                    : 100);
                return Container(
                    color:
                        (eventInFocus == index) ? Colors.black12 : Colors.white,
                    child: TimelineTile(
                      alignment: TimelineAlign.manual,
                      isFirst: index == 0,
                      isLast: index == widget._histEvents.length - 1,
                      lineXY: 0.20,
                      indicatorStyle: IndicatorStyle(
                        indicatorXY: 0,
                        width: 18,
                        height: 18,
                        indicator: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(100),
                            ),
                          ),
                        ),
                      ),
                      startChild: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: calcMinHeight),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text('${widget._histEvents[index].date_string}')
                              ])),
                      endChild: getSummaryDisplay(index, calcMinHeight),
                      beforeLineStyle: LineStyle(
                        color: Colors.black,
                        thickness: 5,
                      ),
                    ));
              }),
        ),
        if (_bannerAd != null)
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          ),
      ]),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: (_bannerAd != null) ? 50 : 0),
        child: FloatingActionButton(
          onPressed: () {
            // navigate to the home page
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MyHomePage(
                      title: 'Add Timeline',
                      inputList: widget._histEvents,
                      oldTitle: widget._titleString)),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
