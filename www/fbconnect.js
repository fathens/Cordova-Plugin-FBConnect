var cordova = require("cordova/exec");

var pluginName = "FBConnectPlugin"

var names = [ "login", "logout", "getToken", "getName" ];

var obj = {};

names.forEach(function(methodName) {
    obj[methodName] = function() {
        var log = function(msg) {
            if (obj.logger) {
                logger.debug(function() {
                    return '(' + methodName + ') ' + msg;
                });
            } else {
                console.log(msg);
            }
        }
        var args = Array.prototype.slice.call(arguments, 0);
        log('Arguments: ' + JSON.stringify(args));
        return new Promise(function(resolve, reject) {
            cordova(function(result) {
                log('Result: ' + result);
                resolve(result);
            }, function(err) {
                log('Error: ' + err);
                reject(err);
            }, pluginName, methodName, args);
        });
    }
});

module.exports = obj;
