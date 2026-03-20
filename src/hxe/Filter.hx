package hxe;

class Filter {
	public static function from(filters:Array<Lib.Entry>):h2d.filter.Group {
		var group = new h2d.filter.Group();

		for (entry in filters) {
			var filter:h2d.filter.Filter = null;

			switch (entry.name) {
				case "ColorMatrix":
					var colorMatrix = new h2d.filter.ColorMatrix();
					colorMatrix.matrix.adjustColor(entry.prop);
					filter = colorMatrix;
	
				case "DropShadow":
					filter = new h2d.filter.DropShadow();
					apply(filter, entry.prop);
	
				case "Outline":
					filter = new h2d.filter.Outline();
					apply(filter, entry.prop);
	
				case "Glow":
					filter = new h2d.filter.Glow();
					apply(filter, entry.prop);
	
				case "Blur":
					filter = new h2d.filter.Blur();
					apply(filter, entry.prop);
			}
			
			group.add(filter);
		}

		return group;
	}

	static function apply(target:h2d.filter.Filter, props:Dynamic) {
		for (f in Reflect.fields(props)) {
			var v = Reflect.field(props, f);
			Reflect.setProperty(target, f, v);
		}
	}
}