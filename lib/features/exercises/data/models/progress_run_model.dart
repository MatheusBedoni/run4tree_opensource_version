import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'progress_run_model.g.dart';

@JsonSerializable()
class ProgressRun {
  int? id;
  int? duracao;
  String? date;
  String? temperature;

  @JsonKey(fromJson: _parseDouble, toJson: _doubleToString)
  double? km;

  bool? nigth;
  double? calories;
  int? tree;
  double? ritmo;
  double? velocidadeMedia;
  double? velocidadeMaxima;
  String? polyLine;

  ProgressRun({
    this.id,
    this.duracao = 0,
    this.date = '',
    this.temperature = '',
    this.km = 0,
    this.nigth = false,
    this.calories = 0,
    this.tree = 0,
    this.ritmo = 0,
    this.velocidadeMaxima = 0,
    this.velocidadeMedia = 0,
    this.polyLine,
  });

  List<LatLng>? getPolyLineData() {
    if (polyLine == null || polyLine!.isEmpty) return [];

    List<LatLng> polylineData = [];
    List<dynamic> list = jsonDecode(polyLine!);

    for (var element in list) {
      var lat = double.parse((element)[0].toString());
      var long = double.parse((element)[1].toString());

      polylineData.add(LatLng(lat, long));
    }

    return polylineData;
  }

  factory ProgressRun.fromJson(Map<String, dynamic> json) =>
      _$ProgressRunFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressRunToJson(this);

  static double? _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String? _doubleToString(double? value) {
    return value?.toString();
  }
}
