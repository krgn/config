-- system imports
import Control.Monad
import Control.Monad.Trans
import Data.Bits ((.|.))
import Data.Map (fromList)
import Data.Monoid
import Data.Ratio
import GHC.Real
import System.Exit

-- xmonad core
import XMonad
import XMonad.StackSet hiding (workspaces)

-- xmonad contrib
import XMonad.Actions.GridSelect
import XMonad.Actions.SpawnOn
import XMonad.Actions.Warp
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Layout.Grid
import XMonad.Layout.IndependentScreens
import XMonad.Layout.Magnifier
import XMonad.Layout.NoBorders
import XMonad.Util.EZConfig
import XMonad.Util.Run

centerMouse = warpToWindow (1/2) (1/2)
statusBarMouse = warpToScreen 0 (5/1600) (5/1200)
withScreen screen f = screenWorkspace screen >>= flip whenJust (windows . f)

makeLauncher yargs run exec close = concat ["exe=`dmenu_run -b -p open -nf '#4d4d4d' -nb '#000' -sb '#8004d3' ", yargs, "` && ", run, " ", exec, "$exe", close]
launcher     = makeLauncher "" "eval" "\"exec " "\""
termLauncher = makeLauncher "-p withterm" "exec urxvtc -e" "" ""
viewShift  i = view i . shift i
floatAll     = composeAll . map (\s -> className =? s --> doFloat)
sinkFocus    = peek >>= maybe id sink

bright = "#4d4d4d"
dark   = "#121212"

fullscreenMPlayer = className =? "MPlayer" --> do
    dpy   <- liftX $ asks display
    win   <- ask
    hints <- liftIO $ getWMNormalHints dpy win
    case fmap (approx . fst) (sh_aspect hints) of
        Just ( 4 :% 3)  -> viewFullOn win 0 "1"
        Just (16 :% 9)  -> viewFullOn win 1 "5"
        _               -> doFloat
    where
    fi               = fromIntegral
    approx (n, d)    = approxRational (fi n / fi d) (1/100)
    viewFullOn w s n = do
        let ws = marshall s n
        liftX  $ withScreen s view
        return . Endo $ view ws . shiftWin ws w

myLayout = avoidStruts tiled ||| Mirror tiled ||| tiled ||| noBorders Full
  where
     tiled   = Tall nmaster delta ratio
     nmaster = 1
     ratio   = 1/2
     delta   = 3/100

main = do
    nScreens    <- countScreens
    hs          <- mapM (spawnPipe . xmobarCommand) [0 .. nScreens-1]
    trayers     <- mapM (spawnPipe . trayerCommand) [0 .. 0]
    xmonad $ defaultConfig {
        borderWidth             = 3,
        workspaces              = withScreens nScreens (map show [1..9]),
        terminal                = "urxvtc",
        normalBorderColor       = dark,
        focusedBorderColor      = bright,
        modMask                 = mod4Mask,
        keys                    = keyBindings,
        ---layoutHook              = magnifierOff $ avoidStruts (GridRatio 0.9) ||| noBorders Full,
        layoutHook              = myLayout,
        manageHook              = floatAll ["Wine"]
                                  <+> (title =? "CGoban: Main Window" --> doF sinkFocus)
                                  <+> (isFullscreen --> doFullFloat)
                                  <+> fullscreenMPlayer
                                  <+> manageDocks
                                  <+> manageSpawn,
        logHook                 = mapM_ dynamicLogWithPP $ zipWith pp hs [0..nScreens],
        startupHook             = setWMName "LG3D" -- gotta keep this until all the machines I use have the version of openjdk that respects _JAVA_AWT_WM_NONREPARENTING`
    }

keyBindings conf = let m = modMask conf in fromList $ [
  ((mod1Mask               , xK_r     ), spawnHere launcher),
  ((m .|. shiftMask        , xK_p     ), spawnHere termLauncher),
  ((mod1Mask .|. shiftMask , xK_c     ), kill),
  ((m                      , xK_q     ), restart "xmonad" True),
  ((m .|. shiftMask        , xK_q     ), io (exitWith ExitSuccess)),
  ((m                      , xK_grave ), sendMessage NextLayout),
  ((m .|. shiftMask        , xK_grave ), setLayout $ layoutHook conf),
  ((m                      , xK_o     ), sendMessage Toggle),
  ((m                      , xK_x     ), withFocused (windows . sink)),
  ((m                      , xK_j     ), windows focusUp),
  ((m .|. shiftMask        , xK_j     ), windows swapUp),
  ((m                      , xK_k     ), windows focusDown),
  ((m .|. shiftMask        , xK_k     ), windows swapDown),
  ((m                      , xK_h     ), sendMessage Shrink), -- %! Shrink the master area
  ((m                      , xK_l     ), sendMessage Expand), -- %! Expand the master area
  ((m                      , xK_a     ), windows focusMaster),
  ((m .|. shiftMask        , xK_a     ), windows swapMaster),
  ((m                      , xK_m     ), withScreen 0 view),
  ((m .|. shiftMask        , xK_m     ), withScreen 0 viewShift),
  ((m                      , xK_n     ), withScreen 1 view),
  ((m .|. shiftMask        , xK_n     ), withScreen 1 viewShift),
  ((m                      , xK_u     ), centerMouse),
  ((m .|. shiftMask        , xK_u     ), statusBarMouse)
  ] ++ [
  ((mod1Mask .|. e .|. i    , key     ), windows (onCurrentScreen f workspace))
  | (key, workspace) <- zip [xK_1..xK_9] (workspaces' conf)
  , (e, f)           <- [(0, view     ), (shiftMask, viewShift)]
  , i                <- [0, controlMask, mod1Mask, controlMask .|. mod1Mask]
  ]
    
xmobarCommand (S s) = unwords ["xmobar", "-x", show s, "~/.xmobarrc"]
trayerCommand (S s) = unwords ["trayer", "--edge", "bottom", "--align", "right", "--SetDockType", "true", "--SetPartialStrut", "true", "--expand", "true", "--width", "6", "--transparent", "true", "--alpha", "0", "--tint", "0x000000", "--height", "12", "--monitor", show s]

xmobarCommand (S s) = unwords ["xmobar", "-x", show s, "~/.xmobarrc"]
pp h s = marshallPP s defaultPP {
    ppCurrent           = color "white",
    ppVisible           = color "white",
    ppHiddenNoWindows   = color dark,
    ppUrgent            = color "red",
    ppSep               = "",
    ppOrder             = \(wss:layout:title:_) -> [ wss, " "],
    ppOutput            = hPutStrLn h
    }
    where color c = xmobarColor c ""
