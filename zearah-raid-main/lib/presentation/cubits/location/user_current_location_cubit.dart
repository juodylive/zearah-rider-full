import 'dart:async';
import 'dart:convert';
 import 'package:zearah_rider/domain/entities/catrgory.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
 import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import '../../../core/services/geocoding_service.dart';
import '../../../core/extensions/workspace.dart' show navigatorKey;
import '../../../core/utils/common_widget.dart' show showErrorToastMessage;
import '../../../core/utils/translate.dart';

const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
const Map<String, String> nominatimHeaders = {
  'User-Agent': 'ZearahRiderApp/1.0 (contact@zearah.dpdns.org)'
};

abstract class LocationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationSucess extends LocationState {
  final LatLng? currentLocation;

  LocationSucess({
    this.currentLocation,
  });

  @override
  List<Object?> get props => [currentLocation];
}

// ignore: must_be_immutable
class LocationFailure extends LocationState {
  String? error;
  LocationFailure({this.error});
  @override
  List<Object?> get props => [error];
}

class LocationUserCubit extends Cubit<LocationState> {
  LocationUserCubit() : super(LocationInitial());
  late StreamSubscription<Position> positionStreamSubscription;
  var markers = <dynamic>{};

  void startLiveLocationTracking({bool? ischeckedLoading}) async {
    try {
      if (ischeckedLoading == true) {
        emit(LocationLoading());
      }

      LocationPermission permission = await _checkPermissions();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {

        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );

      updateUserLocation(position);


    } catch (e) {
      emit(LocationFailure(error: "$e"));

    }
  }

  Future<LocationPermission> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {

      return LocationPermission.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {

      }
    }

    if (permission == LocationPermission.deniedForever) {

    }

    return permission;
  }

  Timer? _debounceTimer; // Add a timer

  void updateUserLocation(Position position) {
    try {
      if (_debounceTimer?.isActive ?? false) {
        _debounceTimer!.cancel();
      }

      _debounceTimer = Timer(const Duration(seconds: 1), () {
        LatLng currentLocation = LatLng(position.latitude, position.longitude);
        emit(LocationSucess(currentLocation: currentLocation));
      });
    } catch (err) {
      emit(LocationFailure(error: "$err"));
    }
  }

  void removeState() {
    emit(LocationInitial());
  }
}

abstract class UpdateCurrentAddressState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UpdateCurrentAddresInitial extends UpdateCurrentAddressState {}

class UpdateCurrentAddressLoading extends UpdateCurrentAddressState {}

class UpdateCurrentAddressFailed extends UpdateCurrentAddressState {}

class UpdateCurrentAddresSuccess extends UpdateCurrentAddressState {
  final String? currentAddress;
  final double? lat;
  final double? lng;
  UpdateCurrentAddresSuccess({this.currentAddress, this.lat, this.lng});

  @override
  List<Object?> get props => [currentAddress, lat, lng];
}

class UpdateCurrentAddressCubit extends Cubit<UpdateCurrentAddressState> {
  UpdateCurrentAddressCubit() : super(UpdateCurrentAddresInitial());

  Future<void> getAddressFromLatLng(
      {double? latitude, double? longitude}) async {
    try {
      emit(UpdateCurrentAddressLoading());

      if (latitude != null && longitude != null) {
        String url =
            "$nominatimBaseUrl/reverse?format=json&lat=$latitude&lon=$longitude&accept-language=${GeocodingService.instance.language}";

        final response = await http.get(Uri.parse(url), headers: nominatimHeaders);

        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          if (data["display_name"] != null) {
            String address = data["display_name"];
            emit(UpdateCurrentAddresSuccess(
                currentAddress: address, lat: latitude, lng: longitude));
          } else {
            emit(UpdateCurrentAddressFailed());

          }
        } else {
          emit(UpdateCurrentAddressFailed());

        }
      }
    } catch (e) {
      emit(UpdateCurrentAddressFailed());

    }
  }

  void removeAddress() {
    emit(UpdateCurrentAddresInitial());
  }
}

abstract class UpdateSearchMapAddressState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UpdateSearchMapAddresInitial extends UpdateSearchMapAddressState {}

class UpdateSearchMapAddresSuccess extends UpdateSearchMapAddressState {
  final String? currentAddress;
  final double? lat;
  final double? lng;
  UpdateSearchMapAddresSuccess({this.currentAddress, this.lat, this.lng});

  @override
  List<Object?> get props => [currentAddress, lat, lng];
}

class UpdateSearchMapAddressCubit extends Cubit<UpdateSearchMapAddressState> {
  UpdateSearchMapAddressCubit() : super(UpdateSearchMapAddresInitial());

  Future<void> getAddressFromLatLng(
      {double? latitude, double? longitude}) async {
    try {
      if (latitude != null && longitude != null) {
        String url =
            "$nominatimBaseUrl/reverse?format=json&lat=$latitude&lon=$longitude&accept-language=${GeocodingService.instance.language}";

        final response = await http.get(Uri.parse(url), headers: nominatimHeaders);

        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          if (data["display_name"] != null) {
            String address = data["display_name"];
            emit(UpdateSearchMapAddresSuccess(
                currentAddress: address, lat: latitude, lng: longitude));
          } else {

          }
        } else {

        }
      }
    } catch (e) {
       //
    }
  }




  void removeAddress() {
    emit(UpdateSearchMapAddresInitial());
  }
}

class GetSuggestionAddressState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetSuggestionAddressSuccess extends GetSuggestionAddressState {
  final List<String>? suggestions;
  GetSuggestionAddressSuccess({this.suggestions});
  @override
  List<Object?> get props => [suggestions];
}

class GetSuggestionAddressCubit extends Cubit<GetSuggestionAddressState> {
  GetSuggestionAddressCubit() : super(GetSuggestionAddressState());

  // Incremented on every request/cancel so late responses are ignored.
  int _requestId = 0;
  DateTime _lastNotice = DateTime.fromMillisecondsSinceEpoch(0);

  void _emitEmpty() =>
      emit(GetSuggestionAddressSuccess(suggestions: const []));

  Future<void> getSuggestions(String query) async {
    final id = ++_requestId;
    final q = query.trim();

    if (q.length < GeocodingService.minChars) {
      _emitEmpty();
      return;
    }

    try {
      final places = await GeocodingService.instance.search(q);
      if (isClosed || id != _requestId) return; // stale response
      emit(GetSuggestionAddressSuccess(
          suggestions: places.map((p) => p.name).toList()));
    } on GeocodingRateLimited {
      if (isClosed || id != _requestId) return;
      _notifyRateLimited();
      _emitEmpty();
    } catch (_) {
      if (isClosed || id != _requestId) return;
      _emitEmpty();
    }
  }

  void _notifyRateLimited() {
    // Tell the user once per 20s instead of silently showing an empty list.
    if (DateTime.now().difference(_lastNotice) < const Duration(seconds: 20)) {
      return;
    }
    _lastNotice = DateTime.now();
    final ctx = navigatorKey.currentContext;
    const msg = 'Too many searches. Please wait a moment and try again.';
    showErrorToastMessage(ctx != null ? msg.translate(ctx) : msg);
  }

  void removeAddress() {
    _requestId++; // cancel any pending response
    _emitEmpty();
  }
}

class GetCordinatesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetCordinatesSuccess extends GetCordinatesState {
  final String? lattiude;
  final String? longitude;
  final String? address;

  GetCordinatesSuccess({this.lattiude, this.longitude, this.address});
  @override
  List<Object?> get props => [lattiude, longitude];
}

class GetCordinatesFailure extends GetCordinatesState {
  final String? error;

  GetCordinatesFailure({
    this.error,
  });
  @override
  List<Object?> get props => [error];
}

class GetCordinatesCubit extends Cubit<GetCordinatesState> {
  GetCordinatesCubit() : super(GetCordinatesState());

  Future<void> getCoordinates(
      {required String address, bool? checkStatus}) async {
    try {
      // Normally answered from the suggestion cache: no network request.
      final place = await GeocodingService.instance.resolve(address);
      if (place != null) {
        emit(GetCordinatesSuccess(
            lattiude: place.lat.toString(), longitude: place.lon.toString()));
      } else {
        emit(GetCordinatesFailure(error: "No results"));
      }
    } on GeocodingRateLimited {
      emit(GetCordinatesFailure(error: "Too many requests"));
    } catch (e) {
      emit(GetCordinatesFailure(error: "Exception: $e"));
    }
  }

  void removeCordinates() {
    emit(GetCordinatesSuccess(lattiude: "", longitude: ""));
  }
}

class SelectedAddressState extends Equatable {
  final String selectedPickupAddress;
  final String selectedDropOffAddress;
  final bool isCheckedSelectedPickup;
  final bool isCheckedSelectedDropOff;
  final bool icheckedCrossIconPickup;
  final bool ischeckedCrossIconDropOff;
  final bool ischeckedPickupSuggestion;
  final bool ischekcedDropOffSuggestion;

  const SelectedAddressState(
      {this.selectedPickupAddress = "",
      this.selectedDropOffAddress = "",
      this.ischeckedPickupSuggestion = false,
      this.ischekcedDropOffSuggestion = false,
      this.icheckedCrossIconPickup = false,
      this.ischeckedCrossIconDropOff = false,
      this.isCheckedSelectedDropOff = false,
      this.isCheckedSelectedPickup = false});

  SelectedAddressState copyWith(
      {String? selectedPickupAddress,
      String? selectedDropOffAddress,
      bool? isCheckedSelectedDropOff,
      bool? ischeckedPickupSuggestion,
      bool? ischekcedDropOffSuggestion,
      bool? isCheckedSelectedPickup,
      bool? icheckedCrossIconPickup,
      bool? ischeckedCrossIconDropOff}) {
    return SelectedAddressState(
        ischeckedPickupSuggestion:
            ischeckedPickupSuggestion ?? this.ischeckedPickupSuggestion,
        ischekcedDropOffSuggestion:
            ischekcedDropOffSuggestion ?? this.ischekcedDropOffSuggestion,
        ischeckedCrossIconDropOff:
            ischeckedCrossIconDropOff ?? this.ischeckedCrossIconDropOff,
        icheckedCrossIconPickup:
            icheckedCrossIconPickup ?? this.icheckedCrossIconPickup,
        isCheckedSelectedDropOff:
            isCheckedSelectedDropOff ?? this.isCheckedSelectedDropOff,
        isCheckedSelectedPickup:
            isCheckedSelectedPickup ?? this.isCheckedSelectedPickup,
        selectedPickupAddress:
            selectedPickupAddress ?? this.selectedPickupAddress,
        selectedDropOffAddress:
            selectedDropOffAddress ?? this.selectedDropOffAddress);
  }

  @override
  List<Object?> get props => [
        selectedPickupAddress,
        selectedDropOffAddress,
        isCheckedSelectedDropOff,
        isCheckedSelectedPickup,
        ischeckedCrossIconDropOff,
        icheckedCrossIconPickup,
        ischeckedPickupSuggestion,
        ischekcedDropOffSuggestion
      ];
}

class SelectedAddressCubit extends Cubit<SelectedAddressState> {
  SelectedAddressCubit() : super(const SelectedAddressState());

  final TextEditingController pickupAddressController = TextEditingController();
  final TextEditingController dropOffAddressController =
      TextEditingController();

  void updateSelectePickupdSuggestion({
    bool? ischeckedPickupSuggestion,
  }) {
    emit(state.copyWith(
      ischeckedPickupSuggestion: ischeckedPickupSuggestion,
    ));
  }

  void updateSelecteDropOffdSuggestion({
    bool? ischekcedDropOffSuggestion,
  }) {
    emit(state.copyWith(
      ischekcedDropOffSuggestion: ischekcedDropOffSuggestion,
    ));
  }

  void removeSelectePickupdSuggestion() {
    emit(state.copyWith(ischeckedPickupSuggestion: false));
  }

  void removeSelecteDropOffdSuggestion() {
    emit(state.copyWith(
      ischekcedDropOffSuggestion: false,
    ));
  }

  void updateSelectePickupdAddress({
    String? selectedPickupAddress,
  }) {
    emit(state.copyWith(
      selectedPickupAddress: selectedPickupAddress,
    ));
  }

  void updateSelecteDropOffdAddress({
    String? selectedDropOffAddress,
  }) {
    emit(state.copyWith(
      selectedDropOffAddress: selectedDropOffAddress,
    ));
  }

  void updateIsSelectePickupdAddress({
    bool? isCheckedSelectedPickup,
  }) {
    emit(state.copyWith(
      isCheckedSelectedPickup: isCheckedSelectedPickup,
    ));
  }

  void updateIsSelectedDropOffAddress({
    bool? isCheckedSelectedDropOff,
  }) {
    emit(state.copyWith(
      isCheckedSelectedDropOff: isCheckedSelectedDropOff,
    ));
  }

  void updateIsCrossIconSelectePickup({
    bool? icheckedCrossIconPickup,
  }) {
    emit(state.copyWith(
      icheckedCrossIconPickup: icheckedCrossIconPickup,
    ));
  }

  void updateIsCrossIconSelectedDropOff({
    bool? ischeckedCrossIconDropOff,
  }) {
    emit(state.copyWith(
      ischeckedCrossIconDropOff: ischeckedCrossIconDropOff,
    ));
  }

  void removeIsCrossIconSelectePickupd() {
    emit(const SelectedAddressState(icheckedCrossIconPickup: false));
  }

  void removeIsCrosssIconSelectedDropOff() {
    emit(const SelectedAddressState(ischeckedCrossIconDropOff: false));
  }

  void removeIsSelectePickupdAddress() {
    emit(const SelectedAddressState(isCheckedSelectedPickup: false));
  }

  void removeIsSelectedDropOffAddress() {
    emit(const SelectedAddressState(isCheckedSelectedDropOff: false));
  }

  void removeSelectedPickupAddress() {
    emit(const SelectedAddressState(selectedPickupAddress: ""));
  }

  void removeSelectedDropOffAddress() {
    emit(const SelectedAddressState(selectedDropOffAddress: ""));
  }

  void resetAllParameter() {
    emit(const SelectedAddressState());
  }
}

class SetVehicleCategoryState extends Equatable {
  final List<ItemTypes> itemList;

  const SetVehicleCategoryState({this.itemList = const []});

  SetVehicleCategoryState copyWith({List<ItemTypes>? itemList}) {
    return SetVehicleCategoryState(
      itemList: itemList ?? this.itemList,
    );
  }


  bool shouldRebuild(SetVehicleCategoryState previousState) {
    return itemList != previousState.itemList;
  }

  @override
  List<Object?> get props => [itemList];
}

class SetVehicleCategoryCubit extends Cubit<SetVehicleCategoryState> {
  SetVehicleCategoryCubit() : super(const SetVehicleCategoryState());

  void updateSetVehicleCategoryList(List<ItemTypes>? itemList) {
    emit(state.copyWith(
      itemList: itemList,
    ));
  }

  void resetState() {
    emit(const SetVehicleCategoryState());
  }
}




