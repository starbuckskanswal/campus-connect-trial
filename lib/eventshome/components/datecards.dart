import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stephenscalender2024/constants.dart';

class EventDateSelector extends StatefulWidget {
  final Function(DateTime?) onDateSelected;

  const EventDateSelector({Key? key, required this.onDateSelected}) : super(key: key);

  @override
  _EventDateSelectorState createState() => _EventDateSelectorState();
}

class _EventDateSelectorState extends State<EventDateSelector> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 31, // Number of days you want to show, including "All Days"
        itemBuilder: (context, index) {
          DateTime currentDate;
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                  widget.onDateSelected(null); // Reset selected date
                },
                child: Container(
                  width: 70.0,
                  decoration: BoxDecoration(
                    color: selectedIndex == 0 ? kPrimaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: selectedIndex == 0
                        ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      'All Days',
                      style: TextStyle(
                        color: selectedIndex == 0 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else {
            currentDate = DateTime.now().add(Duration(days: index - 1));
          }

          bool isSelected = index == selectedIndex;
          String dayName = DateFormat('EEE').format(currentDate);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
                widget.onDateSelected(currentDate); // Pass selected date
              },
              child: Container(
                width: 60.0, // Adjust the width according to your design
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1b263b) : Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayName, // Display day name (e.g., Mon, Tue, ...)
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      '${currentDate.day}/${currentDate.month}', // Display month/day
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


