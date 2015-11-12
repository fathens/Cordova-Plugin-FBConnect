var cordova = require("cordova/exec");

var pluginName = "FBConnectPlugin"

var names = [ "renewSystemCredentials", "login", "getName" ];

var obj = {};

names.forEach(function(methodName) {
	obj[methodName] = function() {
		callback = arguments[0]
		args = Array.prototype.slice.call(arguments, 1);
		callback(null, "Calling " + pluginName + "." + methodName + ": " + args);
	}
});

module.exports = obj;
