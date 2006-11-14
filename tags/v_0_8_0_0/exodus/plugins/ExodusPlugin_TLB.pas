unit ExodusPlugin_TLB;

// ************************************************************************ //
// WARNING                                                                    
// -------                                                                    
// The types declared in this file were generated from data read from a       
// Type Library. If this type library is explicitly or indirectly (via        
// another type library referring to this type library) re-imported, or the   
// 'Refresh' command of the Type Library Editor activated while editing the   
// Type Library, the contents of this file will be regenerated and all        
// manual modifications will be lost.                                         
// ************************************************************************ //

// PASTLWTR : $Revision: 1.1 $
// File generated on 6/16/2002 3:48:27 PM from Type Library described below.

// ************************************************************************  //
// Type Lib: D:\Src\exodus\plugins\ExodusPlugin.tlb (1)
// LIBID: {053C946B-D466-4686-BC8F-CB5B5D7C9C2A}
// LCID: 0
// Helpfile: 
// DepndLst: 
//   (1) v2.0 stdole, (C:\WINDOWS\System32\stdole2.tlb)
//   (2) v4.0 StdVCL, (C:\WINDOWS\System32\STDVCL40.DLL)
// Errors:
//   Hint: TypeInfo 'ExodusPlugin' changed to 'ExodusPlugin_'
// ************************************************************************ //
{$TYPEDADDRESS OFF} // Unit must be compiled without type-checked pointers. 
{$WARN SYMBOL_PLATFORM OFF}
{$WRITEABLECONST ON}

interface

uses Windows, ActiveX, Classes, Graphics, StdVCL, Variants;
  

// *********************************************************************//
// GUIDS declared in the TypeLibrary. Following prefixes are used:        
//   Type Libraries     : LIBID_xxxx                                      
//   CoClasses          : CLASS_xxxx                                      
//   DISPInterfaces     : DIID_xxxx                                       
//   Non-DISP interfaces: IID_xxxx                                        
// *********************************************************************//
const
  // TypeLibrary Major and minor versions
  ExodusPluginMajorVersion = 1;
  ExodusPluginMinorVersion = 0;

  LIBID_ExodusPlugin: TGUID = '{053C946B-D466-4686-BC8F-CB5B5D7C9C2A}';

  IID_IExodusPlugin: TGUID = '{ACC22059-DC3D-4C6E-B1B1-A6DB095A983E}';
  DIID_ExodusPlugin_: TGUID = '{7A44F5FC-3C6D-4982-B375-1E04E899F49C}';
type

// *********************************************************************//
// Forward declaration of types defined in TypeLibrary                    
// *********************************************************************//
  IExodusPlugin = interface;
  IExodusPluginDisp = dispinterface;
  ExodusPlugin_ = dispinterface;

// *********************************************************************//
// Interface: IExodusPlugin
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {ACC22059-DC3D-4C6E-B1B1-A6DB095A983E}
// *********************************************************************//
  IExodusPlugin = interface(IDispatch)
    ['{ACC22059-DC3D-4C6E-B1B1-A6DB095A983E}']
    procedure Startup(Exodus: OleVariant); safecall;
    procedure Shutdown; safecall;
    procedure Process(const xml: WideString); safecall;
  end;

// *********************************************************************//
// DispIntf:  IExodusPluginDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {ACC22059-DC3D-4C6E-B1B1-A6DB095A983E}
// *********************************************************************//
  IExodusPluginDisp = dispinterface
    ['{ACC22059-DC3D-4C6E-B1B1-A6DB095A983E}']
    procedure Startup(Exodus: OleVariant); dispid 1;
    procedure Shutdown; dispid 2;
    procedure Process(const xml: WideString); dispid 3;
  end;

// *********************************************************************//
// DispIntf:  ExodusPlugin_
// Flags:     (0)
// GUID:      {7A44F5FC-3C6D-4982-B375-1E04E899F49C}
// *********************************************************************//
  ExodusPlugin_ = dispinterface
    ['{7A44F5FC-3C6D-4982-B375-1E04E899F49C}']
  end;

implementation

uses ComObj;

end.