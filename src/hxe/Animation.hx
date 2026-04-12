package hxe;

class Animation extends Prefab {
	public var childrens:Map<String, h2d.Object> = new Map();
	public var animation:Timeline;

	public var library:Map<String, Timeline> = new Map();
	public var state(default, set):String = "default";

	public var playing:Bool = true;
	public var time:Float = 0;


	public function new(?path:String, ?parent:h2d.Object, ?fields:Array<hxe.Lib.Field>) {
		super(parent);

		if (path != null) {
			hxe.Lib.make(path, this, fields);
			animation = from(path, this);
			init();
		}
	}


	public function set(name:String, data:Timeline) {
		library.set(name, data);

		if (animation == null) {
			animation = library.get(name);
			state = name;
		}
	}
	

	function set_state(name:String) {
		if (!library.exists(name)) return state;
		if (state == name) return state;

		animation = library.get(name);
		state = name;
		time = 0;

		advance();

		return state;
	}

	
	override public function update(dt:Float) {
		var prev = time;
		var next = time + dt * animation.speed;
	
		for (event in animation.event) {
			if (time == 0 && event.start == 0) onEvent(event.name);
			if (prev < event.start && next >= event.start) {
				time = event.start;
				onEvent(event.name);

				if (!playing) return;
			}
		}

		time = next;
		advance();
	
		if (time >= animation.duration) {
			if (!animation.loop) playing = false;
			if (animation.loop) time = 0;

			onEnd();
		}
	}


	function advance() {
		for (key in animation.frame) {
			if (time < key.start || time > key.end) continue;
	
			var tick = clamp(time, key);
			var ease = easing(key.ease, tick);
			var step = key.from + ease * key.range;
	
			var object = childrens.get(key.name);

			switch (key.type) {
				case "x": object.x = step;
				case "y": object.y = step;
				case "scaleX": object.scaleX = step;
				case "scaleY": object.scaleY = step;
				case "rotation": object.rotation = step;
				case "alpha": object.alpha = step;
			}
		}
	}


	public dynamic function onEvent(event:String) {}
	public dynamic function onEnd() {}


	override function sync(ctx:h2d.RenderContext) {
		super.sync(ctx);
		if (animation == null) return;
		if (playing) update(ctx.elapsedTime);
	}


	public static function from(path:String, prefab:Animation):Null<Timeline> {
		var res = Lib.read(path);

		if (res.animation == null) return null;
		if (res.animation.length == 0) return null;

		var animation = new Timeline();

		animation.duration = res.duration;
		animation.speed = res.speed;
		animation.loop = res.loop;

		for (entry in res.animation) {
			var frame = new Frame();

			frame.name = entry.name;
			frame.type = entry.type;

			frame.ease = entry.ease ?? "linear";
		
			frame.start = entry.start;
			frame.end = entry.end;
		
			frame.from = entry.from;
			frame.to = entry.to;

			frame.speed = frame.end - frame.start;
			frame.range = frame.to - frame.from;

			prefab.childrens.set(frame.name, prefab.getObjectByName(frame.name));
			animation.frame.push(frame);
		}

		for (entry in res.events) {
			var frame = new Frame();

			frame.name = entry.name;
			frame.start = entry.start;

			animation.event.push(frame);
		}

		return animation;
	}


	static function easing(type:String, t:Float):Float {
		switch(type) {
			case "linear": 
				return t;

			case "stepped": 
				return t < 1 ? 0 : 1;
	
			case "easeIn": 
				return t * t * t;

			case "easeOut": 
				var u = t - 1;
				return u * u * u + 1;

			case "easeInOut": 
				if (t < 0.5) return 4 * t * t * t;
				var u = 2 * t - 2;
				return 0.5 * u * u * u + 1;
				
			case "backIn":
				var c = 1.70158;
				return (c + 1) * t * t * t - c * t * t;

			case "backOut":
				var c = 1.70158;
				t -= 1;
				return 1 + (c + 1) * t * t * t + c * t * t;

			case "backInOut":
				var c = 1.70158 * 1.525;
	
				if (t < 0.5) {
					var u = 2 * t;
					return (u * u * ((c + 1) * u - c)) / 2;
				}
	
				var u = 2 * t - 2;
				return (u * u * ((c + 1) * u + c) + 2) / 2;
	
			case "elastic":
				if (t == 0 || t == 1) return t;
				return Math.pow(2, -10 * t) * Math.sin((t * 10 - 0.75) * (2 * Math.PI / 3)) + 1;
	
			case "bounce":
				if (t < 1 / 2.75) {
					return 7.5625 * t * t;
				}
				else if (t < 2 / 2.75) {
					t -= 1.5 / 2.75;
					return 7.5625 * t * t + 0.75;
				}
				else if (t < 2.5 / 2.75) {
					t -= 2.25 / 2.75;
					return 7.5625 * t * t + 0.9375;
				}
				else {
					t -= 2.625 / 2.75;
					return 7.5625 * t * t + 0.984375;
				}
	
			default: return t;
		}
	}


	static function clamp(time:Float, key:Frame):Float {
		if (key.start == key.end) return 1;
		return hxd.Math.clamp((time - key.start) / key.speed);
	}
}


class Timeline {
	public var duration:Float = 1;
	public var speed:Float = 1.0;
	public var loop:Bool = true;

	public var frame:Array<Frame> = [];
	public var event:Array<Frame> = [];

	public function new() {}
}


class Frame {
	public var name:String;
	public var type:String;
	public var ease:String;
	
	public var speed:Float;
	public var range:Float;

	public var start:Float;
	public var end:Float;

	public var from:Float;
	public var to:Float;

	public function new() {}
}