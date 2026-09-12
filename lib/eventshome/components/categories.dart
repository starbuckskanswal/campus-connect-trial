import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stephenscalender2024/constants.dart';
import 'package:stephenscalender2024/size_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Categories extends StatefulWidget {
  final ValueChanged<String> onSocietySelected;

  const Categories({Key? key, required this.onSocietySelected}) : super(key: key);

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  late Future<List<String>> _fetchCategories;
  int selectedIndex = 0;
  bool allOptionAdded = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories = fetchCategoriesFromPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.defaultSize! * 2),
      child: FutureBuilder<List<String>>(
        future: _fetchCategories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            List<String> categories = snapshot.data ?? [];
            if (!allOptionAdded) {
              categories.insert(0, 'All');
              allOptionAdded = true; // Update the flag
            }
            return SizedBox(
              height: SizeConfig.defaultSize! * 3.5,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) =>
                    buildCategoryItem(categories[index], index),
              ),
            );
          }
        },
      ),
    );
  }

  Widget buildCategoryItem(String category, int index) => GestureDetector(
    onTap: () {
      setState(() {
        selectedIndex = index;
      });
      String selectedSociety = index == 0 ? 'All' : category;
      widget.onSocietySelected(selectedSociety);
    },
    child: Container(
      alignment: Alignment.center,
      margin: EdgeInsets.only(left: SizeConfig.defaultSize! * 2),
      decoration: BoxDecoration(
          color: selectedIndex == index
              ? const Color(0xFFEFF3EE)
              : Colors.transparent,
          borderRadius:
          BorderRadius.circular(SizeConfig.defaultSize! * 1.6)),
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.defaultSize! * 1.1,
          vertical: SizeConfig.defaultSize! * 0.5),
      child: Text(
        category,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selectedIndex == index ? kPrimaryColor : Colors.black),
      ),
    ),
  );

  Future<List<String>> fetchCategoriesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = prefs.getStringList('societies');

    if (listJson == null) return [];

    final names = listJson.map((jsonStr) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return map['name']?.toString() ?? '';
      } catch (e) {
        print("Error decoding society entry: $e");
        return '';
      }
    })
        .where((name) => name.isNotEmpty)
        .toList();

    names.sort(); // Alphabetical sort

    return names;
  }

}


