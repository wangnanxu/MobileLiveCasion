﻿package  HistoryRoad.MoreGame{
	import flash.geom.Point;
	import HistoryRoad.*;
	public class BaccaratMoreGameHistoryResult extends BaccaratHistoryResultManger {

		public function BaccaratMoreGameHistoryResult() {
			// constructor code
			strPearlTable="HistoryRoad.MoreGame.LobbyMorePearlTable";
			strBigTable=null;
			strBigEyesTable=null;
			strSmallTable=null;
			strSmallForcedTablele=null;
			strRoadInfo="";
			roadPos=[new Point(0,0),new Point(186,0),new Point(186,54),new Point(186,82),new Point(336,82)];
			super();
			//roadView=["HistoryRoad.PearlTable","HistoryRoad.LobbyBigTable","HistoryRoad.BigEyesTable","HistoryRoad.SmallTable","HistoryRoad.SmallForcedTable"];
			
		}

	}
	
}
