unit MsgQueue;
{
    Copyright 2001, Peter Millard

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
    Jabber1, ExEvents, Contnrs, Unicode, 
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, Dockable, ComCtrls, StdCtrls, ExtCtrls, ToolWin, RichEdit2,
    ExRichEdit, Menus;

type
  TfrmMsgQueue = class(TfrmDockable)
    lstEvents: TListView;
    Splitter1: TSplitter;
    txtMsg: TExRichEdit;
    PopupMenu1: TPopupMenu;
    D1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure lstEventsChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure lstEventsDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lstEventsKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure lstEventsData(Sender: TObject; Item: TListItem);
    procedure txtMsgURLClick(Sender: TObject; URL: String);
    procedure D1Click(Sender: TObject);
  private
    { Private declarations }
    _queue: TObjectList;
    procedure SaveEvents();
    procedure LoadEvents();
    procedure removeItems();
  public
    { Public declarations }
    procedure LogEvent(e: TJabberEvent; msg: string; img_idx: integer);
    procedure RemoveItem(i: integer);
  end;

var
  frmMsgQueue: TfrmMsgQueue;

function getMsgQueue: TfrmMsgQueue;

{---------------------------------------}
{---------------------------------------}
{---------------------------------------}
implementation

{$R *.dfm}

uses
    ShellAPI, 
    Roster, JabberID, XMLUtils, XMLParser, XMLTag,
    ExUtils, MsgRecv, Session, PrefController;

{---------------------------------------}
function getMsgQueue: TfrmMsgQueue;
begin
    if frmMsgQueue = nil then begin
        frmMsgQueue := TfrmMsgQueue.Create(Application);
        end;

    Result := frmMsgQueue;
end;

{---------------------------------------}
procedure TfrmMsgQueue.LogEvent(e: TJabberEvent; msg: string; img_idx: integer);
var
    tmp_jid: TJabberID;
    ritem: TJabberRosterItem;
begin
    // display this item
    e.img_idx := img_idx;
    e.msg := msg;

    tmp_jid := TJabberID.Create(e.from);
    ritem := MainSession.roster.Find(tmp_jid.jid);
    if (ritem = nil) then
        ritem := MainSession.roster.Find(tmp_jid.full);
    tmp_jid.Free();

    if (ritem <> nil) then
        e.Caption := ritem.nickname
    else
        e.Caption := e.from;

    _queue.Add(e);
    lstEvents.Items.Count := lstEvents.Items.Count + 1;
    SaveEvents();
end;

{---------------------------------------}
procedure TfrmMsgQueue.SaveEvents();
var
    i,d: integer;
    fn: string;
    s, e: TXMLTag;
    event: TJabberEvent;
    ss: TStringList;
begin
    // save all of the events in the listview out to a file
    // fn := ExtractFilePath(Application.EXEName) + 'spool.xml';
    // fn := getUserDir() + 'spool.xml';
    fn := MainSession.Prefs.getString('spool_path');

    s := TXMLTag.Create('spool');
    for i := 0 to _queue.Count - 1 do begin
        event := TJabberEvent(_queue[i]);
        e := s.AddTag('event');
        with e do begin
            e.setAttribute('img', IntToStr(event.img_idx));
            e.setAttribute('caption', event.caption);
            e.setAttribute('msg', event.msg);
            e.setAttribute('timestamp', DateTimeToStr(event.Timestamp));
            e.setAttribute('edate', DateTimeToStr(event.edate));
            e.setAttribute('elapsed_time', IntToStr(event.elapsed_time));
            e.setAttribute('etype', IntToStr(integer(event.eType)));
            e.setAttribute('from', event.from);
            e.setAttribute('id', event.id);
            e.setAttribute('data_type', event.data_type);
            for d := 0 to event.Data.Count - 1 do
                e.AddBasicTag('data', event.Data.Strings[d]);
            end;
        end;

    ss := TStringlist.Create();
    ss.Add(UTF8Encode(s.xml));
    ss.SaveToFile(fn);
    ss.Free();
    s.Free();
end;

{---------------------------------------}
procedure TfrmMsgQueue.LoadEvents();
var
    i,d: integer;
    p: TXMLTagParser;
    cur_e, s: TXMLTag;
    dtags, etags: TXMLTagList;
    e: TJabberEvent;
    fn: string;
begin
    // Load events from the spool file
    // fn := ExtractFilePath(Application.EXEName) + 'spool.xml';
    // fn := getUserDir() + 'spool.xml';
    fn := MainSession.Prefs.getString('spool_path');

    if (not FileExists(fn)) then exit;

    p := TXMLTagParser.Create();
    p.ParseFile(fn);

    if p.Count > 0 then begin
        s := p.popTag();
        etags := s.ChildTags();

        for i := 0 to etags.Count - 1 do begin
            cur_e := etags[i];
            e := TJabberEvent.Create();
            _queue.Add(e);
            e.eType := TJabberEventType(SafeInt(cur_e.GetAttribute('etype')));
            e.from := cur_e.GetAttribute('from');
            e.id := cur_e.GetAttribute('id');
            e.Timestamp := StrToDateTime(cur_e.GetAttribute('timestamp'));
            e.edate := StrToDateTime(cur_e.GetAttribute('edate'));
            e.data_type := cur_e.GetAttribute('date_type');
            e.elapsed_time := SafeInt(cur_e.GetAttribute('elapsed_time'));
            e.msg := cur_e.GetAttribute('msg');
            e.caption := cur_e.GetAttribute('caption');
            e.img_idx := SafeInt(cur_e.GetAttribute('img'));

            lstEvents.Items.Count := lstEvents.Items.Count + 1;

            dtags := cur_e.QueryTags('data');
            for d := 0 to dtags.Count - 1 do
                e.Data.Add(dtags[d].Data);

            end;
        end;

    p.Free();

end;


{---------------------------------------}
procedure TfrmMsgQueue.FormCreate(Sender: TObject);
begin
    inherited;

    _queue := TObjectList.Create();
    _queue.OwnsObjects := true;

    lstEvents.Color := TColor(MainSession.Prefs.getInt('roster_bg'));
    txtMsg.Color := lstEvents.Color;

    AssignDefaultFont(lstEvents.Font);
    AssignDefaultFont(txtMsg.Font);

    Self.LoadEvents();
end;

{---------------------------------------}
procedure TfrmMsgQueue.lstEventsChange(Sender: TObject; Item: TListItem;
  Change: TItemChange);
var
    e: TJabberEvent;
begin
    txtMsg.InputFormat := ifUnicode;
    if (lstEvents.SelCount <= 0) then
        txtMsg.WideLines.Clear
    else begin
        e := TJabberEvent(_queue[lstEvents.Selected.Index]);
        if ((e <> nil) and (lstEvents.SelCount = 1) and (e.Data.Text <> '')) then
            txtMsg.WideText := e.Data.Text;
        end;
end;

{---------------------------------------}
procedure TfrmMsgQueue.lstEventsDblClick(Sender: TObject);
var
    e: TJabberEvent;
begin
    if (lstEvents.SelCount <= 0) then exit;

    e := TJabberEvent(_queue.Items[lstEvents.Selected.Index]);
    ShowEvent(e);
end;

{---------------------------------------}
procedure TfrmMsgQueue.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin

    Action := caFree;
    frmMsgQueue := nil;

    inherited;
end;

{---------------------------------------}
procedure TfrmMsgQueue.RemoveItem(i: integer);
begin
    _queue.Delete(i);
    lstEvents.Items.Count := _queue.Count;
    if (_queue.Count = 0) then begin
        lstEvents.Items.Clear();
        txtMsg.WideLines.Clear();
        end;
    Self.SaveEvents();
end;

procedure TfrmMsgQueue.removeItems();
var
    i: integer;
    first : integer;
    item : TListItem;
    e : TJabberEvent;
begin
    first := -1;
    if (lstEvents.SelCount = 0) then begin
        exit;
        end
    else if (lstEvents.SelCount = 1) then begin
        item := lstEvents.Selected;
        i := item.Index;
        first := i;
        RemoveItem(i);
        end
    else begin
        for i := lstEvents.Items.Count-1 downto 0 do begin
            if (lstEvents.Items[i].Selected) then begin
                _queue.Delete(i);
                lstEvents.Items.Count := lstEvents.Items.Count - 1;
                first := i;
                end;
            end;
        Self.SaveEvents();
        lstEvents.ClearSelection();
        end;

    if ((first <> -1) and (first < lstEvents.Items.Count)) then begin
        lstEvents.Selected := lstEvents.Items[first];
        e := TJabberEvent(_queue[first]);
        if ((e <> nil) and (lstEvents.SelCount = 1) and (e.Data.Text <> '')) then
            txtMsg.WideText := e.Data.Text;
        end
    else if (lstEvents.Items.Count > 0) then
        lstEvents.Selected := lstEvents.Items[lstEvents.Items.Count - 1];

    if (lstEvents.Selected <> nil) then begin
        lstEvents.Selected.MakeVisible(false);
        lstEvents.ItemFocused := lstEvents.Selected;
        end;

    lstEvents.Refresh;
end;

{---------------------------------------}
procedure TfrmMsgQueue.lstEventsKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
    // pickup hot-keys on the list view..
    case Key of
    VK_DELETE, VK_BACK, Ord('d'), Ord('D'): begin
        Key := $0;
        removeItems();
        end;

    end;

end;

{---------------------------------------}
procedure TfrmMsgQueue.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
    inherited;

    // xxx: how do we get into this state???
    if (MainSession.prefs.getBool('expanded')) and (not Docked) then begin
        CanClose := false;
        // frmExodus.DockMsgQueue();
        exit;
        end
    else
        lstEvents.Items.Clear;
end;

{---------------------------------------}
procedure TfrmMsgQueue.lstEventsData(Sender: TObject; Item: TListItem);
var
    e: TJabberEvent;
begin
  inherited;
    e := TJabberEvent(_queue[item.Index]);

    item.Caption := e.caption;
    item.ImageIndex := e.img_idx;
    item.SubItems.Add(DateTimeToStr(e.edate));
    item.SubItems.Add(e.msg);         // Subject
end;

{---------------------------------------}
procedure TfrmMsgQueue.txtMsgURLClick(Sender: TObject; URL: String);
begin
  inherited;
    ShellExecute(0, 'open', PChar(url), nil, nil, SW_SHOWNORMAL);
end;

{---------------------------------------}
procedure TfrmMsgQueue.D1Click(Sender: TObject);
begin
  inherited;
    removeItems();
end;

end.
