var cordova = require("cordova/exec");

var pluginName = "FBConnectPlugin"

var names = [ "login", "logout", "getToken", "getName" ];

var obj = {};

names.forEach(function(methodName) {
    obj[methodName] = function() {
        return new Promise(function(resolve, reject) {
            cordova(resolve, reject, pluginName, methodName, arguments);
        });
    }
});

module.exports = obj;
