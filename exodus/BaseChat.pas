unit BaseChat;
{
    Copyright 2002, Peter Millard

    This file is part of Exodus.

    Exodus is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    Exodus is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Exodus; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
}

interface

uses
    Dockable, 
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, Menus, StdCtrls, ExtCtrls, ComCtrls, OLERichEdit, ExRichEdit;

type
  TfrmBaseChat = class(TfrmDockable)
    Panel3: TPanel;
    MsgList: TExRichEdit;
    Splitter1: TSplitter;
    pnlInput: TPanel;
    MsgOut: TMemo;
    Panel1: TPanel;
    popOut: TPopupMenu;
    Copy1: TMenuItem;
    CopyAll1: TMenuItem;
    Clear1: TMenuItem;
    Emoticons1: TMenuItem;
    procedure Emoticons1Click(Sender: TObject);
    procedure MsgListURLClick(Sender: TObject; url: String);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure SetEmoticon(msn: boolean; imgIndex: integer);
  end;

var
  frmBaseChat: TfrmBaseChat;

implementation

{$R *.dfm}
uses
    MsgDisplay, ShellAPI, Emoticons, Jabber1;

{---------------------------------------}
procedure TfrmBaseChat.Emoticons1Click(Sender: TObject);
var
    l, t: integer;
    cp: TPoint;
begin
  inherited;
    // Show the emoticons form
    GetCaretPos(cp);
    l := MsgOut.ClientOrigin.x + cp.X;

    if (Self.Docked) then begin
        t := frmJabber.Top + frmJabber.ClientHeight - 10;
        frmEmoticons.Left := l + 10;
        end
    else begin
        t := Self.Top + Self.ClientHeight - 10;
        frmEmoticons.Left := l + 10;
        end;

    if ((t + frmEmoticons.Height) > Screen.Height) then
        t := Screen.Height - frmEmoticons.Height;

    frmEmoticons.Top := t;
    frmEmoticons.ChatWindow := Self;
    frmEmoticons.Show;
end;

{---------------------------------------}
procedure TfrmBaseChat.SetEmoticon(msn: boolean; imgIndex: integer);
var
    l, i, m: integer;
    eo: TEmoticon;
begin
    // Setup some Emoticon
    m := -1;

    if (emoticon_list.Count = 0) then
        ConfigEmoticons();

    for i := 0 to emoticon_list.Count - 1 do begin
        eo := TEmoticon(emoticon_list.Objects[i]);
        if (((msn) and (eo.il = frmJabber.imgMSNEmoticons)) or
        ((not msn) and (eo.il = frmJabber.imgYahooEmoticons))) then begin
            // the image lists match
            if (eo.idx = imgIndex) then begin
                m := i;
                break;
                end;
            end;
        end;

    if (m >= 0) then begin
        l := length(MsgOut.Text);
        if ((l > 0) and ((MsgOut.Text[l]) <> ' ')) then
            MsgOut.SelText := ' ';
        MsgOut.SelText := emoticon_list[m];
        end;
end;

{---------------------------------------}
procedure TfrmBaseChat.MsgListURLClick(Sender: TObject; url: String);
begin
    ShellExecute(0, 'open', PChar(url), nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmBaseChat.FormActivate(Sender: TObject);
begin
  inherited;
    if (frmEmoticons.Visible) then
        frmEmoticons.Hide;
end;

end.
