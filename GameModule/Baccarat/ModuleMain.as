﻿package {
	import flash.display.MovieClip;
	import flash.system.*;
	import flash.events.Event;

	import IGameFrame.IGameClass;
	import IGameFrame.IGameModule;

	//模块类
	public class ModuleMain extends MovieClip implements IGameModule {
		public function ModuleMain () {
			//Security.allowDomain ("*");
			System.useCodePage = true;
		}
		//查询游戏类接口
		public function getIGameClass ():IGameClass {
			var game:GameClass;
			var igame:IGameClass;
			try {
				game = new GameClass();
				igame = game.QueryIGameClass();
				return igame;
			} catch (e:Event) {
				System.setClipboard (e.toString());
			}
			game = null;
			igame = null;
			return null;
		}
	}
}