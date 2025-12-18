import 'package:advent/data/advent_service.dart';
import 'package:flutter/material.dart';
import '../data/advent_model.dart';

class AdventViewModel extends ChangeNotifier {
  final AdventService _repository;

  Map<int, AdventDay> _days = {};
  Map<int, AdventDay> get days => _days;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AdventViewModel({required AdventService repository}) : _repository = repository {
    _init();
  }

  void _init() {
    _repository.getAdventDays().listen((daysList) {
      _days = {for (var item in daysList) item.dayNum: item};
      _isLoading = false;
      notifyListeners();
    });
  }

  bool isDayUnlocked(int dayNum) => _days.containsKey(dayNum);

  AdventDay? getDayData(int dayNum) => _days[dayNum];

  Future<void> markAsFound(String docId) async {
    await _repository.markAsFoundInCloud(docId);
  }
}