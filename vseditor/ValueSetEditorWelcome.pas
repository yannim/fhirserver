unit ValueSetEditorWelcome;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.OleCtrls, SHDocVw,
  Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.StdCtrls, ValueSetEditorRegisterServerForm,
  ValueSetEditorCore, ServerOperationForm;

type
  TValueSetEditorWelcomeForm = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Image1: TImage;
    Label2: TLabel;
    webDoco: TWebBrowser;
    Button1: TButton;
    btnCancel: TButton;
    Label3: TLabel;
    cbShowAtStartup: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure btnAddServerClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbxServersChange(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure cbShowAtStartupClick(Sender: TObject);
  private
    FContext: TValueSetEditorContext;
    procedure SetContext(const Value: TValueSetEditorContext);
    { Private declarations }
  public
    { Public declarations }
    property Context : TValueSetEditorContext read FContext write SetContext;
  end;

var
  ValueSetEditorWelcomeForm: TValueSetEditorWelcomeForm;

implementation

{$R *.dfm}

procedure TValueSetEditorWelcomeForm.btnAddServerClick(Sender: TObject);
begin
//todo
end;

procedure TValueSetEditorWelcomeForm.Button1Click(Sender: TObject);
begin
//  ServerOperation(Context.SetNominatedServer, Context.Settings.getServer(cbxServers.ItemIndex), 'Subscribing to Server', false);
  ModalResult := mrOk;
end;

procedure TValueSetEditorWelcomeForm.cbShowAtStartupClick(Sender: TObject);
begin
  Context.Settings.HasViewedWelcomeScreen := not cbShowAtStartup.Checked;
end;

procedure TValueSetEditorWelcomeForm.cbxServersChange(Sender: TObject);
begin
//  Button1.Enabled := cbxServers.ItemIndex > -1;
end;

procedure TValueSetEditorWelcomeForm.FormCreate(Sender: TObject);
var
  fn : String;
begin
  fn := IncludeTrailingPathDelimiter(IncludeTrailingPathDelimiter(ExtractFilePath(paramstr(0)))+'doco')+'welcome.htm';
  if not FileExists(fn) then
    fn := 'C:\work\com.healthintersections.fhir\ValueSetEditor\doco\'+'welcome.htm';
  webDoco.Navigate2('file:'+fn);
end;

procedure TValueSetEditorWelcomeForm.FormDestroy(Sender: TObject);
begin
  FContext.Free;
end;

procedure TValueSetEditorWelcomeForm.SetContext(const Value: TValueSetEditorContext);
begin
  FContext.Free;
  FContext := Value;
  cbShowAtStartup.Checked := not Context.Settings.HasViewedWelcomeScreen;
end;

end.
