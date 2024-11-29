package hxe;


class Lib {
	static var cache:Map<String, hxd.res.Atlas> = new Map();
	static var keepAssets:Bool = true;


	// Load prefab and set prefab objects to `object:Dynamic` instance fields
	public static function bind(path:String, object:Dynamic) {
		var fields = Type.getInstanceFields(Type.getClass(object));

		var hierarchy = get(path, (cast object : h2d.Object));

		for (field in fields) {
			if (hierarchy.exists(field)) {
				Reflect.setField(object, field, hierarchy.get(field));
			}
		}
	}


	// Load data and create Prefab by given `type:Class<Dynamic>` Class
	public static function make(path:String, type:Class<Dynamic>, ?parent:h2d.Object):Dynamic {
		var object = Type.createInstance(type, [parent]);
		var fields = Type.getInstanceFields(type);

		object.hierarchy = get(path, (cast object : h2d.Object));
		object.name = getName(path);

		for (field in fields) {
			if (object.hierarchy.exists(field)) {
				Reflect.setField(object, field, object.hierarchy.get(field));
			}
		}

		return object;
	}


	// Load Prefab
	// Optional `field` for prefab custom values
	public static function load(path:String, ?parent:h2d.Object, ?field:Array<Field>):Prefab {
		var prefab = new Prefab(parent);
		prefab.hierarchy = get(path, prefab, field);
		prefab.name = getName(path);

		return prefab;
	}


	// Load hierarchy and create objects
	static function get(path:String, parent:h2d.Object, ?field:Array<Field>):Map<String, h2d.Object> {
		var raw = hxd.Res.load(path + ".prefab");
		var res:Data = haxe.Json.parse(raw.entry.getText());

		var hierarchy:Map<String, h2d.Object> = new Map();
		var childrens:Map<String, h2d.Object> = new Map();

		for (entry in res.children) {
			var object:h2d.Object = null;

			// Object
			if (entry.type == "object") {
				var item = new h2d.Object();

				hierarchy.set(entry.link, item);
				childrens.set(entry.name, item);
				object = item;
			}

			// Bitmap
			if (entry.type == "bitmap") {
				var tile:h2d.Tile;

				// 1. Bitmap tile from Texture Atlas
				// 2. Bitmap tile from Image

				if (entry.atlas != null) {
					if (!hxd.res.Loader.currentInstance.exists(entry.path)) throw("Could not find atlas " + entry.atlas + ".atlas");

					// Load and store Texture Atlas
					var atlas = getAtlas(entry.path);
					tile = atlas.get(entry.src);

					// Override bitmap tile with value from field
					if (field != null) {
						for (key in field) {
							if (key.name == entry.link && key.type == "bitmap") tile = atlas.get(key.value);
						}
					}
				}
				else {
					if (!hxd.res.Loader.currentInstance.exists(entry.src)) throw("Could not find image " + entry.src);
					tile = hxd.Res.load(entry.src).toImage().toTile();
				}

				var item = new h2d.Bitmap(tile);

				if (entry.width != null) item.width = entry.width;
				if (entry.height != null) item.height = entry.height;

				if (entry.smooth != null) item.smooth = entry.smooth == 1 ? true : false;
				if (entry.dx != null) item.tile.setCenterRatio(entry.dx, entry.dy);

				hierarchy.set(entry.link, item);
				childrens.set(entry.name, item);
				object = item;
			}

			// Text
			if (entry.type == "text") {
				var font = hxd.res.DefaultFont.get();
				if (entry.font != null) {
					if (!hxd.res.Loader.currentInstance.exists(entry.src)) throw("Could not find Font file " + entry.src);
					font = hxd.Res.load(entry.src).to(hxd.res.BitmapFont).toFont();
				}

				var item = new h2d.Text(font);
				item.smooth = true;

				if (entry.color != null) item.textColor = entry.color;
				if (entry.width != null) item.maxWidth = entry.width;
				if (entry.height != null) item.lineSpacing = entry.height;

				if (entry.align != null) {
					switch (entry.align) {
						case 1 : item.textAlign = Center;
						case 2 : item.textAlign = Right;
						default : item.textAlign = Left;
					}
				}

				item.text = entry.text ?? "";

				// Override text with value from field
				if (field != null) {
					for (key in field) {
						if (key.name == entry.link && key.type == "text") item.text = key.value;
					}
				}

				hierarchy.set(entry.link, item);
				childrens.set(entry.name, item);
				object = item;
			}

			// Interactive
			if (entry.type == "interactive") {
				var item = new h2d.Interactive(128, 128);

				item.width = Std.int(entry.width);
				item.height = Std.int(entry.height);

				if (entry.smooth != null) item.isEllipse = true;

				hierarchy.set(entry.link, item);
				childrens.set(entry.name, item);
				object = item;
			}

			// Graphics
			if (entry.type == "graphics") {
				var item = new h2d.Graphics();

				var c = entry.color ?? 0xFFFFFF;
				var w = entry.width ?? 128;
				var h = entry.height ?? 128;

				item.beginFill(c);
				item.drawRect(0, 0, w, h);
				item.endFill();

				hierarchy.set(entry.link, item);
				childrens.set(entry.name, item);
				object = item;
			}

			// Linked Prefab with fields
			if (entry.type == "prefab") {
				if (!hxd.res.Loader.currentInstance.exists(entry.src)) throw("Could not find Prefab file " + entry.src);

				var path = entry.src.split(".").shift();
				var item = load(path, object, entry.field);

				hierarchy.set(entry.link, item);
				childrens.set(entry.name, item);
				object = item;
			}

			if (object == null) continue;

			// Set object name
			object.name = entry.link;

			// Set object transform
			object.x = entry.x ?? 0;
			object.y = entry.y ?? 0;

			object.scaleX = entry.scaleX ?? 1;
			object.scaleY = entry.scaleY ?? 1;

			object.rotation = entry.rotation ?? 0;

			// Set display options
			if (entry.blendMode != null) object.blendMode = haxe.EnumTools.createByName(h2d.BlendMode, entry.blendMode);
			object.visible = entry.visible ?? true;
			object.alpha = entry.alpha ?? 1;


			// Place object
			var p:h2d.Object = entry.parent != null ? childrens.get(entry.parent) : parent;
			p.addChild(object);
		}

		return hierarchy;
	}



	// Load or get Texture Atlas
	static function getAtlas(path:String):hxd.res.Atlas {
		var name = getName(path);

		// Already loaded
		if (cache.exists(name)) return cache.get(name);

		// Load and save
		var atlas = hxd.Res.load(path).to(hxd.res.Atlas);
		cache.set(name, atlas);

		return atlas;
	}


	// Name from Path
	static inline function getName(path:String):String {
		return haxe.io.Path.withoutDirectory(path).split(".").shift();
	}


	public static function setCache(atlas:hxd.res.Atlas) {
		cache.set(getName(atlas.name), atlas);
	}


	public static function cleanCache() {
		cache = new Map();
	}
}


typedef Field = { name : String, type : String, value : String };

typedef Data = {
	var name : String;
	var type : String;
	var link : String;

	@:optional var children : Array<Data>;
	@:optional var parent : String;

	@:optional var x : Float;
	@:optional var y : Float;
	@:optional var scaleX : Float;
	@:optional var scaleY : Float;
	@:optional var rotation : Float;

	@:optional var blendMode : String;
	@:optional var visible : Bool;
	@:optional var alpha : Float;

	@:optional var src : String;

	@:optional var width : Float;
	@:optional var height : Float;

	@:optional var smooth : Int;
	
	@:optional var dx : Float;
	@:optional var dy : Float;

	@:optional var color : Int;
	@:optional var align : Int;

	@:optional var text : String;
	@:optional var atlas : String;
	@:optional var font : String;
	@:optional var path : String;

	@:optional var field : Array<Field>;
}