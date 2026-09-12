import 'package:flutter/material.dart';
import 'package:stephenscalender2024/constants.dart';
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.symmetric(vertical: size.height * .02),
      width: size.width * 0.8,
      child: const Row(
        children: [
          buildDivider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text("OR", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600),),
          ),
          buildDivider(),
        ],
      ),
    );
  }
}

class buildDivider extends StatelessWidget {
  const buildDivider({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Expanded(child: Divider(
      color: Color(0xFFD9D9D9),
      height: 1.5,
    ));
  }
}
