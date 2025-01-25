package funkin.backend;

import openfl.net.FileReference;

class FileDialog {
	var fileRef:FileReference;

	public function new() {
		fileRef = new FileReference();
		fileRef.browse();
	}
}
