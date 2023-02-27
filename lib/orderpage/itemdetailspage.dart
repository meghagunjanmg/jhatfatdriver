import 'package:driver/Themes/colors.dart';
import 'package:driver/baseurl/baseurl.dart';
import 'package:driver/beanmodel/Multistoreorder.dart';
import 'package:driver/beanmodel/orderbean.dart';
import 'package:flutter/material.dart';

class Itemdetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> dataLis = ModalRoute.of(context).settings.arguments;
    List<OrderDetail> orderDeatisSub = dataLis['itemDetails'];
    dynamic currency = dataLis['currency'];
    dynamic cart_id = dataLis['cart_id'];
    return Scaffold(
      body: Item(cart_id,orderDeatisSub,currency),
    );
  }
}



class Item extends StatefulWidget {
  List<OrderDetail> orderDeatisSub = [];
  dynamic currency;
  dynamic cart_id;

  Item(this.cart_id, this.orderDeatisSub, this.currency);

  @override
  ItemDetails createState() => ItemDetails(this.cart_id, this.orderDeatisSub, this.currency);
}

class ItemDetails extends State<Item>
    with SingleTickerProviderStateMixin {
  dynamic cart_id;
  List<OrderDetail> orderDeatisSub=[];
  dynamic currency;
  int indx=0;
  List<Tab> tabs = <Tab>[];
  TabController tabController;

  ItemDetails(this.cart_id,this.orderDeatisSub, this.currency);

  @override
  void initState() {
    super.initState();
    List<Tab> tabss = <Tab>[];

    setState(() {
      orderDeatisSub.forEach((element) {
        tabss.add(new Tab(text: element.vendorName));
      });
    });

    tabs.clear();
    tabs = tabss;
    tabController = TabController(length: tabs.length, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        setState(() {
          indx = tabController.index;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return
      DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            controller: tabController,
            onTap: (index){
              tabController.addListener(() {
                if (!tabController.indexIsChanging) {
                  setState(() {
                    indx = tabController.index;
                  });
                }
              });
            },
            tabs: tabs,
          ),
          title: Text("Orderdetails #"+cart_id),
        ),
        body:

        TabBarView(
          controller: tabController,

          children: tabs.map((Tab tab) {
            return  Container(
              padding: EdgeInsets.only(left: 4.0),
              color: kCardBackgroundColor,
              child: Column(
                children: <Widget>[
                  Container(
                    height: MediaQuery.of(context).size.height-200,
                    margin:EdgeInsets.all(10),
                    child:
                    ListView.builder(
                      itemCount: orderDeatisSub[indx].vendordetails.length,
                      itemBuilder: (context, ind) {
                        return
                          Card(
                            margin:EdgeInsets.all(10),
                            child: Container(
                              color: kWhiteColor,
                              margin:EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Image.network(
                                    '$imageBaseUrl${orderDeatisSub[indx]
                                        .vendordetails[ind]
                                        .varientImage}',
                                    height: 90.3,
                                    width: 90.3,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(bottom: 5),
                                            child: Text(
                                              '${orderDeatisSub[indx]
                                                  .vendordetails[ind]
                                                  .productName}',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: kMainTextColor,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(bottom: 5),
                                            child: Text(
                                              '${orderDeatisSub[indx]
                                                  .vendordetails[ind]
                                                  .description}',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: kMainTextColor,
                                                  fontWeight: FontWeight.w400),
                                            ),
                                          ),
                                          Text(
                                            '(${orderDeatisSub[indx]
                                                .vendordetails[ind]
                                                .quantity}${orderDeatisSub[indx]
                                                .vendordetails[ind]
                                                .unit} x ${orderDeatisSub[indx]
                                                .vendordetails[ind]
                                                .qty})',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: kMainTextColor,
                                                fontWeight: FontWeight.w300),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                      },
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

}
