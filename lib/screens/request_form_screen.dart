//lib/screens/request_form_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../services/firestore_services.dart';

class RequestForm extends StatefulWidget {
  final String tutorId;
  final String? tutorName;
  final String? subjectId;
  final String? subjectName;

  const RequestForm({
    super.key,
    required this.tutorId,
    this.tutorName,
    this.subjectId,
    this.subjectName,
  });

  @override
  // ignore: library_private_types_in_public_api
  _RequestFormState createState() => _RequestFormState();
}

class _RequestFormState extends State<RequestForm> {
  final TextEditingController _subjectController = TextEditingController();
  bool _isLoading = false;
  DateTime _sessionDate = DateTime.now();
  TimeOfDay _sessionTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    if (widget.subjectName != null) {
      _subjectController.text = widget.subjectName!;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  // Show custom time picker dialog
  Future<void> _showCustomTimePicker() async {
    final TimeOfDay? picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return CustomTimePickerDialog(
          initialTime: _sessionTime,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _sessionTime = picked;
      });

      // Automatically send the request after time selection
      _sendRequest();
    }
  }

  // Format time to display
  String _formatTime(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dateTime = DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);

    return DateFormat('h:mm a').format(dateTime);
  }

  Future<void> _sendRequest() async {
    // Validate inputs
    if (_subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw 'User not logged in';
      }

      print('Sending request to tutor: ${widget.tutorId}');
      print('Student ID: ${currentUser.uid}');
      print('Subject: ${_subjectController.text}');
      print('Session Date: $_sessionDate');
      print('Session Time: ${_formatTime(_sessionTime)}');

      // Create request with all required fields
      final result = await FirestoreService().sendTutorRequest(
        studentId: currentUser.uid,
        tutorId: widget.tutorId,
        subject: _subjectController.text,
        message: 'I would like to connect with you for tutoring.',
        sessionDate: _sessionDate,
        sessionTime: _formatTime(_sessionTime),
      );

      // Check if request was successful
      if (result['success'] == true) {
        // Show success message
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? 'Request sent successfully!')),
        );

        // Navigate back
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      } else {
        // Show error message
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? 'Failed to send request')),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text('Send Request to ${widget.tutorName ?? "Tutor"}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subject field
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.subject),
              ),
              readOnly: widget.subjectName != null,
            ),
            const SizedBox(height: 24),

            // Session Date picker
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _sessionDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null && picked != _sessionDate) {
                  setState(() {
                    _sessionDate = picked;
                  });
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Session Date: ${DateFormat('EEEE, MMMM d, yyyy').format(_sessionDate)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Request Session Button
            Container(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _showCustomTimePicker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Request Session',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class CustomTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const CustomTimePickerDialog({
    super.key,
    required this.initialTime,
  });

  @override
  State<CustomTimePickerDialog> createState() => _CustomTimePickerDialogState();
}

class _CustomTimePickerDialogState extends State<CustomTimePickerDialog> {
  late TimeOfDay selectedTime;
  late bool isAM;

  @override
  void initState() {
    super.initState();
    selectedTime = widget.initialTime;
    isAM = selectedTime.hour < 12;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hour
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${isAM ? selectedTime.hourOfPeriod : selectedTime.hourOfPeriod == 0 ? 12 : selectedTime.hourOfPeriod}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Separator
                const Text(
                  ':',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                // Minute
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      selectedTime.minute.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // AM/PM toggle
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          isAM = true;
                          final hour = selectedTime.hour >= 12
                              ? selectedTime.hour - 12
                              : selectedTime.hour;
                          selectedTime = TimeOfDay(
                              hour: hour, minute: selectedTime.minute);
                        });
                      },
                      child: Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              isAM ? Colors.pink.shade50 : Colors.grey.shade200,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'AM',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isAM
                                  ? Colors.pink.shade500
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          isAM = false;
                          final hour = selectedTime.hour < 12
                              ? selectedTime.hour + 12
                              : selectedTime.hour;
                          selectedTime = TimeOfDay(
                              hour: hour, minute: selectedTime.minute);
                        });
                      },
                      child: Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: !isAM
                              ? Colors.pink.shade50
                              : Colors.grey.shade200,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'PM',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: !isAM
                                  ? Colors.pink.shade500
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Clock dial
            SizedBox(
              height: 240,
              width: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Clock background
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Clock numbers
                  ...List.generate(12, (index) {
                    final number = index + 1;
                    final angle = (number * 30 - 90) * (3.14159 / 180);
                    final x = 90 * cos(angle);
                    final y = 90 * sin(angle);

                    return Positioned(
                      left: 120 + x - 12,
                      top: 120 + y - 12,
                      child: Text(
                        '$number',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: (isAM &&
                                      selectedTime.hourOfPeriod == number) ||
                                  (!isAM && selectedTime.hourOfPeriod == number)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                  // Selected hour marker
                  Builder(builder: (context) {
                    final selectedHour = isAM
                        ? selectedTime.hourOfPeriod
                        : selectedTime.hourOfPeriod == 0
                            ? 12
                            : selectedTime.hourOfPeriod;
                    final angle = (selectedHour * 30 - 90) * (3.14159 / 180);
                    final x = 70 * cos(angle);
                    final y = 70 * sin(angle);

                    return Stack(
                      children: [
                        // Line
                        Transform.rotate(
                          angle: angle,
                          child: Container(
                            width: 100,
                            height: 2,
                            color: Colors.purple,
                            alignment: Alignment.centerRight,
                          ),
                        ),
                        // Marker
                        Positioned(
                          left: 120 + x - 15,
                          top: 120 + y - 15,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Colors.purple,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$selectedHour',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Keyboard and buttons
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end, // Changed from spaceBetween to end
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selectedTime),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
