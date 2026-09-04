unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.TMSFNCTypes, FMX.TMSFNCUtils, FMX.TMSFNCGraphics, FMX.TMSFNCGraphicsTypes,
  FMX.TMSFNCCustomControl, FMX.TMSFNCWebBrowser, FMX.TMSFNCEdgeWebBrowser,
  FMX.Menus, System.Actions, FMX.ActnList, IdContext, IdBaseComponent,
  IdComponent, IdCustomTCPServer, IdCustomHTTPServer, IdHTTPServer,
  FMX.StdActns, FMX.TMSFNCWebCoreClientBrowser, FMX.Controls.Presentation,
  FMX.StdCtrls;

type
  TForm1 = class(TForm)
    ActionList1: TActionList;
    MainMenu1: TMainMenu;
    Action1: TAction;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    FileExit1: TFileExit;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    Action2: TAction;
    OpenDialog1: TOpenDialog;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    TMSFNCEdgeWebBrowser1: TTMSFNCEdgeWebBrowser;
    procedure Action1Execute(Sender: TObject);
    procedure TMSFNCEdgeWebBrowser1Initialized(Sender: TObject);
    procedure Action2Execute(Sender: TObject);
    procedure TMSFNCEdgeWebBrowser1WebMessageReceived(Sender: TObject;
      var Params: TTMSFNCWebBrowserWebMessageReceivedParams);
  private
    procedure OpenFile(const FileName: string);
    { private 宣言 }
  public
    { public 宣言 }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses System.NetEncoding, System.JSON, System.Threading, System.IOUtils,
  FMX.Platform;

procedure TForm1.Action1Execute(Sender: TObject);
begin
  TMSFNCEdgeWebBrowser1.ExecuteJavaScript('window.ReaderApp.cleanup;');
  TMSFNCEdgeWebBrowser1.Navigate('http://appsets.local/index.html');
end;

procedure TForm1.Action2Execute(Sender: TObject);
var
  path: string;
begin
  if OpenDialog1.Execute then
    OpenFile(OpenDialog1.FileName);
end;

procedure TForm1.OpenFile(const FileName: string);
begin
  TTask.Run(
    procedure
    var
      b64, jstr: string;
      jsObj: TJSONObject;
    begin
      jsObj := TJSONObject.Create;
      try
        b64 := TNetEncoding.Base64.EncodeBytesToString
          (TFile.ReadAllBytes(FileName));
        jsObj.AddPair('type', 'epub_path');
        jsObj.AddPair('file', b64);
        jsObj.AddPair('path', FileName.Replace('\', '/'));
        jstr := jsObj.ToJSON;
      finally
        jsObj.Free;
      end;
      TThread.Synchronize(nil,
        procedure
        begin
          TMSFNCEdgeWebBrowser1.ExecuteJavaScript('window.postMessage(' +
            jstr + ');');
        end);
    end);
end;

procedure TForm1.TMSFNCEdgeWebBrowser1Initialized(Sender: TObject);
begin
  TMSFNCEdgeWebBrowser1.SetVirtualHostNameToFolderMapping('appsets.local',
    ExtractFilePath(ParamStr(0)),
    TTMSFNCWebBrowserHostResourceAccessKind.akAllow);
  Action1Execute(nil);
end;

procedure TForm1.TMSFNCEdgeWebBrowser1WebMessageReceived(Sender: TObject;
var Params: TTMSFNCWebBrowserWebMessageReceivedParams);
var
  JSON: TJSONString;
begin
  JSON := TJSONObject.ParseJSONValue(Params.WebMessageAsJSON) as TJSONString;
  if FileExists(ParamStr(1)) and (JSON.Value = 'loaded') then
    OpenFile(ParamStr(1));
end;

end.
