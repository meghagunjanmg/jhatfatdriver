import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/baseurl/baseurl.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:driver/Components/bottom_bar.dart';
import 'package:driver/Routes/routes.dart';
import 'package:driver/Themes/colors.dart';
import 'package:driver/Themes/style.dart';
import 'package:driver/parcel/parcelbean/orderdetailpageparcel.dart';
import 'package:driver/parcel/slideupdetails.dart';
import 'package:flutter/material.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OnWayPageParcel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OnWayBodyParcel();
  }
}

class OnWayBodyParcel extends StatefulWidget {
  @override
  _OnWayBodyParcelState createState() => _OnWayBodyParcelState();
}

class _OnWayBodyParcelState extends State<OnWayBodyParcel> {
  TodayOrderParcel orderDeatisSub;
  dynamic userlat;
  dynamic userlng;
  dynamic vendorlat;
  dynamic vendorlng;
  dynamic distance;
  dynamic currency;
  dynamic user_id;
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData> _locationSubscription;
  GoogleMapController _controller;
  List<LatLng> polylineCoordinates = [];
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  bool _added = false;

  double latitude;

  double longitude;



  @override
  void initState() {
    getCurrency();
    _getLocation();
    _listenLocation();
    getDirections();
    super.initState();
  }
  @override
  Future<void> dispose() async {
    super.dispose();

  }

  getCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currency = prefs.getString('curency');
    });
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    final ProgressDialog pr = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false, showLogs: true);
    pr.style(
        message: 'Loading please wait...',
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: CircularProgressIndicator(),
        elevation: 10.0,
        insetAnimCurve: Curves.easeInOut,
        progress: 0.0,
        maxProgress: 100.0,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        progressTextStyle: TextStyle(
            color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600));
    final Map<String, Object> dataObject =
        ModalRoute.of(context).settings.arguments;
    setState(() {
      orderDeatisSub = dataObject['itemDetails'];
      userlat = dataObject['userlat'];
      userlng = dataObject['userlng'];
      vendorlat = dataObject['vendorlat'];
      vendorlng = dataObject['vendorlng'];
      user_id = dataObject['user_id'];
      distance = calculateDistance(
              double.parse(orderDeatisSub.source_lat), double.parse(orderDeatisSub.source_lng), double.parse(orderDeatisSub.destination_lat), double.parse(orderDeatisSub.destination_lng))
          .toStringAsFixed(2);
    });

    return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.0),
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: AppBar(
              automaticallyImplyLeading: true,
              title: Text('Order - #${orderDeatisSub.cart_id}',
                  style: Theme.of(context)
                      .textTheme
                      .headline4
                      .copyWith(fontWeight: FontWeight.w500)),
              actions: <Widget>[
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                  child: FlatButton.icon(
                    icon: Icon(
                      isOpen ? Icons.close : Icons.shopping_basket,
                      color: kMainColor,
                      size: 13.0,
                    ),
                    label: Text(isOpen ? 'Close' : 'Order Info',
                        style: Theme.of(context).textTheme.caption.copyWith(
                              fontSize: 11.7,
                              fontWeight: FontWeight.bold,
                            )),
                    onPressed: () {
                      setState(() {
                        if (isOpen)
                          isOpen = false;
                        else
                          isOpen = true;
                      });
                    },
                  ),
                )
              ],
            ),
          ),
        ),
        body: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Expanded(
                  child:
                  StreamBuilder(
                    stream: FirebaseFirestore.instance.collection('location').snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (_added) {
                        if(snapshot.data.docs.length > 0) {
                          mymap(snapshot);
                          latitude = snapshot.data.docs.singleWhere(
                                  (element) =>
                              element.id == user_id.toString())['latitude'];
                          longitude = snapshot.data.docs.singleWhere(
                                  (element) =>
                              element.id == user_id.toString())['longitude'];

                          getDirections();
                        }
                        else{
                          latitude = double.parse(orderDeatisSub.source_lat);
                          longitude = double.parse(orderDeatisSub.source_lng);
                        }
                      }

                      else if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }


                      return GoogleMap(
                        mapType: MapType.normal,
                        markers: Set<Marker>.of(markers.values),
                        polylines: Set<Polyline>.of(polylines.values),
                        initialCameraPosition: CameraPosition(
                            target: LatLng(
                              latitude,
                              longitude,
                            ),
                            zoom: 12),
                        onMapCreated: (GoogleMapController controller) async {
                          setState(() {
                            _controller = controller;
                            _added = true;
                          });
                          getDirections();
                        },
                      );
                    },
                  ),

                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 16.3),
                            child: Image.asset(
                              'images/vegetables_fruitsact.png',
                              height: 42.3,
                              width: 33.7,
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: Text(
                                '${orderDeatisSub.vendor_name}',
                                style: orderMapAppBarTextStyle.copyWith(
                                    letterSpacing: 0.07),
                              ),
                              subtitle: Row(
                                children: <Widget>[
                                  Text(
                                    '${distance} km ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline6
                                        .copyWith(
                                            fontSize: 11.7,
                                            letterSpacing: 0.06,
                                            color: kMainColor,
                                            fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 20.0),
                            child: FlatButton(
                              onPressed: () {
                                _getDirection(
                                    'https://www.google.com/maps/search/?api=1&query=${orderDeatisSub.destination_lat},${orderDeatisSub.destination_lng}');
                              },
                              color: kMainColor,
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.navigation,
                                    color: kWhiteColor,
                                    size: 14.0,
                                  ),
                                  SizedBox(
                                    width: 4.0,
                                  ),
                                  Text(
                                    'Direction',
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption
                                        .copyWith(
                                            color: kWhiteColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.7,
                                            letterSpacing: 0.06),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(
                        color: kCardBackgroundColor,
                        thickness: 1.0,
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding:
                            const EdgeInsets.only(left: 20, top: 5, bottom: 5),
                        child: Text('Vendor Address',
                            style: Theme.of(context).textTheme.caption.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.06,
                                color: kMainColor)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0, left: 20),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.location_city,
                              size: 30,
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '${orderDeatisSub.vendor_name}',
                                    style: orderMapAppBarTextStyle.copyWith(
                                        fontSize: 10.0, letterSpacing: 0.05),
                                  ),
                                  SizedBox(
                                    height: 5.0,
                                  ),
                                  Text(
                                    '${orderDeatisSub.vendor_loc}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption
                                        .copyWith(
                                            fontSize: 10.0,
                                            letterSpacing: 0.05),
                                  ),
                                ],
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.fill,
                              child: Row(
                                children: <Widget>[
                                  IconButton(
                                    icon: Icon(
                                      Icons.phone,
                                      color: kMainColor,
                                      size: 15.0,
                                    ),
                                    onPressed: () {
                                      _launchURL(
                                          "tel://${orderDeatisSub.vendor_phone}");
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 5.0,
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding:
                            const EdgeInsets.only(left: 20, top: 5, bottom: 5),
                        child: Text('Pickup Address',
                            style: Theme.of(context).textTheme.caption.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.06,
                                color: kMainColor)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0, left: 20),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.location_city,
                              size: 30,
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '${orderDeatisSub.source_name}',
                                    style: orderMapAppBarTextStyle.copyWith(
                                        fontSize: 10.0, letterSpacing: 0.05),
                                  ),
                                  SizedBox(
                                    height: 5.0,
                                  ),
                                  Text(
                                    '${orderDeatisSub.source_add}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption
                                        .copyWith(
                                            fontSize: 10.5,
                                            letterSpacing: 0.05),
                                  ),
                                ],
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.fill,
                              child: Row(
                                children: <Widget>[
                                  IconButton(
                                    icon: Icon(
                                      Icons.phone,
                                      color: kMainColor,
                                      size: 15.0,
                                    ),
                                    onPressed: () {
                                      _launchURL(
                                          "tel://${orderDeatisSub.source_phone}");
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding:
                            const EdgeInsets.only(left: 20, top: 5, bottom: 5),
                        child: Text('Destination Address',
                            style: Theme.of(context).textTheme.caption.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.06,
                                color: kMainColor)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0, left: 20),
                        child: Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Icon(
                              Icons.location_city,
                              size: 30,
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '${orderDeatisSub.destination_name}',
                                    style: orderMapAppBarTextStyle.copyWith(
                                        fontSize: 10.0, letterSpacing: 0.05),
                                  ),
                                  SizedBox(
                                    height: 5.0,
                                  ),
                                  Text(
                                    '${orderDeatisSub.destination_add}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption
                                        .copyWith(
                                            fontSize: 10.5,
                                            letterSpacing: 0.05),
                                  ),
                                ],
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.fill,
                              child: Row(
                                children: <Widget>[
                                  IconButton(
                                    icon: Icon(
                                      Icons.phone,
                                      color: kMainColor,
                                      size: 15.0,
                                    ),
                                    onPressed: () {
                                      _launchURL(
                                          "tel://${orderDeatisSub.destination_phone}");
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Divider(
                        color: kCardBackgroundColor,
                        thickness: 6.0,
                      ),
                      BottomBar(
                          text: "Mark as Delivered",
                          onTap: () async {
                            await FirebaseFirestore.instance.collection('location').doc(user_id.toString()).delete();
                            _locationSubscription.cancel();
                            Navigator.popAndPushNamed(
                                context, PageRoutes.signatureView,
                                arguments: {
                                  "cart_id": orderDeatisSub.cart_id,
                                  "vendorName": orderDeatisSub.vendor_name,
                                  "vendorAddress": orderDeatisSub.vendor_loc,
                                  "vendor_phone": orderDeatisSub.vendor_phone,
                                  "dlat": '',
                                  "dlng": '',
                                  "vendorlat": orderDeatisSub.lat,
                                  "vendorlng": orderDeatisSub.lng,
                                  "userlat": userlat,
                                  "userlng": userlng,
                                  "userName": orderDeatisSub.user_name,
                                  "userAddress":
                                      '${orderDeatisSub.source_houseno}${orderDeatisSub.source_add}${orderDeatisSub.source_landmark}${orderDeatisSub.source_city}${orderDeatisSub.source_state}(${orderDeatisSub.source_pincode})',
                                  "userphone": orderDeatisSub.user_phone,
                                  // "itemDetails": orderDeatisSub,
                                  "remprice":
                                      '${(double.parse('${double.parse('${orderDeatisSub.distance}').toStringAsFixed(2)}') > 1) ? (double.parse('${orderDeatisSub.charges}') * double.parse('${double.parse('${orderDeatisSub.distance}').toStringAsFixed(2)}')) : double.parse('${orderDeatisSub.charges}')}',
                                  "paymentstatus":
                                      orderDeatisSub.payment_status,
                                  "paymentMethod":
                                      orderDeatisSub.payment_method,
                                  "ui_type": "4",
                                  // "addons":addons
                                });
                          }),
                    ],
                  ),
                )
              ],
            ),
            isOpen
                ? OrderInfoContainerParcel(
                    orderDeatisSub,
                    ('${(double.parse('${double.parse('${orderDeatisSub.distance}').toStringAsFixed(2)}') > 1) ? (double.parse('${orderDeatisSub.charges}') * double.parse('${double.parse('${orderDeatisSub.distance}').toStringAsFixed(2)}')) : double.parse('${orderDeatisSub.charges}')}'),
                    orderDeatisSub.payment_method,
                    orderDeatisSub.payment_status,
                    currency)
                : SizedBox.shrink(),
          ],
        ));
  }

  _launchURL(url) async {
  try {
  launch(url);
} catch (error, stack) {
  // log error
}
  }

  _getDirection(url) async {
  try {
  launch(url);
} catch (error, stack) {
  // log error
}
  }


  _getLocation() async {
    try {
      final loc.LocationData _locationResult = await location.getLocation();
      await FirebaseFirestore.instance.collection('location').doc(user_id.toString()).set({
        'latitude': _locationResult.latitude,
        'longitude': _locationResult.longitude,
        'name': 'john'
      }, SetOptions(merge: true));
      latitude = _locationResult.latitude;
      longitude = _locationResult.longitude;
    } catch (e) {
      print(e);
    }
  }


  Future<void> _listenLocation() async {
    _locationSubscription = location.onLocationChanged.handleError((onError) {
      print(onError);
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((loc.LocationData currentlocation) async {
      await FirebaseFirestore.instance.collection('location').doc(user_id.toString()).set({
        'latitude': currentlocation.latitude,
        'longitude': currentlocation.longitude,
        'name': 'john'
      }, SetOptions(merge: true));
      latitude = currentlocation.latitude;
      longitude = currentlocation.longitude;
    });

  }

  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker =
    Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
  }

  Future<void> mymap(AsyncSnapshot<QuerySnapshot> snapshot) async {
    Timer(Duration(minutes: 120), () async {
      await _controller
          .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(
            snapshot.data.docs.singleWhere(
                    (element) => element.id == user_id)['latitude'],
            snapshot.data.docs.singleWhere(
                    (element) => element.id == user_id)['longitude'],
          ),
          zoom: 12)));
    });
    _addMarker(LatLng(latitude, longitude), "source", BitmapDescriptor.defaultMarkerWithHue(90));
    _addMarker(LatLng(double.parse(orderDeatisSub.destination_lat), double.parse(orderDeatisSub.destination_lng)), "dest", BitmapDescriptor.defaultMarkerWithHue(90));
  }


  getDirections() async {
    List<LatLng> polylineCoordinates = [];
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
     apikey,
      PointLatLng(latitude, longitude),
      PointLatLng(double.parse(orderDeatisSub.destination_lat), double.parse(orderDeatisSub.destination_lng)),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }
    addPolyLine(polylineCoordinates);
  }

  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: kMainColor,
      points: polylineCoordinates,
      width: 5,
    );
    polylines[id] = polyline;
    setState(() {});
  }

}
