var cordova = require("cordova/exec");

var pluginName = "FBConnectPlugin"

var names = [ "renewSystemCredentials", "login", "getName" ];

var obj = {};

names.forEach(function(methodName) {
	obj[methodName] = function() {
		callback = arguments[0]
		args = Array.prototype.slice.call(arguments, 1);

		cordova(function(result) {
			callback(null, result);
		}, function(error) {
			callback(error);
		}, pluginName, methodName, args);
	}
});

module.exports = obj;
