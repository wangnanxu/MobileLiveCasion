﻿package Common{
{
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BitmapFilter;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;

	[Event(name="select", type="flash.events.Event")]
	[Event(name="scroll", type="flash.events.Event")]

	/**
	 * @author Mousebomb (mousebomb@gmail.com)
	 * @date 2009-12-30
	 */
	public class DatePicker extends Sprite 
	{
		private var _dayNames :Object = {en:["S","M", "T", "W", "T", "F", "S"],
										ch:["日","一", "二", "三", "四", "五", "六"],
										tw:["日","一", "二", "三", "四", "五", "六"]};
		private var _disabledDays : Array = [];
		private var _firstDayOfWeek : uint = 1;
		private var _monthNames : Object = {en:["January", "February", "March", "April", "May", "June", "July", "August", "September", "October","November", "December"],
											ch:["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月","十一月", "十二月"],
											tw:["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月","十一月", "十二月"]};
		private var _showToday : Boolean;
		private var _selectableRangeStart : Date = new Date(1900, 0, 1);
		private var _selectableRangeEnd : Date = new Date(2999, 11, 31);
		private var _selectedDate : Date = new Date();  //选中的Date，默认是今天，可能和显示的月份不同
		private var _todayDate : Date = new Date();  //指示今天

		private var daysMonthArray : Array = new Array(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
		private var mCount : Number;
		private var yCount : Number;	
		
		//是否允许滚动
		private var _disallowPrev:Boolean;
		private var _disallowNext:Boolean;

		//是否已初始化
		private var _inited : Boolean;

		//display:
		private var board : Sprite;
		private var nextBtn : Sprite;
		private var dayRow : Sprite;
		private var prevBtn : Sprite;
		private var calendar : Sprite;
		private var monthTf : TextField;
		private var gridCont : Sprite; 

		//样式
		protected var _tfmDayNameRow : TextFormat;
		protected var _tfmMonth : TextFormat ;
		protected var _tfmSelectedDay : TextFormat ;
		protected var _tfmGrid : TextFormat ;
		protected var _tfmDisabledDay : TextFormat ;
		protected var _tfmToday : TextFormat ;

		public var bgColorDayNameRow : uint = 0x4D4D4D;
		public var bgColorSelectedDay : uint = 0x666666;
		public var bgColorGrid : uint = 0x4D4D4D;
		public var bgColorDisabled : uint = 0x4D4D4D;
		public var bgColorToday : uint = 0x666666;
		public var arrowColor : uint = 0xffffff;
		public var lineColorSelectDay:uint = 0xCCA246;
		public var lineColorToday:uint = 0x4D4D4D;
		protected var m_lang:String;//语言
		
		/**
		 * @param autoInit	是否自动初始化，设置为true的话则被AddedToStage的时候初始化
		 */
		public function DatePicker(autoInit : Boolean = true)
		{
			_tfmDayNameRow = defaultTxtFormat("dayNameRow");
			_tfmMonth = defaultTxtFormat("month");
			_tfmSelectedDay = defaultTxtFormat("selectedDay");
			_tfmGrid = defaultTxtFormat("dateGrid");
			_tfmDisabledDay = defaultTxtFormat("tfmDisabledDay");
			_tfmToday = defaultTxtFormat("tfmToday");
			if(autoInit)
			{
				addEventListener(Event.ADDED_TO_STAGE, onAdd2StageInit);
			}
		}
		public function Destroy():void {
			nextBtn.removeEventListener(MouseEvent.CLICK, onNextClick);
			nextBtn.removeEventListener(MouseEvent.MOUSE_DOWN, onDown);
			nextBtn.removeEventListener(MouseEvent.MOUSE_UP, onOver);
			nextBtn.removeEventListener(MouseEvent.MOUSE_OVER, onOver);
			nextBtn.removeEventListener(MouseEvent.MOUSE_OUT, onOut);
			
			prevBtn.removeEventListener(MouseEvent.CLICK, onPrevClick);
			prevBtn.removeEventListener(MouseEvent.MOUSE_DOWN, onDown);
			prevBtn.removeEventListener(MouseEvent.MOUSE_UP, onOver);
			prevBtn.removeEventListener(MouseEvent.MOUSE_OVER, onOver);
			prevBtn.removeEventListener(MouseEvent.MOUSE_OUT, onOut);
			
			var len : int = gridCont.numChildren;
			for(var i : int = len - 1 ;i >= 0;--i)
			{
				var gridItem : Sprite = gridCont.getChildAt(i) as Sprite;
				gridItem.removeEventListener(MouseEvent.CLICK, onDateClick);
				gridItem.removeEventListener(MouseEvent.MOUSE_DOWN, onDateDown);
				gridItem.removeEventListener(MouseEvent.MOUSE_UP, onDateOver);
				gridItem.removeEventListener(MouseEvent.MOUSE_OVER, onDateOver);
				gridItem.removeEventListener(MouseEvent.MOUSE_OUT, onDateOut);
				gridCont.removeChildAt(i);
			}
			
			while (numChildren > 0) {
				removeChildAt (0);
			}
		}
		private function defaultTxtFormat(str : String) : TextFormat
		{
			var fmt : TextFormat = new TextFormat("Microsoft YaHei", 14, 0xffffff);
			if(str == "dateGrid")
			{
				fmt.align = TextFormatAlign.CENTER;
				//fmt.italic = true;
			}
			if(str == "dayNameRow") 
			{
				//fmt.bold = true;
				fmt.align = TextFormatAlign.CENTER;
			}
			if(str == "selectedDay") 
			{
				fmt.align = TextFormatAlign.CENTER;
				//fmt.bold = true;
			}
			if(str == "tfmDisabledDay")
			{
				fmt.align = TextFormatAlign.CENTER;
				//fmt.italic = true;
				fmt.color = 0x999999;
			}
			if(str == "tfmToday")
			{
				fmt.align = TextFormatAlign.CENTER;
				//fmt.italic = true;
				//fmt.underline = true;
				fmt.color = 0xffffff;
			}
			return fmt;
		}

		private function onAdd2StageInit(event : Event) : void
		{
			init();
			removeEventListener(Event.ADDED_TO_STAGE, onAdd2StageInit);
		}

		public function init() : void
		{
			if(_inited) return;
			//
			board = drawRadialBackground(240, 240);
			this.addChild(board);
			
			nextBtn = this.addChild(drawArrow(this.width - 25, 23, 0)) as Sprite;
			nextBtn.buttonMode = true;
			nextBtn.addEventListener(MouseEvent.CLICK, onNextClick);
			nextBtn.addEventListener(MouseEvent.MOUSE_DOWN, onDown);
			nextBtn.addEventListener(MouseEvent.MOUSE_UP, onOver);
			nextBtn.addEventListener(MouseEvent.MOUSE_OVER, onOver);
			nextBtn.addEventListener(MouseEvent.MOUSE_OUT, onOut);
			
			prevBtn = this.addChild(drawArrow(25, 23, 180)) as Sprite;
			prevBtn.buttonMode = true;
			prevBtn.addEventListener(MouseEvent.CLICK, onPrevClick);
			prevBtn.addEventListener(MouseEvent.MOUSE_DOWN, onDown);
			prevBtn.addEventListener(MouseEvent.MOUSE_UP, onOver);
			prevBtn.addEventListener(MouseEvent.MOUSE_OVER, onOver);
			prevBtn.addEventListener(MouseEvent.MOUSE_OUT, onOut);
			
			dayRow = this.addChild(drawDayNameRow(6, 40)) as Sprite;
			
			//**初始化日历动态部分
			calendar = new Sprite();
			calendar.x = 10;
			calendar.y = 18;
			this.addChild(calendar);

			//**年、月显示
			monthTf = new TextField();
			monthTf.autoSize = TextFieldAutoSize.CENTER;
			monthTf.width = 190;
			monthTf.y = -6;
			monthTf.x = (this.width - monthTf.width)/2 - 10;
			monthTf.setTextFormat(_tfmMonth);
			calendar.addChild(monthTf);
			
			//日历动态容器
			gridCont = new Sprite();
			calendar.addChild(gridCont);
			
			//**日历动态部分绘制
			drawDateGrid(_selectedDate.getMonth(), _selectedDate.getFullYear());
			//
			_inited = true;
		}

		private function onNextClick(e : MouseEvent) : void
		{
			//**只有当上个月有可选内容时才能滚动
			if(_disallowNext)
			{
				return;
			}
			//**
			clearDateGrid();				// remove current DateGrid-Sprite
			if(mCount == 11)
			{							
				// if month == 11 (December)
				mCount = 0;								// set month to 0 (January)
				yCount++;								// and increase the year counter by 1
			} 
			else 
			{
				mCount++;								// else increase month counter by 1
			}
			drawDateGrid(mCount, yCount);				// make DateGrid-Sprite for the next month
			dispatchEvent(new Event(Event.SCROLL));
		}

		private function onPrevClick(e : MouseEvent) : void
		{
			//**只有当上个月有可选内容时才能滚动
			if(_disallowPrev)
			{
				return;
			}
			//**
			clearDateGrid();
			if(mCount == 0)
			{							
				// if month == 0 (January)
				mCount = 11;							// set month to 11 (December)
				yCount--;								// and decrease the year counter by 1
			} 
			else 
			{
				mCount--;								// else decrease month counter by 1
			}
			drawDateGrid(mCount, yCount);				// make DateGrid-Sprite for the previous month
			dispatchEvent(new Event(Event.SCROLL));
		}
		private function onDown(e : MouseEvent) : void {
			drawButton(e.target as Sprite,0x333333);
		}
		private function onOver(e : MouseEvent) : void
		{
			drawButton(e.target as Sprite,0x666666);
		}
		private function onOut(e : MouseEvent) : void
		{
			drawButton(e.target as Sprite,0x4d4d4d);
		}
		
		private function onDateDown(e : MouseEvent) : void {
			var spr:Sprite = (e.target as Sprite);
			changeRoundColor(spr, 28, 0x333333, 0x333333, 1);
		}
		private function onDateOver(e : MouseEvent) : void {
			var spr:Sprite = (e.target as Sprite);
			changeRoundColor(spr, 28, 0x666666, 0x666666, 1);
		}
		private function onDateOut(e : MouseEvent) : void {
			var spr:Sprite = (e.target as Sprite);
			
			var bgrColor : uint = bgColorGrid;
			var lineColor : uint = bgColorGrid;
			var bgrAlpha : Number = 1;
			
			if(spr.name.indexOf(bgColorSelectedDay.toString())>-1) {
				//选中高亮
				bgrColor = bgColorSelectedDay;
				lineColor = lineColorSelectDay;
			} else if(spr.name.indexOf(bgColorToday.toString())>-1) {
				//今日高亮
				bgrColor = bgColorToday;
				lineColor = lineColorToday;
			}
			changeRoundColor(spr, 28, bgrColor, lineColor, bgrAlpha);
		}

		
		/**
		 * 产生表头行
		 * 显示周一到周日
		 */
		private function drawDayNameRow(tx : Number,ty : Number) : Sprite
		{
			var cont : Sprite = new Sprite();
			cont.x = tx;
			cont.y = ty;
			cont.addChild(drawRoundRect(this.width - 15, 22, bgColorDayNameRow, .8));
			//一周的七天
			for( var i : int = 0;i < 7;i++)
			{
				var dayTf : TextField = new TextField();
				dayTf.text = dayNames[(i + firstDayOfWeek) % 7];
				dayTf.width = 35; 
				dayTf.height = 22;
				dayTf.selectable = false;
				dayTf.y = 3;
				dayTf.x = i * 32;
				dayTf.setTextFormat(_tfmDayNameRow);
				cont.addChild(dayTf);
			}
			return cont;
		}

		/**
		 * 画一个圆角矩形，返回Sprite
		 */
		private function drawRoundRect(w : Number,h : Number,col : uint, alph : Number) : Sprite
		{  
			// creates a simple rect with a color-fill
			var s : Sprite = new Sprite();
			s.graphics.beginFill(col, alph);
			s.graphics.drawRoundRect(0, 0, w, h, 10);
			s.graphics.endFill();
			return s;
		}
		private function drawRound(w:Number, colFill : uint, colLine : uint, alph : Number):Sprite {
			//设置绘图效果并画图
			var s : Sprite = new Sprite();
			s.graphics.beginFill(colFill, alph);
			s.graphics.lineStyle(1,colLine);
			s.graphics.drawCircle(w/2, w/2, w/2);
			s.graphics.endFill();
			return s;
		}
		private function changeRoundColor(s : Sprite, w:Number, colFill : uint, colLine : uint, alph : Number):void {
			s.graphics.clear();
			s.graphics.beginFill(colFill);
			s.graphics.lineStyle(1,colLine);
			s.graphics.drawCircle(w/2, w/2, w/2);
			s.graphics.endFill();
		}

		private function drawDateGrid(mm : Number, yy : Number) : void
		{
			
			//**年、月显示
			monthTf.text = monthNames[mm] + " - " + yy;
			monthTf.setTextFormat(_tfmMonth);
			
			//**日期行
			//每四年二月闰年
			var daysNr : int = (yy % 4 == 0 && mm == 1) ? 29 : daysMonthArray[mm]; 
			var myDate : Date = new Date(yy, mm, 1);								
			// dayNameNr 用来确定该月第一天在第几格
			var dayNameNr : int = (myDate.getDay() - firstDayOfWeek) ;
			// 今天是星期几 0:周日 1~6  
			var curDay : int = myDate.getDay();
			while(dayNameNr < 0 )
			{
				dayNameNr += 7;
			}
			var row : int = 1;
			var disabled : Boolean;
			for(var i : int = 1;i <= daysNr;i++)
			{	
				if(dayNameNr == 0 && i != 1)  row++;  // 换行
				
				//**为格式化做准备
				//判定当前日期是否属于范围(selectableRange)
				if(myDate.valueOf() >= _selectableRangeStart.valueOf() && myDate.valueOf() <= _selectableRangeEnd.valueOf())
				{
					//判定当前创建的日是否被禁用(disabledDays)
					disabled = _disabledDays.indexOf(curDay) != -1;
				}
				else
				{
					disabled = true;
				}
				//是否当前渲染的日期是今天
				var isCurToday : Boolean = (_showToday && _todayDate.getDate() == i && _todayDate.getMonth() == mm && _todayDate.fullYear == yy);
				//是否当前渲染的日期是选中状态
				var isCurSelected : Boolean = (_selectedDate.fullYear == yy && _selectedDate.getMonth() == mm && _selectedDate.getDate() == i);
				
				
				//** 每个日期数字
				var gridItem : Sprite = new Sprite();
				gridItem.name = i + "." + (mm) + "." + yy;
				gridItem.x = dayNameNr * 32;
				gridItem.y = row * 29 + 30;
				gridItem.mouseChildren = false;
				if(!disabled)
				{
					gridItem.buttonMode = true;
					gridItem.addEventListener(MouseEvent.CLICK, onDateClick);
					gridItem.addEventListener(MouseEvent.MOUSE_DOWN, onDateDown);
					gridItem.addEventListener(MouseEvent.MOUSE_UP, onDateOver);
					gridItem.addEventListener(MouseEvent.MOUSE_OVER, onDateOver);
					gridItem.addEventListener(MouseEvent.MOUSE_OUT, onDateOut);
				}
				
				//** 每个日期数字的背景
				var bgrColor : uint = bgColorGrid;
				var lineColor : uint = bgColorGrid;
				var bgrAlpha : Number = 1;
				if(disabled)
				{
					//不可选 已禁用
					bgrColor = bgColorDisabled;
				}else if(isCurSelected) 
				{
					//选中高亮
					bgrColor = bgColorSelectedDay;
					lineColor = lineColorSelectDay;
				} else if(isCurToday)
				{
					//今日高亮
					bgrColor = bgColorToday;
					lineColor = lineColorToday;
				}
				else
				{
					//普通日期数字
				}
				gridItem.name = gridItem.name +"|"+bgrColor;
				
				changeRoundColor(gridItem, 28, bgrColor, lineColor, bgrAlpha);
			
				//** 每个日期数字的文本
				var gridItemTf : TextField = new TextField();
				gridItemTf.width = 28;
				gridItemTf.height = 28;
				gridItemTf.text = String(i);
				gridItemTf.selectable = false;
				
				//格式化字体
				if(disabled) {
					//禁用
					gridItemTf.setTextFormat(_tfmDisabledDay);
				} else if(isCurSelected)  {
					//选中高亮
					gridItemTf.setTextFormat(_tfmSelectedDay) ;
				} else if(isCurToday) {
					//今日
					gridItemTf.setTextFormat(_tfmToday);
				} else {
					gridItemTf.setTextFormat(_tfmGrid);
				}
				
				gridCont.addChild(gridItem);
				gridItem.addChild(gridItemTf);
				gridItemTf.y = 2;
				
				//维护今天星期几
				dayNameNr == 6 ? dayNameNr = 0 : dayNameNr++; 
				curDay == 6 ? curDay = 0 : curDay++;
				myDate.date++;
			}
			//**记下当前年月
			mCount = mm;
			yCount = yy;
			//**记下是否允许翻到下个月(根据选择范围)
			_disallowPrev = (selectableRangeStart.valueOf() >= new Date(yCount, mCount,1).valueOf());
			_disallowNext = (selectableRangeEnd.valueOf() <= myDate.valueOf());  //此时myDate是这个月月底
			
			if(row > 5 && board.height < 270) {
				removeChild(board);
				board = null;
				board = drawRadialBackground(240, 270);
				this.addChildAt(board, 0);
			} else if(row <= 5 && board.height > 240){
				removeChild(board);
				board = null;
				board = drawRadialBackground(240, 240);
				this.addChildAt(board, 0);
			}
		}

		private function clearDateGrid() : void
		{
			var len : int = gridCont.numChildren;
			for(var i : int = len - 1 ;i >= 0;--i)
			{
				var gridItem : Sprite = gridCont.getChildAt(i) as Sprite;
				gridItem.removeEventListener(MouseEvent.CLICK, onDateClick);
				gridItem.removeEventListener(MouseEvent.MOUSE_DOWN, onDateDown);
				gridItem.removeEventListener(MouseEvent.MOUSE_UP, onDateOver);
				gridItem.removeEventListener(MouseEvent.MOUSE_OVER, onDateOver);
				gridItem.removeEventListener(MouseEvent.MOUSE_OUT, onDateOut);
				gridCont.removeChildAt(i);
			}
		}

		private function onDateClick(e : MouseEvent) : void
		{
			var strName:String = (e.target as DisplayObject).name;
			var dateEle : Array = strName.split('|')[0].split(".");
			selectDate = new Date(dateEle[2], dateEle[1], dateEle[0]);
			this.dispatchEvent(new Event(Event.SELECT));
		}

		public function show() : void
		{
			visible = true;
		}

		public function hide() : void
		{
			visible = false;
		}

		private function drawArrow(__x : Number,__y : Number,__rot : Number) : Sprite
		{  
			var spr : Sprite = new Sprite();
			drawButton(spr, 0x4d4d4d);
			
			spr.x = __x;
			spr.y = __y;
			
			spr.rotation = __rot;
			return spr;
		}
		private function drawButton(spr : Sprite, color:uint):void {
			spr.graphics.clear();
			spr.graphics.beginFill(color, 1);
			spr.graphics.lineStyle(1, color);
			spr.graphics.drawCircle(0, 0, 14);
			spr.graphics.endFill();
			
			spr.graphics.moveTo(-3,-7.5);
			
			spr.graphics.lineStyle(3, 0xffffff);
			spr.graphics.lineTo(3.5, 0);
			spr.graphics.lineTo(-3, 7.5);
			spr.graphics.endFill();
			spr.graphics.moveTo(-2,6);
		}

		private function drawRadialBackground(tw : Number, th : Number) : Sprite
		{  
			// creates background with gradient-fill
			var bg : Sprite = new Sprite();
			var fillType : String = GradientType.LINEAR;
			var colors : Array = new Array();
			colors = [0x4D4D4D,0x4D4D4D];
			var alphas : Array = [1, 1];
			var ratios : Array = [0x00, 0xFF];
			var matr : Matrix = new Matrix();
			matr.createGradientBox(tw, th, 90, 0, 0);
			var spreadMethod : String = SpreadMethod.PAD;
			bg.graphics.beginGradientFill(fillType, colors, alphas, ratios, matr, spreadMethod);
			bg.graphics.lineStyle(1, 0x000000);
			bg.graphics.drawRoundRect(0, 0, tw, th, 8, 8);
			return bg;
		}

		public function get dayNames() : Array
		{
			return _dayNames[m_lang];
		}

		/**
		 * dayNames 设置一星期中各天的名称。该值是一个数组，其默认值为 ["日","一", "二", "三", "四", "五", "六"]。
		 */
		public function set dayNames(dayNames : Array) : void
		{
			_dayNames = dayNames;
		}

		public function get disabledDays() : Array
		{
			return _disabledDays;
		}

		/**
		 * 指示一星期中禁用的各天。该参数是一个数组，并且最多具有七个值。默认值为 []（空数组）。
		 */
		public function set disabledDays(disabledDays : Array) : void
		{
			_disabledDays = disabledDays;
		}

		public function get firstDayOfWeek() : uint
		{
			return _firstDayOfWeek;
		}

		/**
		 * 指示一星期中的哪一天（其值为 0-6，0 是 dayNames 数组的第一个元素）显示在日期选择器的第一列中。此属性更改"日"列的显示顺序。
		 */
		public function set firstDayOfWeek(firstDayOfWeek : uint) : void
		{
			_firstDayOfWeek = firstDayOfWeek;
		}

		public function get monthNames() : Array
		{
			return _monthNames[m_lang];
		}

		/**
		 * 设置在日历的标题行中显示的月份名称。该值是一个数组，其默认值为 ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October","November", "December"]。
		 */
		public function set monthNames(monthNames : Array) : void
		{
			_monthNames = monthNames;
		}

		public function get selectableRangeStart() : Date
		{
			return _selectableRangeStart;
		}

		/**
		 * 设置一定范围的可选日期的开始点。用户不能滚动到可选择范围以外。
		 */
		public function set selectableRangeStart(selectableRangeStart : Date) : void
		{
			_selectableRangeStart = selectableRangeStart;
		}

		public function get selectableRangeEnd() : Date
		{
			return _selectableRangeEnd;
		}

		/**
		 * 设置一定范围可选日期的结束点。用户不能滚动到可选择范围以外。
		 */
		public function set selectableRangeEnd(selectableRangeEnd : Date) : void
		{
			_selectableRangeEnd = selectableRangeEnd;
		}

		/**
		 * 当前选中的日期
		 */
		public function get selectDate() : Date
		{
			return _selectedDate;
		}

		/**
		 * 设置当前选中的日期
		 * 默认为今天
		 */
		public function set selectDate(v : Date) : void
		{
			_selectedDate = v;
			//如果如果已初始化则要更新视图,若当前选中的日期在当前显示的这个grid内，则使被选中者高亮
			if(_inited && _selectedDate.getFullYear() == yCount && _selectedDate.getMonth() == mCount)
			{
				//已经确定selectedDate在当前显示的日期内
				clearDateGrid();
				drawDateGrid(mCount, yCount);
			}
		}

		public function get tfmMonth() : TextFormat
		{
			return _tfmMonth;
		}

		public function set tfmMonth(tfmMonth : TextFormat) : void
		{
			_tfmMonth = tfmMonth;
		}

		public function get tfmSelectedDay() : TextFormat
		{
			return _tfmSelectedDay;
		}

		public function set tfmSelectedDay(tfmSelectedDay : TextFormat) : void
		{
			_tfmSelectedDay = tfmSelectedDay;
		}

		public function get tfmGrid() : TextFormat
		{
			return _tfmGrid;
		}

		public function set tfmGrid(tfmGrid : TextFormat) : void
		{
			_tfmGrid = tfmGrid;
		}

		public function get showToday() : Boolean
		{
			return _showToday;
		}

		/**
		 * 是否高亮显示出今天
		 */
		public function set showToday(v : Boolean) : void
		{
			if(_showToday == v)return;
			_showToday = v;
			//如果已初始化则要更新视图,若今天在当前显示的这个grid内，则使今天高亮
			if(_inited && _todayDate.getFullYear() == yCount && _todayDate.getMonth() == mCount)
			{
				//已经确定selectedDate在当前显示的日期内
				clearDateGrid();
				drawDateGrid(mCount, yCount);
			}
		}

		public function get tfmToday() : TextFormat
		{
			return _tfmToday;
		}

		/**
		 * 设置高亮显示今天日期的文本样式
		 */
		public function set tfmToday(tfmToday : TextFormat) : void
		{
			_tfmToday = tfmToday;
		}
		public function IChangLang(lang):void{
			if(lang){
				m_lang=lang;
			}
		}
	}
}
}