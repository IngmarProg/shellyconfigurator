object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Shelly conf - www.stiigo.com'
  ClientHeight = 371
  ClientWidth = 721
  Color = clBtnFace
  Constraints.MaxHeight = 950
  Constraints.MaxWidth = 1200
  Constraints.MinHeight = 350
  Constraints.MinWidth = 200
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    721
    371)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 156
    Width = 17
    Height = 13
    Caption = 'Log'
  end
  object Label2: TLabel
    Left = 8
    Top = 10
    Width = 28
    Height = 13
    Caption = 'Shelly'
  end
  object Label3: TLabel
    Left = 241
    Top = 8
    Width = 66
    Height = 13
    Anchors = [akTop, akRight]
    Caption = '- Router SSID'
  end
  object Label4: TLabel
    Left = 441
    Top = 8
    Width = 46
    Height = 13
    Anchors = [akTop, akRight]
    Caption = 'Password'
  end
  object mmLog: TMemo
    Left = 8
    Top = 176
    Width = 705
    Height = 187
    Anchors = [akLeft, akTop, akRight, akBottom]
    Lines.Strings = (
      '')
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 7
  end
  object btnScan: TButton
    Left = 44
    Top = 2
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = '&Scan'
    TabOrder = 0
    OnClick = btnScanClick
  end
  object ListView1: TListView
    Left = 8
    Top = 31
    Width = 705
    Height = 90
    Anchors = [akLeft, akTop, akRight]
    Columns = <
      item
        Caption = 'SSID'
        Width = 285
      end
      item
        Caption = 'Profile name'
        Width = 235
      end>
    GridLines = True
    MultiSelect = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 5
    ViewStyle = vsReport
  end
  object btnGetShellyConf: TButton
    Left = 125
    Top = 2
    Width = 104
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Get shelly conf'
    Enabled = False
    TabOrder = 1
    OnClick = btnGetShellyConfClick
  end
  object edSSID: TEdit
    Left = 314
    Top = 4
    Width = 121
    Height = 21
    Anchors = [akTop, akRight]
    Enabled = False
    TabOrder = 2
  end
  object edPasswd: TEdit
    Left = 493
    Top = 4
    Width = 121
    Height = 21
    Anchors = [akTop, akRight]
    Enabled = False
    TabOrder = 3
  end
  object btnSetShellyClientMode: TButton
    Left = 620
    Top = 2
    Width = 93
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Set Client mode'
    Enabled = False
    TabOrder = 4
    OnClick = btnSetShellyClientModeClick
  end
  object btnMacList: TButton
    Left = 620
    Top = 127
    Width = 93
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Save mac list'
    Enabled = False
    TabOrder = 6
    OnClick = btnMacListClick
  end
  object IdHTTP1: TIdHTTP
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = -1
    Request.ContentRangeStart = -1
    Request.ContentRangeInstanceLength = -1
    Request.Accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    Request.Ranges.Units = 'bytes'
    Request.Ranges = <>
    HTTPOptions = [hoForceEncodeParams]
    Left = 152
    Top = 56
  end
  object OpenDialog1: TOpenDialog
    FileName = 'shelly_mac.txt'
    Filter = 'Text file|*.txt'
    Title = 'Mac list'
    Left = 536
    Top = 136
  end
end
