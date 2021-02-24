package en;

typedef Point = { x: Float, y: Float }

class Hero extends Entity implements hxbit.NetworkSerializable {
    var ca : dn.heaps.Controller.ControllerAccess;
	var net(get,never) : ext.Network; inline function get_net() return ext.Network.ME;
	var bmp : h2d.Graphics;

	@:s public var netuid : Int;
	@:s var point(default, set): Point; function set_point(p) {
		point = p;
		render();
		return p;
	}

	public function new(uid, x, y) {
		netuid = uid;
		init(x,y);
		point = { x: x, y: y };
	}

	override function init(x,y) {
		super.init(x,y);
		net.log('Init ${this}');
		bmp = new h2d.Graphics(spr);
		bmp.beginFill(netuid);
		bmp.drawRect(0,0,16,16);

		enableReplication = true;
	}

	public function alive() {
		init(0,0);

		affects = new Map();
		actions = [];
		entityVisible = true;
		dir = 1;
		sprScaleX = 1.0;
		sprScaleY = 1.0;
		sprSquashX = 1.0;
		sprSquashY = 1.0;
		net.log('Alive ${this}');

		if (netuid == net.uid)
			renderSelf();

		render();
	}

	public function render() {
        if (point == null) return;
        if (bmp != null) bmp.x = point.x;
		if (bmp != null) bmp.y = point.y;
		setPosPixel(point.x, point.y);
    }

	function renderSelf() {
		net.log('Alive self');
		net.host.self.ownerObject = Game.ME.hero = this;

		var i = new h2d.Interactive(10, 10, spr);
		// i.x = i.y = -5;
		i.isEllipse = true;
		i.onClick = (_) -> _blink( 2 + Math.random() * 2 );

		var s2d = Boot.ME.s2d;
		hxd.Window.getInstance().addEventTarget((event: hxd.Event) -> {
			if (event.kind == hxd.Event.EventKind.EPush)
				point = { x: s2d.mouseX, y: s2d.mouseY };
		});

		ca = Main.ME.controller.createAccess('hero');
	}

	@:rpc function _blink( s : Float ) {
		bmp.scale(s);
		net.event.waitUntil((dt) -> {
			bmp.scaleX *= Math.pow(0.9, dt * 60);
			bmp.scaleY *= Math.pow(0.9, dt * 60);
			if (bmp.scaleX < 1)
				bmp.scaleX = bmp.scaleY = 1;
			return bmp.scaleX == 1;
		});
	}

	public function networkAllow( op : hxbit.NetworkSerializable.Operation, propId : Int, client : hxbit.NetworkSerializable ) : Bool {
		return client == this;
	}

	override function dispose() {
		super.dispose();

		enableReplication = false;

		if (ca != null)
			ca.dispose();
	}

	override function update() {
		super.update();

		if (ca == null)
			return;

		if( ca.leftDown() || ca.isKeyboardDown(hxd.Key.LEFT) )
			dx -= 0.1*tmod;

		if( ca.rightDown() || ca.isKeyboardDown(hxd.Key.RIGHT) )
			dx += 0.1*tmod;
	}

	public function toString() {
		return 'Hero ${uid} ${enableReplication?":ALIVE":""}';
	}
}
