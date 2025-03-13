import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManageReservationScreen extends StatefulWidget {
  @override
  _ManageReservationScreenState createState() => _ManageReservationScreenState();
}

class _ManageReservationScreenState extends State<ManageReservationScreen> {
  TimeOfDay? startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay? endTime = TimeOfDay(hour: 21, minute: 0);
  int advanceBookingDays = 7;
  List<Map<String, dynamic>> unavailableTimes = [];

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime! : endTime!,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  Future<void> _selectDateTime(BuildContext context, int index) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: unavailableTimes[index]['date'] ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: unavailableTimes[index]['time'] ?? TimeOfDay(hour: 9, minute: 0),
      );
      if (pickedTime != null) {
        setState(() {
          unavailableTimes[index] = {'date': pickedDate, 'time': pickedTime};
        });
      }
    }
  }

  void _addUnavailableTime() {
    setState(() {
      unavailableTimes.add({'date': DateTime.now(), 'time': TimeOfDay(hour: 9, minute: 0)});
    });
  }

  void _removeUnavailableTime(int index) {
    setState(() {
      unavailableTimes.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Color(0xFF8B2323)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Manage Reservations',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.save, color: Colors.green),
                    label: Text('Save', style: TextStyle(color: Colors.green)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.green),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking Time Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _timePickerButton(context, 'Start Time', startTime!, true),
                        Text('-', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        _timePickerButton(context, 'End Time', endTime!, false),
                      ],
                    ),
                    SizedBox(height: 15),
                    Text('Advance Booking Allowed:', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text('$advanceBookingDays days', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 20),
                    Divider(),
                    Text('Unavailable Booking Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _addUnavailableTime,
                      icon: Icon(Icons.add, color: Colors.black),
                      label: Text('Add Unavailable Time', style: TextStyle(fontSize: 16, color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: unavailableTimes.length,
                        itemBuilder: (context, index) {
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 2,
                            child: ListTile(
                              title: GestureDetector(
                                onTap: () => _selectDateTime(context, index),
                                child: Row(
                                  children: [
                                    Text(DateFormat.yMMMd().format(unavailableTimes[index]['date'])),
                                    SizedBox(width: 10),
                                    Text(unavailableTimes[index]['time'].format(context)),
                                  ],
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeUnavailableTime(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timePickerButton(BuildContext context, String label, TimeOfDay time, bool isStart) {
    return ElevatedButton(
      onPressed: () => _selectTime(context, isStart),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(time.format(context), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}