package hxe;

class Layout extends Prefab {
	public var library:Array<Element> = [];
	public var profile(default, set):String = "Default";

	public var width:Float = 960;
	public var height:Float = 640;
	
	public var clipping:Bool = false;
	public var padding:Int = 0;


	public function new(?path:String, ?parent:h2d.Object, ?fields:Array<hxe.Lib.Field>) {
		super(parent);

		if (path != null) {
			hxe.Lib.make(path, this, fields);
			profile = path;
			onResize();
			init();
		}
	}


	function set_profile(name:String) {
		if (profile == name) return profile;

		library = from(name);
		profile = name;

		return profile;
	}


	function from(path:String):Array<Element> {
		var lib:Array<Element> = [];
		var res = Lib.read(path);

		for (entry in res.children) {
			if (entry.type == "layout" && entry.children != null) {
				var object = getObjectByName(entry.link);
				var origin = (cast object : Layout);

				origin.clipping = false;
				origin.padding = 0;

				clipping = entry.clipping ?? false;
				padding = entry.padding ?? 0;

				for (child in entry.children) {
					var element = new Element();

					element.name = child.name;
					element.type = child.type;
			
					element.width = child.width;
					element.height = child.height;

					element.resizeX = Std.int(child.x);
					element.resizeY = Std.int(child.y);

					element.scaleX = child.scaleX;
					element.scaleY = child.scaleY;
		
					element.anchorX = child.dx;
					element.anchorY = child.dy;
		
					var layout = child.path == entry.link ? this : getObjectByName(child.path);
					var object = getObjectByName(child.name);

					if (child.type == "layout") {
						Reflect.setProperty(object, "clipping", child.clipping ?? false);
						Reflect.setProperty(object, "padding", child.padding ?? 0);
					}
		
					element.parent = (cast layout : Layout);
					element.object = object;

					lib.push(element);
				}
			}
		}

		return lib;
	}


	public function add(child:Layout, to:String = ""):Element {
		var layout:Layout = get(to, Layout) ?? this;
		layout.addChild(child);

		var element = new Element();

		element.name = child.name;
		element.type = "layout";
	
		element.parent = layout;
		element.object = child;

		element.width = child.getBounds(child).width;
		element.height = child.getBounds(child).height;

		library.push(element);
		onResize();

		return element;
	}


	public function set(child:h2d.Object, to:String = ""):Element {
		var type = Type.getClassName(Type.getClass(child));

		var layout:Layout = get(to, Layout) ?? this;
		layout.addChild(child);

		var element = new Element();

		element.name = child.name;
		element.type = type.split(".").pop().toLowerCase();
	
		element.parent = layout;
		element.object = child;

		element.width = child.getBounds(child).width;
		element.height = child.getBounds(child).height;

		library.push(element);
		onResize();

		return element;
	}


	public function search(object:h2d.Object):Null<Element> {
		for (child in library) {
			if (child.object == object) return child;
		}
		return null;
	}


	public function onResize() {
		width = hxd.Window.getInstance().width;
		height = hxd.Window.getInstance().height;
		checkResize();
	}


	public function checkResize() {
		for (child in library) {
			var parent = child.parent;

			var w:Float = parent.width - parent.padding * 2;
			var h:Float = parent.height - parent.padding * 2;

			var width:Float = w;
			var height:Float = h;

			if (child.resizeX == ScaleMode.RESIZE) width = width * (child.scaleX / 100);
			if (child.resizeY == ScaleMode.RESIZE) height = height * (child.scaleY / 100);

			var resizeX = width / child.width;
			var resizeY = height / child.height;
		
			var scaleX = 1.0;
			var scaleY = 1.0;

			// STRETCH
			if (child.resizeX == ScaleMode.RESIZE && child.resizeY == ScaleMode.RESIZE) {
				scaleX = resizeX;
				scaleY = resizeY;
			}
			// AUTO
			if (child.resizeX == ScaleMode.AUTO && child.resizeY == ScaleMode.AUTO) {
				var s = (child.width > width || child.height > height) ? Math.min(resizeX, resizeY) : 1.0;
				scaleX = scaleY = s;
			}
			// COVER width
			if (child.resizeX == ScaleMode.RESIZE && child.resizeY == ScaleMode.AUTO) {
				scaleX = scaleY = resizeX;
			}
			// COVER height
			if (child.resizeX == ScaleMode.AUTO && child.resizeY == ScaleMode.RESIZE) {
				scaleX = scaleY = resizeY;
			}

			var sizeX = child.width * scaleX;
			var sizeY = child.height * scaleY;

			switch (child.type) {
				case "layout":
					var layout = (cast child.object : Layout);

					layout.width = width;
					layout.height = height;

					sizeX = width;
					sizeY = height;

					layout.checkResize();

				case "scalegrid", "interactive", "mask":
					Reflect.setProperty(child.object, "width", sizeX);
					Reflect.setProperty(child.object, "height", sizeY);

				default:
					child.object.scaleX = scaleX;
					child.object.scaleY = scaleY;
			}

			child.object.x = parent.padding + (w - sizeX) * child.anchorX;
			child.object.y = parent.padding + (h - sizeY) * child.anchorY;
		}
	}


	override function drawRec(ctx:h2d.RenderContext) {
		if (clipping) h2d.Mask.maskWith(ctx, this, Std.int(width), Std.int(height), 0, 0);
		super.drawRec(ctx);
		if (clipping) h2d.Mask.unmask(ctx);
	}
}


class ScaleMode {
	public static inline var AUTO:Int = 0;
	public static inline var RESIZE:Int = 1;
}


class Element {
	public var name:String = "element";
	public var type:String = "element";
	public var path:String = "element";

	public var parent:Layout;
	public var object:h2d.Object;

	public var width:Float = 0;
	public var height:Float = 0;

	public var anchorX:Float = 0;
	public var anchorY:Float = 0;

	public var resizeX:Int = 0;
	public var resizeY:Int = 0;

	public var scaleX:Float = 100;
	public var scaleY:Float = 100;

	public function new() {}
}