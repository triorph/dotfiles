#Requires AutoHotKey v2
WinHidden(window_name) {
  DetectHiddenWindows 1
  win_id := WinExist(window_name)
  DetectHiddenWindows 0
  win_id_hidden := WinExist(window_name)
  if (win_id_hidden == 0) && (win_id > 0) {
    return 1
  } else {
    return 0
  }
}

SwapMonitor() {
  monitor := FindMonitor()
  new_monitor := Mod(monitor + 1,  MonitorGetCount())
  SetWindowSize(0.05, 0.05, 0.9, 0.9, "A", new_monitor)
  new_monitor := MonitorGetWorkArea(new_monitor, &left, &top, &right, &bottom)
  WinMove(left + 0.05 * (right - left), top + 0.05 * (bottom - top), 0.9 * (right - left), 0.9 * (bottom - top), "A")
}

FindMonitor(window_name := "A") {
  WinGetPos &win_x, &win_y, &win_w, &win_h, window_name
  monitor_count := MonitorGetCount()
  Loop monitor_count {
    monitor_id := MonitorGetWorkArea(A_index, &left, &top, &right, &bottom)
    if (win_x >= left) && ( win_x < right  )&& ( win_y >= top  )&& (win_y < bottom) {
      return monitor_id
    }
  }
  return -1
}

SetWindowSize(x, y, w, h, window_name := "A", monitor := -1) {
  if monitor := -1 {
    monitor := FindMonitor(window_name)
  }
  monitor := MonitorGetWorkArea(monitor, &left, &top, &right, &bottom)
  WinMove(left + x * (right - left), top + y * (bottom - top), w * (right - left), h * (bottom - top), window_name)
}

ToggleWindow(window_name, executable, x:=0.05, y:=0.05, w:=0.9, h:=0.9) {

  DetectHiddenWindows 1
  window_id := WinActive(window_name)
  if window_id {
    if WinHidden(window_name) {
      DetectHiddenWindows 1
      window_id := WinActive(window_name)
      WinShow
      SetWindowSize(x, y, w, h, window_name)
    } else {
      WinHide(window_id)
    }
  } else {
    window_id := WinExist(window_name)
    if window_id  {
      WinShow window_id
      WinActivate window_id
      SetWindowSize(x, y, w, h, window_name)
    } else {
      Run executable
      WinWait(window_name)
      WinActivate(window_name)
      SetWindowSize(x, y, w, h, window_name)
    }
  } 
  return
}

^!b::SetWindowSize(0.02, 0.02, 0.96, 0.96)
^Tab::ToggleWindow("Firefox", "firefox.exe", 0.02, 0.02, 0.96, 0.96)
#^s::ToggleWindow("Slack", "slack.exe", 0.1, 0.1, 0.8, 0.8)
^!s::ToggleWindow("Spotify ahk_class Chrome_WidgetWin_1", "spotify.exe", 0.1, 0.1, 0.8, 0.8)
^Sc029::ToggleWindow("ahk_class org.wezfurlong.wezterm", "wezterm.exe", 0.02, 0.02, 0.96, 0.96)
^m::ToggleWindow("Outlook", "outlook.exe", 0.1, 0.1, 0.8, 0.8)
^!z::ToggleWindow("ahk_class TeamsWebView", "teams.exe", 0.1, 0.1, 0.8, 0.8)
^!m::SwapMonitor()
#^p::{
MsgBox(WinGetClass("A"))
}

^!r::Reload


