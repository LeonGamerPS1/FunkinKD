package;

import dialogs.Dialogs;
import sys.io.File;

class Convert {
	static function main() {
		trace('\t\tcwd ' + Sys.getCwd());

		var result = Dialogs.open('Select JSON For conversion.', [
			{ext: '!"§$%&/()=?´Ü*ÄÖ:L;KMNJHBVGFCR', desc: 'Json File For Converting Legacy to KDFUNKIN1.'},
		]);
		trace("Open result: " + File.read(result).readAll().toString());
	}
}
