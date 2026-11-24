import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ConsultationTab extends StatelessWidget {
  const ConsultationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Center(child: const Text('Consultation')),
          // backgroundColor: AppColors.whiteGhost,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: Center(
          child:
          SizedBox(
            height: 140,
            child: Lottie.asset("assets/lottie/Consultation.json", repeat: true),
          ),
        ),);
  }
}


