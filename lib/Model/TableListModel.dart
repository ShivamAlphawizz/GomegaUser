/// error : false
/// message : "Get Table Data"
/// data : [{"id":"836","seller_id":"927","table":"1","order_id":"0","status":"1","qr_code":"uploads/qrcode/1265767440.png"},{"id":"837","seller_id":"927","table":"2","order_id":"0","status":"1","qr_code":"uploads/qrcode/678447696.png"},{"id":"838","seller_id":"927","table":"3","order_id":"0","status":"1","qr_code":"uploads/qrcode/1993869753.png"},{"id":"839","seller_id":"927","table":"4","order_id":"0","status":"1","qr_code":"uploads/qrcode/2129412140.png"},{"id":"840","seller_id":"927","table":"5","order_id":"0","status":"1","qr_code":"uploads/qrcode/1194306746.png"},{"id":"841","seller_id":"927","table":"6","order_id":"0","status":"1","qr_code":"uploads/qrcode/844784699.png"},{"id":"842","seller_id":"927","table":"7","order_id":"0","status":"1","qr_code":"uploads/qrcode/2047063184.png"},{"id":"843","seller_id":"927","table":"8","order_id":"0","status":"1","qr_code":"uploads/qrcode/1717794228.png"},{"id":"844","seller_id":"927","table":"9","order_id":"0","status":"1","qr_code":"uploads/qrcode/1175824339.png"},{"id":"845","seller_id":"927","table":"10","order_id":"26","status":"1","qr_code":"uploads/qrcode/460934872.png"}]

class TableListModel {
  TableListModel({
      bool? error, 
      String? message, 
      List<Data>? data,}){
    _error = error;
    _message = message;
    _data = data;
}

  TableListModel.fromJson(dynamic json) {
    _error = json['error'];
    _message = json['message'];
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(Data.fromJson(v));
      });
    }
  }
  bool? _error;
  String? _message;
  List<Data>? _data;
TableListModel copyWith({  bool? error,
  String? message,
  List<Data>? data,
}) => TableListModel(  error: error ?? _error,
  message: message ?? _message,
  data: data ?? _data,
);
  bool? get error => _error;
  String? get message => _message;
  List<Data>? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['error'] = _error;
    map['message'] = _message;
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// id : "836"
/// seller_id : "927"
/// table : "1"
/// order_id : "0"
/// status : "1"
/// qr_code : "uploads/qrcode/1265767440.png"

class Data {
  Data({
      String? id, 
      String? sellerId, 
      String? table, 
      String? orderId, 
      String? status, 
      String? qrCode,}){
    _id = id;
    _sellerId = sellerId;
    _table = table;
    _orderId = orderId;
    _status = status;
    _qrCode = qrCode;
}

  Data.fromJson(dynamic json) {
    _id = json['id'];
    _sellerId = json['seller_id'];
    _table = json['table'];
    _orderId = json['order_id'];
    _status = json['status'];
    _qrCode = json['qr_code'];
  }
  String? _id;
  String? _sellerId;
  String? _table;
  String? _orderId;
  String? _status;
  String? _qrCode;
Data copyWith({  String? id,
  String? sellerId,
  String? table,
  String? orderId,
  String? status,
  String? qrCode,
}) => Data(  id: id ?? _id,
  sellerId: sellerId ?? _sellerId,
  table: table ?? _table,
  orderId: orderId ?? _orderId,
  status: status ?? _status,
  qrCode: qrCode ?? _qrCode,
);
  String? get id => _id;
  String? get sellerId => _sellerId;
  String? get table => _table;
  String? get orderId => _orderId;
  String? get status => _status;
  String? get qrCode => _qrCode;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['seller_id'] = _sellerId;
    map['table'] = _table;
    map['order_id'] = _orderId;
    map['status'] = _status;
    map['qr_code'] = _qrCode;
    return map;
  }

}