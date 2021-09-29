program shellyconf;

uses
  Vcl.Forms,
  UMainForm in 'UMainForm.pas' {Form1},
  nductype in 'ndu\nductype.pas',
  ndueaptypes in 'ndu\ndueaptypes.pas',
  ndul2cmn in 'ndu\ndul2cmn.pas',
  nduntddndis in 'ndu\nduntddndis.pas',
  nduwindot11 in 'ndu\nduwindot11.pas',
  nduwinnt in 'ndu\nduwinnt.pas',
  nduwlanapi in 'ndu\nduwlanapi.pas',
  nduwlantypes in 'ndu\nduwlantypes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
