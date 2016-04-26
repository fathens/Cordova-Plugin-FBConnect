var cordova = require("cordova/exec");

var pluginName = "FBConnectPlugin"

var names = [ "login", "logout", "getToken", "getName" ];

var obj = {};

names.forEach(function(methodName) {
    obj[methodName] = function() {
        var log = function(msg) {
            if (obj.logger) {
                logger.debug(function() {
                    return msg;
                });
            } else {
                console.log(msg);
            }
        }
        return new Promise(function(resolve, reject) {
            cordova(function(result) {
                log('Result of ' + pluginName + ': ' + result);
                resolve(result);
            }, function(err) {
                log('Error of ' + pluginName + ': ' + err);
                reject(err);
            }, pluginName, methodName, arguments);
        });
    }
});

module.exports = obj;
