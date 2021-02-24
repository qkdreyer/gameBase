package ext;

import hxbit.NetworkSerializable;
import hxbit.NetworkHost.NetworkClient;

class Network extends dn.Process {
    public static var ME : Network;

	static var HOST = #if prod 'tcv.qkdreyer.dev' #else '127.0.0.1' #end;
	static var PORT = #if prod 443 #else 6676 #end;

	public var host : SocketHost;
	public var event : hxd.WaitEvent;
	public var uid : Int = 0;

	public function new() {
        super(Game.ME);
        ME = this;

		event = new hxd.WaitEvent();
		host = new SocketHost();
		host.setLogger(msg -> log(msg));

		#if debug
		ui.Console.ME.setFlag('network', true);
		#end

		if (#if nodejs true #else false #end) {
			listen();
		} else {
			connect();
		}
	}

	public function listen() {
		host.wait(HOST, PORT, n -> log('Client Connected'));

		host.onMessage = (n: NetworkClient, uid: Int) -> {
			var hero = new en.Hero(uid,5,5);
			n.ownerObject = hero;
			n.sync();
			log('Client identified (${hero.netuid})');
		};

		host.onDisconnect = (n: NetworkClient, error: String) -> {
			var hero = cast(n.ownerObject, en.Hero);
			if (hero == null) return;

			hero.destroy();
			log('Client disconnected (${hero.netuid} : ${error}');
		};

		host.makeAlive();

		log('Server listening on ${HOST}:${PORT}');
	}

	public function connect() {
		log('Connecting');

		uid = 1 + Std.int(Math.random() * 0xffffff - 1);

		host.connect(HOST, PORT, connected -> {
			if (!connected)
				return log('Failed to connect to server');

			log('Connected to server');
			host.sendMessage(uid);
		});

		host.onUnregister = (object: hxbit.NetworkSerializable) -> {
			var hero = cast(object, en.Hero);
			hero.destroy();
			log('Client unregister (${hero.netuid})');
		};

		hxd.Window.getInstance().title = 'client (${uid})';
	}

	public function log(s: String, ?pos: haxe.PosInfos) {
		if (!ui.Console.ME.hasFlag('network'))
			return;

		pos.fileName = '[${host.isAuth ? 'S' : 'C'}] ${pos.fileName}';
		trace(s, pos);
	}

	override function update() {
		event.update(tmod);
        host.flush();
	}
}

class SocketHost extends hxd.net.SocketHost
{
	public dynamic function onDisconnect( networkClient: NetworkClient, error : String ) {
	}

	override public function wait( host : String, port : Int, ?onConnected : NetworkClient -> Void ) {
		super.wait(host, port, (networkClient : NetworkClient) -> {
			var socket = @:privateAccess cast(networkClient, hxd.net.SocketHost.SocketClient).socket;
			var onSocketError = socket.onError;

			socket.onError = (error: String) -> {
				onDisconnect(networkClient, error);
				onSocketError(error);
			}

			onConnected(networkClient);
		});
	}
}
