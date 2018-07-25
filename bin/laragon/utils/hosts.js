var fs = require("fs");
console.log(process.argv.length);
if (process.argv.length != 4) {
	console.log("You must specify exact arguments!");
	process.exit();
}
var hostsFile = process.argv[2];   
var hostsFileTmp = process.argv[3];  
var content = '';

fs.readFile(hostsFileTmp, function read(err, data) {
	if (err) {
		throw err;
	}
	content = data;
	if (content !== '') {
		doWrite();
	}
});

function doWrite() {
	fs.writeFile(hostsFile, content, function(err) {
		if(err) {
			fs.renameSync(hostsFileTmp, hostsFileTmp + '.err');
			return console.log(err);
		}
	});
}
