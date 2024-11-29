package hxe;


class Prefab extends h2d.Object {
	@:allow(hxe.Lib) var hierarchy:Map<String, Dynamic> = new Map();


	public function has(n:String):Bool {
		return hierarchy.exists(n);
	}


	public function get(n:String) {
		return hierarchy.get(n);
	}


	public function is<T:Prefab>(c:Class<T>) return Std.isOfType(this, c);
	public function as<T:Prefab>(c:Class<T>) : T return Std.downcast(this, c);


	public function typeof(n:String):String {
		if (!hierarchy.exists(n)) return "Object not found";
		
		var cl = Type.getClass(hierarchy.get(n));
		return Type.getClassName(cl);
	}
}