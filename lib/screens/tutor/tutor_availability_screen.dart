//lib/screens/tutor/tutor_availability_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // For calendar widget
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart'; // For time picker

class TutorAvailabilityScreen extends StatefulWidget {
  const TutorAvailabilityScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TutorAvailabilityScreenState createState() => _TutorAvailabilityScreenState();
}

class _TutorAvailabilityScreenState extends State<TutorAvailabilityScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week; // Default calendar view
  DateTime _focusedDay = DateTime.now(); // Currently focused day
  DateTime? _selectedDay; // Selected day for availability
  TimeOfDay _selectedTime = TimeOfDay.now(); // Selected time for availability

  // List to store available slots
  final List<Map<String, dynamic>> _availableSlots = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Availability'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Calendar to select a date
            TableCalendar(
              firstDay: DateTime.now(), // First selectable day
              lastDay: DateTime.now().add(Duration(days: 365)), // Last selectable day
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
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
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
            ),
            SizedBox(height: 20),

            // Time picker to select a time
            Text('Select Time:', style: TextStyle(fontSize: 18)),
            TimePickerSpinner(
              is24HourMode: false,
              normalTextStyle: TextStyle(fontSize: 24, color: Colors.grey),
              highlightedTextStyle: TextStyle(fontSize: 24, color: Colors.blue),
              spacing: 50,
              itemHeight: 50,
              onTimeChange: (time) {
                setState(() {
                  _selectedTime = TimeOfDay(hour: time.hour, minute: time.minute);
                });
              },
            ),
            SizedBox(height: 20),

            // Button to add availability
            ElevatedButton(
              onPressed: _addAvailability,
              child: Text('Add Availability'),
            ),
            SizedBox(height: 20),

            // List of added availability slots
            Expanded(
              child: _availableSlots.isEmpty
                  ? Center(child: Text('No availability slots added yet.'))
                  : ListView.builder(
                      itemCount: _availableSlots.length,
                      itemBuilder: (context, index) {
                        final slot = _availableSlots[index];
                        return ListTile(
                          title: Text('${slot['date']}'),
                          subtitle: Text('${slot['time']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeAvailability(index),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to add availability
  void _addAvailability() {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date.')),
      );
      return;
    }

    setState(() {
      _availableSlots.add({
        'date': '${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}',
        'time': '${_selectedTime.hour}:${_selectedTime.minute}',
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Availability added successfully!')),
    );
  }

  // Method to remove availability
  void _removeAvailability(int index) {
    setState(() {
      _availableSlots.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Availability removed.')),
    );
  }
}