import 'package:flutter/material.dart';
import 'data.dart';

// ───────────────────────── LOGIN / SELECCIÓN DE ROL ─────────────────────────
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Icon(Icons.local_fire_department, size: 72, color: cs.primary),
                Text('El Pollo Gordo',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                const Text('Pisco, Perú · Atención de 18:00 a 00:00', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Text('¿Con qué rol ingresas?', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final r in Rol.values)
                  Card(
                    child: ListTile(
                      leading: Icon(r.icono, color: cs.primary),
                      title: Text(r.nombre),
                      subtitle: Text(r.descripcion),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Shell(rol: r))),
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.flag),
                  label: const Text('Nuestra Misión y Visión'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Misión y Visión')),
                        body: const NosotrosPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── MENÚ ADAPTATIVO ─────────────────────────
class _Mod {
  final String label;
  final IconData icon;
  final Widget page;
  const _Mod(this.label, this.icon, this.page);
}

const _nos = _Mod('Misión y Visión', Icons.flag, NosotrosPage());

class Shell extends StatefulWidget {
  final Rol rol;
  const Shell({super.key, required this.rol});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;

  List<_Mod> get mods => switch (widget.rol) {
        Rol.cajero => const [
            _Mod('Nuevo pedido', Icons.add_shopping_cart, NuevoPedido()),
            _Mod('Comandas', Icons.receipt_long, ComandasPage()),
            _nos,
          ],
        Rol.delivery => const [
            _Mod('Pedido delivery', Icons.add_ic_call, NuevoPedido(tipoInicial: 'delivery')),
            _Mod('Reparto', Icons.delivery_dining, RepartoPage()),
            _nos,
          ],
        Rol.cocina => const [
            _Mod('Comandas', Icons.receipt_long, ComandasPage()),
            _nos,
          ],
        Rol.repartidor => const [
            _Mod('Reparto', Icons.delivery_dining, RepartoPage()),
            _nos,
          ],
        Rol.gerencia => const [
            _Mod('Gerencia', Icons.insights, GerenciaPage()),
            _Mod('Comandas', Icons.receipt_long, ComandasPage()),
            _Mod('Reparto', Icons.delivery_dining, RepartoPage()),
            _nos,
          ],
      };

  @override
  Widget build(BuildContext context) {
    final m = mods;
    final wide = MediaQuery.of(context).size.width >= 800;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rol.nombre),
        actions: [
          IconButton(tooltip: 'Cambiar de rol', icon: const Icon(Icons.logout), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: wide
          ? Row(children: [
              NavigationRail(
                selectedIndex: i,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (v) => setState(() => i = v),
                destinations: [for (final x in m) NavigationRailDestination(icon: Icon(x.icon), label: Text(x.label))],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: m[i].page),
            ])
          : m[i].page,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: i,
              onDestinationSelected: (v) => setState(() => i = v),
              destinations: [for (final x in m) NavigationDestination(icon: Icon(x.icon), label: x.label)],
            ),
    );
  }
}

// ───────────────────────── NUEVO PEDIDO ─────────────────────────
class NuevoPedido extends StatefulWidget {
  final String tipoInicial;
  const NuevoPedido({super.key, this.tipoInicial = 'salón'});

  @override
  State<NuevoPedido> createState() => _NuevoPedidoState();
}

class _NuevoPedidoState extends State<NuevoPedido> {
  late String tipo = widget.tipoInicial;
  String mesa = mesas.first;
  final nombre = TextEditingController();
  final tel = TextEditingController();
  final dir = TextEditingController();
  final ref = TextEditingController();
  final envio = TextEditingController(text: '4');
  final pagaCon = TextEditingController();
  final cant = <Producto, int>{};

  double _num(String t) => double.tryParse(t.replaceAll(',', '.')) ?? 0;
  double get costoEnvio => tipo == 'delivery' ? _num(envio.text) : 0;
  double get subtotal => cant.entries.fold(0.0, (s, e) => s + e.key.precio * e.value);

  void _msg(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _registrar() async {
    final items = [for (final e in cant.entries) if (e.value > 0) Item(e.key, e.value)];
    if (items.isEmpty) {
      _msg('Agrega al menos un producto');
      return;
    }
    if (tipo == 'delivery') {
      if (nombre.text.trim().isEmpty || tel.text.trim().isEmpty || dir.text.trim().isEmpty) {
        _msg('Completa nombre, teléfono y dirección');
        return;
      }
      // Verificación de posible duplicado por teléfono
      final dup = tienda.pedidos.any((p) => p.tipo == 'delivery' && !p.cerrado && p.telefono == tel.text.trim());
      if (dup) {
        final seguir = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('Posible pedido duplicado'),
            content: const Text('Ya hay un pedido de delivery activo con este teléfono. ¿Registrar de todas formas?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Registrar igual')),
            ],
          ),
        );
        if (seguir != true || !mounted) return;
      }
    }
    final p = tienda.registrar(
      tipo: tipo,
      mesa: tipo == 'salón' ? mesa : null,
      cliente: nombre.text.trim(),
      telefono: tel.text.trim(),
      direccion: dir.text.trim(),
      referencia: ref.text.trim(),
      items: items,
      envio: costoEnvio,
    );
    setState(() {
      cant.clear();
      nombre.clear();
      tel.clear();
      dir.clear();
      ref.clear();
      pagaCon.clear();
    });
    _msg('Pedido N° ${p.numero} registrado · ${soles(p.total)}');
  }

  @override
  void dispose() {
    for (final c in [nombre, tel, dir, ref, envio, pagaCon]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _dec(String l) => InputDecoration(labelText: l, border: const OutlineInputBorder());

  @override
  Widget build(BuildContext context) {
    final total = subtotal + costoEnvio;
    final paga = _num(pagaCon.text);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'salón', label: Text('Salón'), icon: Icon(Icons.table_restaurant)),
                ButtonSegment(value: 'para llevar', label: Text('Llevar'), icon: Icon(Icons.shopping_bag)),
                ButtonSegment(value: 'delivery', label: Text('Delivery'), icon: Icon(Icons.delivery_dining)),
              ],
              selected: {tipo},
              onSelectionChanged: (s) => setState(() => tipo = s.first),
            ),
            const SizedBox(height: 12),
            if (tipo == 'salón') ...[
              const Text('Mesa'),
              const SizedBox(height: 4),
              Wrap(spacing: 8, children: [
                for (final m in mesas) ChoiceChip(label: Text(m), selected: mesa == m, onSelected: (_) => setState(() => mesa = m)),
              ]),
            ],
            if (tipo == 'delivery') ...[
              TextField(controller: nombre, decoration: _dec('Nombre del cliente')),
              const SizedBox(height: 8),
              TextField(controller: tel, keyboardType: TextInputType.phone, decoration: _dec('Teléfono')),
              const SizedBox(height: 8),
              TextField(controller: dir, decoration: _dec('Dirección')),
              const SizedBox(height: 8),
              TextField(controller: ref, decoration: _dec('Referencia')),
              const SizedBox(height: 8),
              TextField(controller: envio, keyboardType: TextInputType.number, decoration: _dec('Costo de envío (S/)'), onChanged: (_) => setState(() {})),
            ],
            const Divider(height: 32),
            for (final p in tienda.productos)
              ListTile(
                title: Text(p.nombre),
                subtitle: Text('${p.categoria} · ${soles(p.precio)}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: (cant[p] ?? 0) > 0 ? () => setState(() => cant[p] = cant[p]! - 1) : null,
                  ),
                  Text('${cant[p] ?? 0}', style: Theme.of(context).textTheme.titleMedium),
                  IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => cant[p] = (cant[p] ?? 0) + 1)),
                ]),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Subtotal: ${soles(subtotal)}'),
                  if (tipo == 'delivery') Text('Envío: ${soles(costoEnvio)}'),
                  Text('TOTAL: ${soles(total)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(controller: pagaCon, keyboardType: TextInputType.number, decoration: _dec('Paga con (efectivo) S/'), onChanged: (_) => setState(() {})),
                  if (paga >= total && total > 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Vuelto: ${soles(paga - total)}')),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(onPressed: _registrar, icon: const Icon(Icons.check), label: const Text('Registrar pedido')),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── COMANDAS (COCINA / MOSTRADOR) ─────────────────────────
class ComandasPage extends StatefulWidget {
  const ComandasPage({super.key});

  @override
  State<ComandasPage> createState() => _ComandasPageState();
}

class _ComandasPageState extends State<ComandasPage> {
  bool soloPendientes = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: tienda,
      builder: (context, _) {
        final lista = tienda.pedidos.where((p) => !soloPendientes || !p.cerrado).toList().reversed.toList();
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(children: [
              SwitchListTile(
                title: const Text('Solo comandas pendientes'),
                value: soloPendientes,
                onChanged: (v) => setState(() => soloPendientes = v),
              ),
              Expanded(
                child: lista.isEmpty
                    ? const Center(child: Text('No hay comandas'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: lista.length,
                        itemBuilder: (c, k) => _Comanda(lista[k]),
                      ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _Comanda extends StatelessWidget {
  final Pedido p;
  const _Comanda(this.p);

  String? get siguiente => switch (p.estado) {
        'registrado' => 'en preparación',
        'en preparación' => 'listo',
        'listo' => p.tipo == 'delivery' ? null : 'entregado',
        _ => null,
      };

  Future<void> _reclamo(BuildContext context) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Reclamo o cambio · Pedido ${p.numero}'),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'Ej: faltó la ensalada')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      tienda.actualizar(() => p.incidencias.add(c.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = siguiente;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('Pedido N° ${p.numero} · ${p.tipo}${p.mesa != null ? ' · ${p.mesa}' : ''}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Chip(label: Text(p.estado)),
          ]),
          if (p.tipo == 'delivery') Text('${p.cliente} · ${p.direccion}'),
          Text(p.resumen),
          Text('Total ${soles(p.total)}'),
          for (final inc in p.incidencias) Text('⚠ $inc', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            if (s != null) FilledButton(onPressed: () => tienda.actualizar(() => p.estado = s), child: Text('Pasar a "$s"')),
            if (p.tipo == 'delivery' && p.estado == 'listo') const Text('Listo: asignar repartidor en Reparto'),
            if (!p.cerrado)
              OutlinedButton.icon(
                onPressed: () => _reclamo(context),
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('Reclamo / cambio'),
              ),
          ]),
        ]),
      ),
    );
  }
}

// ───────────────────────── REPARTO Y LIQUIDACIÓN ─────────────────────────
class RepartoPage extends StatelessWidget {
  const RepartoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: tienda,
      builder: (context, _) {
        final ds = tienda.pedidos.where((p) => p.tipo == 'delivery').toList().reversed.toList();
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(padding: const EdgeInsets.all(12), children: [
              const _Liquidacion(),
              for (final p in ds) _Entrega(p),
            ]),
          ),
        );
      },
    );
  }
}

class _Liquidacion extends StatelessWidget {
  const _Liquidacion();

  @override
  Widget build(BuildContext context) {
    final filas = <Widget>[];
    var totalEfectivo = 0.0;
    for (final r in tienda.repartidores) {
      final ent = tienda.pedidos.where((p) => p.repartidor == r && p.entregado).toList();
      final fall = tienda.pedidos.where((p) => p.repartidor == r && p.estado == 'no entregado').length;
      final efectivo = ent.fold(0.0, (s, p) => s + p.total);
      totalEfectivo += efectivo;
      filas.add(ListTile(
        dense: true,
        title: Text(r),
        subtitle: Text('${ent.length} entregas · $fall fallidas'),
        trailing: Text(soles(efectivo), style: const TextStyle(fontWeight: FontWeight.bold)),
      ));
    }
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Liquidación de reparto (efectivo a rendir)', style: Theme.of(context).textTheme.titleMedium),
          ...filas,
          const Divider(),
          Text('Total a rendir: ${soles(totalEfectivo)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

class _Entrega extends StatefulWidget {
  final Pedido p;
  const _Entrega(this.p);

  @override
  State<_Entrega> createState() => _EntregaState();
}

class _EntregaState extends State<_Entrega> {
  late String sel = tienda.repartidores.first;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Pedido N° ${p.numero} · ${p.cliente}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
            Chip(label: Text(p.estado)),
          ]),
          Text('Tel: ${p.telefono} · ${p.direccion}'),
          if (p.referencia.isNotEmpty) Text('Ref: ${p.referencia}'),
          Text(p.resumen),
          Text('Cobrar en efectivo: ${soles(p.total)} (envío ${soles(p.envio)})'),
          if (p.repartidor != null) Text('Repartidor: ${p.repartidor}'),
          const SizedBox(height: 8),
          if (p.estado == 'registrado' || p.estado == 'en preparación') const Text('Esperando a cocina…'),
          if (p.estado == 'listo' || p.estado == 'reasignado') ...[
            Wrap(spacing: 8, children: [
              for (final r in tienda.repartidores) ChoiceChip(label: Text(r), selected: sel == r, onSelected: (_) => setState(() => sel = r)),
            ]),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Asignar y enviar'),
              onPressed: () => tienda.actualizar(() {
                p.repartidor = sel;
                p.estado = 'en ruta';
              }),
            ),
          ],
          if (p.estado == 'en ruta')
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(
                icon: const Icon(Icons.payments),
                label: Text('Entregado y cobrado ${soles(p.total)}'),
                onPressed: () => tienda.actualizar(() => p.estado = 'entregado'),
              ),
              OutlinedButton(onPressed: () => tienda.actualizar(() => p.estado = 'no entregado'), child: const Text('No entregado')),
              TextButton(
                onPressed: () => tienda.actualizar(() {
                  p.estado = 'reasignado';
                  p.repartidor = null;
                }),
                child: const Text('Reasignar'),
              ),
            ]),
        ]),
      ),
    );
  }
}

// ───────────────────────── GERENCIA ─────────────────────────
class GerenciaPage extends StatelessWidget {
  const GerenciaPage({super.key});

  Future<void> _comprar(BuildContext context) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Registrar compra de pollos'),
        content: TextField(controller: c, autofocus: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad de pollos')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Guardar')),
        ],
      ),
    );
    final n = double.tryParse(c.text.replaceAll(',', '.'));
    if (ok == true && n != null && n > 0) {
      tienda.actualizar(() => tienda.pollosComprados += n);
    }
  }

  Widget _kpi(BuildContext context, String t, String v, IconData i) => SizedBox(
        width: 230,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(i, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(t),
              Text(v, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: tienda,
      builder: (context, _) {
        final vend = tienda.pedidos.where((p) => p.entregado).toList();
        final proc = tienda.pedidos.where((p) => !p.cerrado).toList();
        final ventas = vend.fold(0.0, (s, p) => s + p.total);
        final porCobrar = proc.fold(0.0, (s, p) => s + p.total);
        final polloVend = vend.fold(0.0, (s, p) => s + p.pollos);
        final polloProc = proc.fold(0.0, (s, p) => s + p.pollos);
        final saldo = tienda.pollosComprados - polloVend - polloProc;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(padding: const EdgeInsets.all(12), children: [
              Text('Resumen del día', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _kpi(context, 'Ventas cobradas', soles(ventas), Icons.payments),
                _kpi(context, 'Por cobrar (en proceso)', soles(porCobrar), Icons.hourglass_bottom),
                _kpi(context, 'Pedidos entregados', '${vend.length}', Icons.check_circle),
                _kpi(context, 'Pedidos en proceso', '${proc.length}', Icons.pending_actions),
              ]),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Ventas por tipo', style: Theme.of(context).textTheme.titleMedium),
                    for (final t in const ['salón', 'para llevar', 'delivery'])
                      ListTile(
                        dense: true,
                        title: Text(t),
                        trailing: Text(soles(vend.where((p) => p.tipo == t).fold(0.0, (s, p) => s + p.total)), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ]),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pollos: comprados vs. vendidos', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Comprados: ${tienda.pollosComprados.toStringAsFixed(2)}'),
                    Text('Vendidos (entregados): ${polloVend.toStringAsFixed(2)}'),
                    Text('En proceso: ${polloProc.toStringAsFixed(2)}'),
                    Text('Saldo disponible: ${saldo.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(onPressed: () => _comprar(context), icon: const Icon(Icons.add), label: const Text('Registrar compra de pollos')),
                  ]),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ───────────────────────── MISIÓN Y VISIÓN ─────────────────────────
class NosotrosPage extends StatelessWidget {
  const NosotrosPage({super.key});

  Widget _bloque(BuildContext context, IconData icono, String titulo, String texto) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icono, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(titulo, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Text(texto, style: Theme.of(context).textTheme.bodyLarge),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Icon(Icons.local_fire_department, size: 56, color: Theme.of(context).colorScheme.primary),
          Text('El Pollo Gordo', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const Text('Pisco, Perú', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          _bloque(
            context,
            Icons.flag,
            'Misión',
            'Ofrecer el mejor pollo a la brasa de Pisco, con sabor tradicional, insumos de calidad y una atención cálida y rápida, '
                'ya sea en salón, para llevar o a domicilio, para que cada noche las familias piscanas disfruten una comida deliciosa a un precio justo.',
          ),
          _bloque(
            context,
            Icons.visibility,
            'Visión',
            'Ser la pollería líder y más querida de Pisco y de la región Ica, reconocida por su sabor, su puntualidad y su servicio, '
                'creciendo con nuevas sedes y tecnología sin perder la calidad que nos caracteriza.',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Nuestros valores', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Wrap(spacing: 8, runSpacing: 8, children: [
                  Chip(label: Text('Calidad')),
                  Chip(label: Text('Calidez')),
                  Chip(label: Text('Puntualidad')),
                  Chip(label: Text('Honestidad')),
                  Chip(label: Text('Higiene')),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
