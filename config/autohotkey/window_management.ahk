#Requires AutoHotKey v2

WinHidden(window_id) {
  ; Returns whether or not a window is currently hidden
  ; uses DetectHiddenWindows to search for the window name,
  ; if it can be found when detect is on but otherwise cannot, then
  ; it must be hidden
  DetectHiddenWindows 1
  win_id := WinExist("ahk_id " window_id)
  DetectHiddenWindows 0
  win_id_hidden := WinExist("ahk_id " window_id)
  if (win_id_hidden == 0) && (win_id > 0) {
    return 1
  } else {
    return 0
  }
}

WinDeactivate(window_name) {
  ; Deactivates a window, so that text doesn't get input into it
  ; (e.g. accidentally typing passwords uh-oh, thankfully I didn't hit enter)
  DetectHiddenWindows 0
  windows := WinGetList()
  if windows.Length > 0 {
    WinActivate(windows[windows.Length])
  }
  DetectHiddenWindows 1
}

SwapMonitor() {
  ; Moves the currently active window to the next monitor, and resizes it to the large size
  monitor := FindMonitor()
  new_monitor := Mod(monitor + 1,  MonitorGetCount())
  SetWindowSize(0.02, 0.02, 0.96, 0.96, "A", new_monitor)
}

FindMonitor(window_name := "A") {
  ; Find which monitor a window is in, by checking the x/y positions compared to the monitors extents
  WinGetPos &win_x, &win_y, &win_w, &win_h, window_name
  monitor_count := MonitorGetCount()
  Loop monitor_count {
    monitor_id := MonitorGetWorkArea(A_index, &left, &top, &right, &bottom)
    if (win_x >= left) && ( win_x <= right  )&& ( win_y >= top  )&& (win_y <= bottom) {
      return monitor_id
    }
  }
  return -1
}

SetWindowSize(x, y, w, h, window_name := "A", monitor := -1) {
  ; Sets the window position/size relative to its monitor
  ;
  ; params:
  ; x/y the positions (relative to top-left) as a proportion of the total monitor size. e.g. 0.1 for 10%
  ; w/h the size of the window, relative to the total monitor size
  ; window_name - a descriptor to find the window. Will use the active window if not specified
  ; monitor - which monitor to set the window on. Defaults to the current monitor (or 0 if this can't be determined)
  if (monitor == -1) {
    monitor := FindMonitor(window_name)
  }
  if (monitor == -1) {
    ; at this point we can't figure out the monitor, so default to monitor 0
    ; this sometimes happens when windows are fully maximised, as they seem to have borders slightly larger than the monitor extent
    monitor := 0
  }
  monitor := MonitorGetWorkArea(monitor, &left, &top, &right, &bottom)
  WinMove(left + x * (right - left), top + y * (bottom - top), w * (right - left), h * (bottom - top), window_name)
}

ToggleWindow(window_name, executable, x:=0.05, y:=0.05, w:=0.9, h:=0.9) {
  ; Either activates or deactivates a specific window type
  ; if the window is active and visible, then it will hide said window. 
  ; If the window is hidden, it will show the window and then activate it
  ; If the window doesn't exist, it will launch the specified program and activate it
  ; In all cases where the window is now active, it sets its position relative to the monitor it is on
  SetTitleMatchMode(2)
  DetectHiddenWindows 1
  window_ids := WinGetList(window_name)
  activated := 0
  if window_ids.Length > 0 {
    for window_id in window_ids {
      if WinActive("ahk_id " window_id) {
        activated := 1
        if WinHidden(window_id) {
          DetectHiddenWindows 1
          WinShow("ahk_id " window_id)
          SetWindowSize(x, y, w, h, "ahk_id " window_id)
        } else {
          WinHide("ahk_id " window_id)
          WinDeactivate("ahk_id " window_id)
        }
      } else {
        WinShow("ahk_id " window_id)
        if activated == 0 {
          WinActivate("ahk_id " window_id)
          activated := 1
        }
        SetWindowSize(x, y, w, h, "ahk_id " window_id)
      }
    }
  } else {
    Run executable
    WinWait(window_name)
    WinActivate(window_name)
    SetWindowSize(x, y, w, h, window_name)
  }

  return
}

^!b::{ ; ctrl+alt_b - emBiggen the window to near max
  SetWindowSize(0.02, 0.02, 0.96, 0.96)
}
^!m::{  ; ctrl+alt+m - move window to next monitor
  SwapMonitor() 
}
^Tab::{ ; ctrl+tab - toggle in/out firefox
  ToggleWindow("Firefox ahk_class MozillaWindowClass", "firefox.exe", 0.02, 0.02, 0.96, 0.96)
}
^s::{ ; ctrl+s - toggle in/out slack
  ToggleWindow("Slack ahk_exe slack.exe ahk_class Chrome_WidgetWin_1", "slack.exe", 0.1, 0.1, 0.8, 0.8)
}
^!s::{ ; ctrl+alt+s - toggle in/out spotify
  ToggleWindow("ahk_exe Spotify.exe ahk_class Chrome_WidgetWin_1", "spotify.exe", 0.1, 0.1, 0.8, 0.8)
}
^Sc029::{ ; ctrl+` - toggle in/out the terminal window
  ToggleWindow("ahk_class org.wezfurlong.wezterm", "wezterm-gui.exe", 0.02, 0.02, 0.96, 0.96)
}
^m::{ ; ctrl+m - toggle mail window
  ToggleWindow("Outlook ahk_exe olk.exe", "olk.exe", 0.1, 0.1, 0.8, 0.8) 
}
^!z::{  ; ctrl+alt+z - toggle MS teams
  ToggleWindow("ahk_class TeamsWebView", "ms-teams.exe", 0.1, 0.1, 0.8, 0.8) 
}
^!d::{  ; ctrl+alt+d - development window (aka visual studio)
  ToggleWindow("Microsoft Visual Studio ahk_exe devenv.exe", "devenv.exe", 0.02, 0.02, 0.96, 0.96)
}
#^p::{  ; ctrl+win+p - debug information about the window
MsgBox(WinGetClass("A") " - " WinGetProcessName("A")  " - " WinGetTitle("A"))
}

^!r::Reload  ; ctrl+alt+r  reload this configuration


