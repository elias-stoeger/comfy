import 
  x11/xlib,
  x11/xutil,
  x11/x,
  x11/xft,
  x11/xrender,
  std/parsecfg,
  std/strutils,
  std/osproc
      
const
  WINDOW_WIDTH  = 400
  WINDOW_HEIGHT = 300

let
  config = loadConfig("comfy.ini")
  bg = config.getSectionValue("Settings", "bg-color")
  background: cuint = bg[1..bg.len - 1].parseHexInt.cuint
  fgHex: string     = config.getSectionValue("Settings", "font-color")
  foreground: cuint = fgHex[1..fgHex.len - 1].parseHexInt.cuint
  fgRed: cushort    = fgHex[1..2].parseHexInt.cushort * 257
  fgGreen: cushort  = fgHex[3..4].parseHexInt.cushort * 257
  fgBlue: cushort   = fgHex[5..6].parseHexInt.cushort * 257
  cursor: string    = config.getSectionValue("Settings", "cursor-symbol")
  fontName: cstring = $config.getSectionValue("Settings", "font") &
                      ":" & $config.getSectionValue("Settings", "font-size")

#echo fgHex
#echo fgRed
#echo fgGreen
#echo fgBlue
#echo fontName

var
  displayString = ">> "
  width, height: cuint
  display: PDisplay
  screen: cint
  depth: int
  win: Window
  sizeHints: XSizeHints
  wmDeleteMessage: Atom
  running: bool
  xev: XEvent
  font: PXftFont
  xftDraw: PXftDraw
  xftColor: XftColor
  lineWidth: int

  window_atts: XWindowAttributes
  buffer: seq[string]
  commands: seq[string]
  index: int

buffer.add(config.getSectionValue("Settings", "start-message"))

proc create_window = 
  width = WINDOW_WIDTH
  height = WINDOW_HEIGHT

  display = XOpenDisplay(nil)
  if display == nil:
    quit "Failed to open display"

  screen = XDefaultScreen(display)

  font = XftFontOpenName(display, screen, fontName)
  if font == nil:
    quit "Failed to load a valid font"

  depth = XDefaultDepth(display, screen)
  var rootwin = XRootWindow(display, screen)
  win = XCreateSimpleWindow(display, rootwin, 100, 10,
                            width, height, 5,
                            #XBlackPixel(display, screen),
                            #XWhitePixel(display, screen)
                            foreground,
                            background
                            )
  #sizeHints.flags = PSize or PMinSize or PMaxSize
  #sizeHints.min_width =  width.cint
  #sizeHints.max_width =  width.cint
  #sizeHints.min_height = height.cint
  #sizeHints.max_height = height.cint
  discard XSetStandardProperties(display, win, "comfy", "window",
                         0, nil, 0, addr(sizeHints))
  discard XSelectInput(display, win, ButtonPressMask or KeyPressMask or 
                                     PointerMotionMask or ExposureMask)
  discard XMapWindow(display, win)

  wmDeleteMessage = XInternAtom(display, "WM_DELETE_WINDOW", false.XBool)
  discard XSetWMProtocols(display, win, wmDeleteMessage.addr, 1)

  xftDraw = XftDrawCreate(display, win, DefaultVisual(display, 0), DefaultColormap(display, 0))

  var xrenderColor: XRenderColor
  #xrenderColor.red = 65535
  #xrenderColor.green = 0
  #xrenderColor.blue = 0
  #xrenderColor.alpha = 65535
  xrenderColor.red    = fgRed
  xrenderColor.green  = fgGreen
  xrenderColor.blue   = fgBlue
  xrenderColor.alpha  = 65535
  discard XftColorAllocValue(
    display,
    DefaultVisual(display, 0),
    DefaultColormap(display, 0),
    xrenderColor.addr,
    xftColor.addr
  )

  running = true

proc close_window =
  discard XDestroyWindow(display, win)
  discard XCloseDisplay(display)

proc draw_screen =
  var distance = 25
  #echo buffer
  let size = 25 + 20 * buffer.len
  #echo "Size: ", size
  #echo "Max Lines: ", (window_atts.height / 20).int
  #echo "Current Lines: ", (size / 20).int
  if buffer.len + 1 > (window_atts.height / 20 - 1).int:
    buffer = buffer[(buffer.len - ((window_atts.height / 20).int - 2))..(buffer.len - 1)]
  for line in buffer:
    XftDrawStringUtf8(xftDraw, xftColor.addr, font, 5, distance.cint, 
                        cast[PFcChar8](line[0].unsafeAddr), line.len.cint)
    distance += 20
  #echo "Distance: " & $distance
  let text = displayString & cursor
  XftDrawStringUtf8(xftDraw, xftColor.addr, font, 5, distance.cint, cast[PFcChar8](text[0].unsafeAddr), text.len.cint)

proc handle_event =
  discard XNextEvent(display, xev.addr)
  case xev.theType
  of Expose:
    discard XGetWindowAttributes(display, win, addr window_atts)
    draw_screen()
  of ClientMessage:
    if cast[Atom](xev.xclient.data.l[0]) == wmDeleteMessage:
      running = false
  of KeyPress:
    var key = XLookupKeysym(cast[PXKeyEvent](xev.addr), 0)
    if key != 0:
      # Enter
      if key == 65293:
        if displayString != ">> ":
          buffer.add(displayString)
          commands.add(displayString)
          index = 0
          try:
            let outp = execCmdEx(displayString[3..displayString.len - 1])[0]
            #echo "Output: " & $outp
            if outp.len > 0:
              let lines = outp.split("\n")
              #echo lines
              for line in lines:
                if line != "":
                  buffer.add(line)

          except:
            buffer.add("Befehl nicht gefunden :(")
            
          displayString = ">> "
          lineWidth = 0

      # Pfeil hoch
      elif key == 65362:
        echo "Index: ", index
        echo "ComLen: ", commands.len
        if index < commands.len:
          echo "+1"
          index += 1
          displayString = commands[commands.len - index]

      # Pfeil runter
      elif key == 65364:
        echo "Index: ", index
        echo "ComLen: ", commands.len
        if index > 1 and index <= commands.len:
          echo "-1"
          index -= 1
          displayString = commands[commands.len - index]
        elif index == 1:
          index -= 1
          displayString = ">> "

      elif key.int in [65515, 65505]:
        echo "Special key"

      # Entf
      elif key == 65288:
        if displayString.len > 3:
          displayString = displayString[0..displayString.len - 2]

      else:
        echo "Keyboard event"
        try:
          echo key.char
        except:
          echo key
        displayString = displayString & key.char
        lineWidth += 10
        echo "Line Width: " & $lineWidth
        discard XGetWindowAttributes(display, win, addr window_atts)
        echo "Atts: " & $window_atts.height
        #if (lineWidth + 10).cint >= DisplayWidth(display, screen):
        #  displayString = displayString & "\n"
        #  lineWidth = 0
      discard XClearWindow(display, win)
      draw_screen()
  of ButtonPressMask, PointerMotionMask:
    echo "Mouse event"
  else:
    discard

create_window()
lineWidth = displayString.len
while running:
  handle_event()
close_window()

