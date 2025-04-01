// lib/widgets/request_session_dialog.dart
import 'package:flutter/material.dart';

class RequestSessionDialog extends StatefulWidget {
  final Function(int) onRequestSession;
  
  const RequestSessionDialog({
    Key? key,
    required this.onRequestSession,
  }) : super(key: key);

  @override
  State<RequestSessionDialog> createState() => _RequestSessionDialogState();
}

class _RequestSessionDialogState extends State<RequestSessionDialog> {
  int _selectedDuration = 60; // Default to 1 hour
  final List<int> _quickDurations = [30, 60, 90]; // in minutes
  
  // Custom time controllers
  final TextEditingController _hoursController = TextEditingController(text: '0');
  final TextEditingController _minutesController = TextEditingController(text: '0');
  bool _isCustomTime = false;
  
  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }
  
  int _calculateCustomTime() {
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    return (hours * 60) + minutes;
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Request Tutoring Session',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Select the duration for your tutoring session:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Quick duration options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_quickDurations.length, (index) {
                final duration = _quickDurations[index];
                final hours = duration ~/ 60;
                final minutes = duration % 60;
                
                String durationText = '';
                if (hours > 0) {
                  durationText += '$hours h';
                  if (minutes > 0) durationText += ' $minutes m';
                } else {
                  durationText = '$minutes m';
                }
                
                final isSelected = !_isCustomTime && duration == _selectedDuration;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDuration = duration;
                          _isCustomTime = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          durationText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 24),
            
            // Custom time input
            Row(
              children: [
                const Text(
                  'Custom time:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _isCustomTime = true;
                          _selectedDuration = _calculateCustomTime();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Hours',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _isCustomTime = true;
                          _selectedDuration = _calculateCustomTime();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Minutes',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      int duration = _isCustomTime ? _calculateCustomTime() : _selectedDuration;
                      // Ensure we have a valid duration (minimum 1 minute)
                      if (duration < 1) duration = 1;
                      widget.onRequestSession(duration);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Request',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
