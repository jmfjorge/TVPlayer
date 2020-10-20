//---------------------------------------------------------------------------
// Copyright (c) 2016 Embarcadero Technologies, Inc. All rights reserved.  
//
// This software is the copyrighted property of Embarcadero Technologies, Inc. 
// ("Embarcadero") and its licensors. You may only use this software if you 
// are an authorized licensee of Delphi, C++Builder or RAD Studio
// (the "Embarcadero Products").  This software is subject to Embarcadero's 
// standard software license and support agreement that accompanied your 
// purchase of the Embarcadero Products and is considered a Redistributable, 
// as such term is defined thereunder. Your use of this software constitutes 
// your acknowledgement of your agreement to the foregoing software license 
// and support agreement. 
//---------------------------------------------------------------------------
unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Media,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit, FMX.ScrollBox, FMX.Memo,
  FMX.TabControl, FMX.Layouts, FMX.ListBox, FMX.Consts, FMX.Media.Android,
  System.IOUtils,  IdBaseComponent, IdComponent, IdSSLOpenSSL, IdSSLOpenSSLHeaders,
  IdTCPConnection, IdTCPClient, IdHTTP, System.Net.URLClient,
  System.Net.HttpClient, System.Net.HttpClientComponent, System.Threading,
  FMX.Objects;

type
  TForm1 = class(TForm)
    Button1: TButton;
    MediaPlayer1: TMediaPlayer;
    Button3: TButton;
    IdHTTP1: TIdHTTP;
    ToolBar1: TToolBar;
    Label1: TLabel;
    NetHTTPClient1: TNetHTTPClient;
    TabControl1: TTabControl;
    TabItemPlayer: TTabItem;
    TabItemLista: TTabItem;
    ListBoxCanais: TListBox;
    Button2: TButton;
    AniIndicator1: TAniIndicator;
    MediaPlayerControl1: TMediaPlayerControl;
    Rectangle1: TRectangle;
    TimerLoadPlayer: TTimer;
    AniIndicatorPlayer: TAniIndicator;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ListBoxCanaisDblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListBoxCanaisItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure FormDestroy(Sender: TObject);
    procedure TabControl1Change(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure ListBoxCanaisKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: Char; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure ListBoxCanaisKeyUp(Sender: TObject; var Key: Word;
      var KeyChar: Char; Shift: TShiftState);
    procedure TimerLoadPlayerTimer(Sender: TObject);
    procedure MediaPlayerControl1Tap(Sender: TObject; const Point: TPointF);
  private
    { Private declarations }
    m_bAtualizandoLista : Boolean;
    m_iCanalSelecionado : Integer;
    m_oListaEnderecos   : TStringList;
    m_bTelaCheia        : Boolean;
    function GetTagValue(var AText: string): string;
    function IsItemCorrect(const AItem: string): Boolean;
    procedure AddItemListaCanais(const sItem: string);
    function DownloadListFromMyDrive : String;
    procedure AtualizarListaCanais;
    procedure VerificaPosicionamentoPlayer;
    procedure VerificaTelaCheia;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}


procedure TForm1.Button1Click(Sender: TObject);
begin
  MediaPlayer1.Stop;
  if ((m_iCanalSelecionado>=0) and (m_iCanalSelecionado<=ListBoxCanais.Items.Count-1)) or (Sender=nil) then
  begin
    VerificaPosicionamentoPlayer;
    if Sender<>nil then
      MediaPlayer1.FileName := m_oListaEnderecos[m_iCanalSelecionado];
    AniIndicatorPlayer.Visible:=True;
    AniIndicatorPlayer.Enabled:=True;
    TimerLoadPlayer.Enabled:=True;
    MediaPlayer1.Play;
  end;

end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  MediaPlayer1.Stop;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  AtualizarListaCanais;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  m_bTelaCheia:=False;
  m_oListaEnderecos:=TStringList.Create;
  TMediaCodecManager.RegisterMediaCodecClass('.m3u8', SVMP4Files, TMediaType.Video, TAndroidVideoCodec);
  m_bAtualizandoLista:=False;
  m_iCanalSelecionado:=-1;
  VerificaPosicionamentoPlayer;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  m_oListaEnderecos.Free;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
begin
  if ((TabItemLista.IsFocused) and (Key=40) and (ListBoxCanais.CanFocus)) then
    ListBoxCanais.SetFocus;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  AtualizarListaCanais;
  TabItemPlayer.SetFocus;
  MediaPlayer1.Volume := 100;
end;

function TForm1.GetTagValue(var AText: string): string;
const
  TagName = '<a href=';
  TagEnd = '>';
var
  NextTagStartPosition: Integer;
  NextTagEndPosition: Integer;
begin
  Result := '';
  NextTagStartPosition := AText.IndexOf(TagName);
  if NextTagStartPosition > 0 then
  begin
    AText := AText.Substring(NextTagStartPosition + TagName.Length);
    NextTagEndPosition := AText.IndexOf(TagEnd);
    if NextTagEndPosition > 0 then
      Result := AText.Substring(1, NextTagEndPosition - 2);
  end;
  if Result.IsEmpty then
    AText := AText.Empty;
end;

function TForm1.IsItemCorrect(const AItem: string): Boolean;
const
  MP3Mask = '.mp3';
begin
  Result := AItem.Contains(MP3Mask);
end;

procedure TForm1.ListBoxCanaisDblClick(Sender: TObject);
begin
  Button3Click(Sender);
  Button1Click(Sender);
end;


procedure TForm1.ListBoxCanaisItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
begin
  m_iCanalSelecionado:=Item.Index;
end;

procedure TForm1.ListBoxCanaisKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if ((Key=38) and (ListBoxCanais.ItemIndex=0)) then
    TabItemLista.SetFocus;
end;

procedure TForm1.ListBoxCanaisKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  m_iCanalSelecionado:=ListBoxCanais.ItemIndex;
end;

procedure TForm1.MediaPlayerControl1Tap(Sender: TObject; const Point: TPointF);
begin
  VerificaTelaCheia;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
begin
  if ((Key=0) and (ListBoxCanais.IsFocused) and (ListBoxCanais.ItemIndex>=0)) then
    Button1Click(Sender);
  VerificaTelaCheia;
end;

procedure TForm1.VerificaTelaCheia;
begin
  if ((TabControl1.ActiveTab=TabItemPlayer) and (MediaPlayer1.State=TMediaState.Playing)) then
  begin
    m_bTelaCheia:=not m_bTelaCheia;
    VerificaPosicionamentoPlayer;
    Button1Click(nil);
    if not m_bTelaCheia then
      TabItemPlayer.SetFocus;
  end;
end;

procedure TForm1.TabControl1Change(Sender: TObject);
begin
  if (MediaPlayer1.State=TMediaState.Playing) then
  begin
    if (TabControl1.ActiveTab=TabItemLista) then
      m_bTelaCheia:=True;
    VerificaPosicionamentoPlayer;
    Button1Click(nil);
  end;
  if (TabControl1.ActiveTab=TabItemPlayer) then
    Button3Click(Sender);

end;

procedure TForm1.TimerLoadPlayerTimer(Sender: TObject);
begin
  if MediaPlayer1.State=TMediaState.Playing then
  begin
    TimerLoadPlayer.Enabled:=False;
    AniIndicatorPlayer.Visible:=False;
    AniIndicatorPlayer.Enabled:=False;
  end;
end;

function TForm1.DownloadListFromMyDrive : String;
var
  oStream : TStringStream;
  sLinkGDrive : String;
  Id_HandlerSocket : TIdSSLIOHandlerSocketOpenSSL;
begin
  //Link do Google Drive gerado em: https://sites.google.com/site/gdocs2direct/home
  sLinkGDrive:='https://drive.google.com/uc?export=download&id=12iFDg0RTURlwZxe9kelCSV1M3KpfWGdp';


  try
    oStream := TStringStream.Create;
    NetHTTPClient1.Get(sLinkGDrive,oStream);
    Result:=oStream.DataString;
  finally
    oStream.Free;
  end;


   {
  try
    oStream := TStringStream.Create;
    IdOpenSSLSetLibPath(TPath.GetDocumentsPath);
    Id_HandlerSocket := TIdSSLIOHandlerSocketOpenSSL.Create(IdHttp1);
    Id_HandlerSocket.SSLOptions.Mode := sslmClient;
    Id_HandlerSocket.SSLOptions.Method := sslvTLSv1;
    IdHttp1.IOHandler := Id_HandlerSocket;
    IdHttp1.HandleRedirects := True;
    IdHttp1.Get(sLinkGDrive , oStream);
    Result:=oStream.DataString;
  finally
    oStream.Free;
  end;
  }
end;


procedure TForm1.AtualizarListaCanais;
var
  ATask  : ITask;
  sLista : String;
begin
  if m_bAtualizandoLista then
    Exit;
  ListBoxCanais.Clear;
  m_oListaEnderecos.Clear;
  AniIndicator1.Visible:=True;
  AniIndicator1.Enabled:=True;
  aTask := TTask.Create (procedure ()
   begin
     sLista:=DownloadListFromMyDrive;
     TThread.Queue(TThread.CurrentThread,
                  procedure
                  var
                    iIndex : Integer;
                    oList  : TStringList;
                  begin
                    try
                      oList:=TStringList.Create;
                      oList.Text:=sLista;
                      ListBoxCanais.BeginUpdate;
                      for iIndex := 0 to oList.Count-1 do
                        AddItemListaCanais(oList[iIndex]);
                    finally
                      oList.Free;
                      ListBoxCanais.EndUpdate;
                      AniIndicator1.Visible:=False;
                      AniIndicator1.Enabled:=False;
                    end;
                  end);
     if ListBoxCanais.Items.Count>0 then
       m_iCanalSelecionado:=0
     else
       m_iCanalSelecionado:=-1;
     m_bAtualizandoLista:=False;
   end);
  aTask.Start;
end;

procedure TForm1.VerificaPosicionamentoPlayer;
var
  iLargura : Integer;
  iAltura  : Integer;
begin
  if TabControl1.ActiveTab=TabItemPlayer then
  begin
    if m_bTelaCheia then
    begin
      MediaPlayerControl1.Position.Y:=Label1.Height*2;
      MediaPlayerControl1.Height:=Self.Height-(Label1.Height*2);
    end
    else
    begin
      MediaPlayerControl1.Position.Y:=-5;
      MediaPlayerControl1.Height:=Self.Height+5;
    end;
    MediaPlayerControl1.Position.X:=-5;
    MediaPlayerControl1.Width:=Self.Width+5;
  end
  else
  begin
    iLargura:=Self.Width div 3;
    if iLargura<160 then
      iLargura:=160;
    MediaPlayerControl1.Position.X:=Self.Width - iLargura;
    iAltura:=Round(iLargura * 9/16);
    MediaPlayerControl1.Position.Y:=Self.Height-iAltura;
    MediaPlayerControl1.Width:=iLargura;
    MediaPlayerControl1.Height:=iAltura;
  end;
end;

procedure TForm1.AddItemListaCanais(const sItem: string);

  function ParseName(const sURL: string): string;
  var
    I: Integer;
  begin
    Result := sURL;
    I := Result.IndexOf('|');
    Result := Result.Substring(0, I);
  end;

  function ParseLink(const sURL: string): string;
  var
    I: Integer;
  begin
    Result := sURL;
    I := Result.IndexOf('|');
    Result := Result.Substring(I + 1);
  end;

var
  sName : String;
  sLink : String;
begin
  sName := ParseName(sItem);
  sLink := ParseLink(sItem);
  ListBoxCanais.Items.Add(sName);
  m_oListaEnderecos.Add(sLink);
end;


end.
