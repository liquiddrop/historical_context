import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:historical_context/model/events.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'ad_helper.dart';
import 'event_dialog.dart';

class DualTimeline extends StatefulWidget {
  const DualTimeline({
    required List<HistoricalEvent> leftHistEvents,
    required List<HistoricalEvent> rightHistEvents,
    required String titleString,
  })  : _leftHistEvents = leftHistEvents,
        _rightHistEvents = rightHistEvents,
        _titleString = titleString;

  final String _titleString;
  final List<HistoricalEvent> _leftHistEvents;
  final List<HistoricalEvent> _rightHistEvents;

  @override
  State<DualTimeline> createState() => DualTimelineState();
}

class DualTimelineState extends State<DualTimeline> {
  ItemScrollController _timelineScrollControllerLeft = ItemScrollController();
  ItemScrollController _timelineScrollControllerRight = ItemScrollController();
  String searchString = '';
  int offsetLeft = 0, offsetRight = 0;
  int eventInFocusLeft = 0, eventInFocusRight = 0;
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

  void findMatchingEvents(String searchString) {
    int seachYears = 0;
    int countLeft = 0, countRight = 0;
    bool onlyCheckNumbers = false;
    if (isNumeric(searchString)) {
      onlyCheckNumbers = true;
      seachYears = int.parse(searchString.toUpperCase().replaceAll('BC', ''));
      if (searchString.toUpperCase().contains('BC')) {
        seachYears = -seachYears;
      }
    }
    for (var element in widget._leftHistEvents) {
      if (onlyCheckNumbers) {
        if (seachYears <= element.year) {
          offsetLeft = countLeft;
          break;
        }
      } else {
        if (element.summary.contains(
                RegExp("\\b($searchString)\\b", caseSensitive: false)) ||
            element.full_summary.contains(
                RegExp("\\b($searchString)\\b", caseSensitive: false))) {
          offsetLeft = countLeft;
          break;
        }
      }
      countLeft++;
    }
    for (var element in widget._rightHistEvents) {
      if (onlyCheckNumbers) {
        if (seachYears <= element.year) {
          offsetRight = countRight;
          break;
        }
      } else {
        if (element.summary.contains(
                RegExp("\\b($searchString)\\b", caseSensitive: false)) ||
            element.full_summary.contains(
                RegExp("\\b($searchString)\\b", caseSensitive: false))) {
          offsetRight = countRight;
          break;
        }
      }
      countRight++;
    }
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
    }else if(yearDifference < 0)
    {
      yearDifference=0;
    }
    return yearDifference;
  }

  Widget getSummaryDisplay(int indexInput, double minHeight, HistoricalEvent histEventToDisplay, bool isLeftSide){
    String tempPicString = histEventToDisplay.picture ?? "";
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
                      '${histEventToDisplay.summary}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () async {
                      setState(() {
                        if(isLeftSide){
                        eventInFocusLeft = indexInput;
                        }else{
                          eventInFocusRight = indexInput;
                        }
                      });
                      await showDialog<void>(
                        context: context,
                        builder: (_) => DisplayEventDialog(
                            histEvent:
                            histEventToDisplay),
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
    print('Enter Dual timeline');
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget._titleString}'),
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
                      Text('Enter a year or search for specific wording'),
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
                      TextButton(
                        child: const Text('Search'),
                        onPressed: () {
                          findMatchingEvents(searchString);
                          setState(() {
                            eventInFocusLeft = offsetLeft;
                            eventInFocusRight = offsetRight;
                            _timelineScrollControllerLeft.scrollTo(
                                index: offsetLeft,
                                duration: Duration(seconds: 1));
                            _timelineScrollControllerRight.scrollTo(
                                index: offsetRight,
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
          child: Row(
            children: [
              Flexible(
                child: ScrollablePositionedList.builder(
                    padding: const EdgeInsets.all(3),
                    itemScrollController: _timelineScrollControllerLeft,
                    physics: AlwaysScrollableScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    itemCount: widget._leftHistEvents.length,
                    itemBuilder: (BuildContext context, int index) {
                      double calcMinHeight = ((index < widget._leftHistEvents.length - 1)
                          ? getMinHeight(widget._leftHistEvents[index].year,
                          widget._leftHistEvents[index + 1].year)
                          : 100);
                      return Container(
                          color: (eventInFocusLeft == index)
                              ? Colors.black12
                              : Colors.white,
                          child: TimelineTile(
                            alignment: TimelineAlign.manual,
                            isFirst: index == 0,
                            isLast: index == widget._leftHistEvents.length - 1,
                            lineXY: 0.25,
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
                                    minHeight: (index <
                                            widget._leftHistEvents.length - 1)
                                        ? getMinHeight(
                                            widget._leftHistEvents[index].year,
                                            widget._leftHistEvents[index + 1]
                                                .year)
                                        : 100),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${widget._leftHistEvents[index].date_string}')
                                    ])),
                            endChild: getSummaryDisplay(index, calcMinHeight, widget._leftHistEvents[index], true),
                            beforeLineStyle: LineStyle(
                              color: Colors.black,
                              thickness: 5,
                            ),
                          ));
                    }),
              ),
              Flexible(
                child: ScrollablePositionedList.builder(
                    padding: const EdgeInsets.all(3),
                    itemScrollController: _timelineScrollControllerRight,
                    physics: AlwaysScrollableScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    itemCount: widget._rightHistEvents.length,
                    itemBuilder: (BuildContext context, int index) {
                      double calcMinHeight = ((index < widget._rightHistEvents.length - 1)
                          ? getMinHeight(widget._rightHistEvents[index].year,
                          widget._rightHistEvents[index + 1].year)
                          : 100);
                      return Container(
                          color: (eventInFocusRight == index)
                              ? Colors.black12
                              : Colors.white,
                          child: TimelineTile(
                            alignment: TimelineAlign.manual,
                            isFirst: index == 0,
                            isLast: index == widget._rightHistEvents.length - 1,
                            lineXY: 0.25,
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
                                  minHeight: (index <
                                          widget._rightHistEvents.length - 1)
                                      ? getMinHeight(
                                          widget._rightHistEvents[index].year,
                                          widget
                                              ._rightHistEvents[index + 1].year)
                                      : 100),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${widget._rightHistEvents[index].date_string}')
                                  ]),
                            ),
                            endChild: getSummaryDisplay(index, calcMinHeight, widget._rightHistEvents[index], false),
                            beforeLineStyle: LineStyle(
                              color: Colors.black,
                              thickness: 5,
                            ),
                          ));
                    }),
              ),
            ],
          ),
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
            // navigate back to the home page
            Navigator.popUntil(
                context, (Route<dynamic> predicate) => predicate.isFirst);
          },
          child: const Icon(Icons.home),
        ),
      ),
    );
  }
}
