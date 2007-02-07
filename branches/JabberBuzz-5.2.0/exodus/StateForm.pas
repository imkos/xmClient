unit StateForm;
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
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls,
  XMLTag,  //JOPL XML
  TntForms; //Unicode form

const
    WS_NORMAL = 0;
    WS_MINIMIZED = 1;
    WS_MAXIMIZED = 2;
    WS_TRAY = 3;

    FLASH_TIMER_INTERVAL = 500;
type

    {
        Encapsulates event handling for auto-open events.

        A stateform may be auto-opened when a particular event is fired. Unlike
        regular Exodus events these events are triggered directly by user actions.
        Currently two events are defined. Each event is paired with a
        mirrored event.

        The user selected sign off. (user is authenticated)
        The user exited the program. (user startup Exodus)

        State forms persist enough information when exiting/disconnecting to
        re-open the window in its exact state when startup/authenticated.

        This class handles walking the stateforms and persiting auto-open info
        and walking the peristed list and reopening the forms.

        Persisted xml is ultimately stored in USER_HOME/App data/Exodus/Exodus.xml
        but is accessed through the PrefController. The window data is not
        stored as a pref but under a <window_state> root (@see defaults.xml).
        The DOM looks like:
        <exodus>
            <prefs>
            ...
            </prefs>
            <ws>
                <state>
                    <TfrmRoom-Default_Profile-jm-client-dev_conference.corp.jabber.com dock="t" pos_h="480" pos_l="27" pos_t="22" pos_w="640" ws="n" />
                </state>
                <auto-open>
                    <event-authed-Default_Profile>
                        <TfrmChat jid="jinxtest2@jabber.com" />
                    </event-authed-Default_Profile>
                    <event-startup>
                        <TfrmDebug />
                        <TfrmMsgQueue />
                    </event-startup>
                </auto-open>
            </ws>
        </exodus>
    }
    TAutoOpenEventManager = class
    public
        {
            Persist or load state forms as appropriate.

            The following are recognized auto-open events:
                disconnected - the user chose to disconnect (sign off).
                    All session dependant windows will be closing (but haven't
                    yet). Session dependant windows should persist when this event
                    is fired.
                shutdown - The user is exiting the program. Non-session dependant
                    windows will be closing. Non-session dependant windows should
                    persist when this event is fired.
                startup - Exodus is starting up (That will make the COM server
                    exodus just that much more interesting!). Non-session windows
                    should re-open themselves when given appropriate persisted
                    information.
                authed - The user is now authenticated. Session windows
                    should re-open themselves when given appropriate persisted
                    information.

            Querying the forms for persisted state is implemented by iterating
            over the Screen.Forms property and invoking GetAutoOpenInfo.
            Auto-opening iterates over the list of persisted forms and calls
            the class method
        }
        class procedure onAutoOpenEvent(event: Widestring);
    end;

    {helper class that abstracts window states prefs and uses profiles as part
     of the keys. If the useProfiles flag is true, these methods will use the
     current profile if authenticated. If not authenticated or useprofile = false
     pkey is looked for off the appropriate root.
     }
    TStateFormPrefsHelper = class
    public
        {wrappers around TPrefController methods, these introduce profiles to prefs}
        procedure setWindowState(windowState: TXMLTag);
        function  getWindowState(pKey: WideString; var windowState: TXMLTag): boolean;
        procedure setAutoOpenEvent(event: WideString; aoWindows: TXMLTagList; Profile: WideString='');
        function  getAutoOpenEvent(event: Widestring; var aoWindows: TXMLTagList; Profile: WideString=''): boolean;
    end;

    TPos = record
        Height: integer;
        Width: integer;
        Left: integer;
        Top: Integer;
    end;

  {
    A state form is one that will save state information on close and restore
    that state at creation.

    The default implementation saves/restores position and window "state"
    (min/max/tray or restored).
  }
  TfrmState = class(TTntForm)
    procedure WMWindowPosChange(var msg: TWMWindowPosChanging); message WM_WINDOWPOSCHANGING;
    procedure WMSysCommand(var msg: TWmSysCommand); message WM_SYSCOMMAND;
    procedure WMActivate(var msg: TMessage); message WM_ACTIVATE;
    procedure WMDisplayChange(var msg: TMessage); message WM_DISPLAYCHANGE;

    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);

  private
     _pos: TPos;          //our position
     _persistPos: boolean; //should we persist our current position?
     _origPos: TPos;      //position we last loaded/saved to prefs
     _windowState: TWindowState; //min max or normal
     _stateRestored: boolean;
     _skipWindowPosHandling: boolean;
     _isNotifying: boolean; //is this form handling some notify event (like flashing)?
     _flasher: TTimer;
     
    procedure NormalizePos(); //
    procedure CenterOnMainformMonitor(var pos: TPos);

    procedure setNotifying(newNotifyingState: boolean);

    procedure OnFlashTim(Sender: TObject);
  protected
     procedure CreateParams(var Params: TCreateParams); override;

    {
        Get the window state associated with this window.

        Default implementation is to return a munged classname (all XML illgal
        characters escaped). Classes should override to change pref (for instance
        chat windows might save based on munged profile&jid).
    }
    function GetWindowStateKey() : WideString;virtual;

    {
        Event fired when form should restore its persisted state.

        Default uses GetPreferenceKey to get pref containing this
        window's state information.

        prefTag is an xml tag
            <windowstatekey>
                <position h="" w="" l="" t=""/>
                <docked/>
            </windowstatekey>

        This event is fired when the form is created.
    }
    procedure OnRestoreWindowState(windowState : TXMLTag);virtual;

    {
        Event fired when form should persist its position and other state
        information.

        Default uses GetWindowStateKey to determine actual key persisted

        OnPersistState is passed an xml tag (<windowstatekey/>) that should be used to
        store state. For instance after the default OnPersistState handler is called
        prefTag will be
            <windowstatekey>
                <position h="" w="" t="" l="" />
                <docked/>
            </windowstatekey>

        This event is fired during the OnCloseQuery event.
    }
    procedure OnPersistWindowState(windowState : TXMLTag);virtual;

    function getPosition(): TRect;
    {
        Restore window state.

        override to use default profile (non-session forms)
    }
    procedure RestoreWindowState();virtual;

    {
        Perists window state

        override to use default profile (non-session forms)
    }
    procedure PersistWindowState();virtual;

    {
        Event fired when the form should handle flash notification
    }
    procedure OnFlash();virtual;

  public
    {
        Show the window in its default configuration.

        The default implementation is to show the window in its last floating
        position. Override this method to change (ie dock instead of float)
        
        @param bringtofront bring the window to the top of the zorder
    }
    procedure ShowDefault(bringtofront:boolean=true; dockOverride: string = 'n');virtual;

    procedure gotActivate(); virtual;
    {
        A notification event has occurred.

        notifyEvents is a bitmap flag of what events should fire.
        StateForm will assume it is a floating window and will
        recognize
            notify_flash - flash the taskbar
            notify_front - bring wiindow to front and take focus

        @param notifyEvents - bitmapped flag of events to execute
    }
    procedure OnNotify(notifyEvents: integer);virtual;
  published
    {
        Use the given persisted information to open a form as if the
        user had done it.

        This method will only be called with info specific to this class.
        TfrmRoom will only be called with a <TfrmRoom> DOM etc.

        Subclasses should override this method to open forms. The default
        implementation does nothing.

        @param autoOpenInfo Persisted opening information
    }
    class procedure AutoOpenFactory(autoOpenInfo: TXMLTag); virtual;

    {
        Get a DOM used later to auto-open the form.

        Two events are currently defined:
            disconnected - all session forms are about to close and should persist
            shutdown - all non-sessions forms are about to close and should persist.

        DOM must have a root element named "classname". The root element is
        later used to find the appropriate class method factory.

        Classes can specify whether or not this auto open info should be persisted
        for the current profile only or for no profile.

        Subclasses should override this method to persist their auto-open info.
        For instance, TfrmChat may return <TfrmChat j='foo@bar"/>. If form does
        not handle a particular event (debug form when disconnected event is fired)
        nil should be returned. The default implementation returns nil.

        @param event
        @param useProfile - should this open be associated with the current profile?
        @returns an DOM of persisted auto-open info or nil if not implementing.
            Freeing this tag is the responibility of the caller.
    }
    function GetAutoOpenInfo(event: Widestring; var useProfile: boolean): TXMLTag;virtual;

   {
        Is this form currently notifying the user.

        This flag will be true if the form is handling some received
        notification event. Is set to false when the form stops
        notifying. Typically when the form receives focus.
    }
    property IsNotifying: boolean read _isNotifying write setNotifying;

  end;

var
  frmState: TfrmState;


implementation

{$R *.dfm}

uses
    PrefController,
    debug,
    room,
    ChatWin,
    msgqueue,

    unicode,
    jabber1,
    types,
    Session,
    GnuGetText,
    ExUtils,
    XMLUtils;

class procedure TAutoOpenEventManager.onAutoOpenEvent(event: Widestring);
var
    i: integer;
    wTag: TXMLTag;
    profileList: TXMLtagList;
    defaultList: TXMLTagList;
    useProfile: boolean;
    discovered: TWideStringList;
    AClass: TPersistentClass;
    prefHelper: TStateFormPrefsHelper;

    function toggleEvent(event: widestring): WideString;
    begin
        if (event = 'disconnected') then
            Result := 'authed'
        else //if (event = 'shutdown') then
            Result := 'startup'
    end;

    //should eb able to use the RTII method below but it not working
    procedure AutoOpenFactory(autoOpenInfo: TXMLTag);
    var
        cName: WideString;
    begin
        cName := autoOpenInfo.Name;
        if (cname = 'TfrmDebug') then
            TfrmDebug.AutoOpenFactory(autoOpenInfo)
        else if (cName = 'TfrmRoom') then
            TfrmRoom.AutoOpenFactory(autoOpenInfo)
        else if (cName = 'TfrmChat') then
            TfrmChat.AutoOpenFactory(autoOpenInfo)
        else if (cName = 'TfrmMsgQueue') then
            TfrmMsgQueue.AutoOpenFactory(autoOpenInfo);
    end;

    procedure OpenWindow(autoOpenInfo: TXMLTag);
    begin
        if (discovered.IndexOf(autoOpenInfo.Name) <> -1) then
            AClass := TPersistentClass(discovered.Objects[discovered.IndexOf(autoOpenInfo.Name)])
        else begin
            AClass := getClass(autoOpenInfo.Name);
            discovered.AddObject(autoOpenInfo.Name, TObject(AClass)); //could be nil but that's OK
        end;
        if ((AClass <> nil) and AClass.InheritsFrom(TfrmState)) then
            AutoOpenFactory(autoOpenInfo);
//            TfrmState(AClass).AutoOpenFactory(wTag);
    end;
begin
    prefHelper := TStateFormPrefsHelper.create();
    if ((event='disconnected') or (event='shutdown')) then begin
        defaultList := TXMLTagList.Create();
        profileList := TXMLTagList.Create();

        //walk open forms and get auto-open tags from them
        for i := 0 to Screen.FormCount - 1 do begin
            if (Screen.Forms[i].InheritsFrom(TfrmState)) then begin
                wTag := TfrmState(Screen.Forms[i]).GetAutoOpenInfo(event, useProfile);
                if (wTag <> nil) then begin
                    if (useProfile) then
                        profileList.add(wTag)
                    else
                        defaultList.add(wTag)
                end;
            end;
        end;
        prefHelper.setAutoOpenEvent(toggleEvent(event), profileList, MainSession.Profile.Name);
        prefHelper.setAutoOpenEvent(toggleEvent(event), defaultList);
    end
    else if (((event='startup') or (event='authed')) and MainSession.Prefs.getBool('restore_desktop')) then begin
        discovered := TWideStringList.create();

        if (prefHelper.getAutoOpenEvent(event, profileList, MainSession.Profile.Name)) then
            for i := 0 to profileList.Count - 1 do
                OpenWindow(profileList[i]);

        if (prefHelper.getAutoOpenEvent(event, defaultList)) then
            for i := 0 to defaultList.Count - 1 do
                OpenWindow(defaultList[i]);
    end;
end;

 {wrappers around TPrefController methods, these introduce profiles to prefs}
procedure TStateFormPrefsHelper.setWindowState(windowState: TXMLTag);
var
    rootTag: TXMLTag;
    sTag: TXMLTag;
    wTag:TXMLTag;
begin
    if (not mainSession.Prefs.getRoot('ws', roottag)) then
        rootTag := TXMLtag.create('ws');

    sTag := rootTag.GetFirstTag('state');
    if (stag = nil) then
        sTag := rootTag.AddTag('state');
    wTag := sTag.GetFirstTag(windowState.Name);
    if (wTag <> nil) then
        sTag.RemoveTag(wTag);

    sTag.AddTag(TXMLTag.create(windowState)); //addtag adds a reference
    MainSession.Prefs.SetRoot(rootTag);
    rootTag.Free();
end;

function  TStateFormPrefsHelper.getWindowState(pKey: WideString; var windowState: TXMLTag): boolean;
var
    rootTag: TXMLTag;
    wsTag: TXMLTag;
begin
    Result := false;
    windowState := nil;
    if (not mainSession.Prefs.getRoot('ws', rootTag)) then exit;

    wsTag := rootTag.GetFirstTag('state');
    if (wsTag = nil) then exit;
    
    windowState := wsTag.GetFirstTag(pKey);
    Result := (windowState <> nil);
end;

procedure TStateFormPrefsHelper.SetAutoOpenEvent(event: WideString; aoWindows: TXMLTagList; Profile: WideString='');
var
    rootTag: TXMLTag;
    aoTag: TXMLTag;
    eTag: TXMLTag;
    i: integer;
    tstr: WideString;
begin
    if (not mainSession.Prefs.getRoot('ws', roottag)) then exit;
    aoTag := rootTag.GetFirstTag('auto-open');
    if (aoTag = nil) then
        aoTag := rootTag.AddTag('auto-open');
    tstr := 'event-' + event;
    if (Profile <> '') then
        tstr := tstr + '-' + XMLUtils.MungeName(Profile);
    //replace if tag already exists...
    eTag := aoTag.GetFirstTag(tstr);
    if (eTag <> nil) then
        aoTag.RemoveTag(eTag);
    if (aoWindows.Count > 0) then begin
        eTag := aoTag.AddTag(tstr);
        for i := 0 to aoWindows.Count - 1 do
            eTag.AddTag(aoWindows[i]);
    end;
    MainSession.Prefs.setRoot(rootTag);
    rootTag.Free();
end;

function  TStateFormPrefsHelper.getAutoOpenEvent(event: Widestring; var aoWindows: TXMLTagList; Profile: WideString=''): boolean;
var
    rootTag: TXMLTag;
    AOTag: TXMLTag;
    eTag: TXMLTag;
    i: integer;
    tstr: wideString;
begin
    Result := false;
    aoWindows := nil;
    if (not mainSession.Prefs.getRoot('ws', rootTag)) then exit;
    aoTag := rootTag.GetFirstTag('auto-open');
    if (aoTag = nil) then exit;

    tstr := 'event-' + event;
    if (Profile <> '') then
        tstr := tstr + '-' + XMLUtils.MungeName(Profile);
    eTag := aoTag.GetFirstTag(tstr);
    if (eTag = nil) then exit;
    aoWindows := TXMLTagList.Create();
    for i := 0 to eTag.ChildCount - 1 do
        aoWindows.Add(TXMLTag.Create(eTag.ChildTags[i]));
    Result := aoWindows.Count > 0;
    if (not Result) then begin
        aoWindows.Free();
        aoWindows := nil;
    end;
end;

{---------------------------------------}
class procedure TfrmState.AutoOpenFactory(autoOpenInfo: TXMLTag);
begin
    //nop
end;

{---------------------------------------}
function TfrmState.GetAutoOpenInfo(event: Widestring; var useProfile: boolean): TXMLTag;
begin
    Result := nil;
    useProfile := false;
end;

{---------------------------------------}
procedure TfrmState.setNotifying(newNotifyingState: boolean);
begin
//perhaps update if state changed?
//    if (_isNotifying <> newNotifyingState) then begin
        _isNotifying := newNotifyingState;
end;

function toRect(pos: TPos): TRect;
begin
    Result.Left := pos.Left;
    Result.Right := pos.Left + pos.Width;
    Result.Top := pos.Top;
    Result.Bottom := pos.Top + pos.Height;
end;

{---------------------------------------}
procedure TfrmState.CenterOnMainformMonitor(var pos: TPos);
var
    dtop: TRect;
    mon: TMonitor;
    cp: TPoint;
begin
    // center it on the mainform's monitor
//    Self.DefaultMonitor := dmMainform;
    Self.DefaultMonitor := dmActiveForm;
    dtop := Screen.ActiveForm.Monitor.WorkareaRect;
    cp := CenterPoint(dtop);
    //adjust width/height if neccessary and possible
    if (Self.BorderStyle = bsSizeable) then begin
        if (pos.Width > (dtop.Right - dtop.Left)) then
            pos.width := (dtop.Right - dtop.Left) - 27;
        if (pos.height > (dtop.bottom - dtop.Top)) then
            pos.height := (dtop.bottom - dtop.Top) - 27;

    end;
    pos.Left := cp.x - (pos.width div 2);
    pos.Top := cp.y - (pos.height div 2);
end;

{ TfrmState }

{---------------------------------------}
procedure TfrmState.CreateParams(var Params: TCreateParams);
begin
    // Make each window appear on the task bar.
    inherited CreateParams(Params);
    with Params do begin
        ExStyle := ExStyle or WS_EX_APPWINDOW;
    end;
end;

{---------------------------------------}
procedure TfrmState.FormCreate(Sender: TObject);
begin
    _stateRestored := false;
    //get state info from prefs
    // do translation magic
    AssignUnicodeFont(Self);
    TranslateComponent(Self);
    _skipWindowPosHandling := false;

    _flasher := TTimer.Create(Application);
    _flasher.Enabled := false;
    _flasher.Interval := FLASH_TIMER_INTERVAL;
    _flasher.OnTimer := OnFlashTim;
end;


{---------------------------------------}
function sToWindowState(s : string): TWindowState;
begin
    if (s = 'm') then
        Result := wsMinimized
    else if (s = 'x') then
        Result := wsMaximized
    else Result := wsNormal;
end;

function wsToString(ws : TWindowState): string;
begin
    if (ws = wsMinimized) then
        Result := 'm'
    else if (ws = wsMaximized) then
        Result := 'x'
    else Result := 'n'
end;

function b2s(b:boolean): String;
begin
    if (b) then
        Result := 'true'
    else
        Result := 'false';
end;

{---------------------------------------}
procedure TfrmState.WMSysCommand(var msg: TWmSysCommand);
begin
    case (msg.CmdType and $FFF0) of
        SC_MINIMIZE: begin
            _windowState := wsMinimized;
        end;
        SC_RESTORE: begin
            _windowState := wsNormal;
        end;
        SC_MAXIMIZE: begin
            _windowState := wsMaximized;
        end;
    end;
OutputDebugMsg('wmssyscommande: new state: ' + wsToString(_windowState));
    inherited;
end;

{---------------------------------------}
procedure TfrmState.WMActivate(var msg: TMessage);
begin
    if (not _skipWindowPosHandling and (Msg.WParamLo <> WA_INACTIVE)) then begin
        // we are getting activated
        _skipWindowPosHandling := true;
        SetWindowPos(Self.Handle, 0, Self.Left, Self.Top,
            Self.Width, Self.Height, HWND_TOP);
        _skipWindowPosHandling := false;
        if (self.Visible) then
            gotActivate();
    end;
    inherited;
end;

{---------------------------------------}
procedure TfrmState.WMWindowPosChange(var msg: TWMWindowPosChanging);
begin
    //only allow window to come to top if activating. Don't bring it
    //to front if resizing in code somewhere.
    if (not _skipWindowPosHandling) then
        msg.WindowPos^.flags := msg.WindowPos^.flags or SWP_NOZORDER;

    inherited;
    
    //save state if not
    //  floating
    //  not creating the form
    //  in normal window state
    if (not _skipWindowPosHandling and Self.Floating and (not (fsCreating in Self.FormState)) and (_windowState = wsNormal)) then begin
        _pos.Left := Self.Left;
        _pos.width := Self.Width;
        _pos.Top := Self.Top;
        _pos.height := Self.Height;
        _persistPos := true;
OutputDebugMsg('WMWindowPosChange: updated position to: l:' + IntToStr(_pos.left) + ', t:' + IntToStr(_pos.Top) + ', h:' + IntToStr(_pos.Height) + ', w:' + IntToStr(_pos.Width));
    end;
end;

{---------------------------------------}
procedure TfrmState.WMDisplayChange(var msg: TMessage);
begin
    //check to make sure this is a floating window, if docked let parent deal
    if (Self.Floating) then
        checkAndCenterForm(Self);
end;


{
    Restore position and window state.

    For backwards compatablility need to check to see if
    position information is stored as attributes, if not look
    for nodes...
}
procedure TfrmState.RestoreWindowState();
var
    stateTag: TXMLTag;
    prefHelper: TStateFormPrefsHelper;
begin
    prefHelper := TStateFormPrefsHelper.create();
    if (not _stateRestored) then begin
        if (not MainSession.Prefs.getBool('restore_window_state') or
           (not prefHelper.getWindowState(GetWindowStateKey(), stateTag))) then begin
            stateTag := TXMLTag.create(GetWindowStateKey());
//            Self.DefaultMonitor := dmMainForm; //open on the main forms monitor 
           end;
        _skipWindowPosHandling := true;
        Self.OnRestoreWindowState(stateTag);
        _skipWindowPosHandling := false;
OutputDebugMsg('Restored window state. key: ' + GetWindowStateKey() + ', state: ' + stateTag.XML);
        stateTag.Free();
        _stateRestored := true;
    end;
    prefHelper.free();
end;

procedure TfrmState.PersistWindowState();
var
    stateTag: TXMLTag;
    prefHelper: TStateFormPrefsHelper;
begin
    prefHelper := TStateFormPrefsHelper.create();
    stateTag := TXMLTag.Create(getWindowStateKey());
    Self.OnPersistWindowState(stateTag);
    prefHelper.setWindowState(stateTag);
OutputDebugMsg('Persisting window state. key: ' + GetWindowStateKey() + ', state: ' + stateTag.XML);
    stateTag.Free();
    prefHelper.free();
end;

{
    Show the window in its default configuration.

    The default implementation is to show the window in its last floating
    position. Override this method to change (ie dock instead of float)
}
procedure TfrmState.ShowDefault(bringtofront:boolean; dockOverride: string);
begin
    if (not Self.Visible) then begin
        RestoreWindowState();
        _skipWindowPosHandling := true;
        if (_windowState = wsMinimized) then
            ShowWindow(Handle, SW_SHOWMINNOACTIVE)
        else if (_windowState = wsMaximized) then
            ShowWindow(Handle, SW_MAXIMIZE)
        else if(bringtofront) then begin
            ShowWindow(Handle, SW_SHOWNORMAL);
            Self.BringToFront;
        end
        else
            SetWindowPos(Self.Handle, HWND_BOTTOM, 0,0,0,0, SWP_NOSIZE + SWP_NOMOVE + SWP_NOACTIVATE + SWP_SHOWWINDOW);
        Self.Visible := true;
        _skipWindowPosHandling := false;
    end
    else if (frmExodus.isMinimized() and not bringtofront) then
        ShowWindow(Handle, SW_SHOWMINNOACTIVE)
    else if(not bringtofront) then
        ShowWindow(Handle, SW_SHOWNOACTIVATE)
    else begin
        ShowWindow(Handle, SW_SHOWNORMAL);
        Self.BringToFront;
    end;
end;

procedure TfrmState.gotActivate();
begin
    //this is going to be a problem if tray should flash
    //until *all* notified windows become active
    StopTrayAlert();

    _flasher.enabled := false;
    isNotifying := false;
    OutputDebugMsg(Self.ClassName +  '.gotActivate');
end;

{
    Get the window state associated with this window.

    Default implementation is to return a munged classname (all XML illgal
    characters escaped). Classes should override to change pref (for instance
    chat windows might save based on munged profile&jid).
}
function TfrmState.GetWindowStateKey() : WideString;
begin
    Result := XMLUtils.MungeName(Self.ClassName);
end;

{
    Event fired when form should restore its persisted state.

    Default uses GetPreferenceKey to get pref containing this
    window's state information.

    prefTag is an xml tag
        <windowstatekey pos_h='' pos_w='' pos_l='' pos_t='' dock='t' ws='n|m|x'/>

    This event is fired when the form is created.
}
procedure TfrmState.OnRestoreWindowState(windowState : TXMLTag);
begin
    _persistPos := true;
    //center on parent
    if (windowState.GetAttribute('pos_w') <> '') then begin
        _pos.Left := SafeInt(windowState.getAttribute('pos_l'));
        _pos.Top := SafeInt(windowState.getAttribute('pos_t'));
        //if window is fixed size, don't try to overwrite
        if (Self.BorderStyle = bsSizeable) then begin
            _pos.height := SafeInt(windowState.getAttribute('pos_h'));
            _pos.width := SafeInt(windowState.getAttribute('pos_w'));
        end else begin
            _pos.height := Self.ExplicitHeight;
            _pos.width := Self.ExplicitWidth;
        end;
    end
    else begin
        _pos.Left := 0;
        _pos.Top := 0;
        _pos.Width := Self.ExplicitWidth;
        _pos.Height := Self.ExplicitHeight;
        CenterOnMainformMonitor(_pos);
    end;
    _origPos.Left := _pos.Left;
    _origPos.width := _pos.width;
    _origPos.Top := _pos.Top;
    _origPos.height := _pos.height;
    normalizePos();
    SetWindowPos(Self.Handle, HWND_BOTTOM, _pos.Left, _pos.Top, _pos.Width, _pos.Height, SWP_NOACTIVATE or SWP_NOOWNERZORDER);
    _windowState := sToWindowState(windowState.GetAttribute('ws'));
end;

{
    Event fired when form should persist its position and other state
    information.

    Default uses GetWindowStateKey to determine actual key persisted

    OnPersistState is passed an xml tag (<windowstatekey/>) that should be used to
    store state. For instance after the default OnPersistState handler is called
    prefTag will be
        <windowstatekey>
            <position h="" w="" t="" l="" />
            <docked>true|false</docked>
        </windowstatekey>

    This event is fired during the OnCloseQuery event.
}
procedure TfrmState.OnPersistWindowState(windowState : TXMLTag);
var
    tp : TPos;
begin
    if (_persistPos) then
        tp := _pos
    else
        tp := _origPos;
    windowState.setAttribute('pos_h', IntToStr(tp.height));
    windowState.setAttribute('pos_w', IntToStr(tp.width));
    windowState.setAttribute('pos_t', IntToStr(tp.Top));
    windowState.setAttribute('pos_l', IntToStr(tp.Left));
    //min/max/restored (see Self.WindowState)
    windowState.setAttribute('ws', wsToString(_windowState));
end;

procedure TfrmState.NormalizePos();
var
    ok: boolean;
    dtop: TRect;
    cp: TPoint;
begin

    // Netmeeting hack
    if (Assigned(Application.MainForm)) then
        Application.MainForm.Monitor;

    //get screnn coords and see if we fit, adjust size/position as needed
    // Make it slightly bigger to acccomodate PtInRect

    Self.DefaultMonitor := dmDesktop;
    dtop := Screen.MonitorFromRect(toRect(_pos)).WorkareaRect;
    inc(dtop.Bottom);// := dtop.Bottom + 1;
    inc(dtop.Right);// := dtop.Right + 1;

    cp.X := _pos.left;
    cp.Y := _pos.Top;
    //check top, right and bottom, left to make sure rectangle is fully on desktop
    ok := PtInRect(dtop, cp);
    cp.X := _pos.left + _pos.width;
    cp.Y := _pos.Top + _pos.Height;
    ok := ok and PtInRect(dtop, cp);

    if (ok = false) then begin
        //we had to move this window as it won't fit in our desktop.
        //don't save new coords.
        _persistPos := false;
        CenterOnMainformMonitor(_pos);
    end;
end;

procedure TfrmState.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
    PersistWindowState();
    _flasher.Enabled := false;  //stop flashing
end;

function TfrmState.getPosition(): TRect;
begin
    Result := Bounds(_pos.Left, _pos.Top, _pos.Width, _pos.Height);
end;

procedure TfrmState.OnFlash();
begin
    FlashWindow(Self.Handle, true)
end;

procedure TfrmState.OnFlashTim(Sender: TObject);
begin
    if (not Self.Active and isNotifying and MainSession.prefs.GetBool('notify_flasher')) then
        onFlash()
    else
        _flasher.Enabled := false;  //stop flashing
end;

procedure TfrmState.OnNotify(notifyEvents: integer);
begin
     if (Self.Floating and ((notifyEvents and notify_front) > 0)) then begin
        ShowWindow(Self.Handle, SW_SHOWNORMAL);
        Self.bringtofront();
     end
     else if ((notifyEvents and PrefController.notify_flash) > 0) then begin
        isNotifying := true;
        OnFlash(); //flash once
        _flasher.Enabled := true; //OnFlash will handle rest
     end;
end;

end.
