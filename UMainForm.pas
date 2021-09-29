unit UMainForm;
// Shelly 1 AP -> to Client mode massconfigurator
// Author: Ingmar Tammeväli stiigo<ättt>stiigo.com
interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,nduWlanAPI, nduWlanTypes,
  Vcl.ComCtrls, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IOUtils,
  IdHTTP;

type
  PWLAN_CALLBACK_INFO = ^TWLAN_CALLBACK_INFO;
  TWLAN_CALLBACK_INFO = record
    InterfaceGuid: TGUID;
    event: THandle;
    callbackReason: DWORD;
  end;

type
  TForm1 = class(TForm)
    mmLog: TMemo;
    btnScan: TButton;
    Label1: TLabel;
    Label2: TLabel;
    ListView1: TListView;
    btnGetShellyConf: TButton;
    IdHTTP1: TIdHTTP;
    Label3: TLabel;
    edSSID: TEdit;
    Label4: TLabel;
    edPasswd: TEdit;
    btnSetShellyClientMode: TButton;
    btnMacList: TButton;
    OpenDialog1: TOpenDialog;
    procedure btnScanClick(Sender: TObject);
    procedure btnGetShellyConfClick(Sender: TObject);
    procedure btnSetShellyClientModeClick(Sender: TObject);
    procedure btnMacListClick(Sender: TObject);
  private
    function addXMLProfile(const ASSid: String; const APWD: String): String;
    procedure setGetShellyData(const ASetAp: Boolean);
    function setWifiClient(const AWifiSSID: String; const APassword: String): String; // depr
  public
    { Public declarations }
  end;

const
  CShellyRegEx = '^shelly(.*)\-(.*)+';

const
  CEta = 'F4CFA1E31EB1';

var
  Form1: TForm1;

implementation
uses System.RegularExpressions, StrUtils;
{$R *.dfm}



function DOT11_AUTH_ALGORITHM_To_String(Dummy: Tndu_DOT11_AUTH_ALGORITHM)
  : AnsiString;
begin
  Result := '';
  case Dummy of
    DOT11_AUTH_ALGO_80211_OPEN:
      Result := '80211_OPEN';
    DOT11_AUTH_ALGO_80211_SHARED_KEY:
      Result := '80211_SHARED_KEY';
    DOT11_AUTH_ALGO_WPA:
      Result := 'WPA';
    DOT11_AUTH_ALGO_WPA_PSK:
      Result := 'WPA_PSK';
    DOT11_AUTH_ALGO_WPA_NONE:
      Result := 'WPA_NONE';
    DOT11_AUTH_ALGO_RSNA:
      Result := 'RSNA';
    DOT11_AUTH_ALGO_RSNA_PSK:
      Result := 'RSNA_PSK';
    DOT11_AUTH_ALGO_IHV_START:
      Result := 'IHV_START';
    DOT11_AUTH_ALGO_IHV_END:
      Result := 'IHV_END';
  end;
end;

function DOT11_CIPHER_ALGORITHM_To_String(Dummy: Tndu_DOT11_CIPHER_ALGORITHM)
  : AnsiString;
begin
  Result := '';
  case Dummy of
    DOT11_CIPHER_ALGO_NONE:
      Result := 'NONE';
    DOT11_CIPHER_ALGO_WEP40:
      Result := 'WEP40';
    DOT11_CIPHER_ALGO_TKIP:
      Result := 'TKIP';
    DOT11_CIPHER_ALGO_CCMP:
      Result := 'CCMP';
    DOT11_CIPHER_ALGO_WEP104:
      Result := 'WEP104';
    DOT11_CIPHER_ALGO_WPA_USE_GROUP:
      Result := 'WPA_USE_GROUP OR RSN_USE_GROUP';
    // DOT11_CIPHER_ALGO_RSN_USE_GROUP : Result:= 'RSN_USE_GROUP';
    DOT11_CIPHER_ALGO_WEP:
      Result := 'WEP';
    DOT11_CIPHER_ALGO_IHV_START:
      Result := 'IHV_START';
    DOT11_CIPHER_ALGO_IHV_END:
      Result := 'IHV_END';
  end;
end;

function getFirstProfile(AProfiles: String): String;
const
  CMagic = 'all user profile';
var
  ppos: Integer;
begin
  Result := '';
  ppos := Pos(CMagic, AProfiles.ToLower);
  if ppos > 0 then
  begin
    system.Delete(AProfiles, 1,  ppos + length(CMagic));
    Result := Trim(AProfiles);
    if (Result <> '') and (Result[1] = ':') then
      system.Delete(Result, 1, 1);
    ppos := Pos(#$0D, Result);
    if ppos = 0 then
      Exit('');

    Result := Copy(Result, 1, ppos - 1);
  end;
end;

// function execCmd(Command: string; Work: string = 'C:\'): string;
// netsh wlan show profiles
// execCmd('netsh wlan show profiles')

// http://thundaxsoftware.blogspot.com/2011/07/capturing-console-output-with-delphi.html
function execCmd(ACommand: string; AParameters: string = ''): string;
const
  CMaxBfr = 4095;
var
  SA: TSecurityAttributes;
  SI: TStartupInfo;
  PI: TProcessInformation;
  hRead, hWrite: THandle;
  WasOK: Boolean;
  pBuffer: array [0..CMaxBfr] of AnsiChar;
  dBuffer: array [0..CMaxBfr] of AnsiChar;
  BytesRead: Cardinal;
  WorkDir: string;
  Handle: Boolean;
  dRunning: Cardinal;
  dRead: DWord;
  flags: Cardinal;
begin
//  FillChar(SA, SizeOf(TSecurityAttributes), #0);
  SA.nLength := SizeOf(TSecurityAttributes);
  SA.bInheritHandle := True;
  SA.lpSecurityDescriptor := nil;

  if CreatePipe(hRead, hWrite, @SA, 0) then
  begin
    try
      FillChar(SI, SizeOf(TStartupInfo), #0);
      SI.cb := SizeOf(TStartupInfo);
      SI.hStdInput := hRead;
      SI.hStdOutput := hWrite;
      SI.hStdError := hWrite;
      SI.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
      SI.wShowWindow := SW_HIDE;

      if CreateProcess(nil, pChar(ACommand + ' ' + AParameters), @SA,
                      @SA, True, NORMAL_PRIORITY_CLASS, nil, nil,
                      SI, PI) then
      begin
        CloseHandle(hWrite);
        try
          repeat
            dRunning := WaitForSingleObject(PI.hProcess, 100);
            Application.ProcessMessages();

            repeat
                dRead := 0;
                ReadFile(hRead, pBuffer[0], CMaxBfr, dRead, nil);
                pBuffer[dRead] := #0;

                //OemToAnsi(pBuffer, pBuffer);
                //Unicode support by Lars Fosdal
                OemToCharA(pBuffer, dBuffer);
                Result := Result + dBuffer;
            until (dRead < CMaxBfr);

          until (dRunning <> WAIT_TIMEOUT);
        finally
          CloseHandle(PI.hProcess);
          CloseHandle(PI.hThread);
        end;

      end;
    finally
      CloseHandle(hRead);
      if GetHandleInformation(hWrite, flags) then
        CloseHandle(hWrite);
    end;
  end;
end;

function TForm1.setWifiClient(const AWifiSSID: String; const APassword: String): String;
var
  pstr: TStringlist;
begin
  pstr := TStringlist.Create;
  pstr.StrictDelimiter := True;
  with pstr do
  try
  {
    enabled 	bool 	Set to 1 to make STA the current WiFi mode
    ssid 	string 	The WiFi SSID to associate with
    key 	string 	The password required for associating to the given WiFi SSID
    ipv4_method 	string 	dhcp or static
    ip 	string 	Local IP address if ipv4_method is static
    netmask 	string 	Mask if ipv4_method is static
    gateway 	string 	Local gateway IP address if ipv4_method is static
    dns 	string 	DNS address if ipv4_method is static
  }
    add('{');
    add('"enabled":0,');
    add(format('"ssid":"%s",', [AWifiSSID]));
    add(format('"key":"%s"', [APassword]));
    add('}');
    Result := pstr.Text;
  finally
    FreeAndNil(pstr);
  end;
end;

procedure TForm1.setGetShellyData(const ASetAp: Boolean);
var
  pitems: TStringlist;
  restprof, subprof, newprofname: String;
  createproffile, newprofiles: TStringList;
begin
  newprofname := '';
  mmLog.Lines.Clear;
  pitems := TStringlist.Create;
  newprofiles := TStringlist.Create;
  try
    restprof := getFirstProfile(execCmd('cmd /c netsh wlan show profiles'));
    for var i: Integer := 0 to ListView1.Items.Count - 1 do
    begin
      if listview1.Items.Item[i].Selected then
      begin
        var filename: String :=  TPath.Combine(TPath.GetTempPath, TPath.GetGUIDFileName) + '.xml';
        createproffile := TStringList.Create;
        try
          subprof := listview1.items.Item[i].Subitems[0].Trim;
          if subprof = '' then
          begin
            var ssid: String := listview1.Items.Item[i].Caption;
            newprofiles.Add(ssid);
            createproffile.Add(addXMLProfile(ssid, ''));
            createproffile.SaveToFile(filename);
            var status : String := execCmd(Format('cmd /c netsh wlan add profile filename="%s"',
              [filename]));
            mmLog.Lines.Add(listview1.Items.Item[i].Caption);
            mmLog.Lines.Add(status);
            subprof := listview1.Items.Item[i].Caption;
            Sleep(150);
          end;

            // subprof := listview1.Items.Item[i].Caption;
          pitems.Values[listview1.Items.Item[i].Caption] := subprof;
        finally
          if FileExists(filename) then
            DeleteFile(filename);

          FreeAndNil(createproffile);
        end;
      end;
    end;

    if pitems.Count < 1 then
    begin
      Showmessage('Select Shelly AP rows');
      Exit;
    end;

    Sleep(150);
    try

      for var j : Integer := 0 to pitems.Count - 1 do
      begin
        var status : String := execCmd(Format('cmd /c netsh wlan connect ssid=%s name=%s',
          [pitems.Names[j], pitems.ValueFromIndex[j]]));
        mmLog.Lines.Add(trim(pitems.Names[j] + ' - ' + status));

        if ASetAp then
        begin

          var str := TStringStream.Create(nil);
          try

            for var k := 1 to 3 do
            try
              Sleep(800);
              var
              rez :=IdHTTP1.Get(Format(''
                + 'http://192.168.33.1/settings/sta?enabled=1&ssid=%s&key=%s',
                [edSSID.Text, edPasswd.Text]));
              mmLog.Lines.Add(rez);
            except
              on E: Exception do
                if k > 1 then
                  mmLog.Lines.Add(E.Message);
            end;

          finally
            FreeAndNil(str);
          end;
        end
        else
        begin
          mmLog.Lines.Add('');
          mmLog.Lines.Add('Common info');
          for var k := 1 to 3 do
          try
            Sleep(900);
            var rez := IdHTTP1.Get('http://192.168.33.1/shelly');

            mmLog.Lines.Add(rez);
            break;
          except
          end;

          mmLog.Lines.Add('');
          mmLog.Lines.Add('Settings');
          mmLog.Lines.Add(IdHTTP1.Get('http://192.168.33.1/settings'));

          if  pitems.Count > 1 then
            mmLog.Lines.Add(StringOfChar('_', 85));
        end;
      end;

    finally
      FreeAndNil(pitems);

      for var profname: String in newprofiles do
      begin
        var status: String := execCmd(Format('cmd /c netsh wlan delete profile name="%s"', [profname]));
        mmLog.Lines.Add(status);
        mmLog.Lines.Add('');
      end;

      if restprof <> '' then
      begin
        var status : String := execCmd(Format('cmd /c netsh wlan connect ssid=%s name=%s',
          [restprof, restprof]));

        mmLog.Lines.Add('');
        mmLog.Lines.Add(trim(restprof + ' - ' + status));
      end;
    end;

  finally
    FreeAndNil(newprofiles);
  end;
end;



procedure TForm1.btnGetShellyConfClick(Sender: TObject);
begin
  setGetShellyData(False);
end;

procedure TForm1.btnSetShellyClientModeClick(Sender: TObject);
begin
  if messageDlg('Turn devices into Client mode ?', MtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  if (edSSID.Text <> '') and (edPasswd.Text <> '') then
    setGetShellyData(True)
  else
    Showmessage('Incorrect password or SSID !');
end;

// //Function to receive callback notifications for the wireless network
procedure wlanCallback(scanNotificationData: Pndu_WLAN_NOTIFICATION_DATA; myContext: Pointer); cdecl;
begin
  Application.ProcessMessages;
  //Get the data from my struct. If it's null, nothing to do
  var callbackInfo: PWLAN_CALLBACK_INFO := PWLAN_CALLBACK_INFO(myContext);
  if not Assigned(myContext) then
    Exit;

	if ((scanNotificationData^.NotificationCode = ord(wlan_notification_acm_scan_complete))
    or (scanNotificationData^.NotificationCode = ord(wlan_notification_acm_scan_fail))) then
	begin
		//Set the notification code as the callbackReason
		callbackInfo^.callbackReason := scanNotificationData^.NotificationCode;

		//Set the event
		SetEvent(callbackInfo^.event);
  end;
end;

procedure TForm1.btnMacListClick(Sender: TObject);
var
  regex : TRegEx;
  // Match : TMatch;
  matchcoll: TMatchCollection;
  maclist: TStringList;
begin
  maclist := TStringList.Create;
  try
    for var i: Integer := 0 to self.ListView1.Items.Count - 1 do
    begin
      regex := TRegEx.Create(CShellyRegEx);
      var shellyssid := ListView1.Items.Item[i].Caption;

      matchcoll := regex.Matches(shellyssid);
      for var z: Integer := 0 to matchcoll.Count-1 do
      begin
          var ppos := Pos('-', shellyssid);
          if ppos < 1 then
            Continue;

          var
            mac : String := Copy(shellyssid, ppos + 1, 255);

          if length(mac) <> length(CEta) then
            Continue;

          var buildmac: String := '';

          var ploop : Integer := 0;
          while ploop < length(mac) do
          begin
            if ploop > 0 then
              buildmac := buildmac + '-';

            buildmac := buildmac + copy(mac, ploop + 1, 2);
            Inc(ploop, 2);
          end;


          maclist.Add(buildmac);
      end;
    end;

    if OpenDialog1.Execute then
    begin
      maclist.SaveToFile(OpenDialog1.Files.Strings[0]);
    end;
  finally
    FreeAndNil(maclist);
  end;
end;

// netsh wlan delete profile "shelly1pm-F4CFA2E385BA"
function TForm1.addXMLProfile(const ASSid: String; const APWD: String): String;
var
  pstr: TStringList;
  ssidhex: String;
begin
  pstr := TStringList.Create;
  try
    with pstr do
    begin
      Add('<?xml version="1.0"?>');
      Add('<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">');
      Add('<name>$SSID</name>');
      Add('<SSIDConfig>');
      Add('<SSID>');
      Add('<hex>$SSHEXID</hex>');
      Add('<name>$SSID</name>');
      Add('</SSID>');
      Add('</SSIDConfig>');
      Add('<connectionType>ESS</connectionType>');
      //Add('<connectionMode>auto</connectionMode>');
      Add('<connectionMode>manual</connectionMode>');
      Add('<MSM>');
      Add('<security>');
      Add('<authEncryption>');
      if APWD <> '' then
      begin
        Add('<authentication>WPA2PSK</authentication>');
        Add('<encryption>AES</encryption>');
      end
      else
      begin
        Add('<authentication>open</authentication>');
        Add('<encryption>none</encryption>');
      end;
      Add('<useOneX>false</useOneX>');
      Add('</authEncryption>');


      if APWD <> '' then
      begin
        Add('<sharedKey>');
        Add('<keyType>passPhrase</keyType>');
        Add('<protected>false</protected>');
        Add('<keyMaterial>$PWD</keyMaterial>');
        Add('</sharedKey>');
      end;

      Add('</security>');
      Add('</MSM>');
      Add('</WLANProfile>');
    end;
    Result := pstr.Text;
    for var i: Integer := 1 to length(ASSid) do
      ssidhex := ssidhex + inttohex(ord(ASSid[i]), 2);



    Result := StringReplace(Result, '$SSID', ASSid, [rfReplaceAll]);
    Result := StringReplace(Result, '$PWD', APwd, [rfReplaceAll]);
    Result := StringReplace(Result, '$SSHEXID', ssidhex, [rfReplaceAll]);


  finally
    pstr.Free;
  end;
end;

procedure TForm1.btnScanClick(Sender: TObject);
const
  WLAN_AVAILABLE_NETWORK_INCLUDE_ALL_ADHOC_PROFILES = $00000001;

var
  i, j: Integer;
  pInterface: Pndu_WLAN_INTERFACE_INFO_LIST;
  pAvailableNetworkList: Pndu_WLAN_AVAILABLE_NETWORK_LIST;
  pInterfaceGuid: PGUID;
  wlanHandle: THandle;
  dwVersion, rez, waitResult: DWord;
  SDummy: AnsiString;
  regex : TRegEx;
  // Match : TMatch;
  matchcoll: TMatchCollection;
  profiles, ssid: String;
  treeitems: TStringList;
begin

  ListView1.Items.Clear;
  profiles := execCmd('cmd /c netsh wlan show profiles');

  // siin kõige esimene on aktiivne profiil !
  mmLog.Lines.Clear;
  btnGetShellyConf.Enabled := False;
  btnSetShellyClientMode.Enabled := False;
  edSSID.Enabled := False;
  edPasswd.Enabled := False;
  btnMacList.Enabled := False;

  dwVersion := 0;
  wlanHandle := 0;
  rez := WlanOpenHandle(1, nil, @dwVersion, @wlanHandle);

  if rez <> ERROR_SUCCESS then
  begin
//      mmLog.Lines.Add(Format('Error Open Client %d', [ResultInt]));
    Exit;
  end;
  rez := WlanEnumInterfaces(wlanHandle, nil, @pInterface);
  if rez <> ERROR_SUCCESS then
  begin
//      mmLog.Lines.Add('Error Enum Interfaces ' + IntToStr(ResultInt));
    Exit;
  end;

  treeitems := TStringList.Create;
  try

    for i := 0 to pInterface^.dwNumberOfItems - 1 do
    begin

    var
      cbinfo: TWLAN_CALLBACK_INFO;

      Sleep(800); // kui seda ei pane ei leia alati kõiki CPsid
      mmLog.Lines.Add('Interface       ' + pInterface^.InterfaceInfo[i].strInterfaceDescription);
      mmLog.Lines.Add('GUID            ' + GUIDToString(pInterface^.InterfaceInfo[i].InterfaceGuid));
      mmLog.Lines.Add('');
      pInterfaceGuid := @pInterface^.InterfaceInfo[pInterface^.dwIndex].InterfaceGuid;

		  rez := WlanScan(wlanHandle, pInterfaceGuid, nil, nil, nil);
      cbinfo.InterfaceGuid := pInterface^.InterfaceInfo[pInterface^.dwIndex].InterfaceGuid;
      cbinfo.event := CreateEvent(nil, FALSE, FALSE, nil);

      waitResult := WlanRegisterNotification(wlanHandle,
        NDU_WLAN_NOTIFICATION_SOURCE_ALL,
        TRUE,
        @wlanCallback,
        @cbinfo,
        nil,
        nil);

      if rez <> ERROR_SUCCESS then
      begin
        Exit;
      end;

      waitResult := WaitForSingleObject( cbinfo.event, 15000);
      // TODO: error messages
		  if (waitResult = WAIT_OBJECT_0) then
	  	begin
        // Success
			end else if (cbinfo.callbackReason = ord(wlan_notification_acm_scan_fail)) then
      begin
        // Network scan failed
      end	else if (waitResult = WAIT_TIMEOUT) then
      begin
        // Timeout error
      end else
      begin
        // Unexpected error
      end;


      rez := WlanGetAvailableNetworkList(wlanHandle, pInterfaceGuid,
        0, nil, pAvailableNetworkList);
      if rez <> ERROR_SUCCESS then
      begin
        Exit;
      end;


      for j := 0 to pAvailableNetworkList^.dwNumberOfItems - 1 do
      begin
          mmLog.Lines.Add('------------------------------------------------------------------------------------------');
          mmLog.Lines.Add(Format('Profile         %s', [WideCharToString(pAvailableNetworkList^.Network[j].strProfileName)]));
          ssid := PAnsiChar(@pAvailableNetworkList^.Network[j].dot11Ssid.ucSSID);
          mmLog.Lines.Add(Format('NetworkName     %s', [ssid]));
          // shelly1pm-F4CFA2E38EB1
          //regex := TRegEx.Create('[-+]?[0-9]*\.?[0-9]+');
          var profname: String := WideCharToString(pAvailableNetworkList^.Network[j].strProfileName);
  //
          mmLog.Lines.Add(Format('Signal Quality  %d ', [pAvailableNetworkList^.Network[j].wlanSignalQuality]) + '%');
          // SDummy := GetEnumName(TypeInfo(Tndu_DOT11_AUTH_ALGORITHM),integer(pAvailableNetworkList^.Network[j].dot11DefaultAuthAlgorithm)) ;
          SDummy := DOT11_AUTH_ALGORITHM_To_String(pAvailableNetworkList^.Network[j].dot11DefaultAuthAlgorithm);
          mmLog.Lines.Add(Format('Auth Algorithm  %s ', [SDummy]));
          SDummy := DOT11_CIPHER_ALGORITHM_To_String(pAvailableNetworkList^.Network[j].dot11DefaultCipherAlgorithm);
          mmLog.Lines.Add(Format('Auth Algorithm  %s ', [SDummy]));
          mmLog.Lines.Add('');

          regex := TRegEx.Create(CShellyRegEx);
          matchcoll := regex.Matches(ssid);

          for var z: Integer := 0 to matchcoll.Count-1 do
          begin
            var str : String := ssid;
            if treeitems.IndexOf(str) >= 0 then
              Continue;

            treeitems.Add(str);

            var ppos := Pos('-', ssid);
            if ppos < 1 then
              Continue;

            var
              mac : String := Copy(ssid, ppos + 1, 255);

            if length(mac) <> length(CEta) then
              Continue;

            var lst := ListView1.items.Add;
            lst.Caption := str;
            lst.SubItems.Add(profname);

            btnGetShellyConf.Enabled := True;
            btnSetShellyClientMode.Enabled := True;
            edSSID.Enabled := True;
            edPasswd.Enabled := True;
            btnMacList.Enabled := True;
          end;
      end;
    end;

  finally
    WlanFreeMemory(pInterface);
	  WlanCloseHandle(wlanHandle, nil);
    FreeAndNil(treeitems);
  end;
end;

end.
