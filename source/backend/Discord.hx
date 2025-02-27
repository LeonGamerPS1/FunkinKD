package backend;

import sys.thread.Thread;
#if DISCORD_ENABLED
import discord_rpc.DiscordRpc;

class Discord {
	@:unreflective
	private static inline var APPILCATION_ID:String = "1320028873290809364";

	public static function init() {
		Thread.create(function() {
			DiscordRpc.start({
				clientID: APPILCATION_ID,
				onReady: () -> return,
				onError: onError,
				onDisconnected: onDisconnected
			});

			while (true) {
				DiscordRpc.process();
			}

			DiscordRpc.shutdown();
		});
	}

	static function onError(_code:Int, _message:String) {
		trace('Error! $_code : $_message');
	}

	static function onDisconnected(_code:Int, _message:String) {
		trace('Disconnected! $_code : $_message');
	}
}
#else
#error "Cannot use backend.Discord if DISCORD_ENABLED hasn't been defined properly"
#end
