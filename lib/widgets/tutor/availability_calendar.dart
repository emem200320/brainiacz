// lib/widgets/tutor/availability_calendar.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AvailabilityCalendar extends StatefulWidget {
  const AvailabilityCalendar({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AvailabilityCalendarState createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          calendarFormat: _calendarFormat,
          focusedDay: _focusedDay,
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(Duration(days: 365)),
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
        ),
        SizedBox(height: 20),
        Text('Selected Day: ${_selectedDay?.toString() ?? "None"}'),
      ],
    );
  }
}