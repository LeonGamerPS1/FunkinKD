package funkin.macro;


import sys.FileSystem;
import sys.io.File;
#if macro
import haxe.macro.Expr.Field;
import haxe.macro.Context;
#end


class VersionMacro
{
	public static function getBuildNum()
	{
        
		#if (macro && !display)
		var fields = Context.getBuildFields();
		if(!FileSystem.exists("export.build"))
			File.saveContent("export.build","0");
		File.saveContent("export/.build",'${Std.parseInt(File.read("export/.build").readAll().toString()) + 1}');
		File.saveContent("assets/buildNum.txt",'${Std.parseInt(File.read("export/.build").readAll().toString())}');

		var buildNum:Field = [for (field in fields) if (field.name == 'get_buildNum') field][0];
		switch (buildNum.kind)
		{
			case FFun(f):
				buildNum.kind = FFun({
					args: f.args,
					params: f.params,
					ret: f.ret,
					expr: macro
					{
						return Std.parseInt(openfl.utils.Assets.getText("assets/buildNum.txt"));
					}
				});
			default:
		}

		return fields;
		#end
	}
}
