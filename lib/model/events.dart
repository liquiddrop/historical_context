
// This is called orders/transactions in the backend.
class HistoricalEvent {
  final int id;
  final String date_string;
  final int year;
  final int month;
  final int day;
  final int importance;
  final String location_country;
  final String location_state;
  final String location_city;
  final String location_building;
  final String summary;
  final String full_summary;
  final String picture;
  final String link;

  HistoricalEvent({
    required this.id,
    required this.date_string,
    required this.year,
    required this.month,
    required this.day,
    required this.importance,
    required this.location_country,
    required this.location_state,
    required this.location_city,
    required this.location_building,
    required this.summary,
    required this.full_summary,
    required this.picture,
    required this.link,
  });

  HistoricalEvent.fromUserInput({
    this.id=0,
    required this.date_string,
    required this.year,
    required this.month,
    required this.day,
    required this.importance,
    required this.location_country,
    required this.location_state,
    required this.location_city,
    required this.location_building,
    required this.summary,
    required this.full_summary,
    required this.picture,
    required this.link,
  });

  factory HistoricalEvent.fromMap(
      Map<String, dynamic> data,
      ) {
    //need to account for when the year is a date range
    int tempYear=0;
    var re = RegExp(r'[–-\s]');
    if(data['year'].runtimeType == int )
      {
        tempYear = data['year'];
      }
    else if (data['year'].runtimeType == String) {
      List<String> parsedYear = data['year'].replaceAll(new RegExp(r'[^0-9]'),' ').split(re);
      String firstStringWithNumbers = parsedYear.firstWhere((element) => element.contains(RegExp(r'[0-9]')));
      tempYear = int.parse(firstStringWithNumbers);
      if(data['year'].contains('BC')){
        tempYear = -tempYear;
      }
    }
    return HistoricalEvent(
      id: data['id']??0,
      date_string: data['date_string']??'No Date',
      year: tempYear,
      month: data['month']??0,
      day: data['day']??0,
      importance: data['importance']??0,
      location_country: data['location_country']??'',
      location_state: data['location_state']??'',
      location_city: data['location_city']??'',
      location_building: data['location_building']??'',
      summary: data['summary']??'',
      full_summary: data['full_summary']??'',
      picture: data['picture']??'',
      link: data['link']??'',
    );
  }
}