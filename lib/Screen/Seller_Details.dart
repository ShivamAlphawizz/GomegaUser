import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:eshop_multivendor/Helper/ApiBaseHelper.dart';
import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:eshop_multivendor/Helper/Constant.dart';
import 'package:eshop_multivendor/Helper/Session.dart';
import 'package:eshop_multivendor/Model/TableListModel.dart';
import 'package:eshop_multivendor/Model/TodaySpecialModel.dart';
import 'package:eshop_multivendor/Provider/CategoryProvider.dart';
import 'package:eshop_multivendor/Screen/ProductList.dart';
import 'package:eshop_multivendor/Screen/QrcodeScanner.dart';
import 'package:eshop_multivendor/Screen/testPage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Helper/String.dart';
import '../Model/Section_Model.dart';
import '../Provider/HomeProvider.dart';
import 'package:http/http.dart' as http;

class SellerProfile extends StatefulWidget {
  final String? sellerID,
      sellerName,
      sellerImage,
      sellerRating,
      title,
      storeDesc,
      todaySpecial,
  todayCategory,
      storeQR,
  address,
      sellerStoreName,
      subCatId,
      estimatedTime,
      foodPerson,
      storerating;
  final sellerData;
  final search;
  final extraData;

  SellerProfile(
      {Key? key,
      this.sellerID,
      this.storerating,
      this.estimatedTime,
      this.sellerName,
      this.address,
      this.todaySpecial,
      this.sellerImage,
      this.title,
      this.storeQR,
      this.foodPerson,
      this.sellerRating,
      this.todayCategory,
      this.storeDesc,
      this.sellerStoreName,
      this.subCatId,
      this.sellerData,
      this.search,
      this.extraData})
      : super(key: key);

  @override
  State<SellerProfile> createState() => _SellerProfileState();
}

class _SellerProfileState extends State<SellerProfile>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  ApiBaseHelper apiBaseHelper = ApiBaseHelper();
  late TabController _tabController;
  bool _isNetworkAvail = true;
  bool isDescriptionVisible = false;

  String? selectedTable;

  TableListModel? tableListModel;

  getTableList()async{
    print("user id here ${CUR_USERID}");
    var headers = {
      'Cookie': 'ci_session=b8ca418c0e288a514e96d316f7c838bc2dd722af'
    };
    var request = http.MultipartRequest('POST', Uri.parse('${baseUrl}get_table_data'));
    request.fields.addAll({
      'seller_id': '${widget.sellerID}',
      "user_id":"${CUR_USERID}"
    });
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var finalResult = await response.stream.bytesToString();
      final jsonResponse = TableListModel.fromJson(json.decode(finalResult));
      print("checking final json response ${jsonResponse}");
      setState(() {
        tableListModel = jsonResponse;
      });
    }
    else {
      print(response.reasonPhrase);
    }
  }
  SharedPreferences? prefs;

  bool mealStatus = false;
  getSharedData()async{
    prefs = await SharedPreferences.getInstance();
    mealStatus = prefs!.getBool('isTakeAway')!;
  }

  @override
  void initState() {
    super.initState();
    print("this is seller ID @@ ${widget.sellerID}");
    _tabController = TabController(vsync: this, length: 2);
    Future.delayed(Duration(seconds: 2),(){
      return showCustomDialog();
    });
    Future.delayed(Duration(milliseconds: 500),(){
      return getTableNo();
    });
    Future.delayed(Duration(seconds: 1),(){
      return getCat();
    });

    getTableList();
    getTodySpecialCategory();
  }

  showCustomDialog(){
    return showDialog(
        barrierDismissible: false,
        context: context, builder: (context){
      return AlertDialog(
        // titlePadding: EdgeInsets.only(bottom: 0),
        // title: Align(
        //     alignment: Alignment.topRight,
        //     child: Icon(Icons.clear)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Where you want to enjoy your food",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w600,fontSize: 15),),
            SizedBox(height: 10,),
            InkWell(
              onTap: ()async{
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setBool('isTakeAway', true);
                getSharedData();
                setState(() {
                  Navigator.pop(context);
                });
              },
              child: Container(
                height: 45,
                child: Row(
                  children: [
                    Icon(Icons.delivery_dining,size: 20,),
                    SizedBox(width: 8,),
                    Text("Take away",style: TextStyle(color: Colors.black,fontSize: 16,fontWeight: FontWeight.w600),),
                  ],
                ),
              ),
            ),

            SizedBox(height: 8,),
            InkWell(
              onTap: ()async{
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setBool('isTakeAway', false);
                getSharedData();
                setState(() {
                  Navigator.pop(context);
                });
              },
              child: Container(
                height: 45,
                child: Row(
                  children: [
                    Icon(Icons.restaurant,size: 20,),
                    SizedBox(width: 8,),
                    Text("Dine In",style: TextStyle(color: Colors.black,fontSize: 16,fontWeight: FontWeight.w600),),
                  ],
                ),
              ),
            ),
          ],
        ),);
    });
  }
  List<Product> catList = [];
  List<Product> popularList = [];
  void getCat() {
    Map parameter = {
      CAT_FILTER: "false",
      "seller_id":"${widget.sellerID}"
    };
    print("get cat api ${getCatApi}");
    print("${parameter}");
    apiBaseHelper.postAPICall(getCatApi, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        print("api working here");
        var data = getdata["data"];
        catList =
            (data as List).map((data) => new Product.fromCat(data)).toList();

        if (getdata.containsKey("popular_categories")) {
          var data = getdata["popular_categories"];
          popularList =
              (data as List).map((data) => new Product.fromCat(data)).toList();

          if (popularList.length > 0) {
            Product pop =
            new Product.popular("Popular", imagePath + "popular.svg");
            catList.insert(0, pop);
           // context.read<CategoryProvider>().setSubList(popularList);
          }
        }
      } else {
       // setSnackbar(msg!, context);
      }

      context.read<HomeProvider>().setCatLoading(false);
    }, onError: (error) {
    //  setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setCatLoading(false);
    });
  }

  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');


  getTodySpecialCategory()async{
    var headers = {
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NzEyNjIxOTQsImlhdCI6MTY3MTI2MTg5NCwiaXNzIjoiZXNob3AifQ.M8LsdbHrK0Pw3nRrgGvnDrPW5p0lEDS0lsLP6DEWvbQ',
      'Cookie': 'ci_session=a316cbb6222497b2a67c267376b0ba7b9bb8c124'
    };
    var request = http.MultipartRequest('POST', Uri.parse('${baseUrl}get_product_today_special'));
    request.fields.addAll({
      'category_id': '${widget.todayCategory}',
      'seller_id': '${widget.sellerID}'
    });
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var finalResult = await response.stream.bytesToString();
      final jsonResponse = TodaySpecialModel.fromJson(json.decode(finalResult));
      print("final json response here ${jsonResponse} and ${jsonResponse.data}");
    }
    else {
      print(response.reasonPhrase);
    }
  }
  
  String tableValue = '';
  getTableNo()async{
    var headers = {
      'Cookie': 'ci_session=0338422c7113c71e82fe660c9efd595dcbb58528'
    };
    var request = http.MultipartRequest('POST', Uri.parse('${baseUrl}last_orders'));
    request.fields.addAll({
      'user_id': '${CUR_USERID}'
    });
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var finalResult = await response.stream.bytesToString();
      final jsonResponse = json.decode(finalResult);
      print("checking final result  and ${jsonResponse['data'][0]['table_no']}");
      setState(() {
        tableValue = jsonResponse['data'][0]['table_no'].toString();
      });
    }
    else {
      print(response.reasonPhrase);
    }

  }


  callWaiter(String tableId)async{
    SharedPreferences prefs = await SharedPreferences.getInstance();

    print("checking seller id here ${widget.sellerID}");
    var headers = {
      'Cookie': 'ci_session=04b2584859e8aa1ecc07660cd52a307f83b37c01'
    };
    var request = http.MultipartRequest('POST', Uri.parse('${baseUrl}call_water_request'));
    request.fields.addAll({
      'seller_id': '${widget.sellerID}',
      'table_no': '${tableId}'
    });
    print("paras ${request.fields}");
    print('${baseUrl}call_water_request');
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    print("waiter res ${response.statusCode}");
    if (response.statusCode == 200) {
      var finalResponse = await response.stream.bytesToString();
      final jsonResponse = json.decode(finalResponse);
      print("call waiter response ${jsonResponse}");
      Fluttertoast.showToast(msg: "${jsonResponse['message']}");
     // Navigator.of(context).pop();
    }
    else {
      print(response.reasonPhrase);
    }

  }


  @override
  Widget build(BuildContext context) {
    print("STORE NAME==== ${widget.sellerStoreName} and ${imageUrl}${widget.todaySpecial} ");
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.whiteTemp,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colors.primary,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: widget.search
            ? Text(
                "${widget.sellerName}",
                style: TextStyle(color: colors.primary),
              )
            : Text(
                "${widget.sellerStoreName}",
                style: TextStyle(color: colors.primary),
              ),
      ),
      body: ListView(
        shrinkWrap: true,
        children: [
          widget.search
              ? Container(
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(widget.sellerImage.toString()),
                          ),
                          title:
                              Text("${widget.sellerStoreName}".toUpperCase()),
                          subtitle: Text(
                            "${widget.storeDesc}",
                            maxLines: 2,
                          ),
                        ),
                       widget.address == null  || widget.address == "" ? SizedBox.shrink() : Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("${widget.address}",style: TextStyle(color: Colors.black,fontSize: 14),),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: colors.primary,
                                  ),
                                widget.sellerRating == null || widget.sellerRating == "" ? Text("0.0") :  Text("${widget.sellerRating}"),

                                ],
                              ),
                              // widget.extraData["estimated_time"]
                              // widget.estimatedTime != ""
                              //     ? Column(
                              //         children: [
                              //           Text("Delivery Time"),
                              //           Text(
                              //             "${widget.estimatedTime}",
                              //             //"${widget.extraData["estimated_time"]}",
                              //             style:
                              //                 TextStyle(color: Colors.green),
                              //           ),
                              //         ],
                              //       )
                              //     : Container(),
                              // // widget.extraData["food_person"]
                              // widget.foodPerson != ""
                              //     ? Column(
                              //         children: [
                              //           Text("₹/Person"),
                              //           Text('${widget.foodPerson}'),
                              //           //Text("${widget.extraData["food_person"]}"),
                              //         ],
                              //       )
                              //     : Container()
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    Container(
                      height: 200,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image:
                                  NetworkImage(widget.sellerImage.toString()),
                              fit: BoxFit.fill)),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.35,
                        width: MediaQuery.of(context).size.width * 0.35,
                        color: Colors.black.withOpacity(0.5),
                        child: Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                // backgroundImage: NetworkImage(widget.sellerData!.seller_profile),
                                backgroundImage:
                                    NetworkImage("${widget.sellerImage}"),
                              ),
                              title: Text(
                                "${widget.sellerStoreName.toString()}"
                                    .toUpperCase(),
                                style: TextStyle(color: colors.whiteTemp),
                              ),
                              subtitle: Text(
                                "${widget.storeDesc}",
                                maxLines: 2,
                                style: TextStyle(color: colors.whiteTemp),
                              ),
                            ),
                            // ListTile(title: Text("Address"), subtitle: Text("${widget.sellerData.address}"),),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        color: colors.primary,
                                      ),
                                      Text(
                                        "${widget.sellerRating}",
                                        style: TextStyle(
                                            color: colors.whiteTemp),
                                      )
                                    ],
                                  ),
                                 // widget.estimatedTime != ""
                                 //     ?
                                 //  Column(
                                 //          children: [
                                 //            Text(
                                 //              "Delivery Time",
                                 //              style: TextStyle(
                                 //                  color: colors.whiteTemp),
                                 //            ),
                                 //            Text(
                                 //              "${widget.estimatedTime}",
                                 //              style: TextStyle(
                                 //                  color: Colors.green),
                                 //            ),
                                 //          ],
                                 //        )
                                 //      : Container(),
                                 //  widget.foodPerson != ""
                                 //      ? Column(
                                 //          children: [
                                 //            Text(
                                 //              "₹/Person",
                                 //              style: TextStyle(
                                 //                  color: colors.whiteTemp),
                                 //            ),
                                 //            Text(
                                 //              "${widget.foodPerson}",
                                 //              style: TextStyle(
                                 //                  color: colors.whiteTemp),
                                 //            ),
                                 //          ],
                                 //        )
                                 //      : Container()
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
          widget.todaySpecial == "" || widget.todaySpecial == null ? SizedBox.shrink() : InkWell(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProductList(
                fromSeller: true,
                name: "",
                id: widget.sellerID,
                subCatId: widget.todayCategory.toString(),
                tag: false,
              )   ));
            },
            child: Column(
              children: [
                SizedBox(height: 10,),
                Text("Today Special",style: TextStyle(color: Colors.black,fontSize: 15,fontWeight: FontWeight.w600),),
                Container(
                  margin: EdgeInsets.all(10),
                  height: 150,
                  width: MediaQuery.of(context).size.width,
                  child: ClipRRect(borderRadius: BorderRadius.circular(7),
                    child: Stack(
                      children: [
                        Container(
                            width: MediaQuery.of(context).size.width,
                            child: Image.network("${imageUrl}${widget.todaySpecial}",fit: BoxFit.fill,)),
                        // Align(
                        //     alignment: Alignment.center,
                        //     child: Text("Today Special",style: TextStyle(color: Colors.white,fontWeight: FontWeight.w600,fontSize: 16),)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ) ,
          // widget.storeQR == ""
          //     ? SizedBox.shrink()
          //     : Container(
          //         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          //         width: MediaQuery.of(context).size.width,
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text("QR Scanner"),
          //             SizedBox(
          //               height: 15,
          //             ),
          //             Align(
          //               alignment: Alignment.center,
          //               child: Container(
          //                 height: 90,
          //                 width: 100,
          //                 child: ClipRRect(
          //                     borderRadius: BorderRadius.circular(7),
          //                     child: Image.network(
          //                       "${imageUrl + widget.storeQR.toString()}",
          //                       fit: BoxFit.fill,
          //                     )),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),

            mealStatus == true ? SizedBox.shrink() :   tableValue == '' || tableValue == null || tableValue == "0" ? Padding(
                padding: EdgeInsets.only(top: 10),
                child: tableListModel ==  null ? Container(child: Center(child: CircularProgressIndicator(),),) : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Call a waiter",style: TextStyle(color: Colors.black,fontSize: 15,fontWeight: FontWeight.w600),),
                    SizedBox(height: 10,),
                 tableListModel!.data!.isEmpty ?   Container(
                      margin: EdgeInsets.only(bottom: 10),
                      alignment: Alignment.center,
                      child: Text("No tables left",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w600),),
                    ) : SizedBox.shrink(),
                    Container(
                      height: 40,
                      width: MediaQuery.of(context).size.width/2.5,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: colors.primary
                      ),
                      child:  DropdownButton(
                        // Initial Value
                        underline: Container(),
                        value: selectedTable,
                          hint: Text("Select Table",style: TextStyle(color: Colors.white),),
                        // Down Arrow Icon
                        icon:  Icon(Icons.keyboard_arrow_down,color: Colors.white,),
                        // Array list of items
                        items: tableListModel!.data!.map(( items) {
                          return DropdownMenuItem(
                            value: items.table.toString(),
                            child: Text("Table No." + items.table.toString(),style: TextStyle(color: Colors.black),),
                          );
                        }).toList(),
                        // After selecting the desired option,it will
                        // change button value to selected value
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedTable = newValue!;
                          });
                          prefs!.setString('newTableId', '${selectedTable.toString()}');
                          callWaiter(selectedTable.toString());
                        },
                      ),
                      //Text("Call a waiter",style: TextStyle(color: Colors.white,fontWeight: FontWeight.w500,fontSize: 15),),
                    ),
                  ],
                ),
              ): Container(
                margin: EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                padding: EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Table No - ${tableValue}"),
                  InkWell(
                    onTap: (){
                      callWaiter(tableValue.toString());
                    },
                    child: Container(
                      height: 40,
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: colors.primary
                      ),
                      alignment: Alignment.center,
                      child: Text("Call a waiter",style: TextStyle(color: Colors.white,fontSize: 14,fontWeight: FontWeight.w500),),),
                  ),
                ],
              ),
            ) ,

          widget.sellerID == "" || widget.sellerID == null ? SizedBox.shrink(): Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 10,left: 10),
                child: Text("Categories",style: TextStyle(color: Colors.black,fontSize: 18,fontWeight: FontWeight.w600),),
              )),
       catList == null || catList.isEmpty ? Center(child: CircularProgressIndicator()):
       ListView.builder(
         shrinkWrap: true,
         itemCount: catList.length,
         physics: ScrollPhysics(),
         itemBuilder: (c,i){
       return i == 0 ? SizedBox.shrink() : Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: Colors.white,
        ),
         margin: EdgeInsets.only(top: 10,left: 10,right: 10),
         padding: EdgeInsets.all(8),
         child: ListTile(
           onTap: (){
             print("sdsds ${catList[i].id}");
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProductList(
            fromSeller: true,
            name: "",
            id: widget.sellerID,
            subCatId: catList[i].id.toString(),
            tag: false,
          )));
           },
           contentPadding: EdgeInsets.symmetric(horizontal: 5),
           title: Text(catList[i].name.toString()),
           leading:Container(
             height: 90,
             width: 80,
             child: ClipRRect(
               borderRadius: BorderRadius.circular(6),
               child: Image.network("${catList[i].image}",fit: BoxFit.cover,),
             ),
           )
         ),
       );
       }),
      // Expanded(
      //       child: ProductList(
      //         fromSeller: true,
      //         name: "",
      //         id: widget.sellerID,
      //         subCatId: widget.subCatId,
      //         tag: false,
      //       ),
      //     ),
        ],
      ),
    );

    DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: getAppBar(getTranslated(context, 'SELLER_DETAILS')!, context),
        body: Container(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: getTranslated(context, 'DETAILS')!),
                  Tab(text: getTranslated(context, 'PRODUCTS')),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    detailsScreen(),
                    ProductList(
                      fromSeller: true,
                      name: "",
                      id: widget.sellerID,
                      tag: false,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        // bottomNavigationBar:
      ),
    );
  }

  // Future fetchSellerDetails() async {
  //   var parameter = {};
  //   final sellerData = await apiBaseHelper.postAPICall(getSellerApi, parameter);
  //   List<Seller> sellerDetails = [];
  //   bool error = sellerData["error"];
  //   String? msg = sellerData["message"];
  //   if (!error) {
  //     var data = sellerData["data"];
  //     sellerDetails =
  //         (data as List).map((data) => Seller.fromJson(data)).toList();
  //   } else {
  //     setSnackbar(msg!, context);
  //   }
  //
  //   return sellerDetails;
  // }

  Widget detailsScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: CircleAvatar(
              radius: 80,
              backgroundColor: colors.primary,
              backgroundImage: NetworkImage(widget.sellerImage!),
              // child: ClipRRect(
              //   borderRadius: BorderRadius.circular(40),
              //   child: FadeInImage(
              //     fadeInDuration: Duration(milliseconds: 150),
              //     image: NetworkImage(widget.sellerImage!),
              //
              //     fit: BoxFit.cover,
              //     placeholder: placeHolder(100),
              //     imageErrorBuilder: (context, error, stackTrace) =>
              //         erroWidget(100),
              //   ),
              // )
            ),
          ),
          getHeading(widget.sellerStoreName!),
          SizedBox(
            height: 5,
          ),
          Text(
            widget.sellerName!,
            style: TextStyle(
                color: Theme.of(context).colorScheme.lightBlack2, fontSize: 16),
          ),
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50.0),
                          color: colors.primary),
                      child: Icon(
                        Icons.star,
                        color: Theme.of(context).colorScheme.white,
                        size: 30,
                      ),
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    Text(
                      widget.sellerRating.toString(),
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.lightBlack2,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    InkWell(
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50.0),
                            color: colors.primary),
                        child: Icon(
                          Icons.description,
                          color: Theme.of(context).colorScheme.white,
                          size: 30,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          isDescriptionVisible = !isDescriptionVisible;
                        });
                      },
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    Text(
                      getTranslated(context, 'DESCRIPTION')!,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.lightBlack2,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    InkWell(
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50.0),
                              color: colors.primary),
                          child: Icon(
                            Icons.list_alt,
                            color: Theme.of(context).colorScheme.white,
                            size: 30,
                          ),
                        ),
                        onTap: () => _tabController
                            .animateTo((_tabController.index + 1) % 2)),
                    SizedBox(
                      height: 5.0,
                    ),
                    Text(
                      getTranslated(context, 'PRODUCTS')!,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.lightBlack2,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Visibility(
              visible: isDescriptionVisible,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.25,
                width: MediaQuery.of(context).size.width * 8,
                margin: const EdgeInsets.all(15.0),
                padding: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: colors.primary)),
                child: SingleChildScrollView(
                    child: Text(
                  (widget.storeDesc != "" || widget.storeDesc != null)
                      ? "${widget.storeDesc}"
                      : getTranslated(context, "NO_DESC")!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                )),
              ))
        ],
      ),
    );
    // return FutureBuilder(
    //     future: fetchSellerDetails(),
    //     builder: (context, snapshot) {
    //       if (snapshot.connectionState == ConnectionState.done) {
    //         // If we got an error
    //         if (snapshot.hasError) {
    //           return Center(
    //             child: Text(
    //               '${snapshot.error} Occured',
    //               style: TextStyle(fontSize: 18),
    //             ),
    //           );
    //
    //           // if we got our data
    //         } else if (snapshot.hasData) {
    //           // Extracting data from snapshot object
    //           var data = snapshot.data;
    //           print("data is $data");
    //
    //           return Center(
    //             child: Text(
    //               'Hello',
    //               style: TextStyle(fontSize: 18),
    //             ),
    //           );
    //         }
    //       }
    //       return shimmer();
    //     });
  }

  Widget getHeading(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headline6!.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.fontColor,
          ),
    );
  }

  Widget getRatingBarIndicator(var ratingStar, var totalStars) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: RatingBarIndicator(
        rating: ratingStar,
        itemBuilder: (context, index) => const Icon(
          Icons.star_outlined,
          color: colors.yellow,
        ),
        itemCount: totalStars,
        itemSize: 20.0,
        direction: Axis.horizontal,
        unratedColor: Colors.transparent,
      ),
    );
  }
  @override
  bool get wantKeepAlive => true;
}
