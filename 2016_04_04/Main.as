﻿import flash.net.NetConnection;import flash.events.NetStatusEvent;import flash.events.AsyncErrorEvent;import flash.events.IOErrorEvent;import flash.events.SecurityErrorEvent;import flash.utils.Timer;import flash.events.TimerEvent;import flash.media.Microphone;import flash.media.Camera;//import flash.system.Capabilities;import flash.display.LoaderInfo;var from:String = 'player';var server_ip:String = '';var ams_timer:Number = 3500;var fms_url:String = "";var fms_url_rtmfp:String = '';var timerLogInfo:Timer = new Timer(250);var it:int = 0;var getBwIt:int = 0;var netBw = new NetConnection();var netBwRtmfp = new NetConnection();var isConnectedToAmsTimer:Timer;var isConnectedToAmsRtmfpTimer:Timer;var toLate:Boolean = false;var rtmfpToLate:Boolean = false;var amsConnectionSucceed:Boolean = false;var connectionStartDate:Number;var connectionEndDate:Number;var startDate:Number;var endDate:Number;var connectionStartDateRtmfp:Number;var connectionEndDateRtmfp:Number;//variable to send to containervar rtmfpSucceed:Boolean = false;var bwValue:Number = -1;var latence:Number = -1;var listMic = Microphone.names;var listCam = Camera.names;//var fpVersion:String = Capabilities.version;function logDisplay(msg:String):void{	it++;	txtArea.appendText(it+' : '+msg+'\n');	ExternalInterface.call("_vdk.env.bwTesterMsg",msg);}function getParameters():void{		logDisplay('');	logDisplay('********** PARAMETERS FROM JS **********');	try {		var keyStr:String;		var valueStr:String;		var paramObj:Object = LoaderInfo(this.root.loaderInfo).parameters;		for (keyStr in paramObj) {			valueStr = String(paramObj[keyStr]);			logDisplay(keyStr+' : '+valueStr);			if(keyStr == 'server_ip'){				server_ip = valueStr;			}else if(keyStr == 'from'){				from = valueStr;			}else if(keyStr == 'ams_timer'){				ams_timer = valueStr;			}		}		if(server_ip != ''){			fms_url = 'RTMP://'+server_ip+'/bwTesterLight';			fms_url_rtmfp = 'RTMFP://'+server_ip+'/bwTesterLight';		}		logDisplay("ams_timer = "+ams_timer);	} catch (error:Error) {		logDisplay("error = "+error.toString());	}	logDisplay('');	logDisplay('********** TEST RTMFP **********');	testRTMFP();	//on lance un timer pour laisser le temps au player flash de recupérer les infos webcam et mic	timerLogInfo.addEventListener(TimerEvent.TIMER, logInfo);	timerLogInfo.start();}function logInfo(evt:TimerEvent):void{	timerLogInfo.stop();		logDisplay('');	logDisplay('********** MIC **********');		if(listMic.length < 1){// sous chrome parfois la recupération de la liste échoue, alors on la retente		logDisplay('*** retente recupération liste mic ***');		listMic = Microphone.names;	}		logDisplay(listMic.toString());	logDisplay('nombre de microphones détectés = '+listMic.length);		for(var i:int = 0;i<listMic.length;i++){		logDisplay('microphone '+i+' : '+listMic[i].toString());	}		logDisplay('');	logDisplay('********** CAM **********');		if(listCam.length < 1){		logDisplay('*** retente recupération liste cam ***');		listCam = Camera.names;	}		logDisplay(listCam.toString());	logDisplay('nombre de webcam détectées = '+listCam.length);		for(var j:int=0;j<listCam.length;j++){		logDisplay('webcam '+j+' : '+listCam[j].toString());	}		logDisplay('');	logDisplay('********** FP **********');	//logDisplay('flash player version = '+fpVersion);		ExternalInterface.call("_vdk.env.userEquipment",listMic.length,listMic,listCam.length,listCam);	startBwTester();}function startBwTester():void{		logDisplay('');	logDisplay('********** BW **********');		logDisplay(fms_url);		if(!isConnectedToAmsTimer){		isConnectedToAmsTimer = new Timer(ams_timer);		isConnectedToAmsTimer.addEventListener(TimerEvent.TIMER, isConnectedToAms);	}		//Connection au server ams	netBw.client=this;	netBw.addEventListener(NetStatusEvent.NET_STATUS, netConnectionStatus);	netBw.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncError);	netBw.addEventListener(IOErrorEvent.IO_ERROR, ioError);	netBw.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityError);		var now:Date = new Date();	connectionStartDate = now.getTime();	isConnectedToAmsTimer.start();	try {		//ATTENTION		//la connection a l'ams ne peut se tester qu'en ligne		//en effet, la connection à l'ams ne marche pas en local		netBw.connect(fms_url,vers);	}	catch(error:Error){		logDisplay("Error = "+Error);	}}function isConnectedToAms(evt:TimerEvent):void{	isConnectedToAmsTimer.stop();	if(amsConnectionSucceed){		return;	}else{		toLate = true;		stopConnection();		ExternalInterface.call("_vdk.env.bwResult",bwValue,latence);//par defaut, les 2 variables valent -1		//ExternalInterface.call(externalFunctionToCall,"onBwConnectionAborted", "No Response","");	}}function netConnectionStatus(evt:NetStatusEvent):void{	logDisplay('********** RTMP RESULT **********');	logDisplay('connection status = '+evt.info.code);	if(evt.info.code == "NetConnection.Connect.Success"){				//récupération de l'ip du server AMS		var amfResponder:Responder = new Responder(receiveServerIp, onFault);    	netBw.call("getServerIp", amfResponder);				amsConnectionSucceed = true;		var now:Date = new Date();		connectionEndDate = now.getTime();		var amsConnectionTime:Number = connectionEndDate-connectionStartDate;		logDisplay("ams connection time = "+amsConnectionTime+" ms");		if(toLate)return;		logDisplay("***** START GETTING BW STAT *****");		onGetStatBw();	}else if(evt.info.code == "NetConnection.Connect.Closed"){	}else if(evt.info.code == "NetConnection.Connect.NetworkChange"){	}else if(evt.info.code == "NetConnection.Connect.Failed"){		//ExternalInterface.call(externalFunctionToCall,"onBwConnectionAborted", "NetConnection.Connect.Failed","");	}	logDisplay('');}function receiveServerIp(amsIp:String){	//logDisplay('*** function receivedIpSucceed ***');	//logDisplay(amsIp);	ExternalInterface.call("_vdk.env.receiveServerAmsIp",amsIp);}function onFault(fault:Object):void {    logDisplay("AMFPHP error: "+fault);}function onGetStatBw():void{	netBw.call("checkBandwidth", null);	var now:Date = new Date();	startDate = now.getTime();}//DEBUT CALCUL DE LA BANDE PASSANTEfunction onBWCheck(... rest):Number {	return 0;}function onBWDone(... rest):void {	var p_bw:Number;	var latence:Number;		if (rest.length > 0) {		p_bw = rest[0];		latence = rest[3];	}	// your application should do something here	// when the bandwidth check is complete		getBwIt++;	if(p_bw<=0){//il arrive parfois que l'on reçoive une valeur négative		if(getBwIt>2){			stopBwConnection(0,latence);					}else{			logDisplay("0 Kbps => getBw again");			onGetStatBw();		}	}else{		stopBwConnection(p_bw, latence);	}}function stopBwConnection(_bwValue:Number, _latence:Number):void{	var now:Date = new Date();	endDate = now.getTime();	var _timeToGetBw:Number = endDate-startDate;	logDisplay(_bwValue + " Kbps. => "+String(_timeToGetBw)+" ms");	logDisplay("latence => "+_latence + " ms");	bwValue = _bwValue;	latence = _latence;	ExternalInterface.call("_vdk.env.bwResult",bwValue,latence);	stopConnection();}//FIN CALCUL DE LA BANDE PASSANTEfunction testRTMFP():void{		if(!isConnectedToAmsRtmfpTimer){		isConnectedToAmsRtmfpTimer = new Timer(3500);		isConnectedToAmsRtmfpTimer.addEventListener(TimerEvent.TIMER, isConnectedToAmsRtmfp);	}	logDisplay('');	//Connection au server ams	netBwRtmfp.client=this;	netBwRtmfp.addEventListener(NetStatusEvent.NET_STATUS, netConnectionStatusRtmfp);	netBwRtmfp.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncError);	netBwRtmfp.addEventListener(IOErrorEvent.IO_ERROR, ioError);	netBwRtmfp.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityError);		logDisplay('connect to '+fms_url_rtmfp);	var now:Date = new Date();	connectionStartDateRtmfp = now.getTime();	isConnectedToAmsRtmfpTimer.start();	netBwRtmfp.connect(fms_url_rtmfp,vers+'_RTMPF');}function isConnectedToAmsRtmfp(evt:TimerEvent):void{	isConnectedToAmsRtmfpTimer.stop();	if(rtmfpSucceed){		return;	}else{		logDisplay('********** RTMFP RESULT **********');		logDisplay('ECHEC DE LA CONNEXION EN RTMFP');		rtmfpToLate = true;		ExternalInterface.call("_vdk.env.rtmfpResult",rtmfpSucceed);		stopRtmfpConnection();		//ExternalInterface.call(externalFunctionToCall,"onBwConnectionAborted", "No Response","");	}}function netConnectionStatusRtmfp(evt:NetStatusEvent):void{	logDisplay('');	logDisplay('********** RTMFP RESULT **********');	logDisplay('connection status Rtmfp = '+evt.info.code);		if(evt.info.code == 'NetConnection.Connect.Success'){		if(rtmfpToLate)return;		rtmfpSucceed = true;		ExternalInterface.call("_vdk.env.rtmfpResult",rtmfpSucceed);		stopRtmfpConnection();		var now:Date = new Date();		connectionEndDateRtmfp = now.getTime();		var amsConnectionTimeRtmfp:Number = connectionEndDateRtmfp-connectionStartDateRtmfp;		logDisplay("ams connection time in RTMFP = "+amsConnectionTimeRtmfp+" ms");	}	logDisplay('');}function stopConnection():void{	netBw.close();}function stopRtmfpConnection():void{	logDisplay('*** call stopRtmfpConnection ***');	try{		//netBwRtmfp.close();		netBwRtmfp.call("sendCloseConnection", null, vers+'_RTMPF');	}catch(error:Error){		logDisplay("Error = "+Error);	}	}function asyncError(evt:AsyncErrorEvent):void{	logDisplay("asyncError : "+evt.error.message);}function ioError(evt:IOErrorEvent):void{	logDisplay("IOError !");}function securityError(evt:SecurityErrorEvent):void{	logDisplay("securityError !");		   }