import 'dart:convert';
import 'dart:math';

import 'package:driver/Components/bottom_bar.dart';
import 'package:driver/Routes/routes.dart';
import 'package:driver/Themes/colors.dart';
import 'package:driver/Themes/style.dart';
import 'package:driver/baseurl/baseurl.dart';
import 'package:driver/parcel/parcelbean/orderdetailpageparcel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:progress_dialog/progress_dialog.dart';
import 'package:toast/toast.dart';

class NewDeliveryParcelPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NewDeliveryParcelBody();
  }
}

class NewDeliveryParcelBody extends StatefulWidget {
  @override
  _NewDeliveryParcelBodyState createState() => _NewDeliveryParcelBodyState();
}

class _NewDeliveryParcelBodyState extends State<NewDeliveryParcelBody> {
  dynamic cart_id = '';
  dynamic vendorName = '';
  dynamic vendorAddress = '';
  dynamic vendorDistance = '';
  dynamic userName = '';
  dynamic userAddress = '';
  dynamic userphone;
  dynamic vendorlat;
  dynamic vendorlng;
  dynamic dlat;
  dynamic dlng;
  dynamic userlat;
  dynamic userlng;
  dynamic remprice;
  dynamic paymentstatus;
  dynamic paymentMethod;
  dynamic user_id;
  TodayOrderParcel orderDeatisSub;
  dynamic distance;

  GoogleMapController _controller;
  List<LatLng> polylineCoordinates = [];
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  bool _added = false;


  @override
  void initState() {
    super.initState();
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

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
      cart_id = dataObject['cart_id'];
      vendorName = dataObject['vendorName'];
      vendorAddress = dataObject['vendorAddress'];
      userName = dataObject['userName'];
      userAddress = dataObject['userAddress'];
      userphone = dataObject['userphone'];
      vendorlat = dataObject['vendorlat'];
      vendorlng = dataObject['vendorlng'];
      userlat = dataObject['userlat'];
      userlng = dataObject['userlng'];
      remprice = dataObject['remprice'];
      paymentstatus = dataObject['paymentstatus'];
      paymentMethod = dataObject['paymentMethod'];
      user_id = dataObject['user_id'];
      orderDeatisSub = dataObject['itemDetails'];
          distance = calculateDistance(
              double.parse(vendorlat), double.parse(vendorlng), double.parse(userlat), double.parse(userlng))
          .toStringAsFixed(2);
    });

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: AppBar(
            automaticallyImplyLeading: true,
            title: Text('New Order - #${cart_id}',
                style: Theme.of(context)
                    .textTheme
                    .headline4
                    .copyWith(fontWeight: FontWeight.w500)),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
       child:
       GoogleMap(
        mapType: MapType.normal,
        markers: Set<Marker>.of(markers.values),
        polylines: Set<Polyline>.of(polylines.values),
        initialCameraPosition: CameraPosition(
            target: LatLng(double.parse(vendorlat),double.parse(vendorlng)),
            zoom: 14),
        onMapCreated: (GoogleMapController controller) async {
          _addMarker(LatLng(double.parse(vendorlat), double.parse(vendorlng)), "source", BitmapDescriptor.defaultMarkerWithHue(90));
          _addMarker(LatLng(double.parse(userlat), double.parse(userlng)), "dest", BitmapDescriptor.defaultMarkerWithHue(90));
          getDirections();

          setState(() {
            _controller = controller;
          });


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
                          '${vendorName}',
                          style: orderMapAppBarTextStyle.copyWith(
                              letterSpacing: 0.07),
                        ),
                        subtitle: Row(
                          children: <Widget>[
                            Text(
                              // '${distanceBetween(double.parse(vendorlat), double.parse(vendorlng), dlat,dlng).toStringAsFixed(2)} km',
                              '${distance} km',
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
                    )
                  ],
                ),
                Divider(
                  color: kCardBackgroundColor,
                  thickness: 1.0,
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.only(left: 20, top: 5, bottom: 5),
                  child: Text('Vendor Address',
                      style: Theme.of(context).textTheme.caption.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.06,
                          color: kMainColor)),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20.0, left: 20),
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
                              '${vendorName}',
                              style: orderMapAppBarTextStyle.copyWith(
                                  fontSize: 10.0, letterSpacing: 0.05),
                            ),
                            SizedBox(
                              height: 5.0,
                            ),
                            Text(
                              '${vendorAddress}',
                              style: Theme.of(context)
                                  .textTheme
                                  .caption
                                  .copyWith(
                                      fontSize: 11.7,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.06,
                                      color: Color(0xff393939)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: kCardBackgroundColor,
                  thickness: 1.0,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20.0, left: 20),
                  child: Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding:
                            const EdgeInsets.only(left: 5, top: 5, bottom: 5),
                        child: Text('Pickup Address',
                            style: Theme.of(context).textTheme.caption.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.06,
                                color: kMainColor)),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                            fontSize: 11.7,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.06,
                                            color: Color(0xff393939))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding:
                            const EdgeInsets.only(left: 5, top: 5, bottom: 5),
                        child: Text('Destination Address',
                            style: Theme.of(context).textTheme.caption.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.06,
                                color: kMainColor)),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                            fontSize: 11.7,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.06,
                                            color: Color(0xff393939))),
                              ],
                            ),
                          ),
                        ],
                      )
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
                    text: "Accept Delivery",
                    onTap: () {
                      pr.show();
                      hitServiceRest(cart_id, pr);
                    } // Navigator.popAndPushNamed(context, PageRoutes.acceptedPage),
                    ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void hitServiceRest(cartid, ProgressDialog pr) async {


      var url = parcel_delivery_accepted_by_dboy;
      var client = http.Client();
      client.post(url, body: {'cart_id': '${cartid}'}).then((value) {
        if (value.statusCode == 200) {
          var jsonData = jsonDecode(value.body);
          if (jsonData['status'] == "1") {
            pr.hide();
            Toast.show('Order Accepted', context,
                duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
            Navigator.popAndPushNamed(context, PageRoutes.parcelacceptpage,
                arguments: {
                  "cart_id": cart_id,
                  "vendorName": vendorName,
                  "vendorAddress": vendorAddress,
                  "vendorlat": vendorlat,
                  "vendorlng": vendorlng,
                  "dlat": dlat,
                  "dlng": dlng,
                  "userlat": userlat,
                  "userlng": userlng,
                  "userName": userName,
                  "userAddress": userAddress,
                  "userphone": userphone,
                  "itemDetails": orderDeatisSub,
                  "remprice": remprice,
                  "paymentstatus": paymentstatus,
                  "paymentMethod": paymentMethod,
                  "user_id": user_id,
                  "ui_type": "4",
                });          } else {
            pr.hide();
            Toast.show('Order Not Accepted', context,
                duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
          }
        }
      }).catchError((e) {
        pr.hide();
        print(e);
      });
     }




  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker =
    Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
  }

  getDirections() async {
    List<LatLng> polylineCoordinates = [];
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
     apikey,
      PointLatLng(double.parse(vendorlat), double.parse(vendorlng)),
      PointLatLng(double.parse(userlat), double.parse(userlng)),
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

