var cordova = require("cordova/exec");

var pluginName = "FBConnectPlugin"

var names = [ "login", "logout", "getToken", "getName" ];

var obj = {};

names.forEach(function(methodName) {
    obj[methodName] = function() {
        return new Promise(function(resolve, reject) {
            cordova(function(result) {
                console.log('Result of ' + pluginName + ': ' + result);
                resolve(result);
            }, function(err) {
                console.log('Error of ' + pluginName + ': ' + err);
                reject(err);
            }, pluginName, methodName, arguments);
        });
    }
});

module.exports = obj;
