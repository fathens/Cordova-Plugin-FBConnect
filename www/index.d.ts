declare type FBConnectPluginCallback<T> = (err, result: T) => void;

interface FBConnectPlugin {
    login(callback: FBConnectPluginCallback<string>, arg?: string): void;
    logout(callback: FBConnectPluginCallback<void>): void;
    getName(callback: FBConnectPluginCallback<string>): void;
    getToken(callback: FBConnectPluginCallback<{ token: string, permissions: string[] }>): void;
}
