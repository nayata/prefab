package hxe;

class Prefab extends h2d.Object {
	@:allow(hxe.Lib) var hierarchy:Map<String, h2d.Object> = new Map();


	/** 
		Creates a `Prefab` instance and loads its visual content from the prefab file at the specified `path`.
		The created objects are instantiated and attached to this prefab’s `hierarchy` using `hxe.Lib.make`.

		@param path Prefab file name. Can point to a subfolder and must be specified without an extension.
		@param parent An optional parent `h2d.Object` instance to which the prefab adds itself, if set.
		@param fields An optional `hxe.Lib.Field` structure used to override default values for objects in the prefab hierarchy.
	**/
	public function new(?path:String, ?parent:h2d.Object, ?fields:Array<hxe.Lib.Field>) {
		super(parent);

		if (path != null) {
			hxe.Lib.make(path, this, fields);
			init();
		}
	}


	/** Initialize the prefab after instantiation. **/
	public function init() {}


	/** Update the prefab from the outside with the given delta time. **/
	public function update(dt:Float) {}


	/**
		Get an object from the prefab hierarchy by name.

		If the optional class `c` is provided, the returned object is verified to be of that type,
		returning null if it does not match. If `c` is not provided, the object is returned directly(unsafe cast).

		@param n Name of the object in the hierarchy
		@param c Optional class to enforce type checking
	**/
	public function get<T:h2d.Object>(n:String, ?c:Class<T>):Null<T> {
		var obj = hierarchy.get(n);
		if (obj == null) return null;
	
		if (c == null) {
			return cast obj;
		}
	
		return Std.isOfType(obj, c) ? cast obj : null;
	}


	/**
		Find all objects of the given class `c` in the prefab hierarchy.
		@param all An optional array instance to fill results with. Allocates a new array if not set.
	**/
	public function all<T:h2d.Object>(c:Class<T>, ?all:Array<T>):Array<T> {
		if (all == null) all = [];
		
		for (o in hierarchy) {
			var i = Std.downcast(o, c);
			if (i != null) all.push(i);
		}
		return all;
	}


	/** Check if the prefab has a object in the hierarchy with the given `n` name. **/
	public function has(n:String):Bool return hierarchy.exists(n);


	/** Check if the prefab matches the given class `c`. **/
	public function is<T:Prefab>(c:Class<T>):Bool return Std.isOfType(this, c);

	
	/** Converts the prefab to another `c` prefab class. **/
	public function as<T:Prefab>(c:Class<T>):T return Std.downcast(this, c);


	/** Get the class name of the object from the prefab hierarchy with the given name `n`. **/
	public function typeof(n:String):String {
		if (!hierarchy.exists(n)) return "Object not found";
		
		var cl = Type.getClass(hierarchy.get(n));
		return Type.getClassName(cl);
	}
}