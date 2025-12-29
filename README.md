# About
[HEXE](https://github.com/nayata/hexe) prefabs API for Heaps based projects


# Usage

Download the editor and create your prefab. 

Install

```
haxelib install prefab
```

Alternatively the dev version of the library can be installed from github:

```
haxelib git prefab https://github.com/nayata/prefab.git
```

Include the library in your project's `.hxml`:

```
-lib prefab
```

Use `hxe.Lib` to load and add a prefab instance to the scene. Note: the prefab name must be without extension.

```haxe
var object:hxe.Prefab = hxe.Lib.load("myPrefab", s2d);
```

Or create prefab directly:

```haxe
var object = new Prefab("myPrefab", s2d);
```


# Documentation

* [Introduction](https://nayata.github.io/hexe)  
* [Quick Start](https://nayata.github.io/hexe/#quick-start)  
* [Working with editor](https://nayata.github.io/hexe/#working-with-editor)  
* [In-game implementation](https://nayata.github.io/hexe-lib)  
* [API](https://nayata.github.io/hexe-api)
