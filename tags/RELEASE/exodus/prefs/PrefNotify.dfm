inherited frmPrefNotify: TfrmPrefNotify
  Left = 267
  Top = 154
  Caption = 'frmPrefNotify'
  ClientHeight = 346
  ClientWidth = 338
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object lblConfigSounds: TTntLabel [0]
    Left = 169
    Top = 32
    Width = 93
    Height = 13
    Cursor = crHandPoint
    Hint = 'Open Sounds Control Panel'
    Caption = 'Configure Sounds...'
    ParentShowHint = False
    ShowHint = True
    OnClick = lblConfigSoundsClick
  end
  inherited pnlHeader: TTntPanel
    Width = 338
    Caption = 'Notification Options'
    TabOrder = 6
  end
  object chkNotify: TTntCheckListBox
    Left = 8
    Top = 112
    Width = 257
    Height = 97
    ItemHeight = 13
    Items.WideStrings = (
      'Contact is online'
      'Contact is offline'
      'New chat session'
      'Normal Messages'
      'Subscription Requests'
      'Conference Invites'
      'Keywords (Conf. Rooms)'
      'Chat window activity'
      'Conf. Room activity'
      'File Transfers'
      'Auto Response generated')
    TabOrder = 4
    OnClick = chkNotifyClick
  end
  object chkSound: TTntCheckBox
    Left = 8
    Top = 32
    Width = 145
    Height = 17
    Caption = 'Use sound notifications'
    TabOrder = 0
    OnClick = chkSoundClick
  end
  object chkNotifyActive: TTntCheckBox
    Left = 8
    Top = 48
    Width = 249
    Height = 17
    Hint = 
      'NOTE: Notifications always occur when Exodus is in the backgroun' +
      'd.'
    Caption = 'Perform notifications when I am using Exodus.'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 1
  end
  object chkFlashInfinite: TTntCheckBox
    Left = 8
    Top = 82
    Width = 289
    Height = 17
    Caption = 'Flash taskbar continuously until Exodus gets focus.'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 3
  end
  object chkNotifyActiveWindow: TTntCheckBox
    Left = 8
    Top = 65
    Width = 281
    Height = 17
    Caption = 'Perform notifications for the window I'#39'm typing in.'
    TabOrder = 2
  end
  object optNotify: TTntGroupBox
    Left = 8
    Top = 216
    Width = 257
    Height = 103
    Caption = 'Notify Options'
    TabOrder = 5
    object chkFlash: TTntCheckBox
      Left = 8
      Top = 36
      Width = 241
      Height = 17
      Caption = 'Flash Taskbar button, or highlight tab'
      TabOrder = 1
      OnClick = chkToastClick
    end
    object chkToast: TTntCheckBox
      Left = 8
      Top = 16
      Width = 241
      Height = 17
      Caption = 'Show a "Toast" popup'
      TabOrder = 0
      OnClick = chkToastClick
    end
    object chkTrayNotify: TTntCheckBox
      Left = 8
      Top = 56
      Width = 241
      Height = 17
      Caption = 'Flash tray icon'
      TabOrder = 2
      OnClick = chkToastClick
    end
    object chkFront: TTntCheckBox
      Left = 8
      Top = 76
      Width = 241
      Height = 17
      Caption = 'Bring window to front'
      TabOrder = 3
      OnClick = chkToastClick
    end
  end
end
