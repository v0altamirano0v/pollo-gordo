import 'package:flutter/material.dart';

/// Formatea un monto en soles.
String soles(double v) => 'S/ ${v.toStringAsFixed(2)}';

/// Roles del sistema.
enum Rol {
  cajero('Cajero / Administrador', 'Local Principal: salón y para llevar', Icons.point_of_sale),
  delivery('Cajero de Delivery', 'Pedidos telefónicos y asignación', Icons.headset_mic),
  cocina('Cocina / Mostrador / Mozo', 'Comandas y estados del pedido', Icons.soup_kitchen),
  repartidor('Repartidor y Liquidación', 'Entregas, cobros y liquidación', Icons.delivery_dining),
  gerencia('Propietario / Gerencia', 'Ventas, pollos y reportes del día', Icons.insights);

  const Rol(this.nombre, this.descripcion, this.icono);
  final String nombre;
  final String descripcion;
  final IconData icono;
}

class Producto {
  final String nombre;
  final String categoria;
  final double precio;
  final double pollos; // equivalencia en pollos enteros
  const Producto(this.nombre, this.categoria, this.precio, this.pollos);
}

class Item {
  final Producto producto;
  final int cantidad;
  const Item(this.producto, this.cantidad);
}

class Pedido {
  final int numero;
  final String tipo; // salón | para llevar | delivery
  final String? mesa;
  final String cliente, telefono, direccion, referencia;
  final List<Item> items;
  final double envio;
  final DateTime hora;
  String estado; // registrado, en preparación, listo, en ruta, entregado, no entregado, reasignado
  String? repartidor;
  final List<String> incidencias = [];

  Pedido({
    required this.numero,
    required this.tipo,
    this.mesa,
    this.cliente = '',
    this.telefono = '',
    this.direccion = '',
    this.referencia = '',
    required this.items,
    this.envio = 0,
    this.estado = 'registrado',
    this.repartidor,
  }) : hora = DateTime.now();

  double get subtotal => items.fold(0.0, (s, i) => s + i.producto.precio * i.cantidad);
  double get total => subtotal + envio;
  double get pollos => items.fold(0.0, (s, i) => s + i.producto.pollos * i.cantidad);
  bool get entregado => estado == 'entregado';
  bool get cerrado => estado == 'entregado' || estado == 'no entregado';
  String get resumen => items.map((i) => '${i.cantidad} × ${i.producto.nombre}').join(', ');
}

final List<String> mesas = List.generate(10, (i) => 'Mesa ${i + 1} · Piso ${i < 5 ? 1 : 2}');

/// Almacén de datos en memoria con datos de prueba.
class Tienda extends ChangeNotifier {
  final List<Producto> productos = const [
    Producto('Pollo entero', 'Pollo a la brasa', 62, 1),
    Producto('1/2 pollo', 'Pollo a la brasa', 33, 0.5),
    Producto('1/4 pollo', 'Pollo a la brasa', 18, 0.25),
    Producto('1/8 pollo', 'Pollo a la brasa', 10, 0.125),
    Producto('Papas fritas', 'Acompañamiento', 8, 0),
    Producto('Ensalada', 'Acompañamiento', 6, 0),
    Producto('Cremas extra', 'Acompañamiento', 2, 0),
    Producto('Gaseosa 1.5 L', 'Bebida', 9, 0),
    Producto('Chicha morada (jarra)', 'Bebida', 12, 0),
  ];
  final List<String> repartidores = ['Carlos Quispe', 'Luis Huamán', 'Jorge Ramos'];
  final List<Pedido> pedidos = [];
  double pollosComprados = 30;
  int _sig = 1;

  Tienda() {
    Producto p(String n) => productos.firstWhere((x) => x.nombre == n);
    registrar(tipo: 'salón', mesa: mesas[0], items: [Item(p('Pollo entero'), 1), Item(p('Papas fritas'), 2), Item(p('Chicha morada (jarra)'), 1)]).estado = 'entregado';
    registrar(tipo: 'salón', mesa: mesas[2], items: [Item(p('1/2 pollo'), 1), Item(p('Papas fritas'), 1), Item(p('Ensalada'), 1)]).estado = 'en preparación';
    registrar(tipo: 'para llevar', items: [Item(p('1/4 pollo'), 2), Item(p('Papas fritas'), 1)]).estado = 'listo';
    registrar(tipo: 'delivery', cliente: 'Rosa Medina', telefono: '956123456', direccion: 'Av. San Martín 450', referencia: 'Frente al grifo', envio: 4, items: [Item(p('Pollo entero'), 1), Item(p('Papas fritas'), 1), Item(p('Gaseosa 1.5 L'), 1)]).estado = 'listo';
    registrar(tipo: 'delivery', cliente: 'Miguel Torres', telefono: '944222111', direccion: 'Calle Comercio 120', referencia: 'Casa verde', envio: 3, items: [Item(p('1/4 pollo'), 3)]);
  }

  Pedido registrar({
    required String tipo,
    String? mesa,
    String cliente = '',
    String telefono = '',
    String direccion = '',
    String referencia = '',
    required List<Item> items,
    double envio = 0,
  }) {
    final p = Pedido(numero: _sig++, tipo: tipo, mesa: mesa, cliente: cliente, telefono: telefono, direccion: direccion, referencia: referencia, items: items, envio: envio);
    pedidos.add(p);
    notifyListeners();
    return p;
  }

  /// Ejecuta un cambio y avisa a las pantallas.
  void actualizar(void Function() cambio) {
    cambio();
    notifyListeners();
  }
}

final Tienda tienda = Tienda();
