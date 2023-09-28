import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:historical_context/model/events.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DisplayEventDialog extends StatelessWidget {
  DisplayEventDialog({
    required HistoricalEvent histEvent,
  }) : _histEvent = histEvent;

  final HistoricalEvent _histEvent;
  bool useSvgPicture = false;

  String getLocationString() {
    String tempOutput = '';
    if ((_histEvent.location_city ?? '') != '') {
      tempOutput += '${_histEvent.location_city}, ';
    }
    if ((_histEvent?.location_state ?? '') != '') {
      tempOutput += '${_histEvent.location_state}, ';
    }
    if ((_histEvent?.location_country ?? '') != '') {
      tempOutput += '${_histEvent.location_country}, ';
    }
    if (tempOutput.length > 3) {
      if (tempOutput.substring(tempOutput.length - 2) == ', ') {
        return tempOutput.substring(0, tempOutput.length - 2);
      }
    }
    return tempOutput;
  }

  @override
  Widget build(BuildContext context) {
    String tempPicString = _histEvent?.picture ?? "";
    if (tempPicString != '' && tempPicString.length > 3) {
      if (tempPicString.substring(tempPicString.length - 3) == 'JPG') {
        tempPicString =
            tempPicString.substring(0, tempPicString.length - 3) + 'jpg';
      } else if(tempPicString.toLowerCase().substring(tempPicString.length - 3) == 'svg'){
        useSvgPicture = true;
      }else if(tempPicString.toLowerCase().substring(tempPicString.length - 3) == 'png'){
        //converted these from png to jpg
        tempPicString =
            tempPicString.substring(0, tempPicString.length - 3) + 'jpg';
      }
    }
    String locationString = getLocationString();
    return AlertDialog(
      insetPadding: EdgeInsets.all(10),
      title: Text('${_histEvent.summary}'),
      content: Container(
        height: MediaQuery.of(context).size.height * .4,
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * .1,
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_histEvent.date_string}'),
                      Text('${locationString}')
                    ],
                  ),
                  Expanded(
                      child: (tempPicString != '')
                          ? Align(
                              alignment: Alignment.topRight,
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
                          : Container())
                ],
              ),
            ),
            SizedBox(
              height: 12,
            ),
            Expanded(
              child: Container(
                color: Colors.black12,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('${_histEvent.full_summary}'),
                          SizedBox(
                            height: 12,
                          ),
                          (_histEvent.link != '')
                              ? InkWell(
                                  child: Text(
                                    '${_histEvent.link}',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                  onTap: () async => await launchUrl(
                                      Uri.parse(_histEvent.link)),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
