# ACTIVESTATE TEAPOT-PKG BEGIN TM -*- tcl -*-
# -- Tcl Module

# @@ Meta Begin
# Package hv3 0.1
# Meta as::author      {Richard Hipp} {Dan Kennedy}
# Meta as::build::date 2013-12-16
# Meta as::origin      http://tkhtml.tcl.tk
# Meta category        HTML
# Meta description     HTML viewer megawidet (hv3 application core)
# Meta license         LGPL
# Meta platform        tcl
# Meta require         {Tcl 8.4}
# Meta require         {Tk 8.4}
# Meta require         {Tkhtml 3}
# Meta require         snit
# Meta subject         Tk HTML rendering display show
# Meta summary         HTML viewer widget
# @@ Meta End


# ACTIVESTATE TEAPOT-PKG BEGIN REQUIREMENTS

package require Tcl 8.4
package require Tk 8.4
package require Tkhtml 3
package require snit

# ACTIVESTATE TEAPOT-PKG END REQUIREMENTS

# ACTIVESTATE TEAPOT-PKG BEGIN DECLARE

package provide hv3 0.1

# ACTIVESTATE TEAPOT-PKG END DECLARE
# ACTIVESTATE TEAPOT-PKG END TM
package provide hv3 0.1
namespace eval hv3 { set {version($Id: hv3_util.tcl,v 1.9 2008/02/02 17:15:02 danielk1977 Exp $)} 1 }


namespace eval hv3 {

  proc ReturnWithArgs {retval args} {
    return $retval
  }

  proc scrollbar {args} {
    set w [eval [linsert $args 0 ::scrollbar]]
    $w configure -highlightthickness 0
    $w configure -borderwidth 1
    return $w
  }

  # scrolledwidget
  #
  #     Widget to add automatic scrollbars to a widget supporting the
  #     [xview], [yview], -xscrollcommand and -yscrollcommand interface (e.g.
  #     html, canvas or text).
  #
  namespace eval scrolledwidget {
  
    proc new {me widget args} {
      upvar #0 $me O
      set w $O(win)

      set O(-propagate) 0 
      set O(-scrollbarpolicy) auto
      set O(-takefocus) 0

      set O(myTakeControlCb) ""

      # Create the three widgets - one user widget and two scrollbars.
      set O(myWidget) [eval [linsert $widget 1 ${w}.widget]]
      set O(myVsb) [::hv3::scrollbar ${w}.vsb -orient vertical -takefocus 0] 
      set O(myHsb) [::hv3::scrollbar ${w}.hsb -orient horizontal -takefocus 0]

      set wid $O(myWidget)
      bind $w <KeyPress-Up>     [list $me scrollme $wid yview scroll -1 units]
      bind $w <KeyPress-Down>   [list $me scrollme $wid yview scroll  1 units]
      bind $w <KeyPress-Return> [list $me scrollme $wid yview scroll  1 units]
      bind $w <KeyPress-Right>  [list $me scrollme $wid xview scroll  1 units]
      bind $w <KeyPress-Left>   [list $me scrollme $wid xview scroll -1 units]
      bind $w <KeyPress-Next>   [list $me scrollme $wid yview scroll  1 pages]
      bind $w <KeyPress-space>  [list $me scrollme $wid yview scroll  1 pages]
      bind $w <KeyPress-Prior>  [list $me scrollme $wid yview scroll -1 pages]
  
      $O(myVsb) configure -cursor "top_left_arrow"
      $O(myHsb) configure -cursor "top_left_arrow"
  
      grid configure $O(myWidget) -column 0 -row 1 -sticky nsew
      grid columnconfigure $w 0 -weight 1
      grid rowconfigure    $w 1 -weight 1
      grid propagate       $w $O(-propagate)
  
      # First, set the values of -width and -height to the defaults for 
      # the scrolled widget class. Then configure this widget with the
      # arguments provided.
      $me configure -width  [$O(myWidget) cget -width] 
      $me configure -height [$O(myWidget) cget -height]
      eval $me configure $args
  
      # Wire up the scrollbars using the standard Tk idiom.
      $O(myWidget) configure -yscrollcommand [list $me scrollcallback $O(myVsb)]
      $O(myWidget) configure -xscrollcommand [list $me scrollcallback $O(myHsb)]
      $O(myVsb) configure -command [list $me scrollme $O(myWidget) yview]
      $O(myHsb) configure -command [list $me scrollme $O(myWidget) xview]
  
      # Propagate events from the scrolled widget to this one.
      bindtags $O(myWidget) [concat [bindtags $O(myWidget)] $O(win)]
    }

    proc destroy {me} {
      uplevel #0 [list unset $me]
      rename $me ""
    }
  
    proc configure-propagate {me} {
      upvar #0 $me O
      grid propagate $O(win) $O(-propagate)
    }
  
    proc take_control {me callback} {
      upvar #0 $me O
      if {$O(myTakeControlCb) ne ""} {
        uplevel #0 $O(myTakeControlCb)
      }
      set O(myTakeControlCb) $callback
    }
  
    proc scrollme {me args} {
      upvar #0 $me O
      if {$O(myTakeControlCb) ne ""} {
        uplevel #0 $O(myTakeControlCb)
        set O(myTakeControlCb) ""
      }
      eval $args
    }
  
    proc scrollcallback {me scrollbar first last} {
      upvar #0 $me O

      $scrollbar set $first $last
      set ismapped   [expr [winfo ismapped $scrollbar] ? 1 : 0]
  
      if {$O(-scrollbarpolicy) eq "auto"} {
        set isrequired [expr ($first == 0.0 && $last == 1.0) ? 0 : 1]
      } else {
        set isrequired $O(-scrollbarpolicy)
      }
  
      if {$isrequired && !$ismapped} {
        switch [$scrollbar cget -orient] {
          vertical   {grid configure $scrollbar  -column 1 -row 1 -sticky ns}
          horizontal {grid configure $scrollbar  -column 0 -row 2 -sticky ew}
        }
      } elseif {$ismapped && !$isrequired} {
        grid forget $scrollbar
      }
    }

    proc configure-scrollbarpolicy {me} {
      upvar #0 $me O
      eval $me scrollcallback $O(myHsb) [$O(myWidget) xview]
      eval $me scrollcallback $O(myVsb) [$O(myWidget) yview]
    }
  
    proc widget {me} {
      upvar #0 $me O
      return $O(myWidget)
    }

    proc unknown {method me args} {
      # puts "UNKNOWN: $me $method $args"
      upvar #0 $me O
      uplevel 3 [list eval $O(myWidget) $method $args]
    }
    namespace unknown unknown

    set DelegateOption(-width) hull
    set DelegateOption(-height) hull
    set DelegateOption(-cursor) hull
    set DelegateOption(*) myWidget
  }

  # Wrapper around the ::hv3::scrolledwidget constructor. 
  #
  # Example usage to create a 400x400 canvas widget named ".c" with 
  # automatic scrollbars:
  #
  #     ::hv3::scrolled canvas .c -width 400 -height 400
  #
  proc scrolled {widget name args} {
    return [eval [concat ::hv3::scrolledwidget $name $widget $args]]
  }

  proc Expand {template args} {
    return [string map $args $template]
  }
}

namespace eval ::hv3::string {

  # A generic tokeniser procedure for strings. This proc splits the
  # input string $input into a list of tokens, where each token is either:
  #
  #     * A continuous set of alpha-numeric characters, or
  #     * A quoted string (quoted by " or '), or
  #     * Any single character.
  #
  # White-space characters are not returned in the list of tokens.
  #
  proc tokenise {input} {
    set tokens [list]
    set zIn [string trim $input]
  
    while {[string length $zIn] > 0} {
  
      if {[ regexp {^([[:alnum:]_.-]+)(.*)$} $zIn -> zToken zIn ]} {
        # Contiguous alpha-numeric characters
        lappend tokens $zToken
  
      } elseif {[ regexp {^(["'])} $zIn -> zQuote]} {      #;'"
        # Quoted string
  
        set nEsc 0
        for {set nToken 1} {$nToken < [string length $zIn]} {incr nToken} {
          set c [string range $zIn $nToken $nToken]
          if {$c eq $zQuote && 0 == ($nEsc%2)} break
          set nEsc [expr {($c eq "\\") ? $nEsc+1 : 0}]
        }
        set zToken [string range $zIn 0 $nToken]
        set zIn [string range $zIn [expr {$nToken+1}] end]
  
        lappend tokens $zToken
  
      } else {
        lappend tokens [string range $zIn 0 0]
        set zIn [string range $zIn 1 end]
      }
  
      set zIn [string trimleft $zIn]
    }
  
    return $tokens
  }

  # Dequote $input, if it appears to be a quoted string (starts with 
  # a single or double quote character).
  #
  proc dequote {input} {
    set zIn $input
    set zQuote [string range $zIn 0 0]
    if {$zQuote eq "\"" || $zQuote eq "\'"} {
      set zIn [string range $zIn 1 end]
      if {[string range $zIn end end] eq $zQuote} {
        set zIn [string range $zIn 0 end-1]
      }
      set zIn [regsub {\\(.)} $zIn {\1}]
    }
    return $zIn
  }


  # A procedure to parse an HTTP content-type (media type). See section
  # 3.7 of the http 1.1 specification.
  #
  # A list of exactly three elements is returned. These are the type,
  # subtype and charset as specified in the parsed content-type. Any or
  # all of the fields may be empty strings, if they are not present in
  # the input or a parse error occurs.
  #
  proc parseContentType {contenttype} {
    set tokens [::hv3::string::tokenise $contenttype]

    set type [lindex $tokens 0]
    set subtype [lindex $tokens 2]

    set enc ""
    foreach idx [lsearch -regexp -all $tokens (?i)charset] {
      if {[lindex $tokens [expr {$idx+1}]] eq "="} {
        set enc [::hv3::string::dequote [lindex $tokens [expr {$idx+2}]]]
        break
      }
    }

    return [list $type $subtype $enc]
  }

  proc htmlize {zIn} {
    string map [list "<" "&lt;" ">" "&gt;" "&" "&amp;" "\"" "&quote;"] $zIn
  }

}


proc ::hv3::char {text idx} {
  return [string range $text $idx $idx]
}

proc ::hv3::next_word {text idx idx_out} {

  while {[char $text $idx] eq " "} { incr idx }

  set idx2 $idx
  set c [char $text $idx2] 

  if {$c eq "\""} {
    # Quoted identifier
    incr idx2
    set c [char $text $idx2] 
    while {$c ne "\"" && $c ne ""} {
      incr idx2
      set c [char $text $idx2] 
    }
    incr idx2
    set word [string range $text [expr $idx+1] [expr $idx2 - 2]]
  } else {
    # Unquoted identifier
    while {$c ne ">" && $c ne " " && $c ne ""} {
      incr idx2
      set c [char $text $idx2] 
    }
    set word [string range $text $idx [expr $idx2 - 1]]
  }

  uplevel [list set $idx_out $idx2]
  return $word
}

proc ::hv3::sniff_doctype {text pIsXhtml} {
  upvar $pIsXhtml isXHTML
  # <!DOCTYPE TopElement Availability "IDENTIFIER" "URL">

  set QuirksmodeIdentifiers [list \
    "-//w3c//dtd html 4.01 transitional//en" \
    "-//w3c//dtd html 4.01 frameset//en"     \
    "-//w3c//dtd html 4.0 transitional//en" \
    "-//w3c//dtd html 4.0 frameset//en" \
    "-//softquad software//dtd hotmetal pro 6.0::19990601::extensions to html 4.0//en" \
    "-//softquad//dtd hotmetal pro 4.0::19971010::extensions to html 4.0//en" \
    "-//ietf//dtd html//en//3.0" \
    "-//w3o//dtd w3 html 3.0//en//" \
    "-//w3o//dtd w3 html 3.0//en" \
    "-//w3c//dtd html 3 1995-03-24//en" \
    "-//ietf//dtd html 3.0//en" \
    "-//ietf//dtd html 3.0//en//" \
    "-//ietf//dtd html 3//en" \
    "-//ietf//dtd html level 3//en" \
    "-//ietf//dtd html level 3//en//3.0" \
    "-//ietf//dtd html 3.2//en" \
    "-//as//dtd html 3.0 aswedit + extensions//en" \
    "-//advasoft ltd//dtd html 3.0 aswedit + extensions//en" \
    "-//ietf//dtd html strict//en//3.0" \
    "-//w3o//dtd w3 html strict 3.0//en//" \
    "-//ietf//dtd html strict level 3//en" \
    "-//ietf//dtd html strict level 3//en//3.0" \
    "html" \
    "-//ietf//dtd html//en" \
    "-//ietf//dtd html//en//2.0" \
    "-//ietf//dtd html 2.0//en" \
    "-//ietf//dtd html level 2//en" \
    "-//ietf//dtd html level 2//en//2.0" \
    "-//ietf//dtd html 2.0 level 2//en" \
    "-//ietf//dtd html level 1//en" \
    "-//ietf//dtd html level 1//en//2.0" \
    "-//ietf//dtd html 2.0 level 1//en" \
    "-//ietf//dtd html level 0//en" \
    "-//ietf//dtd html level 0//en//2.0" \
    "-//ietf//dtd html strict//en" \
    "-//ietf//dtd html strict//en//2.0" \
    "-//ietf//dtd html strict level 2//en" \
    "-//ietf//dtd html strict level 2//en//2.0" \
    "-//ietf//dtd html 2.0 strict//en" \
    "-//ietf//dtd html 2.0 strict level 2//en" \
    "-//ietf//dtd html strict level 1//en" \
    "-//ietf//dtd html strict level 1//en//2.0" \
    "-//ietf//dtd html 2.0 strict level 1//en" \
    "-//ietf//dtd html strict level 0//en" \
    "-//ietf//dtd html strict level 0//en//2.0" \
    "-//webtechs//dtd mozilla html//en" \
    "-//webtechs//dtd mozilla html 2.0//en" \
    "-//netscape comm. corp.//dtd html//en" \
    "-//netscape comm. corp.//dtd html//en" \
    "-//netscape comm. corp.//dtd strict html//en" \
    "-//microsoft//dtd internet explorer 2.0 html//en" \
    "-//microsoft//dtd internet explorer 2.0 html strict//en" \
    "-//microsoft//dtd internet explorer 2.0 tables//en" \
    "-//microsoft//dtd internet explorer 3.0 html//en" \
    "-//microsoft//dtd internet explorer 3.0 html strict//en" \
    "-//microsoft//dtd internet explorer 3.0 tables//en" \
    "-//sun microsystems corp.//dtd hotjava html//en" \
    "-//sun microsystems corp.//dtd hotjava strict html//en" \
    "-//ietf//dtd html 2.1e//en" \
    "-//o'reilly and associates//dtd html extended 1.0//en" \
    "-//o'reilly and associates//dtd html extended relaxed 1.0//en" \
    "-//o'reilly and associates//dtd html 2.0//en" \
    "-//sq//dtd html 2.0 hotmetal + extensions//en" \
    "-//spyglass//dtd html 2.0 extended//en" \
    "+//silmaril//dtd html pro v0r11 19970101//en" \
    "-//w3c//dtd html experimental 19960712//en" \
    "-//w3c//dtd html 3.2//en" \
    "-//w3c//dtd html 3.2 final//en" \
    "-//w3c//dtd html 3.2 draft//en" \
    "-//w3c//dtd html experimental 970421//en" \
    "-//w3c//dtd html 3.2s draft//en" \
    "-//w3c//dtd w3 html//en" \
    "-//metrius//dtd metrius presentational//en" \
  ]

  set isXHTML 0
  set idx [string first <!DOCTYPE $text]
  if {$idx < 0} { return "quirks" }

  # Try to parse the TopElement bit. No quotes allowed.
  incr idx [string length "<!DOCTYPE "]
  while {[string range $text $idx $idx] eq " "} { incr idx }

  set TopElement   [string tolower [next_word $text $idx idx]]
  set Availability [string tolower [next_word $text $idx idx]]
  set Identifier   [string tolower [next_word $text $idx idx]]
  set Url          [next_word $text $idx idx]

#  foreach ii [list TopElement Availability Identifier Url] {
#    puts "$ii -> [set $ii]"
#  }

  # Figure out if this should be handled as XHTML
  #
  if {[string first xhtml $Identifier] >= 0} {
    set isXHTML 1
  }
  if {$Availability eq "public"} {
    set s [expr [string length $Url] > 0]
    if {
         $Identifier eq "-//w3c//dtd xhtml 1.0 transitional//en" ||
         $Identifier eq "-//w3c//dtd xhtml 1.0 frameset//en" ||
         ($s && $Identifier eq "-//w3c//dtd html 4.01 transitional//en") ||
         ($s && $Identifier eq "-//w3c//dtd html 4.01 frameset//en")
    } {
      return "almost standards"
    }
    if {[lsearch $QuirksmodeIdentifiers $Identifier] >= 0} {
      return "quirks"
    }
  }

  return "standards"
}


proc ::hv3::configure_doctype_mode {html text pIsXhtml} {
  upvar $pIsXhtml isXHTML
  set mode [sniff_doctype $text isXHTML]

  switch -- $mode {
    "quirks"           { set defstyle [::tkhtml::htmlstyle -quirks] }
    "almost standards" { set defstyle [::tkhtml::htmlstyle] }
    "standards"        { set defstyle [::tkhtml::htmlstyle]
    }
  }

  $html configure -defaultstyle $defstyle -mode $mode

  return $mode
}

namespace eval ::hv3 {

  variable Counter 1

  proc handle_destroy {me obj win} {
    if {$obj eq $win} {
      upvar #0 $me O
      set cmd $O(cmd)
      $me destroy
      rename $cmd ""
    }
  }
  proc handle_rename {me oldname newname op} {
    upvar #0 $me O
    set O(cmd) $newname
  }

  proc construct_object {ns obj arglist} {

    set PROC proc
    if {[info commands real_proc] ne ""} {
      set PROC real_proc
    } 

    set isWidget [expr {[string range $obj 0 0] eq "."}]

    # The name of the array to use for this object.
    set arrayname $obj
    if {$arrayname eq "%AUTO%" || $isWidget} {
      set arrayname ${ns}::inst[incr ${ns}::_OBJ_COUNTER]
    }

    # Create the object command.
    set body "namespace eval $ns \$m $arrayname \$args"
    namespace eval :: [list $PROC $arrayname {m args} $body]

    # If the first character of the new command name is ".", then
    # this is a new widget. Populate the state array with the following
    # special variables:
    #
    #   O(win)        Window path.
    #   O(hull)       Window command.
    #
    if {[string range $obj 0 0] eq "."} {
      variable HullType
      variable Counter
      upvar #0 $arrayname O

      set O(hull) ${obj}_win[incr Counter]
      set O(win) $obj
      eval $HullType($ns) $O(win)
      namespace eval :: rename $O(win) $O(hull)

      bind $obj <Destroy> +[list ::hv3::handle_destroy $arrayname $obj %W]

      namespace eval :: [list $PROC $O(win) {m args} $body]
      set O(cmd) $O(win)
      trace add command $O(win) rename [list ::hv3::handle_rename $arrayname]
    }

    # Call the object constructor.
    namespace eval $ns new $arrayname $arglist
    return [expr {$isWidget ? $obj : $arrayname}]
  }

  proc make_constructor {ns {hulltype frame}} {
    variable HullType

    if {[info commands ${ns}::destroy] eq ""} {
      error "Object class has no destructor: $ns"
    }
    set HullType($ns) $hulltype

    # Create the constructor
    #
    proc $ns {obj args} "::hv3::construct_object $ns \$obj \$args"

    # Create the [cget] method.
    #
    namespace eval $ns "
      proc cget {me option} {
        upvar \$me O
        if {!\[info exists O(\$option)\]} {
          variable DelegateOption
          if {\[info exists DelegateOption(\$option)\]} {
            return \[
              eval \$O(\$DelegateOption(\$option)) [list cget \$option]
            \]
            return
          } elseif {\[info exists DelegateOption(*)\]} {
            return \[eval \$O(\$DelegateOption(*)) [list cget \$option ]\]
          }
          error \"unknown option: \$option\"
        }
        return \$O(\$option)
      }
    "
    # Create the [configure] method.
    #
    set cc ""
    foreach cmd [info commands ${ns}::configure*] {
      set key [string range $cmd [string length ${ns}::configure] end]
      append cc "if {\$option eq {$key}} {configure$key \$me}\n"
    }
    namespace eval $ns "
      proc configure {me args} {
        upvar \$me O
        foreach {option value} \$args {
          if {!\[info exists O(\$option)\]} {
            variable DelegateOption
            if {\[info exists DelegateOption(\$option)\]} {
              eval \$O(\$DelegateOption(\$option)) [list configure \$option \$value]
            } elseif {\[info exists DelegateOption(*)\]} {
              eval \$O(\$DelegateOption(*)) [list configure \$option \$value]
            } else {
              error \"unknown option: \$option\"
            }
          } elseif {\$O(\$option) != \$value} {
            set O(\$option) \$value
            $cc
          }
        }
      }
    "
  }
}

::hv3::make_constructor ::hv3::scrolledwidget


namespace eval hv3 { set {version($Id: hv3.tcl,v 1.248 2008/03/02 15:00:13 danielk1977 Exp $)} 1 }

# This file contains the mega-widget hv3::hv3 that is at the core
# of the Hv3 web browser implementation. An instance of this widget 
# displays a single HTML frame. Documentation for the published
# interface to this widget is found at:
#
#   http://tkhtml.tcl.tk/hv3_widget.html
#
# Other parts of the interface, used internally and by the Hv3
# web-browser, are documented in comments in this file. Eventually,
# the Hv3 web-browser will use the published interface only. But
# that is not the case yet.
#
#-------------------------------------------------------------------
#
# 
#
# Standard Functionality:
#
#     xview
#     yview
#     -xscrollcommand
#     -yscrollcommand
#     -width
#     -height
# 
# Widget Specific Options:
#
#     -requestcmd
#         If not an empty string, this option specifies a script to be
#         invoked for a GET or POST request. The script is invoked with a
#         download handle appended to it. See the description of class
#         ::hv3::request for a description.
#
#     -targetcmd
#         If not an empty string, this option specifies a script for
#         the widget to invoke when a hyperlink is clicked on or a form
#         submitted. The script is invoked with the node handle of the 
#         clicked hyper-link element appended. The script must return
#         the name of an hv3 widget to load the new document into. This
#         is intended to be used to implement frameset handling.
#
#     -isvisitedcmd
#         If not an empty string, this option specifies a script for
#         the widget to invoke to determine if a hyperlink node should
#         be styled with the :link or :visited pseudo-class. The
#         script is invoked with the node handle appended to it. If
#         true is returned, :visited is used, otherwise :link.
#
#     -fonttable
#         Delegated through to the html widget.
#
#     -locationvar
#         Set to the URI of the currently displayed document.
#
#     -scrollbarpolicy
#         This option may be set to either a boolean value or "auto". It
#         determines the visibility of the widget scrollbars. TODO: This
#         is now set internally by the value of the "overflow" property
#         on the root element. Maybe the option should be removed?
#
#
# Widget Sub-commands:
#
#     goto URI ?OPTIONS?
#         Load the content at the specified URI into the widget. 
#
#     stop
#         Cancel all pending downloads.
#
#     node        
#         Caching wrapper around html widget [node] command.
#
#     reset        
#         Wrapper around the html widget command of the same name. Also
#         resets all document related state stored by the mega-widget.
#
#     html        
#         Return the path of the underlying html widget. This should only
#         be used to determine paths for child widgets. Bypassing hv3 and
#         accessing the html widget interface directly may confuse hv3.
#
#     title        
#         Return the "title" of the currently loaded document.
#
#     location        
#         Return the location URI of the widget.
#
#     selected        
#         Return the currently selected text, or an empty string if no
#         text is currently selected.
#
#
# Widget Custom Events:
#
#     <<Goto>>
#         This event is generated whenever the goto method is called.
#
#     <<Complete>>
#         This event is generated once all of the resources required
#         to display a document have been loaded. This is analogous
#         to the Html "onload" event.
#
#     <<Location>>
#         This event is generated whenever the "location" is set.
#
#     <<SaveState>>
#         Generated whenever the widget state should be saved.

#
# The code in this file is partitioned into the following classes:
#
#     ::hv3::hv3
#     ::hv3::selectionmanager
#     ::hv3::dynamicmanager
#     ::hv3::hyperlinkmanager
#     ::hv3::mousemanager
#
# ::hv3::hv3 is, of course, the main mega-widget class. Class
# ::hv3::request is part of the public interface to ::hv3::hv3. A
# single instance of ::hv3::request represents a resource request made
# by the mega-widget package - for document, stylesheet, image or 
# object data.
#
# The three "manager" classes all implement the following interface. Each
# ::hv3::hv3 widget has exactly one of each manager class as a component.
# Further manager objects may be added in the future. Interface:
#
#     set manager [::hv3::XXXmanager $hv3]
#
#     $manager motion  X Y
#     $manager release X Y
#     $manager press   X Y
#
# The -targetcmd option of ::hv3::hv3 is delegated to the
# ::hv3::hyperlinkmanager component.
#
package require Tkhtml 3.0
package require snit

package provide hv3 0.1

if {[info commands ::hv3::make_constructor] eq ""} {
  source [file join [file dirname [info script]] hv3_encodings.tcl]
  source [file join [file dirname [info script]] hv3_util.tcl]
  source [file join [file dirname [info script]] hv3_form.tcl]
  source [file join [file dirname [info script]] hv3_request.tcl]
}
#source [file join [file dirname [info script]] hv3_request.tcl.bak]

#--------------------------------------------------------------------------
# Class ::hv3::hv3::mousemanager
#
#     This type contains code for the ::hv3::hv3 widget to manage 
#     dispatching mouse events that occur in the HTML widget to the 
#     rest of the application. The following HTML4 events are handled:
#
#     Pointer movement:
#         onmouseover
#         onmouseout
#         motion
#
#     Click-related events:
#         onmousedown
#         onmouseup
#         onclick
#
#     Currently, the following hv3 subsystems subscribe to one or more of
#     these events:
#
#         ::hv3::hyperlinkmanager
#             Click events, mouseover and mouseout on all nodes.
#
#         ::hv3::dynamicmanager
#             Events mouseover, mouseout, mousedown mouseup on all nodes.
#
#         ::hv3::formmanager
#             Click events (for clickable controls) on all nodes.
#
#         ::hv3::selectionmanager
#             motion
#
namespace eval ::hv3::hv3::mousemanager {

  proc new {me hv3} {
    upvar $me O

    set O(myHv3) $hv3
    set O(myHtml) [$hv3 html]

    # In browsers with no DOM support, the following option is set to
    # an empty string.
    #
    # If not set to an empty string, this option is set to the name
    # of the ::hv3::dom object to dispatch events too. The DOM 
    # is a special client because it may cancel the "default action"
    # of mouse-clicks (it may also cancel other events, but they are
    # dispatched by other sub-systems).
    #
    # Each time an event occurs, the following script is executed:
    #
    #     $O(-dom) mouseevent EVENT-TYPE NODE X Y ?OPTIONS?
    #
    # where OPTIONS are:
    #
    #     -button          INTEGER        (default 0)
    #     -detail          INTEGER        (default 0)
    #     -relatedtarget   NODE-HANDLE    (default "")
    #
    # the EVENT-TYPE parameter is one of:
    #
    #     "click", "mouseup", "mousedown", "mouseover" or "mouseout".
    #
    # NODE is the target leaf node and X and Y are the pointer coordinates
    # relative to the top-left of the html widget window.
    #
    # For "click" events, if the $O(-dom) script returns false, then
    # the "click" event is not dispatched to any subscribers (this happens
    # when some javascript calls the Event.preventDefault() method). If it
    # returns true, proceed as normal. Other event types ignore the return 
    # value of the $O(-dom) script.
    #
    set O(-dom) ""
  
    # This variable is set to the node-handle that the pointer is currently
    # hovered over. Used by code that dispatches the "mouseout", "mouseover"
    # and "mousemove" to the DOM.
    #
    set O(myCurrentDomNode) ""
  
    # The "top" node from the ${me}.hovernodes array. This is the node
    # that determines the pointer to display (via the CSS2 'cursor' 
    # property).
    #
    set O(myTopHoverNode) ""
  
    set O(myCursor) ""
    set O(myCursorWin) [$hv3 hull]

    # Database of callback scripts for each event type.
    #
    set O(scripts.onmouseover) ""
    set O(scripts.onmouseout) ""
    set O(scripts.onclick) ""
    set O(scripts.onmousedown) ""
    set O(scripts.onmouseup) ""
    set O(scripts.motion) ""

    # There are also two arrays that store lists of nodes currently "hovered"
    # over and "active". An entry in the correspondoing array indicates the
    # condition is true. The arrays are named:
    #
    #   ${me}.hovernodes
    #   ${me}.activenodes
    #
  
    set w [$hv3 win]
    bind $w <Motion>          "+[list $me Motion  %W %x %y]"
    bind $w <ButtonPress-1>   "+[list $me Press   %W %x %y]"
    bind $w <ButtonRelease-1> "+[list $me Release %W %x %y]"
  }


  proc subscribe {me event script} {
    upvar $me O

    # Check that the $event argument is Ok:
    if {![info exists O(scripts.$event)]} {
      error "No such mouse-event: $event"
    }

    # Append the script to the callback list.
    lappend O(scripts.$event) $script
  }

  proc reset {me} {
    upvar $me O
    array unset ${me}.activenodes
    array unset ${me}.hovernodes
    set O(myCurrentDomNode) ""
  }

  proc GenerateEvents {me eventlist} {
    upvar $me O
    foreach {event node} $eventlist {
      if {[info commands $node] ne ""} {
        foreach script $O(scripts.$event) {
          eval $script $node
        }
      }
    }
  }

  proc AdjustCoords {to W xvar yvar} {
    upvar $xvar x
    upvar $yvar y
    while {$W ne "" && $W ne $to} {
      incr x [winfo x $W]
      incr y [winfo y $W]
      set W [winfo parent $W]
    }
  }

  # Mapping from CSS2 cursor type to Tk cursor type.
  #
  variable CURSORS
  array set CURSORS [list      \
      crosshair crosshair      \
      default   ""             \
      pointer   hand2          \
      move      fleur          \
      text      xterm          \
      wait      watch          \
      progress  box_spiral     \
      help      question_arrow \
  ]

  proc Motion {me W x y} {
    upvar $me O
    variable CURSORS

    if {$W eq ""} return
    AdjustCoords [$O(myHv3) html] $W x y

    # Figure out the node the cursor is currently hovering over. Todo:
    # When the cursor is over multiple nodes (because overlapping content
    # has been generated), maybe this should consider all overlapping nodes
    # as "hovered".
    set nodelist [lindex [$O(myHtml) node $x $y] end]
    
    # Handle the 'cursor' property.
    #
    set topnode [lindex $nodelist end]
    if {$topnode ne "" && $topnode ne $O(myTopHoverNode)} {

      set Cursor ""
      if {[$topnode tag] eq ""} {
        set Cursor xterm
        set topnode [$topnode parent]
      }
      set css2_cursor [$topnode property cursor]
      catch { set Cursor $CURSORS($css2_cursor) }

      if {$Cursor ne $O(myCursor)} {
        $O(myCursorWin) configure -cursor $Cursor
        set O(myCursor) $Cursor
      }
      set O(myTopHoverNode) $topnode
    }

    # Dispatch any DOM events in this order:
    #
    #     mouseout
    #     mouseover
    #     mousemotion
    #
    set N [lindex $nodelist end]
    if {$N eq ""} {set N [$O(myHv3) node]}

    if {$O(-dom) ne ""} {
      if {$N ne $O(myCurrentDomNode)} {
        $O(-dom) mouseevent mouseout $O(myCurrentDomNode) $x $y
        $O(-dom) mouseevent mouseover $N $x $y
        set O(myCurrentDomNode) $N
      }
      $O(-dom) mouseevent mousemove $N $x $y
    }

    foreach script $O(scripts.motion) {
      eval $script $N $x $y
    }

    # After the loop runs, hovernodes will contain the list of 
    # currently hovered nodes.
    array set hovernodes [list]

    # Events to generate:
    set events(onmouseout)  [list]
    set events(onmouseover) [list]

    foreach node $nodelist {
      if {[$node tag] eq ""} {set node [$node parent]}

      for {set n $node} {$n ne ""} {set n [$n parent]} {
        if {[info exists hovernodes($n)]} {
          break
        } else {
          if {[info exists ${me}.hovernodes($n)]} {
            unset ${me}.hovernodes($n)
          } else {
            lappend events(onmouseover) $n
          }
          set hovernodes($n) ""
        }
      }
    }
    set events(onmouseout)  [array names ${me}.hovernodes]

    array unset ${me}.hovernodes
    array set ${me}.hovernodes [array get hovernodes]

    set eventlist [list]
    foreach key [list onmouseover onmouseout] {
      foreach node $events($key) {
        lappend eventlist $key $node
      }
    }
    $me GenerateEvents $eventlist
  }

  proc Press {me W x y} {
    upvar $me O
    if {$W eq ""} return
    AdjustCoords [$O(myHv3) html] $W x y
    set N [lindex [$O(myHtml) node $x $y] end]
    if {$N ne ""} {
      if {[$N tag] eq ""} {set N [$N parent]}
    }
    if {$N eq ""} {set N [$O(myHv3) node]}

    # Dispatch the "mousedown" event to the DOM, if any.
    #
    set rc ""
    if {$O(-dom) ne ""} {
      set rc [$O(-dom) mouseevent mousedown $N $x $y]
    }

    # If the DOM implementation called preventDefault(), do 
    # not start selecting text. But every mouseclick should clear
    # the current selection, otherwise the browser window can get
    # into an annoying state.
    #
    if {$rc eq "prevent"} {
      $O(myHv3) theselectionmanager clear
    } else {
      $O(myHv3) theselectionmanager press $N $x $y
    }

    for {set n $N} {$n ne ""} {set n [$n parent]} {
      set ${me}.activenodes($n) 1
    }

    set eventlist [list]
    foreach node [array names ${me}.activenodes] {
      lappend eventlist onmousedown $node
    }
    $me GenerateEvents $eventlist
  }

  proc Release {me W x y} {
    upvar $me O
    if {$W eq ""} return
    AdjustCoords [$O(myHv3) html] $W x y
    set N [lindex [$O(myHtml) node $x $y] end]
    if {$N ne ""} {
      if {[$N tag] eq ""} {set N [$N parent]}
    }
    if {$N eq ""} {set N [$O(myHv3) node]}

    # Dispatch the "mouseup" event to the DOM, if any.
    #
    # In Tk, the equivalent of the "mouseup" (<ButtonRelease>) is always
    # dispatched to the same widget as the "mousedown" (<ButtonPress>). 
    # But in the DOM things are different - the event target for "mouseup"
    # depends on the current cursor location only.
    #
    if {$O(-dom) ne ""} {
      $O(-dom) mouseevent mouseup $N $x $y
    }

    # Check if the is a "click" event to dispatch to the DOM. If the
    # ::hv3::dom [mouseevent] method returns 0, then the click is
    # not sent to the other hv3 sub-systems (default action is cancelled).
    #
    set domrc ""
    if {$O(-dom) ne ""} {
      for {set n $N} {$n ne ""} {set n [$n parent]} {
        if {[info exists ${me}.activenodes($N)]} {
          set domrc [$O(-dom) mouseevent click $n $x $y]
          break
        }
      }
    }

    set eventlist [list]
    foreach node [array names ${me}.activenodes] {
      lappend eventlist onmouseup $node
    }
    
    if {$domrc ne "prevent"} {
      set onclick_nodes [list]
      for {set n $N} {$n ne ""} {set n [$n parent]} {
        if {[info exists ${me}.activenodes($n)]} {
          lappend onclick_nodes $n
        }
      }
      foreach node $onclick_nodes {
        lappend eventlist onclick $node
      }
    }

    $me GenerateEvents $eventlist

    array unset ${me}.activenodes
  }

  proc destroy me {
    array unset $me
    array unset ${me}.hovernodes
    array unset ${me}.activenodes
    rename $me {}
  }
}
::hv3::make_constructor ::hv3::hv3::mousemanager

#--------------------------------------------------------------------------
# ::hv3::hv3::selectionmanager
#
#     This type encapsulates the code that manages selecting text
#     in the html widget with the mouse.
#
namespace eval ::hv3::hv3::selectionmanager {

  proc new {me hv3} {
    upvar $me O

    # Variable myMode may take one of the following values:
    #
    #     "char"           -> Currently text selecting by character.
    #     "word"           -> Currently text selecting by word.
    #     "block"          -> Currently text selecting by block.
    #
    set O(myState) false             ;# True when left-button is held down
    set O(myMode) char
  
    # The ::hv3::hv3 widget.
    #
    set O(myHv3) $hv3
    set O(myHtml) [$hv3 html]
  
    set O(myFromNode) ""
    set O(myFromIdx) ""
  
    set O(myToNode) ""
    set O(myToIdx) ""
  
    set O(myIgnoreMotion) 0

    set w [$hv3 win]
    selection handle $w [list ::hv3::bg [list $me get_selection]]

    # bind $myHv3 <Motion>               "+[list $self motion %x %y]"
    # bind $myHv3 <ButtonPress-1>        "+[list $self press %x %y]"
    bind $w <Double-ButtonPress-1> "+[list $me doublepress %x %y]"
    bind $w <Triple-ButtonPress-1> "+[list $me triplepress %x %y]"
    bind $w <ButtonRelease-1>      "+[list $me release %x %y]"
  }

  # Clear the selection.
  #
  proc clear {me} {
    upvar $me O
    $O(myHtml) tag delete selection
    $O(myHtml) tag configure selection -foreground white -background darkgrey
    set O(myFromNode) ""
    set O(myToNode) ""
  }

  proc press {me N x y} {
    upvar $me O

    # Single click -> Select by character.
    clear $me
    set O(myState) true
    set O(myMode) char
    motion $me $N $x $y
  }

  # Given a node-handle/index pair identifying a character in the 
  # current document, return the index values for the start and end
  # of the word containing the character.
  #
  proc ToWord {node idx} {
    set t [$node text]
    set cidx [::tkhtml::charoffset $t $idx]
    set cidx1 [string wordstart $t $cidx]
    set cidx2 [string wordend $t $cidx]
    set idx1 [::tkhtml::byteoffset $t $cidx1]
    set idx2 [::tkhtml::byteoffset $t $cidx2]
    return [list $idx1 $idx2]
  }

  # Add the widget tag "selection" to the word containing the character
  # identified by the supplied node-handle/index pair.
  #
  proc TagWord {me node idx} {
    upvar $me O
    foreach {i1 i2} [ToWord $node $idx] {}
    $O(myHtml) tag add selection $node $i1 $node $i2
  }

  # Remove the widget tag "selection" to the word containing the character
  # identified by the supplied node-handle/index pair.
  #
  proc UntagWord {me node idx} {
    upvar $me O
    foreach {i1 i2} [ToWord $node $idx] {}
    $O(myHtml) tag remove selection $node $i1 $node $i2
  }

  proc ToBlock {me node idx} {
    upvar $me O
    set t [$O(myHtml) text text]
    set offset [$O(myHtml) text offset $node $idx]

    set start [string last "\n" $t $offset]
    if {$start < 0} {set start 0}
    set end   [string first "\n" $t $offset]
    if {$end < 0} {set end [string length $t]}

    set start_idx [$O(myHtml) text index $start]
    set end_idx   [$O(myHtml) text index $end]

    return [concat $start_idx $end_idx]
  }

  proc TagBlock {me node idx} {
    upvar $me O
    foreach {n1 i1 n2 i2} [ToBlock $me $node $idx] {}
    $O(myHtml) tag add selection $n1 $i1 $n2 $i2
  }
  proc UntagBlock {me node idx} {
    upvar $me O
    foreach {n1 i1 n2 i2} [ToBlock $me $node $idx] {}
    catch {$O(myHtml) tag remove selection $n1 $i1 $n2 $i2}
  }

  proc doublepress {me x y} {
    upvar $me O

    # Double click -> Select by word.
    clear $me
    set O(myMode) word
    set O(myState) true
    motion $me "" $x $y
  }

  proc triplepress {me x y} {
    upvar $me O

    # Triple click -> Select by block.
    clear $me
    set O(myMode) block
    set O(myState) true
    motion $me "" $x $y
  }

  proc release {me x y} {
    upvar $me O
    set O(myState) false
  }

  proc reset {me} {
    upvar $me O

    set O(myState) false

    # Unset the myFromNode variable, since the node handle it (may) refer 
    # to is now invalid. If this is not done, a future call to the [selected]
    # method of this object will cause an error by trying to use the
    # (now invalid) node-handle value in $myFromNode.
    set O(myFromNode) ""
    set O(myToNode) ""
  }

  proc motion {me N x y} {
    upvar $me O
    if {!$O(myState) || $O(myIgnoreMotion)} return

    set to [$O(myHtml) node -index $x $y]
    foreach {toNode toIdx} $to {}

    # $N containst the node-handle for the node that the cursor is
    # currently hovering over (according to the mousemanager component).
    # If $N is in a different stacking-context to the closest text, 
    # do not update the highlighted region in this event.
    #
    if {$N ne "" && [info exists toNode]} {
      if {[$N stacking] ne [$toNode stacking]} {
        set to ""
      }
    }

    if {[llength $to] > 0} {
  
      if {$O(myFromNode) eq ""} {
        set O(myFromNode) $toNode
        set O(myFromIdx) $toIdx
      }
  
      # This block is where the "selection" tag is added to the HTML 
      # widget (so that the selected text is highlighted). If some
      # javascript has been messing with the tree, then either or
      # both of $myFromNode and $myToNode may be orphaned or deleted.
      # If so, catch the exception and clear the selection.
      #
      set rc [catch {
        if {$O(myToNode) ne $toNode || $toIdx != $O(myToIdx)} {
          switch -- $O(myMode) {
            char {
              if {$O(myToNode) ne ""} {
                $O(myHtml) tag remove selection $O(myToNode) $O(myToIdx) $toNode $toIdx
              }
              $O(myHtml) tag add selection $O(myFromNode) $O(myFromIdx) $toNode $toIdx
              if {$O(myFromNode) ne $toNode || $O(myFromIdx) != $toIdx} {
                selection own [$O(myHv3) win]
              }
            }
    
            word {
              if {$O(myToNode) ne ""} {
                $O(myHtml) tag remove selection $O(myToNode) $O(myToIdx) $toNode $toIdx
                $me UntagWord $O(myToNode) $O(myToIdx)
              }
    
              $O(myHtml) tag add selection $O(myFromNode) $O(myFromIdx) $toNode $toIdx
              $me TagWord $toNode $toIdx
              $me TagWord $O(myFromNode) $O(myFromIdx)
              selection own [$O(myHv3) win]
            }
    
            block {
              set to_block2  [$me ToBlock $toNode $toIdx]
              set from_block [$me ToBlock $O(myFromNode) $O(myFromIdx)]
    
              if {$O(myToNode) ne ""} {
                set to_block [$me ToBlock $O(myToNode) $O(myToIdx)]
                $O(myHtml) tag remove selection $O(myToNode) $O(myToIdx) $toNode $toIdx
                eval $O(myHtml) tag remove selection $to_block
              }
    
              $O(myHtml) tag add selection $O(myFromNode) $O(myFromIdx) $toNode $toIdx
              eval $O(myHtml) tag add selection $to_block2
              eval $O(myHtml) tag add selection $from_block
              selection own [$O(myHv3) win]
            }
          }
    
          set O(myToNode) $toNode
          set O(myToIdx) $toIdx
        }
      } msg]

      if {$rc && [regexp {[^ ]+ is an orphan} $msg]} {
        $me clear
      }
    }

    set motioncmd ""
    set win [$O(myHv3) win]
    if {$y > [winfo height $win]} {
      set motioncmd [list yview scroll 1 units]
    } elseif {$y < 0} {
      set motioncmd [list yview scroll -1 units]
    } elseif {$x > [winfo width $win]} {
      set motioncmd [list xview scroll 1 units]
    } elseif {$x < 0} {
      set motioncmd [list xview scroll -1 units]
    }

    if {$motioncmd ne ""} {
      set O(myIgnoreMotion) 1
      eval $O(myHv3) $motioncmd
      after 20 [list $me ContinueMotion]
    }
  }

  proc ContinueMotion {me} {
    upvar $me O
    set win [$O(myHv3) win]
    set O(myIgnoreMotion) 0
    set x [expr [winfo pointerx $win] - [winfo rootx $win]]
    set y [expr [winfo pointery $win] - [winfo rooty $win]]
    set N [lindex [$O(myHv3) node $x $y] 0]
    $me motion $N $x $y
  }

  # get_selection OFFSET MAXCHARS
  #
  #     This command is invoked whenever the current selection is selected
  #     while it is owned by the html widget. The text of the selected
  #     region is returned.
  #
  proc get_selection {me offset maxChars} {
    upvar $me O
    set t [$O(myHv3) html text text]

    set n1 $O(myFromNode)
    set i1 $O(myFromIdx)
    set n2 $O(myToNode)
    set i2 $O(myToIdx)

    set stridx_a [$O(myHv3) html text offset $O(myFromNode) $O(myFromIdx)]
    set stridx_b [$O(myHv3) html text offset $O(myToNode) $O(myToIdx)]
    if {$stridx_a > $stridx_b} {
      foreach {stridx_a stridx_b} [list $stridx_b $stridx_a] {}
    }

    if {$O(myMode) eq "word"} {
      set stridx_a [string wordstart $t $stridx_a]
      set stridx_b [string wordend $t $stridx_b]
    }
    if {$O(myMode) eq "block"} {
      set stridx_a [string last "\n" $t $stridx_a]
      if {$stridx_a < 0} {set stridx_a 0}
      set stridx_b [string first "\n" $t $stridx_b]
      if {$stridx_b < 0} {set stridx_b [string length $t]}
    }
  
    set T [string range $t $stridx_a [expr $stridx_b - 1]]
    set T [string range $T $offset [expr $offset + $maxChars]]

    return $T
  }

  proc selected {me} {
    upvar $me O
    if {$O(myFromNode) eq ""} {return ""}
    return [$me get_selection 0 10000000]
  }

  proc destroy {me} {
    array unset $me
    rename $me {}
  }
}
::hv3::make_constructor ::hv3::hv3::selectionmanager
#
# End of ::hv3::hv3::selectionmanager
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
# Class ::hv3::hv3::dynamicmanager
#
#     This class is responsible for setting the dynamic :hover flag on
#     document nodes in response to cursor movements. It may one day
#     be extended to handle :focus and :active, but it's not yet clear
#     exactly how these should be dealt with.
#
namespace eval ::hv3::hv3::dynamicmanager {

  proc new {me hv3} {
    $hv3 Subscribe onmouseover [list $me handle_mouseover]
    $hv3 Subscribe onmouseout  [list $me handle_mouseout]
    $hv3 Subscribe onmousedown [list $me handle_mousedown]
    $hv3 Subscribe onmouseup   [list $me handle_mouseup]
  }
  proc destroy {me} {
    uplevel #0 [list unset $me]
    rename $me ""
  }

  proc handle_mouseover {me node} { $node dynamic set hover }
  proc handle_mouseout {me node}  { $node dynamic clear hover }
  proc handle_mousedown {me node} { $node dynamic set active }
  proc handle_mouseup {me node}   { $node dynamic clear active }
}
::hv3::make_constructor ::hv3::hv3::dynamicmanager
#
# End of ::hv3::hv3::dynamicmanager
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
# Class ::hv3::hv3::hyperlinkmanager
#
# Each instance of the hv3 widget contains a single hyperlinkmanager as
# a component. The hyperlinkmanager takes care of:
#
#     * -targetcmd option and associate callbacks
#     * -isvisitedcmd option and associate callbacks
#     * Modifying the cursor to the hand shape when over a hyperlink
#     * Setting the :link or :visited dynamic condition on hyperlink 
#       elements (depending on the return value of -isvisitedcmd).
#
# This class installs a node handler for <a> elements. It also subscribes
# to the <Motion>, <ButtonPress-1> and <ButtonRelease-1> events on the
# associated hv3 widget.
#
namespace eval ::hv3::hv3::hyperlinkmanager {

  proc new {me hv3 baseuri} {
    upvar $me O

    set O(myHv3) $hv3

    set O(myBaseUri) $baseuri

    set O(myLinkHoverCount) 0

    set O(-targetcmd) [list ::hv3::ReturnWithArgs $hv3]

    set O(-isvisitedcmd) [list ::hv3::ReturnWithArgs 0]

    configure-isvisitedcmd $me
    $O(myHv3) Subscribe onclick [list $me handle_onclick]
  }

  proc reset {me} {
    upvar $me O
    set O(myLinkHoverCount) 0
  }

  # This is the configure method for the -isvisitedcmd option. This
  # option configures a callback script that sets or clears the 'visited' 
  # and 'link' properties of an <a href="..."> element. This is a 
  # performance critical operation because it is called so many times.
  #
  proc configure-isvisitedcmd {me} {
    upvar $me O

    # Create a proc to use as the node-handler for <a> elements.
    #
    set P_NODE ${me}.a_node_handler
    catch {rename $P_NODE ""}
    set template [list \
      proc $P_NODE {node} {
        if {![catch {
          set uri [%BASEURI% resolve [$node attr href]]
        }]} {
          if {[%VISITEDCMD% $uri]} {
            $node dynamic set visited
          } else {
            $node dynamic set link
          }
        }
      }
    ]
    eval [::hv3::Expand $template \
        %BASEURI% $O(myBaseUri) %VISITEDCMD% $O(-isvisitedcmd)
    ]

    # Create a proc to use as the attribute-handler for <a> elements.
    #
    set P_ATTR ${me}.a_attr_handler
    catch {rename $P_ATTR ""}
    set template [list \
      proc $P_ATTR {node attr val} {
        if {$attr eq "href"} {
          if {![catch {
            set uri [%BASEURI% resolve $val]
          }]} {
            if {[%VISITEDCMD% $uri]} {
              $node dynamic set visited
            } else {
              $node dynamic set link
            }
          }
        }
      }
    ]
    eval [::hv3::Expand $template \
        %BASEURI% $O(myBaseUri) %VISITEDCMD% $O(-isvisitedcmd)
    ]

    $O(myHv3) html handler node a $P_NODE
    $O(myHv3) html handler attribute a $P_ATTR
  }

  # This method is called whenever an onclick event occurs. If the
  # node is an <A> with an "href" attribute that is not "#" or the
  # empty string, call the [goto] method of some hv3 widget to follow 
  # the hyperlink.
  #
  # The particular hv3 widget is located by evaluating the -targetcmd 
  # callback script. This allows the upper layer to implement frames,
  # links that open in new windows/tabs - all that irritating stuff :)
  #
  proc handle_onclick {me node} {
    upvar $me O
    if {[$node tag] eq "a"} {
      set href [$node attr -default "" href]
      if {$href ne "" && $href ne "#"} {
        set hv3 [eval [linsert $O(-targetcmd) end $node]]
        set href [$O(myBaseUri) resolve $href]
        after idle [list $hv3 goto $href -referer [$O(myHv3) location]]
      }
    }
  }

  proc destroy {me} {
    catch {rename ${me}.a_node_handler ""}
    catch {rename ${me}.a_attr_handler ""}
  }
}
::hv3::make_constructor ::hv3::hv3::hyperlinkmanager
#
# End of ::hv3::hv3::hyperlinkmanager
#--------------------------------------------------------------------------

namespace eval ::hv3::hv3::framelog {

  proc new {me hv3} {
    upvar $me O

    set O(myHv3) $hv3
    set O(myStyleErrors) {}
    set O(myHtmlDocument) {}
  }
  proc destroy {me} {
    uplevel #0 [list unset $me]
    rename $me ""
  }

  proc loghtml {me data} {
    upvar $me O
    if {![info exists ::hv3::log_source_option]} return
    if {$::hv3::log_source_option} {
      append O(myHtmlDocument) $data
    }
  }

  proc log {me id filename data parse_errors} {
    upvar $me O
    if {![info exists ::hv3::log_source_option]} return
    if {$::hv3::log_source_option} {
      lappend O(myStyleErrors) [list $id $filename $data $parse_errors]
    }
  }

  proc clear {me} {
    upvar $me O
    set O(myStyleErrors) ""
    set O(myHtmlDocument) ""
  }

  proc get {me args} {
    upvar $me O
    switch -- [lindex $args 0] {
      html { 
        return $O(myHtmlDocument)
      }

      css { 
        return $O(myStyleErrors)
      }
    }
  }
}
::hv3::make_constructor ::hv3::hv3::framelog

#--------------------------------------------------------------------------
# Class hv3 - the public widget class.
#
namespace eval ::hv3::hv3 {

  proc theselectionmanager {me args} {
    upvar #0 $me O
    eval $O(mySelectionManager) $args
  }
  proc log {me args} {
    upvar #0 $me O
    eval $O(myFrameLog) $args
  }
  proc uri {me args} {
    upvar #0 $me O
    eval $O(myUri) $args
  }

  proc Subscribe {me args} {
    upvar #0 $me O
    eval $O(myMouseManager) subscribe $args
  }
  proc selected {me args} {
    upvar #0 $me O
    eval $O(mySelectionManager) selected $args
  }

  set TextWrapper {
    <html>
      <style>
        body {background-color: #c3c3c3}
        pre  {
          margin: 20px 30px; 
          background-color: #d9d9d9; 
          background-color: white;
          padding: 5px;
          border: 1px solid;
          border-color: #828282 #ffffff #ffffff #828282;
        }
      </style>
    <pre>
  }

  proc new {me args} {
    upvar #0 $me O
    set win $O(win)
	   
    # The scrolled html widget.
    # set O(myHtml) [::hv3::scrolled html $win.html]
    set O(myHtml) $O(hull)
    set O(html) [html $me]
    catch {::hv3::profile::instrument [$O(myHtml) widget]}

    # Current location and base URIs. The default URI is "blank://".
    set O(myUri)  [::tkhtml::uri home://blank/]
    set O(myBase) [::tkhtml::uri home://blank/]

    # Component objects.
    set O(myMouseManager)     [mousemanager       %AUTO% $me]
    set O(myHyperlinkManager) [hyperlinkmanager   %AUTO% $me $O(myBase)]
    set O(mySelectionManager) [selectionmanager   %AUTO% $me]
    set O(myDynamicManager)   [dynamicmanager     %AUTO% $me]
    set O(myFormManager)      [::hv3::formmanager %AUTO% $me]
    set O(myFrameLog)         [framelog           %AUTO% $me]

    set O(-storevisitedcmd) ""

    set O(myStorevisitedDone) 0
    set O(-historydoccmd) ""

    # The option to display images (default true).
    set O(-enableimages) 1

    # The option to execute javascript (default false). 
    #
    # When javascript is enabled, the O(myDom) variable is set to the name of
    # an object of type [::hv3::dom]. When it is not enabled, O(myDom) is
    # an empty string.
    #
    # When the -enablejavascript option is changed from true to false,
    # the O(myDom) object is deleted (and O(myDom) set to the empty 
    # string). But the dom object is not created immediately when 
    # -enablejavascript is changed from false to true. Instead, we
    # wait until the next time the hv3 widget is reset.
    #
    set O(-enablejavascript) 0
    set O(myDom) ""

    set O(-scrollbarpolicy) auto

    set O(-locationvar) ""
    set O(-downloadcmd) ""
    set O(-requestcmd) ""

    set O(-frame) ""

    # Full text of referrer URI, if any.
    #
    # Note that the DOM attribute HTMLDocument.referrer has a double-r,
    # but the name of the HTTP header, "Referer", has only one.
    #
    set O(myReferrer) ""
  
    # Used to assign internal stylesheet ids.
    set O(myStyleCount) 0
  
    # This variable may be set to "unknown", "quirks" or "standards".
    set O(myQuirksmode) unknown
  
    set O(myFirstReset) 1
  
    # Current value to set the -cachecontrol option of download handles to.
    #
    set O(myCacheControl) normal
  
    # This variable stores the current type of resource being displayed.
    # When valid, it is set to one of the following:
    #
    #     * html
    #     * image
    #
    # Otherwise, it is set to an empty string, indicating that the resource
    # has been requested, but has not yet arrived.
    #
    set O(myMimetype) ""
  
    # This variable is only used when ($O(myMimetype) eq "image"). It stores
    # the data for the image about to be displayed. Once the image
    # has finished downloading, the data in this variable is loaded into
    # a Tk image and this variable reset to "".
    #
    set O(myImageData) ""
  
    # If this variable is not set to the empty string, it is the id of an
    # [after] event that will refresh the current document (i.e from a 
    # Refresh header or <meta type=http-equiv> markup). This scheduled 
    # event should be cancelled when the [reset] method is called.
    #
    # There should only be one Refresh event scheduled at any one time.
    # The [Refresh] method, which calls [after] to schedule the events,
    # cancels any pending event before scheduling a new one.
    #
    set O(myRefreshEventId) ""
  
    # This boolean variable is set to zero until the first call to [goto].
    # Before that point it is safe to change the values of the -enableimages
    # option without reloading the document.
    #
    set O(myGotoCalled) 0
  
    # This boolean variable is set after the DOM "onload" event is fired.
    # It is cleared by the [reset] method.
    set O(myOnloadFired) 0
  
    set O(myFragmentSeek) ""
  
    # The ::hv3::request object used to retrieve the main document.
    #
    set O(myDocumentHandle) ""
  
    # List of handle objects that should be released after the page has
    # loaded. This is part of the hack to work around the polipo bug.
    #
    set O(myShelvedHandles) [list]
  
    # List of all active download handles.
    #
    set O(myActiveHandles) [list]
  
    set O(myTitleVar) ""

    $O(myMouseManager) subscribe motion [list $O(mySelectionManager) motion]

    $O(myFormManager) configure -getcmd  [list $me Formcmd get]
    $O(myFormManager) configure -postcmd [list $me Formcmd post]

    # Attach an image callback to the html widget. Store images as 
    # pixmaps only when possible to save memory.
    $O(myHtml) configure -imagecmd [list $me Imagecmd] -imagepixmapify 1

    # Register node handlers to deal with the various elements
    # that may appear in the document <head>. In html, the <head> section
    # may contain the following elements:
    #
    #     <script>, <style>, <meta>, <link>, <object>, <base>, <title>
    #
    # All except <title> are handled by code in ::hv3::hv3. Note that the
    # handler for <object> is the same whether the element is located in
    # the head or body of the html document.
    #
    $O(myHtml) handler node   link     [list $me link_node_handler]
    $O(myHtml) handler node   base     [list $me base_node_handler]
    $O(myHtml) handler node   meta     [list $me meta_node_handler]
    $O(myHtml) handler node   title    [list $me title_node_handler]
    $O(myHtml) handler script style    [list $me style_script_handler]
    $O(myHtml) handler script script   [list ::hv3::ignore_script]

    # Register handler commands to handle <body>.
    $O(myHtml) handler node body   [list $me body_node_handler]

    bind $win <Configure>  [list $me goto_fragment]
    #bind [html $me].document <Visibility> [list $me VisibilityChange %s]

    eval $me configure $args
  }

  # Destructor. This is called automatically when the window is destroyed.
  #
  proc destroy {me} {
    upvar #0 $me O

    # Cancel any and all pending downloads.
    #
    $me stop
    catch {$O(myDocumentHandle) release}

    # Destroy the components. We don't need to destroy the scrolled
    # html component because it is a Tk widget - it is automatically
    # destroyed when it's parent widget is.
    catch { $O(mySelectionManager) destroy }
    catch { $O(myDynamicManager)   destroy }
    catch { $O(myHyperlinkManager) destroy }
    catch { $O(myUri)              destroy }
    catch { $O(myFormManager)      destroy }
    catch { $O(myMouseManager)     destroy }
    catch { $O(myBase)             destroy }
    catch { $O(myDom)              destroy }

    # Cancel any refresh-event that may be pending.
    if {$O(myRefreshEventId) ne ""} {
      after cancel $O(myRefreshEventId)
      set O(myRefreshEventId) ""
    }

    unset $me
    rename $me {}
  }

  proc VisibilityChange {me state} {
    upvar #0 $me O

    switch -- $state {
      VisibilityUnobscured {
        set enablelayout 1
      }
      VisibilityPartiallyObscured {
        set enablelayout 1
      }
      VisibilityFullyObscured {
        set enablelayout 0
      }
    }
    if {[$O(myHtml) cget -enablelayout] != $enablelayout} {
      $O(myHtml) configure -enablelayout $enablelayout
    }
  }

  # Return the location URI of the widget.
  #
  proc location {me} { 
    upvar #0 $me O
    return [$O(myUri) get] 
  }

  # Return the referrer URI of the widget.
  #
  proc referrer {me} { 
    upvar #0 $me O
    return $O(myReferrer) 
  }

  proc Forget {me handle} {
    upvar #0 $me O
    set idx [lsearch $O(myActiveHandles) $handle]
    set O(myActiveHandles) [lreplace $O(myActiveHandles) $idx $idx]
  }

  # The argument download-handle contains a configured request. This 
  # method initiates the request. 
  #
  # This method is used by hv3 and it's component objects (i.e. code in
  # hv3_object_handler). Also the dom code, for XMLHTTPRequest.
  #
  proc makerequest {me downloadHandle} {            # PRIVATE
    upvar #0 $me O

    lappend O(myActiveHandles) $downloadHandle
    $downloadHandle finish_hook [list $me Forget $downloadHandle]

    # Execute the -requestcmd script. Fail the download and raise
    # an exception if an error occurs during script evaluation.
    set cmd [concat $O(-requestcmd) [list $downloadHandle]]
    set rc [catch $cmd errmsg]
    if {$rc} {
      #set einfo $::errorInfo
      #error $errmsg $einfo
      puts "Error in -requestcmd [$downloadHandle cget -uri]: $errmsg"
      catch {$downloadHandle destroy}
    }
  }

  # Based on the current contents of instance variable $O(myUri), set the
  # variable identified by the -locationvar option, if any.
  #
  proc SetLocationVar {me } {
    upvar #0 $me O
    if {$O(-locationvar) ne ""} {
      uplevel #0 [list set $O(-locationvar) [$O(myUri) get]]
    }
    event generate $O(win) <<Location>>
  }

  proc MightBeComplete {me } {
    upvar #0 $me O
    if {[llength $O(myActiveHandles)] == 0} {
      event generate $O(win) <<Complete>>

      # There are no outstanding HTTP transactions. So fire
      # the DOM "onload" event.
      if {$O(myDom) ne "" && !$O(myOnloadFired)} {
        set O(myOnloadFired) 1
        set bodynode [$O(myHtml) search body]
	# Workaround. Currently meta reload causes empty completion.
	# XXX: Check this again!
	if {[llength $bodynode]} {
          $O(myDom) event load [lindex $bodynode 0]
	}
      }
    }
  }

  proc onload_fired {me } { 
    upvar #0 $me O
    return $O(myOnloadFired) 
  }

  # PUBLIC METHOD.
  #
  proc resolve_uri {me uri} {
    upvar #0 $me O
    if {$uri eq ""} {
      set ret "[$O(myBase) scheme]://[$O(myBase) authority][$O(myBase) path]"
    } else {
      set ret [$O(myBase) resolve $uri]
    }
    return $ret
  }

  # This proc is registered as the -imagecmd script for the Html widget.
  # The argument is the URI of the image required.
  #
  # This proc creates a Tk image immediately. It also kicks off a fetch 
  # request to obtain the image data. When the fetch request is complete,
  # the contents of the Tk image are set to the returned data in proc 
  # ::hv3::imageCallback.
  #
  proc Imagecmd {me uri} {
    upvar #0 $me O

    # Massage the URI a bit. Trim whitespace from either end.
    set uri [string trim $uri]

    if {[string match replace:* $uri]} {
        set img [string range $uri 8 end]
        return $img
    }
    set name [image create photo]

    if {$uri ne ""} {
      set full_uri [$me resolve_uri $uri]
    
      # Create and execute a download request. For now, "expect" a mime-type
      # of image/gif. This should be enough to tell the protocol handler to
      # expect a binary file (of course, this is not correct, the real
      # default mime-type might be some other kind of image).
      set handle [::hv3::request %AUTO%                \
          -uri          $full_uri                      \
          -mimetype     image/gif                      \
          -cachecontrol $O(myCacheControl)             \
          -cacheable    0                              \
      ]
      $handle configure -finscript [list $me Imagecallback $handle $name]
      $me makerequest $handle
    }

    # Return a list of two elements - the image name and the image
    # destructor script. See tkhtml(n) for details.
    return [list $name [list image delete $name]]
  }

  # This method is called to handle the "Location" header for all requests
  # except requests for the main document (see the [Refresh] method for
  # these). If there is a Location method, then the handle object is
  # destroyed, a new one dispatched and 1 returned. Otherwise 0 is returned.
  #
  proc HandleLocation {me handle} {
    upvar #0 $me O
    # Check for a "Location" header. TODO: Handling Location
    # should be done in one common location for everything except 
    # the main document. The main document is a bit different...
    # or is it?
    set location ""
    foreach {header value} [$handle cget -header] {
      if {[string equal -nocase $header "Location"]} {
        set location $value
      }
    }

    if {$location ne ""} {
      set finscript [$handle cget -finscript]
      $handle release
      set full_location [$me resolve_uri $location]
      set handle2 [::hv3::request $handle               \
          -uri          $full_location                   \
          -mimetype     image/gif                        \
          -cachecontrol $O(myCacheControl)                  \
      ]
      $handle2 configure -finscript $finscript
      $me makerequest $handle2
      return 1
    }
    return 0
  }

  # This proc is called when an image requested by the -imagecmd callback
  # ([imagecmd]) has finished downloading. The first argument is the name of
  # a Tk image. The second argument is the downloaded data (presumably a
  # binary image format like gif). This proc sets the named Tk image to
  # contain the downloaded data.
  #
  proc Imagecallback {me handle name data} {
    upvar #0 $me O
    if {0 == [$me HandleLocation $handle]} {
      # If the image data is invalid, it is not an error. Possibly hv3
      # should log a warning - if it had a warning system....
      catch { $name configure -data $data }
      $handle release
    }
  }

  # Request the resource located at URI $full_uri and treat it as
  # a stylesheet. The parent stylesheet id is $parent_id. This
  # method is used for stylesheets obtained by either HTML <link> 
  # elements or CSS "@import {...}" directives.
  #
  proc Requeststyle {me parent_id full_uri} {
    upvar #0 $me O
    set id        ${parent_id}.[format %.4d [incr O(myStyleCount)]]
    set importcmd [list $me Requeststyle $id]
    set urlcmd    [list ::hv3::ss_resolve_uri $full_uri]
    append id .9999

    set handle [::hv3::request %AUTO%               \
        -uri         $full_uri                      \
        -mimetype    text/css                       \
        -cachecontrol $O(myCacheControl)            \
        -cacheable 1                                \
    ]
    $handle configure -finscript [
        list $me Finishstyle $handle $id $importcmd $urlcmd
    ]
    $me makerequest $handle
  }

  # Callback invoked when a stylesheet request has finished. Made
  # from method Requeststyle above.
  #
  proc Finishstyle {me handle id importcmd urlcmd data} {
    upvar #0 $me O
    if {0 == [$me HandleLocation $handle]} {
      set full_id "$id.[$handle cget -uri]"
      $O(html) style             \
          -id $full_id           \
          -importcmd $importcmd  \
          -urlcmd $urlcmd        \
          -errorvar parse_errors \
          $data

      $O(myFrameLog) log $full_id [$handle cget -uri] $data $parse_errors

      $me goto_fragment
      $me MightBeComplete
      $handle release
    }
  }

  # Node handler script for <meta> tags.
  #
  proc meta_node_handler {me node} {
    upvar #0 $me O
    set httpequiv [string tolower [$node attr -default "" http-equiv]]
    set content   [$node attr -default "" content]

    switch -- $httpequiv {
      refresh {
        $me Refresh $content
      }

      content-type {
        foreach {a b enc} [::hv3::string::parseContentType $content] {}
        if {
           ![$O(myDocumentHandle) cget -hastransportencoding] &&
           ![::hv3::encoding_isequal $enc [$me encoding]]
        } {
          # This occurs when a document contains a <meta> element that
          # specifies a character encoding and the document was 
          # delivered without a transport-layer encoding (Content-Type
          # header). We need to start reparse the document from scratch
          # using the new encoding.
          #
          # We need to be careful to work around a polipo bug here: If
          # there are more than two requests for a single resource
          # to a single polipo process, and one of the requests is 
          # cancelled, then the other (still active) request is truncated
          # by polipo. The polipo developers acknowledge that this is
          # a bug, but as it doesn't come up very often in normal polipo
          # usage it is not likely to be fixed soon.
          #
          # It's a problem for Hv3 because if the following [reset] cancels
          # any requests, then when reparsing the same document with a
          # different encoding the same resources are requested, we are 
          # likely to trigger this bug.
          #
          puts "INFO: This page triggers meta enc reload"
          
          # For all active handles except the document handle, configure
          # the -incrscript as a no-op, and have the finscript simply 
          # release the handle reference. This means the polipo bug will
          # not be triggered.
          foreach h $O(myActiveHandles) {
            if {$h ne $O(myDocumentHandle)} {
              set fin [list ::hv3::release_handle $h]
              $h configure -incrscript "" -finscript $fin
            }
          }

          $me InternalReset
          $O(myDocumentHandle) configure -encoding $enc
          $me HtmlCallback                 \
              $O(myDocumentHandle)              \
              [$O(myDocumentHandle) isFinished] \
              [$O(myDocumentHandle) data]
        }
      }
    }
  }

  # Return the default encoding that should be used for 
  # javascript and CSS resources.
  proc encoding {me} {
    upvar #0 $me O
    if {$O(myDocumentHandle) eq ""} { 
      return [encoding system] 
    }
    return [$O(myDocumentHandle) encoding]
  }

  # This method is called to handle "Refresh" and "Location" headers
  # delivered as part of the response to a request for a document to
  # display in the main window. Refresh headers specified as 
  # <meta type=http-equiv> markup are also handled. The $content argument
  # contains a the content portion of the Request header, for example:
  #
  #     "5 ; URL=http://www.news.com"
  #
  # (wait 5 seconds before loading the page www.news.com).
  #
  # In the case of Location headers, a synthetic Refresh content header is
  # constructed to pass to this method.
  #
  # Returns 1 if immediate refresh (seconds = 0) is requested.
  #
  proc Refresh {me content} {
    upvar #0 $me O
    # Use a regular expression to extract the URI and number of seconds
    # from the header content. Then dequote the URI string.
    set uri ""
    set re {([[:digit:]]+) *; *[Uu][Rr][Ll] *= *([^ ]+)}
    regexp $re $content -> seconds uri
    regexp {[^\"\']+} $uri uri                  ;# Primitive dequote

    if {$uri ne ""} {
      if {$O(myRefreshEventId) ne ""} {
          after cancel $O(myRefreshEventId)
      }
      set cmd [list $me RefreshEvent $uri]
      set O(myRefreshEventId) [after [expr {$seconds*1000}] $cmd]

      # puts "Parse of content for http-equiv refresh successful! ($uri)"

      return [expr {$seconds == 0}]
    } else {
      # puts "Parse of content for http-equiv refresh failed..."
      return 0
    }
  }

  proc RefreshEvent {me uri} {
    upvar #0 $me O
    set O(myRefreshEventId) ""
    $me goto $uri -nosave
  }

  # System for handling <title> elements. This object exports
  # a method [titlevar] that returns a globally valid variable name
  # to a variable used to store the string that should be displayed as the
  # "title" of this document. The idea is that the caller add a trace
  # to that variable.
  #
  proc title_node_handler {me node} {
    upvar #0 $me O
    set val ""
    foreach child [$node children] {
      append val [$child text]
    }
    set O(myTitleVar) $val
  }
  proc titlevar {me}    {
    return ::${me}(myTitleVar)
  }
  proc title {me} {
    upvar #0 $me O
    return $O(myTitleVar)
  }

  # Node handler script for <body> tags. The purpose of this handler
  # and the [body_style_handler] method immediately below it is
  # to handle the 'overflow' property on the document root element.
  # 
  proc body_node_handler {me node} {
    upvar #0 $me O
    $node replace dumO(my) -stylecmd [list $me body_style_handler $node]
  }
  proc body_style_handler {me bodynode} {
    upvar #0 $me O

    if {$O(-scrollbarpolicy) ne "auto"} {
      $O(myHtml) configure -scrollbarpolicy $O(-scrollbarpolicy)
      return
    }

    set htmlnode [$bodynode parent]
    set overflow [$htmlnode property overflow]

    # Variable $overflow now holds the value of the 'overflow' property
    # on the root element (the <html> tag). If this value is not "visible",
    # then the value is used to govern the viewport scrollbars. If it is
    # visible, then use the value of 'overflow' on the <body> element.
    # See section 11.1.1 of CSS2.1 for details.
    #
    if {$overflow eq "visible"} {
      set overflow [$bodynode property overflow]
    }
    switch -- $overflow {
      visible { $O(myHtml) configure -scrollbarpolicy auto }
      auto    { $O(myHtml) configure -scrollbarpolicy auto }
      hidden  { $O(myHtml) configure -scrollbarpolicy 0 }
      scroll  { $O(myHtml) configure -scrollbarpolicy 1 }
      default {
        puts stderr "Hv3 is confused: <body> has \"overflow:$overflow\"."
        $O(myHtml) configure -scrollbarpolicy auto
      }
    }
  }

  # Node handler script for <link> tags.
  #
  proc link_node_handler {me node} {
    upvar #0 $me O
    set rel  [string tolower [$node attr -default "" rel]]
    set href [string trim [$node attr -default "" href]]
    set media [string tolower [$node attr -default all media]]
    if {
        [string match *stylesheet* $rel] &&
        ![string match *alternat* $rel] &&
        $href ne "" && 
        [regexp all|screen $media]
    } {
      set full_uri [$me resolve_uri $href]
      $me Requeststyle author $full_uri
    }
  }

  # Node handler script for <base> tags.
  #
  proc base_node_handler {me node} {
    upvar #0 $me O
    # Technically, a <base> tag is required to specify an absolute URI.
    # If a relative URI is specified, hv3 resolves it relative to the
    # current location URI. This is not standards compliant (a relative URI
    # is technically illegal), but seems like a reasonable idea.
    $O(myBase) load [$node attr -default "" href]
  }

  # Script handler for <style> tags.
  #
  proc style_script_handler {me attr script} {
    upvar #0 $me O
    array set attributes $attr
    if {[info exists attributes(media)]} {
      if {0 == [regexp all|screen $attributes(media)]} return ""
    }

    set id        author.[format %.4d [incr O(myStyleCount)]]
    set importcmd [list $me Requeststyle $id]
    set urlcmd    [list $me resolve_uri]
    append id ".9999.<style>"
    $O(html) style -id $id     \
        -importcmd $importcmd  \
        -urlcmd $urlcmd        \
        -errorvar parse_errors \
        $script

    $O(myFrameLog) log $id "<style> block $O(myStyleCount)" $script $parse_errors

    return ""
  }

  proc goto_fragment {me } {
    upvar #0 $me O
    switch -- [llength $O(myFragmentSeek)] {
      0 { # Do nothing }
      1 {
        $O(myHtml) yview moveto [lindex $O(myFragmentSeek) 0]
      }
      2 {
        set fragment [lindex $O(myFragmentSeek) 1]
        set selector [format {[name="%s"]} $fragment]
        set goto_node [lindex [$O(myHtml) search $selector] 0]

        # If there was no node with the name attribute set to the fragment,
        # search for a node with the id attribute set to the fragment.
        if {$goto_node eq ""} {
          set selector [format {[id="%s"]} $fragment]
          set goto_node [lindex [$O(myHtml) search $selector] 0]
        }
  
        if {$goto_node ne ""} {
          $O(myHtml) yview $goto_node
        }
      }
    }
  }

  proc seek_to_fragment {me fragment} {
    upvar #0 $me O

    # A fragment was specified as part of the URI that has just started
    # loading. Set O(myFragmentSeek) to the fragment name. Each time some
    # more of the document or a stylesheet loads, the [goto_fragment]
    # method will try to align the vertical scrollbar so that the 
    # named fragment is at the top of the view.
    #
    # If and when the user manually scrolls the viewport, the 
    # O(myFragmentSeek) variable is cleared. This is so we don't wrest
    # control of the vertical scrollbar after the user has manually
    # positioned it.
    #
    $O(myHtml) take_control [list set ::${me}(myFragmentSeek) ""]
    if {$fragment ne ""} {
      set O(myFragmentSeek) [list # $fragment]
    }
  }

  proc seek_to_yview {me moveto} {
    upvar #0 $me O
    $O(myHtml) take_control [list set ::${me}(myFragmentSeek) ""]
    set O(myFragmentSeek) $moveto
  }

  proc documenthandle {me } {
    upvar #0 $me O
    return $O(myDocumentHandle)
  }

  proc documentcallback {me handle referrer savestate final data} {
    upvar #0 $me O

    if {$O(myMimetype) eq ""} {
  
      # TODO: Real mimetype parser...
      set mimetype  [string tolower [string trim [$handle cget -mimetype]]]
      foreach {major minor} [split $mimetype /] {}

      switch -- $major {
        text {
          if {[lsearch [list html xml xhtml] $minor]>=0} {
            set q [::hv3::configure_doctype_mode $O(myHtml) $data isXHTML]
            $me reset $savestate
            set O(myQuirksmode) $q
            if {$isXHTML} { $O(myHtml) configure -parsemode xhtml } \
            else          { $O(myHtml) configure -parsemode html }
            set O(myMimetype) html
          } else {
            # Plain text mode.
            $me reset $savestate
            $O(myHtml) parse $::hv3::hv3::TextWrapper
            set O(myMimetype) text
	  }
        }
  
        image {
          set O(myImageData) ""
          $me reset $savestate
          set O(myMimetype) image
        }
      }

      # If there is a "Location" or "Refresh" header, handle it now.
      set refreshheader ""
      foreach {name value} [$handle cget -header] {
        switch -- [string tolower $name] {
          location {
            set refreshheader "0 ; URL=$value"
          }
          refresh {
            set refreshheader $value
          }
        }
      }

      set isImmediateRefresh [$me Refresh $refreshheader]
  
      if {!$isImmediateRefresh && $O(myMimetype) eq ""} {
        # Neither text nor an image. This is the upper layers problem.
        if {$O(-downloadcmd) ne ""} {
          # Remove the download handle from the list of handles to cancel
          # if [$hv3 stop] is invoked (when the user clicks the "stop" button
          # we don't want to cancel pending save-file operations).
          $me Forget $handle
          eval [linsert $O(-downloadcmd) end $handle $data $final]
        } else {
          $handle release
          set sheepish "Don't know how to handle \"$mimetype\""
          tk_dialog .apology "Sheepish apology" $sheepish 0 OK
        }
        return
      }

      $O(myUri)  load [$handle cget -uri]
      $O(myBase) load [$O(myUri) get]
      $me SetLocationVar

      if {$isImmediateRefresh} {
        $handle release
        return
      }

      set O(myReferrer) $referrer
  
      if {$O(myCacheControl) ne "relax-transparency"} {
        $me seek_to_fragment [$O(myUri) fragment]
      }

      set O(myStyleCount) 0
    }

    if {$O(myDocumentHandle) ne $handle} {
      if {$O(myDocumentHandle) ne ""} {
        $O(myDocumentHandle) release
      }
      set O(myDocumentHandle) $handle
    }

    switch -- $O(myMimetype) {
      text  {$me TextCallback $handle $final $data}
      html  {$me HtmlCallback $handle $final $data}
      image {$me ImageCallback $handle $final $data}
    }


    if {$final} {
      if {$O(myStorevisitedDone) == 0 && $O(-storevisitedcmd) ne ""} {
        set O(myStorevisitedDone) 1
        eval $O(-storevisitedcmd) 1
      }
      $me MightBeComplete
    }
  }

  proc TextCallback {me handle isFinal data} {
    upvar #0 $me O
    set z [string map {< &lt; > &gt;} $data]
    if {$isFinal} {
	$O(myHtml) parse -final $data
    } else {
	$O(myHtml) parse $data
    }
  }

  proc HtmlCallback {me handle isFinal data} {
    upvar #0 $me O
    $O(myFrameLog) loghtml $data
    if {$isFinal} {
	$O(html) parse -final $data
    } else {
	$O(html) parse $data
    }
    $me goto_fragment
  }

  proc ImageCallback {me handle isFinal data} {
    upvar #0 $me O
    append O(myImageData) $data
    if {$isFinal} {
      set img [image create photo -data $O(myImageData)]
      set O(myImageData) ""
      set imagecmd [$O(myHtml) cget -imagecmd]
      $O(myHtml) configure -imagecmd [list ::hv3::ReturnWithArgs $img]
      $O(myHtml) parse -final { <img src="unused"> }
      $O(myHtml) _force
      $O(myHtml) configure -imagecmd $imagecmd
    }
  }

  proc Formcmd {me method node uri querytype encdata} {
    upvar #0 $me O
    set cmd [linsert [$me cget -targetcmd] end $node]
    [eval $cmd] Formcmd2 $method $uri $querytype $encdata
  }

  proc Formcmd2 {me method uri querytype encdata} {
    upvar #0 $me O
    puts "Formcmd $method $uri $querytype $encdata"

    set uri_obj [::tkhtml::uri [$me resolve_uri $uri]]

    event generate $O(win) <<Goto>>

    set handle [::hv3::request %AUTO% -mimetype text/html]
    set O(myMimetype) ""
    set referer [$me uri get]
    $handle configure                                       \
        -incrscript [list $me documentcallback $handle $referer 1 0] \
        -finscript  [list $me documentcallback $handle $referer 1 1] \
        -requestheader [list Referer $referer]              \

    if {$method eq "post"} {
      $handle configure -uri [$uri_obj get] -postdata $encdata
      $handle configure -enctype $querytype
      $handle configure -cachecontrol normal
    } else {
      $uri_obj load "?$encdata"
      $handle configure -uri [$uri_obj get]
      $handle configure -cachecontrol $O(myCacheControl)
    }
    $uri_obj destroy
    $me makerequest $handle

    # Grab the keyboard focus for this widget. This is so that after
    # the form is submitted the arrow keys and PgUp/PgDown can be used
    # to scroll the main display.
    #
    focus [$me html]
  }

  proc seturi {me uri} {
    upvar #0 $me O
    $O(myUri) load $uri
    $O(myBase) load [$O(myUri) get]
  }

  #--------------------------------------------------------------------------
  # PUBLIC INTERFACE TO HV3 WIDGET STARTS HERE:
  #
  #     Method              Delegate
  # --------------------------------------------
  #     goto                N/A
  #     xview               $O(myHtml)
  #     yview               $O(myHtml)
  #     html                N/A
  #     hull                N/A
  #   

  proc dom {me} { 
    upvar #0 $me O
    if {$O(myDom) eq ""} { return ::hv3::ignore_script }
    return $O(myDom)
  }

  #--------------------------------------------------------------------
  # Load the URI specified as an argument into the main browser window.
  # This method has the following syntax:
  #
  #     $hv3 goto URI ?OPTIONS?
  #
  # Where supported options are:
  #
  #     -cachecontrol "normal"|"relax-transparency"|"no-cache"
  #     -nosave
  #     -referer URI
  #     -history_handle  DOWNLOAD-HANDLE
  #
  # The -cachecontrol option (default "normal") specifies the value 
  # that will be used for all ::hv3::request objects issued as a 
  # result of this load URI operation.
  #
  # Normally, a <<SaveState>> event is generated. If -nosave is specified, 
  # this is suppressed.
  # 
  proc goto {me uri args} {
    upvar #0 $me O

    set O(myGotoCalled) 1

    # Process the argument switches. Local variable $cachecontrol
    # is set to the effective value of the -cachecontrol option.
    # Local boolean var $savestate is true unless the -nogoto
    # option is specified.
    set savestate 1
    set cachecontrol normal
    set referer ""
    set history_handle ""

    for {set iArg 0} {$iArg < [llength $args]} {incr iArg} {
      switch -- [lindex $args $iArg] {
        -cachecontrol {
          incr iArg
          set cachecontrol [lindex $args $iArg]
        }
        -referer {
          incr iArg
          set referer [lindex $args $iArg]
        }
        -nosave {
          set savestate 0
        }
        -history_handle {
          incr iArg
          set history_handle [lindex $args $iArg]
        }
        default {
          error "Bad option \"[lindex $args $iArg]\" to \[::hv3::hv3 goto\]"
        }
      }
    }

    # Special case. If this URI begins with "javascript:" (case independent),
    # pass it to the current running DOM implementation instead of loading
    # anything into the current browser.
    if {[string match -nocase javascript:* $uri]} {
      if {$O(myDom) ne ""} {
        $O(myDom) javascript [string range $uri 11 end]
      }
      return
    }

    set O(myCacheControl) $cachecontrol

    set current_uri [$O(myUri) get_no_fragment]
    set uri_obj [::tkhtml::uri [$me resolve_uri $uri]]
    set full_uri [$uri_obj get_no_fragment]
    set fragment [$uri_obj fragment]

    # Generate the <<Goto>> event.
    event generate $O(win) <<Goto>>

    if {$full_uri eq $current_uri && $cachecontrol ne "no-cache"} {
      # Save the current state in the history system. This ensures
      # that back/forward controls work when navigating between
      # different sections of the same document.
      if {$savestate} {
        event generate $O(win) <<SaveState>>
      }
      $O(myUri) load $uri

      # If the cache-mode is "relax-transparency", then the history 
      # system is controlling this document load. It has already called
      # [seek_to_yview] to provide a seek offset.
      if {$cachecontrol ne "relax-transparency"} {
        if {$fragment eq ""} {
          $me seek_to_yview 0.0
        } else {
          $me seek_to_fragment $fragment
        }
      }
      $me goto_fragment

      $me SetLocationVar
      return [$O(myUri) get]
    }

    # Abandon any pending requests
    if {$O(myStorevisitedDone) == 0 && $O(-storevisitedcmd) ne ""} {
      set O(myStorevisitedDone) 1
      eval $O(-storevisitedcmd) $savestate
    }
    $me stop
    set O(myMimetype) ""

    if {$history_handle eq ""} {
      # Base the expected type on the extension of the filename in the
      # URI, if any. If we can't figure out an expected type, assume
      # text/html. The protocol handler may override this anyway.
      set mimetype text/html
      set path [$uri_obj path]
      if {[regexp {\.([A-Za-z0-9]+)$} $path dumO(my) ext]} {
        switch -- [string tolower $ext] {
  	jpg  { set mimetype image/jpeg }
          jpeg { set mimetype image/jpeg }
          gif  { set mimetype image/gif  }
          png  { set mimetype image/png  }
          gz   { set mimetype application/gzip  }
          gzip { set mimetype application/gzip  }
          zip  { set mimetype application/gzip  }
          kit  { set mimetype application/binary }
        }
      }
  
      # Create a download request for this resource. We expect an html
      # document, but at this juncture the URI may legitimately refer
      # to kind of resource.
      #
      set handle [::hv3::request %AUTO%              \
          -uri         [$uri_obj get]                \
          -mimetype    $mimetype                     \
          -cachecontrol $O(myCacheControl)           \
          -hv3          $me                          \
      ]
      $handle configure                                                        \
        -incrscript [list $me documentcallback $handle $referer $savestate 0]\
        -finscript  [list $me documentcallback $handle $referer $savestate 1] 
      if {$referer ne ""} {
        $handle configure -requestheader [list Referer $referer]
      }
  
      $me makerequest $handle
    } else {
      # The history system has supplied the data to load into the widget.
      # Use $history_handle instead of creating a new request.
      #
      $history_handle reference
      $me documentcallback $history_handle $referer $savestate 1 [
        $history_handle data
      ]
      $me goto_fragment
    }
    $uri_obj destroy
  }

  # Abandon all currently pending downloads. This method is 
  # part of the public interface.
  #
  proc stop {me } {
    upvar #0 $me O

    foreach dl $O(myActiveHandles) { 
      if {$dl eq $O(myDocumentHandle)} {
        set O(myDocumentHandle) ""
      }
      $dl release 
    }

    if {$O(myStorevisitedDone) == 0 && $O(-storevisitedcmd) ne ""} {
      set O(myStorevisitedDone) 1
      eval $O(-storevisitedcmd) 1
    }
  }

  proc InternalReset {me } {
    upvar #0 $me O

    $O(myFrameLog) clear

    foreach m [list \
        $O(myMouseManager) $O(myFormManager)          \
        $O(mySelectionManager) $O(myHyperlinkManager) \
    ] {
      if {$m ne ""} {$m reset}
    }
    $O(html) reset
    $O(myHtml) configure -scrollbarpolicy $O(-scrollbarpolicy)

    catch {$O(myDom) destroy}
    if {$O(-enablejavascript)} {
      set O(myDom) [::hv3::dom %AUTO% $me]
      $O(myHtml) handler script script   [list $O(myDom) script]
      $O(myHtml) handler script noscript ::hv3::ignore_script
    } else {
      set O(myDom) ""
      $O(myHtml) handler script script   ::hv3::ignore_script
      $O(myHtml) handler script noscript {}
    }
    $O(myMouseManager) configure -dom $O(myDom)
  }

  proc reset {me isSaveState} {
    upvar #0 $me O

    # Clear the "onload-event-fired" flag
    set O(myOnloadFired) 0
    set O(myStorevisitedDone) 0

    # Cancel any pending "Refresh" event.
    if {$O(myRefreshEventId) ne ""} {
      after cancel $O(myRefreshEventId)
      set O(myRefreshEventId) ""
    }

    # Generate the <<Reset>> and <<SaveState> events.
    if {!$O(myFirstReset) && $isSaveState} {
      event generate $O(win) <<SaveState>>
    }
    set O(myFirstReset) 0

    set O(myTitleVar) ""
    set O(myQuirksmode) unknown

    $me InternalReset
  }

  proc configure-enableimages {me} {
    upvar #0 $me O

    # The -enableimages switch. If false, configure an empty string
    # as the html widget's -imagecmd option. If true, configure the
    # same option to call the [Imagecmd] method of this mega-widget.
    #
    # We used to reload the frame contents here. But it turns out
    # that is really inconvenient. If the user wants to reload the
    # document the reload button is right there anyway.
    #
    if {$O(-enableimages)} {
      $O(myHtml) configure -imagecmd [list $me Imagecmd]
    } else {
      $O(myHtml) configure -imagecmd ""
    }
  }

  proc configure-enablejavascript {me} {
    upvar #0 $me O
    if {!$O(-enablejavascript)} {
      catch {$O(myDom) destroy}
      set O(myDom) ""
      $O(myHtml) handler script script   ::hv3::ignore_script
      $O(myHtml) handler script noscript {}
      $O(myMouseManager) configure -dom ""
    }
  }

  proc pending {me}  {
    upvar #0 $me O
    return [llength $O(myActiveHandles)]
  }
  proc html {me args}     { 
    upvar #0 $me O
    if {[llength $args]>0} {
      eval [$O(myHtml) widget] $args
    } else {
      $O(myHtml) widget
    }
  }
  proc hull {me}     { 
    upvar #0 $me O
    return $O(hull)
  }
  proc win {me} {
    upvar #0 $me O
    return $O(win)
  }
  proc me {me} { return $me }

  proc yview {me args} {
    upvar #0 $me O
    eval $O(html) yview $args
  }
  proc xview {me args} {
    upvar #0 $me O
    eval $O(html) xview $args
  }

  proc javascriptlog {me args} {
    upvar #0 $me O
    if {$O(-dom) ne ""} {
      eval $O(-dom) javascriptlog $args
    }
  }

  #proc unknown {method me args} {
    # puts "UNKNOWN: $me $method $args"
    #upvar #0 $me O
    #uplevel 3 [list eval $O(myHtml) $method $args]
  #}
  #namespace unknown unknown

  proc node {me args} { 
    upvar #0 $me O
    eval $O(myHtml) node $args
  }

  set DelegateOption(-isvisitedcmd) myHyperlinkManager
  set DelegateOption(-targetcmd) myHyperlinkManager

  # Standard scrollbar and geometry stuff is delegated to the html widget
  #set DelegateOption(-xscrollcommand) myHtml
  #set DelegateOption(-yscrollcommand) myHtml
  set DelegateOption(-width) myHtml
  set DelegateOption(-height) myHtml

  # Display configuration options implemented entirely by the html widget
  set DelegateOption(-fonttable) myHtml
  set DelegateOption(-fontscale) myHtml
  set DelegateOption(-zoom) myHtml
  set DelegateOption(-forcefontmetrics) myHtml
}

::hv3::make_constructor ::hv3::hv3 [list ::hv3::scrolled html]

proc ::hv3::release_handle {handle args} {
  $handle release
}

proc ::hv3::ignore_script {args} {}

# This proc is passed as the -urlcmd option to the [style] method of the
# Tkhtml3 widget. Returns the full-uri formed by resolving $rel relative
# to $base.
#
proc ::hv3::ss_resolve_uri {base rel} {
  set b [::tkhtml::uri $base]
  set ret [$b resolve $rel]
  $b destroy
  set ret
}

bind Html <Tab>       [list ::hv3::forms::tab %W]
bind Html <Shift-Tab> [list ::hv3::forms::tab %W]

proc ::hv3::bg {script args} {
  set eval [concat $script $args]
  set rc [catch [list uplevel $eval] result]
  if {$rc} {
    set cmd [list bgerror $result]
    set error [list $::errorInfo $::errorCode]
    after idle [list foreach {::errorInfo ::errorCode} $error $cmd]
    set ::errorInfo ""
    return ""
  }
  return $result
}

proc ::hv3::ReturnWithArgs {retval args} {
  return $retval
}


# hv3_encodings.tcl
#
#     This file contains wrappers around the Tcl built-in commands 
#     [fconfigure] and [encoding]. The purpose is to support identifiers 
#     like "windows-1257" as an alias for "cp1257". We need to replace
#     the original commands so that the http package sees our encoding
#     database.
#
#     To add new encoding aliases, entries should be added to the
#     global ::Hv3EncodingMap array. This array maps from identifiers
#     commonly used on the web to the cannonical name used by Tcl. For
#     example, some Japanese websites use "shift_jis", but Tcl calls
#     this encoding "shiftjis". To work around this, we add the following
#     entry to ::Hv3EncodingMap:
#
#          set ::Hv3EncodingMap(shift_jis) shiftjis
#
#     Entries may be added to ::Hv3EncodingMap at any time (even before
#     this file is [source]ed).
#


rename encoding encoding_orig
rename fconfigure fconfigure_orig

# encoding convertfrom ?encoding? data
# encoding convertto ?encoding? string
# encoding names
#
proc encoding {args} {
  set argv $args

  # Handle [encoding names]
  #
  if {[llength $argv] == 1 && [lindex $argv 0] eq "names"} {
    return [concat [array names ::Hv3EncodingMap] [encoding_orig names]]
  }

  # Map any explicitly specified encoding.
  #
  if {[llength $argv] == 3} {
    set enc [string tolower [lindex $argv 1]]
    if {[info exists ::Hv3EncodingMap($enc)]} {
      lset argv 1 $::Hv3EncodingMap($enc)
    }
  }

  # Call the real [encoding] command.
  eval encoding_orig $argv
}

# fconfigure channelId name value ?name value ...?
#
proc fconfigure {args} {
  set argv $args
  for {set ii 1} {($ii+1) < [llength $argv]} {incr ii 2} {
    if {[lindex $argv $ii] eq "-encoding"} {
      set enc [string tolower [lindex $argv [expr {$ii+1}]]]
      if {[info exists ::Hv3EncodingMap($enc)]} {
        lset argv [expr {$ii+1}] $::Hv3EncodingMap($enc)
      }
    }
  }

  # Call the real [fconfigure] command.
  eval fconfigure_orig $argv
}

namespace eval ::hv3 {

  # The argument is an encoding name, which may or may not be known to Tcl.
  # Return the name of the Tcl encoding that will be used by Hv3.
  #
  proc encoding_resolve {enc} {
    set encoding [string tolower $enc]
    if {[info exists ::Hv3EncodingMap($encoding)]} {
      set ::Hv3EncodingMap($encoding)
    } else {
      encoding system
    }
  }

  # The two arguments are encoding names. This proc returns true if the
  # two encodings are handled identically by Hv3.
  #
  proc ::hv3::encoding_isequal {enc1 enc2} {
    string equal [::hv3::encoding_resolve $enc1] [::hv3::encoding_resolve $enc2]
  }
}

##########################################################################
# Below this point is where new encoding alias' can be added. See
# the comment in the file header for instructions.
#

# Build the mappings "database".
#
foreach name [encoding_orig names] {
  set ::Hv3EncodingMap($name) $name
  if {[string match cp* $name]} {
    set name2 "windows-[string range $name 2 end]"
    set ::Hv3EncodingMap($name2) $name
  } 
  if {[string match iso* $name]} {
    set name2 "iso-[string range $name 3 end]"
    set ::Hv3EncodingMap($name2) $name
  } 
}

# Deal with some Japanese encodings. Because of the dominance of
# Microsoft, websites that specify "shift_jis" or "shiftjis" as an
# encoding are usually better handled with cp932. So, if cp932 is
# present, use it in preference to the encoding Tcl calls shiftjis.
#
if {[lsearch [encoding_orig names] cp932]>=0} {
  set ::Hv3EncodingMap(shiftjis) cp932
  set ::Hv3EncodingMap(shift_jis) cp932
} else {
  set ::Hv3EncodingMap(shift_jis) shiftjis
}

# Various encodings best handled by pretending they are utf-8.
set ::Hv3EncodingMap(us-ascii) utf-8
set ::Hv3EncodingMap(iso-8559-1) utf-8

# Thai encoding.
set ::Hv3EncodingMap(windows-874) tis-620

namespace eval hv3 { set {version($Id: hv3_form.tcl,v 1.99 2008/03/03 10:29:00 danielk1977 Exp $)} 1 }

###########################################################################
# hv3_form.tcl --
#
#     This file contains code to implement Html forms for Tkhtml based
#     browsers. The only requirement is that no other code register for
#     node-handler callbacks for <input>, <button> <select> or <textarea> 
#     elements. The application must provide this module with callback
#     scripts to execute for GET and POST form submissions.
#

# Load Bryan Oakley combobox. 
#
# Todo: Puppy linux has this (combobox) packaged already. Should use 
# this fact to reduce installation footprint size on that platform.
#

#----------------------------------------------------------------------
#     The following HTML elements create document nodes that are replaced with
#     form controls:
#
#         <!ELEMENT INPUT    - O EMPTY> 
#         <!ELEMENT BUTTON   - - (%flow;)* -(A|%formctrl;|FORM|FIELDSET)>
#         <!ELEMENT SELECT   - - (OPTGROUP|OPTION)+> 
#         <!ELEMENT TEXTAREA - - (#PCDATA)> 
#         <!ELEMENT ISINDEX  - O EMPTY> 
#
#     This module registers node handler scripts with client html widgets for
#     these five element types. The <isindex> element (from ancient times) is
#     handled specially, by transforming it to an equivalent HTML4 form.
#
#         <input>       -> button|radiobutton|checkbutton|combobox|entry|image
#         <button>      -> button|image
#         <select>      -> combobox
#         <textarea>    -> text
#
# <input>
# type = text|password|checkbox|radio|submit|reset|file|hidden|image|button
#
# <button>
# type = submit|button|reset
#
#     <select>   -> [::hv3::forms::select]
#     <textarea> -> [::hv3::forms::textarea]
#     <isindex>  -> Transformed to <INPUT type="text"> by script handler 
#
# TODO: Handle <BUTTON> markup.
#

#----------------------------------------------------------------------
# Code in this file is organized into the following types:
#
#     ::hv3::fileselect (widget)
#     ::hv3::control (widget)
#     ::hv3::clickcontrol
#     ::hv3::form
#     ::hv3::formmanager
#

#
#     ::hv3::forms::checkbox
#     ::hv3::forms::entrycontrol
#     ::hv3::forms::select
#     ::hv3::forms::textarea
#

#----------------------------------------------------------------------
# Standard controls interface. All control types implement this.
#
#         formsreport
#         name
#         value
#         success
#         filename
#         stylecmd
#         reset
#
#         get_text_widget
#         configurecmd
#
#     get_text_widget and configurecmd will be removed sooner or later.
#
# As well as the standard controls interface, each type implements an
# interface for interaction with the DOM. For HTMLInputElement objects:
#
#         dom_checked
#         dom_value
#         dom_select
#         dom_focus
#         dom_blur
#         dom_click
#

namespace eval ::hv3::forms {
  proc configurecmd {win font} {
    set descent [font metrics $font -descent]
    set ascent  [font metrics $font -ascent]
    expr {([winfo reqheight $win] + $descent - $ascent) / 2}
  }
}

proc ::hv3::boolean_attr {node attr def} {
  set val [$node attribute -default $def $attr]
  if {$val eq "" || ![string is boolean $val]} {
    set val true
  }
  return $val
}
proc ::hv3::put_boolean_attr {node attr val} {
  if {$val eq "" || ![string is boolean $val]} {
    set val true
  }
  $node attribute $attr $val
}

# The argument node must be either a <FORM> or an element that generates 
# a form control. The return value is a list of node handles. The first
# is the associated <FORM> node, followed by all controls also associated
# with the same <FORM> node.
#
# If there is no associated <FORM>, an empty string is returned.
#
proc ::hv3::get_form_nodes {node} {
  set html [$node html]
  set N [$html search INPUT,SELECT,TEXTAREA,BUTTON,FORM]

  set idx [lsearch -exact $N $node]
  if {$idx >= 0} {
    set iFirst $idx
    while { $iFirst>=0 && [[lindex $N $iFirst] tag] ne "form" } {
      incr iFirst -1
    }
  
    set iLast [expr $idx+1]
    while { $iLast<[llength $N] && [[lindex $N $iLast] tag] ne "form" } {
      incr iLast 1
    }
  
    if {$iFirst>=0} {
      return [lrange $N $iFirst [expr $iLast-1]]
    }
  }

  return ""
}

# Scan the document currently displayed by html widget $html, returning
# a list of nodes that can accept focus. The list is ordered according
# to the order in which they should be navigated by the user agent (the
# "tabindex" order).
#
# In Hv3, the following are considered focusable:
#
#   + <TEXTAREA>
#   + <INPUT type="text"> <INPUT type="password"> <INPUT type="file">
#
proc ::hv3::get_focusable_nodes {html} {
  set ret [list]
  foreach N [$html search TEXTAREA,INPUT] {
    if {[::hv3::boolean_attr $N disabled 0]} continue
    if {[string toupper [$N tag]] eq "INPUT"} {
      set type [string tolower [$N attr -default "" type]]
      set L [list radio button hidden checkbox image reset submit]
      if {[lsearch $L $type]>=0} continue
    }
    lappend ret $N
  }

  lsort -command [list ::hv3::compare_focusable $ret] $ret
}

proc ::hv3::compare_focusable {orig L R} {
  set tl [$L attr -default 0 tabindex]
  set tr [$R attr -default 0 tabindex]
  if {![string is integer $tl]} {set tl 0}
  if {![string is integer $tr]} {set tr 0}
  if {$tr<0} {set tr 0}
  if {$tl<0} {set tl 0}

  if {$tr == $tl} {
    # Compare based on order in $orig
    set il [lsearch $orig $L]
    set ir [lsearch $orig $R]
    return [expr {$il - $ir}]
  }

  # Nodes with tabindex=0 come after those with +ve tabindex values
  if {$tr == 0} {return -1}
  if {$tl == 0} {return 1}

  # Node with the smallest tabindex comes first.
  return [expr {$tl - $tr}]
}

# Called when <Tab> or <Shift-Tab> is pressed when the html widget or
# one of it's form controls has the focus. This makes sure the stacking
# order of the controls within the Html widget is correct for
# html traversal rules (i.e. the "tabindex" attribute).
#
proc ::hv3::forms::tab {html} {
  set L [::hv3::get_focusable_nodes $html]
  set prev ""
  foreach node $L {
    set win [$node replace]
    raise $win
  }
}

# Given a node that generates a control - $node - return the
# corresponding <FORM> node. Or an empty string, if there is
# no such node.
proc ::hv3::control_to_form {node} {
  lindex [::hv3::get_form_nodes $node] 0
}

#--------------------------------------------------------------------------
# ::hv3::forms::checkbox 
#
#     Object for controls created elements of the following form:
#    
#         <INPUT type="checkbox">
#
::snit::widgetadaptor ::hv3::forms::checkbox {
  option -takefocus -default 0

  variable mySuccess 0        ;# -variable for checkbutton widget
  variable myNode             ;# Tkhtml <INPUT> node

  delegate option * to hull
  delegate method * to hull

  constructor {node bindtag args} {
    installhull [checkbutton $win]
    $hull configure -variable [myvar mySuccess]
    $hull configure -highlightthickness 0 -pady 0 -padx 0 -borderwidth 0
    set myNode $node
    bindtags $self [concat $bindtag [bindtags $self]]
    $self reset
  }

  # Generate html for the "HTML Forms" tab of the tree-browser.
  #
  method formsreport {} { 
    subst {}
  }

  # This method is called during form submission to determine the 
  # name of the control. It returns the value of the Html "name" 
  # attribute. Or, failing that, an empty string.
  #
  method name {} { return [$myNode attr -default "" name] }

  # This method is called during form submission to determine the 
  # value of the control. It returns the value of the Html "value" 
  # attribute. Or, failing that, an empty string.
  #
  method value {} { return [$myNode attr -default "" value] }

  # True if the control is considered successful for the purposes
  # of submitting this form.
  #
  method success {} { return [expr {$mySuccess && [$self name] ne ""}] }

  # Empty string. This method is only implemented by 
  # <INPUT type="file"> controls.
  #
  method filename {} { return "" }

  # Reset the state of the control.
  #
  method reset {} { 
    set mySuccess [expr [catch {$myNode attr checked}] ? 0 : 1]
  }

  # TODO: The sole purpose of this is to return a linebox offset...
  method configurecmd {values} { 
    ::hv3::forms::configurecmd $win [$hull cget -font]
  }

  method stylecmd {} {
    set N $myNode
    set bg "transparent"
    while {$bg eq "transparent" && $N ne ""} {
      set bg [$N property background-color]
      set N [$N parent]
    }
    if {$bg eq "transparent"} {set bg white}
    catch {
      $hull configure -bg $bg
      $hull configure -highlightbackground $bg
      $hull configure -activebackground $bg
      $hull configure -highlightcolor $bg
    }
  }

  #---------------------------------------------------------------------
  # START OF DOM FUNCTIONALITY
  #
  # Below this point are some methods used by the DOM class 
  # HTMLInputElement. None of this is used unless scripting is enabled.
  #

  # Get/set on the DOM "checked" attribute. This means the state 
  # of control (1==checked, 0==not checked) for this type of object.
  #
  method dom_checked {args} {
    if {[llength $args]>0} {
      set mySuccess [expr {[lindex $args 0] ? 1 : 0}]
    }
    return $mySuccess
  }

  # DOM Implementation does not call this. HTMLInputElement.value is
  # the "value" attribute of the HTML element for this type of object.
  #
  method dom_value {args} { error "N/A" }

  # HTMLInputElement.select() is a no-op for this kind of object. It
  # contains no text so there is nothing to select...
  #
  method dom_select  {} {}

  # Hv3 will not support keyboard access to checkboxes. Until
  # this changes these can be no-ops :)
  method dom_focus {} {}
  method dom_blur  {} {}

  # Generate a synthetic click. This same trick can be used for <INPUT>
  # elements with "type" set to "Button", "Radio", "Reset", or "Submit".
  #
  method dom_click {} {
    set x [expr [winfo width $win]/2]
    set y [expr [winfo height $win]/2]
    event generate $win <ButtonPress-1> -x $x -y $y
    event generate $win <ButtonRelease-1> -x $x -y $y
  }
}

#--------------------------------------------------------------------------
# ::hv3::forms::radio 
#
#     Object for controls created by elements of the following form:
#    
#         <INPUT type="radio">
#
::snit::widgetadaptor ::hv3::forms::radio {
  option -takefocus -default 0

  variable myNode             ;# Tkhtml <INPUT> node
  variable myVarname

  delegate option * to hull
  delegate method * to hull

  constructor {node bindtag} {
    installhull [radiobutton $win]
    set myNode $node
    set myVarname ::hv3::radiobutton_[$node attr -default "" name]

    $hull configure -variable [myvar mySuccess]
    $hull configure -highlightthickness 0 -pady 0 -padx 0 -borderwidth 0
    catch { $hull configure -tristatevalue EWLhwEUGHWZAZWWZE }

    bindtags $self [concat $bindtag [bindtags $self]]
    $self reset

    $hull configure -value $myNode
    $hull configure -variable $myVarname
    if {[::hv3::boolean_attr $myNode checked 0] || ![info exists $myVarname]} {
      set $myVarname $myNode
    }
  }

  # Generate html for the "HTML Forms" tab of the tree-browser.
  #
  method formsreport {} { 
    subst {}
  }

  # This method is called during form submission to determine the 
  # name of the control. It returns the value of the Html "name" 
  # attribute. Or, failing that, an empty string.
  #
  method name {} { return [$myNode attr -default "" name] }

  # This method is called during form submission to determine the 
  # value of the control. It returns the value of the Html "value" 
  # attribute. Or, failing that, an empty string.
  #
  method value {} { return [$myNode attr -default "" value] }

  # True if the control is considered successful for the purposes
  # of submitting this form.
  #
  method success {} { 
    if {[catch {$myNode attr name}]} {return 0}
    return [expr {[set $myVarname] eq $myNode}]
  }

  # Empty string. This method is only implemented by 
  # <INPUT type="file"> controls.
  #
  method filename {} { return "" }

  # Reset the state of the control.
  #
  method reset {} {
    #puts "TODO: ::hv3::forms::radio reset"
  }

  # TODO: The sole purpose of this is to return a linebox offset...
  method configurecmd {values} { 
    ::hv3::forms::configurecmd $win [$hull cget -font]
  }

  # Style the widget. All we do is set the background color.
  #
  method stylecmd {} {
    set N $myNode
    set bg "transparent"
    while {$bg eq "transparent" && $N ne ""} {
      set bg [$N property background-color]
      set N [$N parent]
    }
    if {$bg eq "transparent"} {set bg white}
    catch {
      $hull configure -bg $bg
      $hull configure -highlightbackground $bg
      $hull configure -activebackground $bg
      $hull configure -highlightcolor $bg
    }
  }

  #---------------------------------------------------------------------
  # START OF DOM FUNCTIONALITY
  #
  # Below this point are some methods used by the DOM class 
  # HTMLInputElement. None of this is used unless scripting is enabled.
  #

  # Get/set on the DOM "checked" attribute.
  #
  method dom_checked {args} {
    if {[llength $args] == 1} {
      if {[lindex $args 0]} {
        set $myVarname $myNode
      } else {
        set $myVarname ""
      }
    }
    return [expr {[set $myVarname] eq $myNode}]
  }

  method dom_select  {} { }
  method dom_focus {} { }
  method dom_blur  {} { }

  method dom_click {} {
    set x [expr [winfo width $me]/2]
    set y [expr [winfo height $me]/2]
    event generate $me <ButtonPress-1> -x $x -y $y
    event generate $me <ButtonRelease-1> -x $x -y $y
  }
}

#--------------------------------------------------------------------------
# ::hv3::forms::entrycontrol 
#
#     Object for controls created elements of the following form:
#    
#         <INPUT type="text">
#         <INPUT type="password">
#
namespace eval ::hv3::forms::entrycontrol {

  proc new {me node bindtag args} {
    upvar #0 $me O

    set O(-takefocus) 0

    set O(myValue) ""

    set O(myNode) $node

    set O(myWidget) [entry $O(win).entry]

    $O(myWidget) configure -highlightthickness 0 -borderwidth 0 
    $O(myWidget) configure -selectborderwidth 0
    $O(myWidget) configure -textvar ${me}(myValue)
    $O(myWidget) configure -background white

    $O(myWidget) configure -validatecommand [list $me Validate %P]
    $O(myWidget) configure -validate key

    pack $O(myWidget) -expand true -fill both

    # If this is a password entry field, obscure it's contents
    set zType [string tolower [$node attr -default "" type]]
    if {$zType eq "password" } { $O(myWidget) configure -show * }

    # Set the default width of the widget to 20 characters. Unless there
    # is no size attribute and the CSS 'width' property is set to "auto",
    # this will be overidden.
    $O(myWidget) configure -width 20

    # Pressing enter in an entry widget submits the form.
    bind $O(myWidget) <KeyPress-Return> [list $me Submit]

    bind $O(myWidget) <Tab>       [list ::hv3::forms::tab [$O(myNode) html]]
    bind $O(myWidget) <Shift-Tab> [list ::hv3::forms::tab [$O(myNode) html]]

    set tags [bindtags $O(myWidget)]
    bindtags $O(myWidget) [concat $tags $O(win)]

    $me reset
    eval $me configure $args
  }

  proc destroy {me} {
    uplevel #0 [list unset $me]
    rename $me {}
  }

  # Generate html for the "HTML Forms" tab of the tree-browser.
  #
  proc formsreport {me} { return {<i color=red>TODO</i>} }

  # This method is called during form submission to determine the 
  # name of the control. It returns the value of the Html "name" 
  # attribute. Or, failing that, an empty string.
  #
  proc name {me} { 
    upvar #0 $me O
    return [$O(myNode) attr -default "" name] 
  }

  # This method is called during form submission to determine the 
  # value of the control. Return the current contents of the widget.
  #
  proc value {me} { 
    upvar #0 $me O
    return $O(myValue) 
  }

  # True if the control is considered successful for the 
  # purposes of submitting this form.
  #
  proc success {me} { 
    upvar #0 $me O
    return [expr {[$me name] ne ""}] 
  }

  # Empty string. This method is only implemented by 
  # <INPUT type="file"> controls.
  #
  proc filename {me} { 
    upvar #0 $me O
    return "" 
  }

  # Reset the state of the control.
  #
  proc reset {me} { 
    upvar #0 $me O
    set O(myValue) [$O(myNode) attr -default "" value]
  }

  # TODO: The sole purpose of this is to return a linebox offset...
  proc configurecmd {me values} { 
    upvar #0 $me O
    ::hv3::forms::configurecmd $O(myWidget) [$O(myWidget) cget -font]
  }

  proc stylecmd {me} {
    upvar #0 $me O
    catch { $O(myWidget) configure -font [$O(myNode) property font] }
  }

  proc Submit {me} {
    upvar #0 $me O
    set form [::hv3::control_to_form $O(myNode)]
    if {$form ne ""} {
      [$form replace] submit $me
    }
  }

  # This method is called each time a character is inserted or
  # removed from the [entry] widget. To enforce the semantics of
  # the HTML "maxlength" attribute.
  #
  proc Validate {me newvalue} {
    upvar #0 $me O
    set iLimit [$O(myNode) attr -default -1 maxlength]
    if {$iLimit >= 0 && [string length $newvalue] > $iLimit} {
      return 0
    }
    return 1
  }

  #---------------------------------------------------------------------
  # START OF DOM FUNCTIONALITY
  #
  # Below this point are some methods used by the DOM class 
  # HTMLInputElement. None of this is used unless scripting is enabled.
  #

  # Get/set on the DOM "checked" attribute. This is always 0 for
  # an entry widget.
  #
  proc dom_checked {me args} { return 0 }

  # HTMLInputElement.value is the current contents of the widget 
  # for this type of object.
  #
  proc dom_value {me args} {
    upvar #0 $me O
    if {[llength $args]>0} {
      set O(myValue) [lindex $args 0]
    }
    return $O(myValue)
  }

  # Select the text in this widget.
  #
  proc dom_select  {me} {
    upvar #0 $me O
    $O(myWidget) selection range 0 end
  }

  # Methods [dom_focus] and [dom_blur] are used to implement the
  # focus() and blur() methods on DOM classes HTMLInputElement,
  # HTMLTextAreaElement and HTMLSelectElement.
  #
  # At present, calling blur() when a widget has the focus causes the
  # focus to be transferred to the html widget. This should be fixed 
  # so that the focus is passed to the next control in tab-index order
  # But tab-index is not supported yet. :(
  # 
  proc dom_focus {me} {
    upvar #0 $me O
    focus $O(myWidget)
  }
  proc dom_blur {me} {
    upvar #0 $me O
    set now [focus]
    if {$O(myWidget) eq [focus]} {
      focus [winfo parent $win]
    }
  }

  # This is a no-op for this type of <INPUT> element.
  #
  proc dom_click {me} {}
}
::hv3::make_constructor ::hv3::forms::entrycontrol

#--------------------------------------------------------------------------
# ::hv3::forms::textarea 
#
#     Object for controls created elements of the following form:
#    
#         <TEXTAREA>
#
::snit::widget ::hv3::forms::textarea {
  option -takefocus -default 0

  option -submitcmd -default ""

  variable myWidget ""
  variable myNode ""

  constructor {node bindtag args} {
    set myWidget [::hv3::scrolled text ${win}.widget -width 500]

    $myWidget configure -borderwidth 0
    $myWidget configure -pady 0
    $myWidget configure -selectborderwidth 0
    $myWidget configure -highlightthickness 0
    $myWidget configure -background white

    set myNode $node
    bindtags $myWidget [concat $bindtag [bindtags $myWidget] $win]
    $self reset
    $self configurelist $args

    bind $myWidget <Tab>       [list ::hv3::forms::tab [$myNode html]]
    bind $myWidget <Shift-Tab> [list ::hv3::forms::tab [$myNode html]]

    pack $myWidget -expand true -fill both
  }

  # Generate html for the "HTML Forms" tab of the tree-browser.
  #
  method formsreport {} { return {<i color=red>TODO</i>} }

  # This method is called during form submission to determine the 
  # name of the control. It returns the value of the Html "name" 
  # attribute. Or, failing that, an empty string.
  #
  method name {} { return [$myNode attr -default "" name] }

  # This method is called during form submission to determine the 
  # value of the control. Return the current contents of the widget.
  #
  method value {} { 
    string range [$myWidget get 0.0 end] 0 end-1
  }

  # True if the control is considered successful for the 
  # purposes of submitting this form.
  #
  method success {} { return [expr {[$self name] ne ""}] }

  # Empty string. This method is only implemented by 
  # <INPUT type="file"> controls.
  #
  method filename {} { return "" }

  # Reset the state of the control.
  #
  method reset {} { 
    set state [$myWidget cget -state]
    $myWidget configure -state normal
    set contents ""
    $myWidget delete 0.0 end
    foreach child [$myNode children] {
      append contents [$child text -pre]
    }
    $myWidget insert 0.0 $contents
    $myWidget configure -state $state
  }

  # TODO: The sole purpose of this is to return a linebox offset...
  method configurecmd {values} { 
    ::hv3::forms::configurecmd $myWidget [$myWidget cget -font]
  }

  method stylecmd {} {
    catch { $myWidget configure -font [$myNode property font] }
  }

  #---------------------------------------------------------------------
  # START OF DOM FUNCTIONALITY
  #
  # Below this point are some methods used by the DOM class 
  # HTMLTextAreaElement. All the important stuff uses the text widget
  # directly (see hv3_dom_html.tcl).
  #
  method get_text_widget {} {
    return $myWidget
  }

  method dom_blur {} {
    set now [focus]
    if {[$myWidget widget] eq [focus]} {
      focus [winfo parent $win]
    }
  }
  method dom_focus {} {
    focus [$myWidget widget]
  }
}


#--------------------------------------------------------------------------
# ::hv3::forms::select 
#
#     Object for controls created by elements of the following form:
#    
#         <SELECT>
#
snit::widgetadaptor ::hv3::forms::select {

  variable myHv3 ""
  variable myNode ""
  variable myCurrentSelected -1

  variable myValues [list]
  variable myLabels [list]

  delegate option * to hull
  delegate method * to hull

  constructor {node hv3 args} {
    installhull [::combobox::combobox $win]
    set myNode $node
    set myHv3 $hv3
    bindtags $self [concat $myHv3 [bindtags $self]]

    $hull configure -highlightthickness 0
    $hull configure -background white
    $hull configure -borderwidth 0
    $hull configure -highlightthickness 0
    $hull configure -editable false
    $hull configure -command [list $self ComboboxChanged]
    $hull configure -takefocus 0

    $self treechanged
    $self reset
  }

  method formsreport {} {
    return <I>TODO</I>
  }

  method name {} {
    return [$myNode attr -default "" name]
  }

  method value {} {
    lindex $myValues [$hull curselection]
  }

  method success {} {
    # If it has a name and is not disabled, it is successful.
    if {[catch {$myNode attr name}]}              { return 0 }
    if {[::hv3::boolean_attr $myNode disabled 0]} { return 0 }
    return 1
  }

  method filename {} { 
    return "" 
  }

  method stylecmd {} {
    $hull configure -font [$myNode property font]
  }

  method reset {} {
    set idx 0
    set ii 0
    foreach child [$myNode children]  {
      if {[$child tag] == "option"} {
        if {![catch {$child attr selected}]} {
          set idx $ii
        }
        incr ii
      }
    }
    set myCurrentSelected $idx
    $win select $idx
  }

  # TODO: The sole purpose of this is to return a linebox offset...
  method configurecmd {values} { 
    $self treechanged
    ::hv3::forms::configurecmd $win [$hull cget -font]
  }

  method ComboboxChanged {widget newValue} {
    set idx [$hull curselection]
    if {$myCurrentSelected<0 || $idx eq "" || $idx == $myCurrentSelected} return
    set myCurrentSelected $idx
    focus [winfo parent $win]

    # Fire the "onchange" dom event.
    [$myHv3 dom] event change $myNode
  }

  # This is called by the DOM module whenever the tree-structure 
  # surrounding this element has been modified. Update the
  # state of the widget to reflect the new tree structure.
  method treechanged {} {

    # Figure out a list of options for the drop-down list. This block 
    # sets up two list variables, $labels and $values. The $labels
    # list stores the options from which the user may select, and the 
    # $values list stores the corresponding form control values.
    set maxlen 5
    set labels [list]
    set values [list]
    foreach child [$myNode children] {
      if {[$child tag] == "option"} {

        # If the element has text content, this is used as the default
	# for both the label and value of the entry (used if the Html
	# attributes "value" and/or "label" are not defined.
	set contents ""
        catch {
          set t [lindex [$child children] 0]
          set contents [$t text]
        }

        # Append entries to both $values and $labels
        set     label  [$child attr -default $contents label]
        set     value  [$child attr -default $contents value]
        lappend labels $label
        lappend values $value

        set len [string length $label]
        if {$len > $maxlen} {set maxlen $len}
      }
    }

    # If the following if{...} statement is true, then the tree has
    # not changed in any way that this object cares about. In this 
    # case, we can return early.
    #
    if {$labels eq $myLabels && $values eq $myValues} {
      return
    }

    $hull configure -state normal

    set myLabels $labels
    set myValues $values

    # Set up the combobox widget. 
    $hull list delete 0 end
    eval [concat [list $hull list insert 0] $labels]

    # Set the width and height of the combobox. Prevent manual entry.
    if {[set height [llength $myValues]] > 10} { set height 10 }
    $hull configure -width  $maxlen
    $hull configure -height $height

    if {$myCurrentSelected>0 && $myCurrentSelected>=[llength $myValues]} {
      set myCurrentSelected [expr [llength $myValues]-1]
    }
    $hull select $myCurrentSelected
    set disabled [::hv3::boolean_attr $myNode disabled 0]
    if {$disabled} {
      $hull configure -state disabled
    } else {
      $hull configure -state normal
    }
  }

  #---------------------------------------------------------------------
  # START OF DOM FUNCTIONALITY
  #
  # Below this point are some methods used by the DOM class 
  # HTMLSelectElement. None of this is used unless scripting
  # is enabled. This interface is unique to this object - no other
  # control type has to interface with HTMLSelectElement.
  #

  method dom_selectionIndex {} { 
    set idx [$hull curselection]
    if {[$hull cget -state] eq "disabled" || $idx eq ""} {
      set idx -1
    }
    set idx
  }
  method dom_setSelectionIndex {value} { 
    if {[$hull cget -state] ne "disabled"} {
      $hull select $value 
    }
  }

  # Selection widget cannot take the focus in Hv3, so these two are 
  # no-ops.  Maybe some keyboard enthusiast will change this one day.
  #
  method dom_blur  {} {}
  method dom_focus {} {}
}

# ::hv3::fileselect
#
snit::widget ::hv3::forms::fileselect {
  option -takefocus -default 0

  component myButton
  component myEntry

  delegate option -text to myButton
  delegate option -highlightthickness to hull

  variable myNode ""

  constructor {node bindtag} {
    set myNode $node
    set myEntry [entry ${win}.entry -width 30]
    set myButton [button ${win}.button -command [list $self Browse]]
    $myButton configure -text "Browse..."

    $myEntry configure -highlightthickness 0
    $myEntry configure -borderwidth 0
    $myEntry configure -bg white

    $myButton configure -highlightthickness 0
    $myButton configure -pady 0

    # The [entry] widget may take the focus. The [button] does not.
    #
    $myButton configure -takefocus 0
    $myEntry configure  -takefocus 1
    bind $myEntry <Tab>       [list ::hv3::forms::tab [$node html]]
    bind $myEntry <Shift-Tab> [list ::hv3::forms::tab [$node html]]

    bindtags $myEntry  [concat $bindtag [bindtags $myEntry] $self]
    bindtags $myButton [concat $bindtag [bindtags $myButton] $self]

    pack $myButton -side right
    pack $myEntry -fill both -expand true
  }

  method success {} {
    set fname [${win}.entry get]
    if {$fname ne ""} {
      return 1
    }
    return 0
  }
  method value {} {
    set fname [${win}.entry get]
    if {$fname ne ""} {
      set fd [open $fname]
      fconfigure $fd -encoding binary -translation binary
      set data [read $fd]
      close $fd
      return $data
    }
    return ""
  }
  method filename {} {
    set fname [${win}.entry get]
    return [file tail $fname]
  }
  method name {} {
    return [$myNode attr -default "" name]
  }

  method formsreport {} {
    return <I>TODO</I>
  }
  
  method reset {} {
    $myEntry delete 0 end
  }

  method stylecmd {} {
    set font [$myNode property font]
    $myEntry configure -font $font
    $myButton configure -font $font
  }

  method configurecmd {values} { 
    ::hv3::forms::configurecmd $win [$myEntry cget -font]
  }

  #-----------------------------------------------------------------------
  # End of standard controls interface. Start of internal methods.
  #
  method Browse {} {
    set file [tk_getOpenFile]
    if {$file ne ""} {
      $myEntry delete 0 end
      $myEntry insert 0 $file
    }
  }

  #-----------------------------------------------------------------------
  # DOM interface for HTMLInputElement
  #
  method dom_checked {args} {return 0}

  method dom_value {args} {
    if {[llength $args]>0} {
      $myEntry delete 0 end
      $myEntry insert 0 [lindex $args 0]
    }
    return [$myEntry get]
  }

  method dom_select  {} {
    $myEntry selection range 0 end
  }

  method dom_focus  {} {
    focus $myEntry
  }

  method dom_blur  {} {
    set now [focus]
    if {$myEntry eq [focus]} {
      focus [winfo parent $win]
    }
  }

  method dom_click  {} { }
}

#--------------------------------------------------------------------------
# ::hv3::clickcontrol
#
#     An object of this class is used for the following types of form
#     control elements:
#
#         <input type=hidden>
#         <input type=image>
#         <input type=button>
#         <input type=submit>
#         <input type=reset>
#
#
namespace eval ::hv3::clickcontrol {

  proc new {me node} {
    upvar #0 $me O
    set O(myClicked) 0
    set O(myClickX) 0
    set O(myClickY) 0 
    set O(-clickcmd) ""
    set O(myNode) $node
  }
  proc destroy {me} {
    rename $me ""
    uplevel #0 [list unset $me]
  }

  # This method is used by graphical-submit buttons only. Controls
  # created by markup like:
  #
  #     <INPUT type="image">
  #
  proc graphicalSubmit {me} {
    upvar #0 $me O
    set t    [string tolower [$myNode attr -default "" type]]
    set name [$myNode attr -default "" name]
    if {$t ne "image" || $name eq ""} {return [list]}

    list "${name}.x" $myClickX "${name}.y" $myClickY
  }
 
  proc value {me} { 
    upvar #0 $me O
    return [$O(myNode) attr -default "" value] 
  }
  proc name {me}  {
    upvar #0 $me O
    return [$O(myNode) attr -default "" name]
  }

  proc success {me} { 
    upvar #0 $me O

    # Controls that are disabled cannot be succesful:
    if {[$O(myNode) attr -default 0 disabled]} {return 0}

    if {[catch {$O(myNode) attr name ; $O(myNode) attr value}]} {
      return 0
    }
    switch -- [string tolower [$O(myNode) attr type]] {
      hidden { return 1 }
      submit { return $O(myClicked) }
      image  { return 0 }
      button { return 0 }
      reset  { return 0 }
      default { 
        return 0 
      }
    }
  }

  # click --
  #
  #     This method is called externally when this widget is clicked
  #     on. If it is not "", evaluate the script configured as -clickcmd
  #
  proc click {me {isSynthetic 1}} {
    upvar #0 $me O

    # Controls that are disabled cannot be activated:
    #
    if {[$O(myNode) attr -default 0 disabled]} return

    set cmd $O(-clickcmd)
    set formnode [::hv3::control_to_form $O(myNode)]
    if {$cmd ne "" && $formnode ne ""} {

      set bbox [[$O(myNode) html] bbox $O(myNode)]
      foreach {x1 y1 x2 y2} $bbox {}
      if {$isSynthetic} {
        set O(myClickX) [expr {($x2-$x1)/2}]
        set O(myClickY) [expr {($y2-$y1)/2}]
      } else {
        foreach {px py} [winfo pointerxy [$O(myNode) html]] {}
        set wx [winfo rootx [$O(myNode) html]]
        set wy [winfo rooty [$O(myNode) html]]
        set O(myClickX) [expr $px - ($x1 + $wx)]
        set O(myClickY) [expr $py - ($y1 + $wy)]
      }

      set O(myClicked) 1
      eval [[$formnode replace] $cmd $me]

      catch {
        # Catch these in case this object has been destroyed by the 
        # form method invoked above.
        set O(myClicked) 0
        set O(myClickX) 0
        set O(myClickY) 0
      }
    }
  }

  proc configurecmd {me values} {}
  proc stylecmd {me} {}

  proc formsreport {me} {
    upvar #0 $me O
    set n [::hv3::control_to_form $O(myNode)]
    set report "<p>"
    if {$n eq ""} {
      append report {<i>No associated form node.</i>}
    } else {
      append report [subst -nocommands {
        <i>Controled by form node <a href="$n">$n</a></i>
      }]
    }
    append report "</p>"
    return $report
  }

  proc reset {me } { # no-op }

  #---------------------------------------------------------------------
  # START OF DOM FUNCTIONALITY
  #
  # Below this point are some methods used by the DOM class 
  # HTMLInputElement. None of this is used unless scripting is enabled.
  #

  # Get/set on the DOM "checked" attribute. This means the state 
  # of control (1==checked, 0==not checked) for this type of object.
  #
  proc dom_checked {me args} {
    return 0
  }

  # DOM Implementation does not call this. HTMLInputElement.value is
  # the "value" attribute of the HTML element for this type of object.
  #
  proc dom_value {me args} { error "N/A" }

  # HTMLInputElement.select() is a no-op for this kind of object. It
  # contains no text so there is nothing to select...
  #
  proc dom_select {me} {}

  # Hv3 will not support keyboard access to checkboxes. Until
  # this changes these can be no-ops :)
  proc dom_focus {me} {}
  proc dom_blur {me} {}

  # Generate a synthetic click. This same trick can be used for <INPUT>
  # elements with "type" set to "Button", "Radio", "Reset", or "Submit".
  #
  proc dom_click {me} {
    upvar #0 $me O
    set x [expr [winfo width $win]/2]
    set y [expr [winfo height $win]/2]
    event generate $win <ButtonPress-1> -x $x -y $y
    event generate $win <ButtonRelease-1> -x $x -y $y
  }
}

::hv3::make_constructor ::hv3::clickcontrol

#-----------------------------------------------------------------------
# ::hv3::format_query
#
#     This command is intended as a replacement for [::http::formatQuery].
#     It does the same thing, except it allows the following characters
#     to slip through unescaped:
#
#         - _ . ! ~ * ' ( )
#
#     as well as the alphanumeric characters (::http::formatQuery only
#     allows the alphanumeric characters through).
#
#     QUOTE FROM RFC2396:
#
#     2.3. Unreserved Characters
#     
#        Data characters that are allowed in a URI but do not have a reserved
#        purpose are called unreserved.  These include upper and lower case
#        letters, decimal digits, and a limited set of punctuation marks and
#        symbols.
#     
#           unreserved  = alphanum | mark
#     
#           mark        = "-" | "_" | "." | "!" | "~" | "*" | "'" | "(" | ")"
#     
#        Unreserved characters can be escaped without changing the semantics
#        of the URI, but this should not be done unless the URI is being used
#        in a context that does not allow the unescaped character to appear.
#
#     END QUOTE
#
#     So in a way both versions are correct. But some websites (yahoo.com)
#     do not work unless we allow the extra characters through unescaped.
#
proc ::hv3::format_query {enc args} {
  set result ""
  set sep ""
  foreach i $args {
    append result $sep [::hv3::escape_string [encoding convertto $enc $i]]
    if {$sep eq "="} {
      set sep &
    } else {
      set sep =
    }
  }
  return $result
}
set ::hv3::escape_map ""
proc ::hv3::escape_string {string} {
  if {$::hv3::escape_map eq ""} {
    for {set i 0} {$i < 256} {incr i} {
      set c [format %c $i]
      if {$c ne "-" && ![string match {[a-zA-Z0-9_.!~*'()]} $c]} {
        set map($c) %[format %.2X $i]
      }
    }
    set {map( )} +
    set ::hv3::escape_map [array get map]
  }

  set converted [string map $::hv3::escape_map $string]
  return $converted
}
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# ::hv3::form
#
#     A single instance of this type is created for each HTML form in the 
#     document. 
#
#     This object is set as the "replacement" object for the corresponding
#     Tkhtml3 <form> node, even though it is not a Tk window, and therefore 
#     has no effect on display.
#
#   Options:
#
#       -getcmd
#       -postcmd
#
#   Methods
#
#       add_control NODE IS-SUBMIT 
#           Called to register a node that generates a control with this
#           form object.
#
#       submit ?SUBMIT-CONTROL?
#           Submit the form. Optionally, specify the control which did the
#           submitting.
#
#       reset
#           Reset the form.
#
#       controls
#           Return a list of nodes that create controls associated with
#           this <FORM> object (i.e. everything added via [add_control]).
#
#       formsreport 
#           For the tree-browser. Return a nicely formatted HTML report
#           summarizing the form state.
#    
snit::type ::hv3::form {

  # <FORM> element that corresponds to this object.
  variable myFormNode 

  variable myHv3

  # When the onsubmit() event is fired, this boolean variable is set.
  # If the event handler calls submit() on this form object, it is
  # submitted immediately, without running the event handler.
  #
  variable myInSubmitEvent 0

  option -getcmd  -default ""
  option -postcmd -default ""

  constructor {node hv3} {
    set myFormNode $node
    set myHv3 $hv3
    $node replace $self -deletecmd [list $self destroy]
  }

  destructor { }

  # Return a list of control nodes associated with this form.
  #
  method controls {} {
    return [lrange [::hv3::get_form_nodes $myFormNode] 1 end]
  }

  method reset {resetcontrol} {
    foreach c [lrange [::hv3::get_form_nodes $myFormNode] 1 end] {
      [$c replace] reset
    }
  }

  method ControlNodes {} {
    set ret [list]
    foreach c [lrange [::hv3::get_form_nodes $myFormNode] 1 end] {
      lappend ret $c
    }
    set ret
  }

  method SubmitNodes {} {
    set ret [list]
    foreach c [lrange [::hv3::get_form_nodes $myFormNode] 1 end] {
      set tag [string toupper [$c tag]]
      set type [string toupper [$c attr -default "" type]]
      if {$tag eq "INPUT" && $type eq "SUBMIT"} {
        lappend ret [$c replace]
      }
    }
    set ret
  }

  method submit {submitcontrol} {

    # Before doing anything, execute the onsubmit event
    # handlers, if any. If the submit handler script returns
    # false, do not submit the form. Otherwise, proceed.
    #
    if {!$myInSubmitEvent} {
      set myInSubmitEvent 1
      set rc [[$myHv3 dom] event onsubmit $myFormNode]
      if {$rc eq "prevent"} return
      if {$rc eq "error"} return
      set myInSubmitEvent 0
    }

    set SubmitControls [$self SubmitNodes]
    set Controls       [$self ControlNodes]

    set data [list]
    if {
        [lsearch $SubmitControls $submitcontrol] < 0 &&
        [llength $SubmitControls] > 0
    } {
      foreach s $SubmitControls {
        if {[$s name] ne ""} {
          lappend data [$s name]
          lappend data 1
          break
        }
      }
    }

    # If $submitcontrol is a graphical submit control, this line adds
    # the ${name}.x and ${name}.y elements to the form submission data.
    #
    catch { eval lappend data [$submitcontrol graphicalSubmit] }

    foreach controlnode $Controls {
      set control [$controlnode replace]
      if {$control eq ""} continue
      set success [$control success]
      set name    [$control name]
      if {$success} {
        set value [$control value]
        # puts "    Control \"$name\" is successful: \"$value\""
        lappend data $name $value
      } else {
        # puts "    Control \"$name\" is unsuccessful"
      }
    }

    # Now encode the data, depending on the enctype attribute of the
    set enctype [$myFormNode attr -default "" enctype]
    if {[string match -nocase *multipart* $enctype]} {
      # Generate a pseudo-random boundary string. The key here is that
      # if this exact string actually appears in any form control values,
      # the form submission will fail. So generate something nice and
      # long to minimize the odds of this happening.
      set bound "-----Submitted_by_Hv3_[clock seconds].[pid].[expr rand()]"

      set querytype "multipart/form-data ; boundary=$bound"
      set querydata ""
      set CR "\r\n"
      foreach controlnode $Controls {
        set control [$controlnode replace]
        if {$control eq ""} continue
        if {[$control success]} {

          set name  [$control name]
          set value [$control value]

          set filename ""
          catch {set filename [$control filename]}

          append querydata "--${bound}$CR"
          append querydata "Content-Disposition: form-data; name=\"${name}\""
          if { $filename ne "" } {
            append querydata "; filename=\"$filename\""
          }
          append querydata "$CR$CR"
          append querydata "${value}$CR"
        }
      }
      append querydata "--${bound}--$CR"
    } else {
      set querytype "application/x-www-form-urlencoded"
      set enc [$myHv3 encoding]
      set querydata [eval [linsert $data 0 ::hv3::format_query $enc]]
    }

    set action [$myFormNode attr -default "" action]
    set method [string toupper [$myFormNode attr -default get method]]
    switch -- $method {
      GET     { set script $options(-getcmd) }
      POST    { set script $options(-postcmd) }
      ISINDEX { 
        set script $options(-getcmd) 
        set control [[lindex $Controls 0] replace]
        set querydata [::hv3::format_query [$myHv3 encoding] [$control value]]
      }
      default { set script "" }
    }

    if {$script ne ""} {
      set exec [concat $script [list $myFormNode $action $querytype $querydata]]
      eval $exec
    }
  }

  method formsreport {} {
    set action [$myFormNode attr -default "" action]
    set method [$myFormNode attr -default "" method]

    set Template {
      <table>
        <tr><th>Action: <td>$action
        <tr><th>Method: <td>$method
      </table>

      <table>
        <tr><th>Name<th>Successful?<th>Value<th>Is Submit?
    }

    set report [subst $Template]

    foreach controlnode [lrange [::hv3::get_form_nodes $myFormNode] 1 end] {
      set control [$controlnode replace]
      if {$control eq ""} continue
      set success [$control success]
      set name    [$control name]
      set isSubmit [expr {([lsearch [$self SubmitNodes] $controlnode]>=0)}]

      if {$success} {
        set value [::hv3::string::htmlize [$control value]]
      } else {
        set value "<i>N/A</i>"
      }
      append report "<tr><td>"
      append report "<a href=\"$controlnode\">"
      if {$name ne ""} {
        append report "[::hv3::string::htmlize $name]"
      } else {
        append report "<i>$controlnode</i>"
      }
      append report "<td>$success<td>$value<td>$isSubmit"
    }
    append report "</table>"

    return $report
  }
}

#-----------------------------------------------------------------------
# ::hv3::formmanager
#
#     Each hv3 mega-widget has a single instance of the following type
#     It contains the logic and state required to manager any HTML forms
#     contained in the current document.
#    
snit::type ::hv3::formmanager {

  option -getcmd  -default ""
  option -postcmd -default ""

  # Map from node-handle to ::hv3::clickcontrol object for all clickable
  # form controls currently managed by this form-manager.
  variable myClickControls -array [list]
  variable myClicked ""

  variable myHv3
  variable myHtml

  constructor {hv3 args} {
    $self configurelist $args
    set myHv3  $hv3
    set myHtml [$myHv3 html]

    # Register handlers for elements that create controls. (todo: <button>).
    #
    $myHtml handler node input     [list $self control_handler]
    $myHtml handler node textarea  [list $self control_handler]
    $myHtml handler node select    [list $self control_handler]
    $myHtml handler node button    [list $self control_handler]
    $myHtml handler script isindex [list ::hv3::isindex_handler $hv3]

    $myHtml handler node form [list $self FormHandler]

    # Subscribe to mouse-clicks (for the benefit of ::hv3::clickcontrol
    # instances).
    $myHv3 Subscribe onclick [list $self clickhandler]
  }

  # FormHandler
  #
  #     A Tkhtml parse-handler for <form> and </form> tags.
  method FormHandler {node} {
    # This ::hv3::form object will be automatically deleted when
    # the <FORM> node is removed from the document.
    set form [::hv3::form %AUTO% $node $myHv3]

    $form configure -getcmd $options(-getcmd)
    $form configure -postcmd $options(-postcmd)
  }

  # This method is called by the [control_handler] method to add [bind] 
  # scripts to the forms control widget passed as an argument. The
  # [bind] scripts are used to generate the "keyup", "keydown" and 
  # "keypress" HTML 4.01 scripting events.
  #
  method SetupKeyBindings {widget node} {
    bind $widget <KeyPress>   +[list $self WidgetKeyPress $widget $node]
    bind $widget <KeyRelease> +[list $self WidgetKeyRelease $widget $node]
    bind $widget <FocusIn>    +[list $self WidgetFocus $widget $node]
    bind $widget <FocusOut>   +[list $self WidgetBlur $widget $node]
  }

  # Handler scripts for the <KeyPress> and <KeyRelease> events.
  #
  variable myKeyPressNode ""
  method WidgetKeyPress {widget node} {
    [$myHv3 dom] event keydown $node
    set myKeyPressNode $node
  }
  method WidgetKeyRelease {widget node} {
    [$myHv3 dom] event keyup $node
    if {$node eq $myKeyPressNode} {
      [$myHv3 dom] event keypress $node
    }
    set myKeyPressNode ""
  }
  method WidgetFocus {widget node} {
    [$myHv3 dom] event focus $node
  }
  method WidgetBlur {widget node} {
    [$myHv3 dom] event blur $node
  }

  method control_handler {node} {

    #set zWinPath ${myHtml}.document.control_[string map {: _} $node]
    set zWinPath ${myHtml}.document.control_[string map {: _} $node]
    set isSubmit 0

    set tag [string tolower [$node tag]]
    set type ""
    if {$tag eq "input"} {
      set type [string tolower [$node attr -default {} type]]
    }

    switch -- ${tag}.${type} {

      select. {
        set control [::hv3::forms::select $zWinPath $node $myHv3]
      }

      textarea. {
        set control [::hv3::forms::textarea $zWinPath $node $myHv3]
      }

      input.image {
        set control [::hv3::clickcontrol %AUTO% $node]
        set myClickControls($node) $control
        $control configure -clickcmd submit
        set isSubmit 1
      }
      input.submit {
        set control [::hv3::clickcontrol %AUTO% $node]
        set myClickControls($node) $control
        $control configure -clickcmd submit
        set isSubmit 1
      }
      input.reset {
        set control [::hv3::clickcontrol %AUTO% $node]
        $control configure -clickcmd reset
        set myClickControls($node) $control
      }
      button. {
        set buttontype [string tolower [$node attr -default {} type]]
        if {$buttontype eq "submit" || $buttontype eq "reset"} {
          set control [::hv3::clickcontrol %AUTO% $node]
          set myClickControls($node) $control
          $control configure -clickcmd $buttontype
          set isSubmit [expr {$buttontype eq "reset"}]
        } else {
          return
        }
      }
      input.button {
        set control [::hv3::clickcontrol %AUTO% $node]
        set myClickControls($node) $control
      }
      input.hidden {
        set control [::hv3::clickcontrol %AUTO% $node]
        set myClickControls($node) $control
      }
      input.checkbox {
        set hv3 [winfo parent [winfo parent $myHtml]]
        set control [::hv3::forms::checkbox $zWinPath $node $hv3]
      }
      input.radio {
        set hv3 [winfo parent [winfo parent $myHtml]]
        set control [::hv3::forms::radio $zWinPath $node $hv3]
      }
      input.file {
        set hv3 [winfo parent [winfo parent $myHtml]]
        set control [::hv3::forms::fileselect $zWinPath $node $hv3]
      }

      default {
        # This includes <INPUT type="password">, <INPUT type="text"> and
        # any unrecognized value for the type attribute.
        #
        set hv3 [winfo parent [winfo parent $myHtml]]
        set control [::hv3::::forms::entrycontrol $zWinPath $node $hv3]
      }
    }

    $self SetupKeyBindings $control $node

    if {[info exists myClickControls($node)]} {
      set deletecmd [list $control destroy]
    } else {
      set deletecmd [list destroy $control]
    }
    $node replace $control                         \
        -configurecmd [list $control configurecmd] \
        -stylecmd     [list $control stylecmd]     \
        -deletecmd    $deletecmd

  }

  destructor {
    $self reset
  }

  method reset {} {
    array unset myClickControls
  }

  method dumpforms {} {
    foreach node [$myHv3 html search form] {
      set form [$node replace]
      puts [$form dump]
    }
  }

  method clickhandler {node} {
    if {[info exists myClickControls($node)]} {
      $myClickControls($node) click 0
    }
  }
}

#-----------------------------------------------------------------------
# ::hv3::formsreport
#
#     This proc is called by the tree-browser code to obtain the HTML
#     text for the "HTML Forms" tab. If the argument $node is a <FORM>
#     node, or a node that generates a form control, a report is
#     returned explaining that nodes role in the HTML form.
#
#     Otherwise, a message is returned to say that the forms module
#     doesn't care two figs for node $node.
# 
proc ::hv3::formsreport {node} {

  # Never return a report for a text node.
  if {[$node tag] eq ""} return

  # If the [replace] object for the node exists and is of
  # one of the following classes, then we have a forms object!
  # The following classes all support the [formsreport] method
  # to return the report body.
  #
  set FORMS_CLASSES [list    \
      ::hv3::clickcontrol    \
      ::hv3::form            \
  ]

  set CONTROL_CLASSES [list      \
      ::hv3::forms::checkbox     \
      ::hv3::forms::entrycontrol \
      ::hv3::forms::select       \
      ::hv3::forms::textarea     \
      ::hv3::forms::fileselect   \
      ::hv3::forms::radio        \
  ]

  set R [$node replace]
  set rc [catch { set T [$R info type] } msg]

  if {$rc == 0} {
    if {[lsearch $CONTROL_CLASSES $T] >= 0} {
      set formnode [::hv3::control_to_form $node]
      if {$formnode eq ""} {
        set formnode "none"
      } else {
        set formnode "<A href=\"$formnode\">$formnode</A>"
      }
  
      return [subst {
        <TABLE>
          <TR><TH>Tcl (snit) class <TD>$T
          <TR><TH>Form node        <TD>$formnode
        </TABLE>
      }]
    }
  
    if {[lsearch $FORMS_CLASSES $T] >= 0} {
      return [$R formsreport]
    }
  }

  return {<i>No forms engine handling for this node</i>}
}

#-----------------------------------------------------------------------
# ::hv3::isindex_handler
#
#     This proc is registered as a Tkhtml script-handler for <isindex> 
#     elements. An <isindex> element is essentially an entire form
#     in and of itself.
#
#     Example from HTML 4.01:
#         The following ISINDEX declaration: 
#
#              <ISINDEX prompt="Enter your search phrase: "> 
#
#         could be rewritten with INPUT as follows: 
#
#              <FORM action="..." method="post">
#                  <P> Enter your search phrase:<INPUT type="text"> </P>
#              </FORM>
#
proc ::hv3::isindex_handler {hv3 attr script} {
  set a(prompt) ""
  array set a $attr

  set loc [::tkhtml::uri [$hv3 location]]
  set LOCATION "[$loc scheme]://[$loc authority][$loc path]"
  set PROMPT   $a(prompt)
  $loc destroy

  $hv3 write text [subst {
    <hr>
    <form action="$LOCATION" method="ISINDEX">
      <p>
        $PROMPT
        <input type="text">
      </p>
    </form>
    <hr>
  }]
}

namespace eval hv3 { set {version($Id: hv3_request.tcl,v 1.28 2008/02/03 06:29:39 danielk1977 Exp $)} 1 }

#--------------------------------------------------------------------------
# This file contains the implementation of two types used by hv3:
#
#     ::hv3::request
#

#--------------------------------------------------------------------------
# Class ::hv3::request
#
#     Instances of this class are used to interface between the protocol
#     implementation and the hv3 widget.
#
# OVERVIEW:
#
# HOW CHARSETS ARE HANDLED:
#
#     The protocol implementation (the thing that calls [$download append] 
#     and [$download finish]) passes binary data to this object. This
#     object converts the binary data to utf-8 text, based on the encoding
#     assigned to the request. An encoding may be assigned either by an
#     http header or a <meta> tag.
#
#     Assuming the source of the data is http (or https), then the
#     encoding may be specified by way of a Content-Type HTTP header.
#     In this case, when the protocol configures the -header option
#     (which it does before calling [append] for the first time) the 
#     -encoding option will be automatically set.
#
#
# OPTIONS:
#
#     The following options are set only by the requestor (the Hv3 widget)
#     for the protocol to use as request parameters:
#
#       -cachecontrol
#       -uri
#       -postdata
#       -requestheader
#       -enctype
#       -encoding
#
#     This is set by the requestor also to show the origin of the request:
#
#       -hv3
#
#     These are set by the requestor before the request is made to 
#     configure callbacks invoked by this object when requested data 
#     is available:
#    
#       -incrscript
#       -finscript
#
#     This is initially set by the requestor. It may be modified by the
#     protocol implementation before the first invocation of -incrscript
#     or -finscript is made.
#
#       -mimetype
#
#     The protocol implementation also sets:
#
#       -header
#       -expectedsize
#
# METHODS:
#
#     Methods used by the protocol implementation:
#
#         append DATA
#         finish
#         fail
#         authority         (return the authority part of the -uri option)
#
#     finish_hook SCRIPT
#         Configure the object with a script to be invoked just before
#         the object is about to be destroyed. If more than one of
#         these is configured, then the scripts are called in the
#         same order as they are configured in (i.e. most recently
#         configured is invoked last).
#
#     reference
#     release
#
#     data
#     encoding
#

namespace eval ::hv3::request {

  proc new {me args} {

    upvar $me O

    # The requestor (i.e. the creator of the ::hv3::request object) sets the
    # following configuration options. The protocol implementation may set the
    # -mimetype option before returning.
    #
    # The -cachecontrol option may be set to the following values:
    #
    #     * normal             (try to be clever about caching)
    #     * no-cache           (never return cached resources)
    #     * relax-transparency (return cached resources even if stale)
    #
    set O(-cachecontrol) normal
    set O(-uri) ""
    set O(-postdata) ""
    set O(-mimetype) ""
    set O(-enctype) ""

    set O(-cacheable) 0

    # The hv3 widget that issued this request. This is used
    # (a) to notify destruction of root request,
    # (b) by the handler for home:// uris and
    # (c) to call [$myHtml reset] in restartCallback.
    #
    set O(-hv3) ""

    # The protocol implementation sets this option to contain the 
    # HTTP header (or it's equivalent). The format is a serialised array.
    # Example:
    # 
    #     {Set-Cookie safe-search=on Location http://www.google.com}
    #
    # The following http-header types are handled locally by the 
    # configure-header method, as soon as the -header option is set:
    #
    #     Set-Cookie         (Call ::hv3::the_cookie_manager method)
    #     Content-Type       (Set the -mimetype option)
    #     Content-Length     (Set the -expectedsize option)
    #
    set O(-header) ""
  
    set O(-requestheader) ""
  
    # Expected size of the resource being requested. This is used
    # for displaying a progress bar when saving remote resources
    # to the local filesystem (aka downloadin').
    #
    set O(-expectedsize) ""
  
    # Callbacks configured by the requestor.
    #
    set O(-incrscript) ""
    set O(-finscript) ""
  
    # This -encoding option is used to specify explicit conversion of
    # incoming http/file data.
    # When this option is set, [http::geturl -binary] is used.
    # Then [$self append] will call [encoding convertfrom].
    #
    # See also [encoding] and [suggestedEncoding] methods.
    #
    set O(-encoding) ""
  
    # True if the -encoding option has been set by the transport layer. 
    # If this is true, then any encoding specified via a <meta> element
    # in the main document is ignored.
    #
    set O(-hastransportencoding) 0

    # END OF OPTIONS
    #----------------------------

    set O(chunksize) 2048
  
    # The binary data returned by the protocol implementation is 
    # accumulated in this variable.
    set O(myRaw) {}
    set O(myRawMode) 0
  
    # If this variable is non-zero, then the first $myRawPos bytes of
    # $myRaw have already been passed to Hv3 via the -incrscript 
    # callback.
    set O(myRawPos) 0
  
    # These objects are referenced counted. Initially the reference count
    # is 1. It is increased by calls to the [reference] method and decreased
    # by the [release] method. The object is deleted when the ref-count 
    # reaches zero.
    set O(myRefCount) 1
  
    set O(myIsText) 1; # Whether mimetype is text/* or not.
  
    # Make sure finish is processed only once.
    set O(myIsFinished) 0
  
    # Destroy-hook scripts configured using the [finish_hook] method.
    set O(myFinishHookList) [list]

    set O(myDestroying) 0

    eval configure $me $args
  }

  proc destroy {me} {
    upvar $me O
    set O(myDestroying) 1
    foreach hook $O(myFinishHookList) {
      eval $hook 
    }
    rename $me {}
    array unset $me
  }

  proc data {me} {
    upvar $me O
    set raw [string range $O(myRaw) 0 [expr {$O(myRawPos)-1}]]
    if {$O(myIsText)} {
      return [::encoding convertfrom [encoding $me] $raw]
    }
    return $raw
  }
  proc rawdata {me} {
    upvar $me O
    return $O(myRaw)
  }
  proc set_rawmode {me} {
    upvar $me O
    set O(myRawMode) 1
    set O(myRaw) ""
  }

  # Increment the object refcount.
  #
  proc reference {me} {
    upvar $me O
    incr O(myRefCount)
  }

  # Decrement the object refcount.
  #
  proc release {me} {
    upvar $me O
    incr O(myRefCount) -1
    if {$O(myRefCount) == 0} {
      $me destroy
    }
  }

  # Add a script to be called just before the object is destroyed. See
  # description above.
  #
  proc finish_hook {me script} {
    upvar $me O
    lappend O(myFinishHookList) $script
  }

  # This method is called each time the -header option is set. This
  # is where the locally handled HTTP headers (see comments above the
  # -header option) are handled.
  #
  proc configure-header {me} {
    upvar $me O
    foreach {name value} $O(-header) {
      switch -- [string tolower $name] {
        set-cookie {
          catch {
            ::hv3::the_cookie_manager SetCookie $O(-uri) $value
          }
        }
        content-type {
          set parsed [hv3::string::parseContentType $value]
          foreach {major minor charset} $parsed break
          set O(-mimetype) $major/$minor
          if {$charset ne ""} {
            set O(-hastransportencoding) 1
            set O(-encoding) [::hv3::encoding_resolve $charset]
          }
        }
        content-length {
          set O(-expectedsize) $value
        }
      }
    }
  }

  proc configure-mimetype {me} {
    upvar $me O
    set O(myIsText) [string match text* $O(-mimetype)]
  }

  proc configure-encoding {me} {
    upvar $me O
    set O(-encoding) [::hv3::encoding_resolve $O(-encoding)]
  }

  # Return the "authority" part of the URI configured as the -uri option.
  #
  proc authority {me} {
    upvar $me O
    set obj [::tkhtml::uri $O(-uri)]
    set authority [$obj authority]
    $obj destroy
    return $authority
  }

  # Interface for returning data.
  proc append {me raw} {
    upvar $me O

    if {$O(myDestroying)} {return}
    if {$O(myRawMode)} {
      eval [linsert $O(-incrscript) end $raw]
      return
    }

    ::append O(myRaw) $raw

    if {$O(-incrscript) != ""} {
      # There is an -incrscript callback configured. If enough data is 
      # available, invoke it.

      set nLast 0
      foreach zWhite [list " " "\n" "\t"] {
        set n [string last $zWhite $O(myRaw)]
        if {$n>$nLast} {set nLast $n ; break}
      }
      set nAvailable [expr {$nLast-$O(myRawPos)}]
      if {$nAvailable > $O(chunksize)} {

        set zDecoded [string range $O(myRaw) $O(myRawPos) $nLast]
        if {$O(myIsText)} {
          set zDecoded [::encoding convertfrom [encoding $me] $zDecoded]
        }
        set O(myRawPos) [expr {$nLast+1}]
        if {$O(chunksize) < 30000} {
          set O(chunksize) [expr $O(chunksize) * 2]
        }

        eval [linsert $O(-incrscript) end $zDecoded] 
      }
    }
  }

  # Called after all data has been passed to [append].
  #
  proc finish {me {raw ""}} {
    upvar $me O

    if {$O(myDestroying)} {return}
    if {$O(myIsFinished)} {error "finish called twice on $me"}
    set O(myIsFinished) 1

    if {$O(myRawMode)} {
      foreach hook $O(myFinishHookList) {
        eval $hook
      }
      eval [linsert $O(-finscript) end $raw]
      return
    }

    ::append O(myRaw) $raw

    set zDecoded [string range $O(myRaw) $O(myRawPos) end]
    if {$O(myIsText)} {
      set zDecoded [::encoding convertfrom [encoding $me] $zDecoded]
    }

    foreach hook $O(myFinishHookList) {
      eval $hook
    }
    set O(myFinishHookList) [list]
    set O(myRawPos) [string length $O(myRaw)]
    eval [linsert $O(-finscript) end $zDecoded] 
  }

  proc isFinished {me} {
    upvar $me O
    set O(myIsFinished)
  }

  proc fail {me} {
    upvar $me O
    # TODO: Need to do something here...
    puts FAIL
  }

  proc encoding {me} {
    upvar $me O
    set ret $O(-encoding)
    if {$ret eq ""} {set ret [::encoding system]}
    return $ret
  }
}

::hv3::make_constructor ::hv3::request

# Copyright (c) 1998-2003, Bryan Oakley
# All Rights Reservered
#
# Bryan Oakley
# oakley@bardo.clearlight.com
#
# combobox v2.3 August 16, 2003
#
# a combobox / dropdown listbox (pick your favorite name) widget 
# written in pure tcl
#
# this code is freely distributable without restriction, but is 
# provided as-is with no warranty expressed or implied. 
#
# thanks to the following people who provided beta test support or
# patches to the code (in no particular order):
#
# Scott Beasley     Alexandre Ferrieux      Todd Helfter
# Matt Gushee       Laurent Duperval        John Jackson
# Fred Rapp         Christopher Nelson
# Eric Galluzzo     Jean-Francois Moine	    Oliver Bienert
#
# A special thanks to Martin M. Hunt who provided several good ideas, 
# and always with a patch to implement them. Jean-Francois Moine, 
# Todd Helfter and John Jackson were also kind enough to send in some 
# code patches.
#
# ... and many others over the years.

package require Tk 8.0
package provide combobox 2.3

namespace eval ::combobox {

    # this is the public interface
    namespace export combobox

    # these contain references to available options
    variable widgetOptions

    # these contain references to available commands and subcommands
    variable widgetCommands
    variable scanCommands
    variable listCommands
}

# ::combobox::combobox --
#
#     This is the command that gets exported. It creates a new
#     combobox widget.
#
# Arguments:
#
#     w        path of new widget to create
#     args     additional option/value pairs (eg: -background white, etc.)
#
# Results:
#
#     It creates the widget and sets up all of the default bindings
#
# Returns:
#
#     The name of the newly create widget

proc ::combobox::combobox {w args} {
    variable widgetOptions
    variable widgetCommands
    variable scanCommands
    variable listCommands

    # perform a one time initialization
    if {![info exists widgetOptions]} {
	Init
    }

    # build it...
    eval Build $w $args

    # set some bindings...
    SetBindings $w

    # and we are done!
    return $w
}


# ::combobox::Init --
#
#     Initialize the namespace variables. This should only be called
#     once, immediately prior to creating the first instance of the
#     widget
#
# Arguments:
#
#    none
#
# Results:
#
#     All state variables are set to their default values; all of 
#     the option database entries will exist.
#
# Returns:
# 
#     empty string

proc ::combobox::Init {} {
    variable widgetOptions
    variable widgetCommands
    variable scanCommands
    variable listCommands
    variable defaultEntryCursor

    array set widgetOptions [list \
	    -background          {background          Background} \
	    -bd                  -borderwidth \
	    -bg                  -background \
	    -borderwidth         {borderWidth         BorderWidth} \
	    -buttonbackground    {buttonBackground    Background} \
	    -command             {command             Command} \
	    -commandstate        {commandState        State} \
	    -cursor              {cursor              Cursor} \
	    -disabledbackground  {disabledBackground  DisabledBackground} \
	    -disabledforeground  {disabledForeground  DisabledForeground} \
            -dropdownwidth       {dropdownWidth       DropdownWidth} \
	    -editable            {editable            Editable} \
	    -elementborderwidth  {elementBorderWidth  BorderWidth} \
	    -fg                  -foreground \
	    -font                {font                Font} \
	    -foreground          {foreground          Foreground} \
	    -height              {height              Height} \
	    -highlightbackground {highlightBackground HighlightBackground} \
	    -highlightcolor      {highlightColor      HighlightColor} \
	    -highlightthickness  {highlightThickness  HighlightThickness} \
	    -image               {image               Image} \
	    -listvar             {listVariable        Variable} \
	    -maxheight           {maxHeight           Height} \
	    -opencommand         {opencommand         Command} \
	    -relief              {relief              Relief} \
	    -selectbackground    {selectBackground    Foreground} \
	    -selectborderwidth   {selectBorderWidth   BorderWidth} \
	    -selectforeground    {selectForeground    Background} \
	    -state               {state               State} \
	    -takefocus           {takeFocus           TakeFocus} \
	    -textvariable        {textVariable        Variable} \
	    -value               {value               Value} \
	    -width               {width               Width} \
	    -xscrollcommand      {xScrollCommand      ScrollCommand} \
    ]


    set widgetCommands [list \
	    bbox      cget     configure    curselection \
	    delete    get      icursor      index        \
	    insert    list     scan         selection    \
	    xview     select   toggle       open         \
            close    subwidget  \
    ]

    set listCommands [list \
	    delete       get      \
            index        insert       size \
    ]

    set scanCommands [list mark dragto]

    # why check for the Tk package? This lets us be sourced into 
    # an interpreter that doesn't have Tk loaded, such as the slave
    # interpreter used by pkg_mkIndex. In theory it should have no
    # side effects when run 
    if {[lsearch -exact [package names] "Tk"] != -1} {

	##################################################################
	#- this initializes the option database. Kinda gross, but it works
	#- (I think). 
	##################################################################

	# the image used for the button...
	if {$::tcl_platform(platform) == "windows"} {
	    image create bitmap ::combobox::bimage -data {
		#define down_arrow_width 12
		#define down_arrow_height 12
		static char down_arrow_bits[] = {
		    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
		    0xfc,0xf1,0xf8,0xf0,0x70,0xf0,0x20,0xf0,
		    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
		}
	    }
	} else {
	    image create bitmap ::combobox::bimage -data  {
		#define down_arrow_width 15
		#define down_arrow_height 15
		static char down_arrow_bits[] = {
		    0x00,0x80,0x00,0x80,0x00,0x80,0x00,0x80,
		    0x00,0x80,0xf8,0x8f,0xf0,0x87,0xe0,0x83,
		    0xc0,0x81,0x80,0x80,0x00,0x80,0x00,0x80,
		    0x00,0x80,0x00,0x80,0x00,0x80
		}
	    }
	}

	# compute a widget name we can use to create a temporary widget
	set tmpWidget ".__tmp__"
	set count 0
	while {[winfo exists $tmpWidget] == 1} {
	    set tmpWidget ".__tmp__$count"
	    incr count
	}

	# get the scrollbar width. Because we try to be clever and draw our
	# own button instead of using a tk widget, we need to know what size
	# button to create. This little hack tells us the width of a scroll
	# bar.
	#
	# NB: we need to be sure and pick a window  that doesn't already
	# exist... 
	scrollbar $tmpWidget
	set sb_width [winfo reqwidth $tmpWidget]
	set bbg [$tmpWidget cget -background]
	destroy $tmpWidget

	# steal options from the entry widget
	# we want darn near all options, so we'll go ahead and do
	# them all. No harm done in adding the one or two that we
	# don't use.
	entry $tmpWidget 
	foreach foo [$tmpWidget configure] {
	    # the cursor option is special, so we'll save it in
	    # a special way
	    if {[lindex $foo 0] == "-cursor"} {
		set defaultEntryCursor [lindex $foo 4]
	    }
	    if {[llength $foo] == 5} {
		set option [lindex $foo 1]
		set value [lindex $foo 4]
		option add *Combobox.$option $value widgetDefault

		# these options also apply to the dropdown listbox
		if {[string compare $option "foreground"] == 0 \
			|| [string compare $option "background"] == 0 \
			|| [string compare $option "font"] == 0} {
		    option add *Combobox*ComboboxListbox.$option $value \
			    widgetDefault
		}
	    }
	}
	destroy $tmpWidget

	# these are unique to us...
	option add *Combobox.elementBorderWidth  1	widgetDefault
	option add *Combobox.buttonBackground    $bbg	widgetDefault
	option add *Combobox.dropdownWidth       {}     widgetDefault
	option add *Combobox.openCommand         {}     widgetDefault
	option add *Combobox.cursor              {}     widgetDefault
	option add *Combobox.commandState        normal widgetDefault
	option add *Combobox.editable            1      widgetDefault
	option add *Combobox.maxHeight           10     widgetDefault
	option add *Combobox.height              0
    }

    # set class bindings
    SetClassBindings
}

# ::combobox::SetClassBindings --
#
#    Sets up the default bindings for the widget class
#
#    this proc exists since it's The Right Thing To Do, but
#    I haven't had the time to figure out how to do all the
#    binding stuff on a class level. The main problem is that
#    the entry widget must have focus for the insertion cursor
#    to be visible. So, I either have to have the entry widget
#    have the Combobox bindtag, or do some fancy juggling of
#    events or some such. What a pain.
#
# Arguments:
#
#    none
#
# Returns:
#
#    empty string

proc ::combobox::SetClassBindings {} {

    # make sure we clean up after ourselves...
    bind Combobox <Destroy> [list ::combobox::DestroyHandler %W]

    # this will (hopefully) close (and lose the grab on) the
    # listbox if the user clicks anywhere outside of it. Note
    # that on Windows, you can click on some other app and
    # the listbox will still be there, because tcl won't see
    # that button click
    set this {[::combobox::convert %W -W]}
    bind Combobox <Any-ButtonPress>   "$this close"
    bind Combobox <Any-ButtonRelease> "$this close"

    # this helps (but doesn't fully solve) focus issues. The general
    # idea is, whenever the frame gets focus it gets passed on to
    # the entry widget
    bind Combobox <FocusIn> {::combobox::tkTabToWindow \
				 [::combobox::convert %W -W].entry}

    # this closes the listbox if we get hidden
    bind Combobox <Unmap> {[::combobox::convert %W -W] close}

    return ""
}

# ::combobox::SetBindings --
#
#    here's where we do most of the binding foo. I think there's probably
#    a few bindings I ought to add that I just haven't thought
#    about...
#
#    I'm not convinced these are the proper bindings. Ideally all
#    bindings should be on "Combobox", but because of my juggling of
#    bindtags I'm not convinced thats what I want to do. But, it all
#    seems to work, its just not as robust as it could be.
#
# Arguments:
#
#    w    widget pathname
#
# Returns:
#
#    empty string

proc ::combobox::SetBindings {w} {
    upvar ::combobox::${w}::widgets  widgets
    upvar ::combobox::${w}::options  options

    # juggle the bindtags. The basic idea here is to associate the
    # widget name with the entry widget, so if a user does a bind
    # on the combobox it will get handled properly since it is
    # the entry widget that has keyboard focus.
    bindtags $widgets(entry) \
	    [concat $widgets(this) [bindtags $widgets(entry)]]

    bindtags $widgets(button) \
	    [concat $widgets(this) [bindtags $widgets(button)]]

    # override the default bindings for tab and shift-tab. The
    # focus procs take a widget as their only parameter and we
    # want to make sure the right window gets used (for shift-
    # tab we want it to appear as if the event was generated
    # on the frame rather than the entry. 
    bind $widgets(entry) <Tab> \
	    "::combobox::tkTabToWindow \[tk_focusNext $widgets(entry)\]; break"
    bind $widgets(entry) <Shift-Tab> \
	    "::combobox::tkTabToWindow \[tk_focusPrev $widgets(this)\]; break"
    
    # this makes our "button" (which is actually a label)
    # do the right thing
    bind $widgets(button) <ButtonPress-1> [list $widgets(this) toggle]

    # this lets the autoscan of the listbox work, even if they
    # move the cursor over the entry widget.
    bind $widgets(entry) <B1-Enter> "break"

    bind $widgets(listbox) <ButtonRelease-1> \
        "::combobox::Select [list $widgets(this)] \
         \[$widgets(listbox) nearest %y\]; break"

    bind $widgets(vsb) <ButtonPress-1>   {continue}
    bind $widgets(vsb) <ButtonRelease-1> {continue}

    bind $widgets(listbox) <Any-Motion> {
	%W selection clear 0 end
	%W activate @%x,%y
	%W selection anchor @%x,%y
	%W selection set @%x,%y @%x,%y
	# need to do a yview if the cursor goes off the top
	# or bottom of the window... (or do we?)
    }

    # these events need to be passed from the entry widget
    # to the listbox, or otherwise need some sort of special
    # handling. 
    foreach event [list <Up> <Down> <Tab> <Return> <Escape> \
	    <Next> <Prior> <Double-1> <1> <Any-KeyPress> \
	    <FocusIn> <FocusOut>] {
	bind $widgets(entry) $event \
            [list ::combobox::HandleEvent $widgets(this) $event]
    }

    # like the other events, <MouseWheel> needs to be passed from
    # the entry widget to the listbox. However, in this case we
    # need to add an additional parameter
    catch {
	bind $widgets(entry) <MouseWheel> \
	    [list ::combobox::HandleEvent $widgets(this) <MouseWheel> %D]
    }
}

# ::combobox::Build --
#
#    This does all of the work necessary to create the basic
#    combobox. 
#
# Arguments:
#
#    w        widget name
#    args     additional option/value pairs
#
# Results:
#
#    Creates a new widget with the given name. Also creates a new
#    namespace patterened after the widget name, as a child namespace
#    to ::combobox
#
# Returns:
#
#    the name of the widget

proc ::combobox::Build {w args } {
    variable widgetOptions

    if {[winfo exists $w]} {
	error "window name \"$w\" already exists"
    }

    # create the namespace for this instance, and define a few
    # variables
    namespace eval ::combobox::$w {

	variable ignoreTrace 0
	variable oldFocus    {}
	variable oldGrab     {}
	variable oldValue    {}
	variable options
	variable this
	variable widgets

	set widgets(foo) foo  ;# coerce into an array
	set options(foo) foo  ;# coerce into an array

	unset widgets(foo)
	unset options(foo)
    }

    # import the widgets and options arrays into this proc so
    # we don't have to use fully qualified names, which is a
    # pain.
    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options

    # this is our widget -- a frame of class Combobox. Naturally,
    # it will contain other widgets. We create it here because
    # we need it in order to set some default options.
    set widgets(this)   [frame  $w -class Combobox -takefocus 0]
    set widgets(entry)  [entry  $w.entry -takefocus 1]
    set widgets(button) [label  $w.button -takefocus 0] 

    # this defines all of the default options. We get the
    # values from the option database. Note that if an array
    # value is a list of length one it is an alias to another
    # option, so we just ignore it
    foreach name [array names widgetOptions] {
	if {[llength $widgetOptions($name)] == 1} continue

	set optName  [lindex $widgetOptions($name) 0]
	set optClass [lindex $widgetOptions($name) 1]

	set value [option get $w $optName $optClass]
	set options($name) $value
    }

    # a couple options aren't available in earlier versions of
    # tcl, so we'll set them to sane values. For that matter, if
    # they exist but are empty, set them to sane values.
    if {[string length $options(-disabledforeground)] == 0} {
        set options(-disabledforeground) $options(-foreground)
    }
    if {[string length $options(-disabledbackground)] == 0} {
        set options(-disabledbackground) $options(-background)
    }

    # if -value is set to null, we'll remove it from our
    # local array. The assumption is, if the user sets it from
    # the option database, they will set it to something other
    # than null (since it's impossible to determine the difference
    # between a null value and no value at all).
    if {[info exists options(-value)] \
	    && [string length $options(-value)] == 0} {
	unset options(-value)
    }

    # we will later rename the frame's widget proc to be our
    # own custom widget proc. We need to keep track of this
    # new name, so we'll define and store it here...
    set widgets(frame) ::combobox::${w}::$w

    # gotta do this sooner or later. Might as well do it now
    pack $widgets(button) -side right -fill y    -expand no
    pack $widgets(entry)  -side left  -fill both -expand yes

    # I should probably do this in a catch, but for now it's
    # good enough... What it does, obviously, is put all of
    # the option/values pairs into an array. Make them easier
    # to handle later on...
    array set options $args

    # now, the dropdown list... the same renaming nonsense
    # must go on here as well...
    set widgets(dropdown)   [toplevel  $w.top]
    set widgets(listbox) [listbox   $w.top.list]
    set widgets(vsb)     [scrollbar $w.top.vsb]

    pack $widgets(listbox) -side left -fill both -expand y

    # fine tune the widgets based on the options (and a few
    # arbitrary values...)

    # NB: we are going to use the frame to handle the relief
    # of the widget as a whole, so the entry widget will be 
    # flat. This makes the button which drops down the list
    # to appear "inside" the entry widget.

    $widgets(vsb) configure \
	    -borderwidth 1 \
	    -command "$widgets(listbox) yview" \
	    -highlightthickness 0

    $widgets(button) configure \
	    -background $options(-buttonbackground) \
	    -highlightthickness 0 \
	    -borderwidth $options(-elementborderwidth) \
	    -relief raised \
	    -width [expr {[winfo reqwidth $widgets(vsb)] - 2}]

    $widgets(entry) configure \
	    -borderwidth 0 \
	    -relief flat \
	    -highlightthickness 0 

    $widgets(dropdown) configure \
	    -borderwidth $options(-elementborderwidth) \
	    -relief sunken

    $widgets(listbox) configure \
	    -selectmode browse \
	    -background [$widgets(entry) cget -bg] \
	    -yscrollcommand "$widgets(vsb) set" \
	    -exportselection false \
	    -borderwidth 0


#    trace variable ::combobox::${w}::entryTextVariable w \
#	    [list ::combobox::EntryTrace $w]
	
    # do some window management foo on the dropdown window
    wm overrideredirect $widgets(dropdown) 1
    wm transient        $widgets(dropdown) [winfo toplevel $w]
    wm group            $widgets(dropdown) [winfo parent $w]
    wm resizable        $widgets(dropdown) 0 0
    wm withdraw         $widgets(dropdown)
    
    # this moves the original frame widget proc into our
    # namespace and gives it a handy name
    rename ::$w $widgets(frame)

    # now, create our widget proc. Obviously (?) it goes in
    # the global namespace. All combobox widgets will actually
    # share the same widget proc to cut down on the amount of
    # bloat. 
    proc ::$w {command args} \
        "eval ::combobox::WidgetProc $w \$command \$args"


    # ok, the thing exists... let's do a bit more configuration. 
    if {[catch "::combobox::Configure [list $widgets(this)] [array get options]" error]} {
	catch {destroy $w}
	error "internal error: $error"
    }

    return ""

}

# ::combobox::HandleEvent --
#
#    this proc handles events from the entry widget that we want
#    handled specially (typically, to allow navigation of the list
#    even though the focus is in the entry widget)
#
# Arguments:
#
#    w       widget pathname
#    event   a string representing the event (not necessarily an
#            actual event)
#    args    additional arguments required by particular events

proc ::combobox::HandleEvent {w event args} {
    upvar ::combobox::${w}::widgets  widgets
    upvar ::combobox::${w}::options  options
    upvar ::combobox::${w}::oldValue oldValue

    # for all of these events, if we have a special action we'll
    # do that and do a "return -code break" to keep additional 
    # bindings from firing. Otherwise we'll let the event fall
    # on through. 
    switch $event {

        "<MouseWheel>" {
	    if {[winfo ismapped $widgets(dropdown)]} {
                set D [lindex $args 0]
                # the '120' number in the following expression has
                # it's genesis in the tk bind manpage, which suggests
                # that the smallest value of %D for mousewheel events
                # will be 120. The intent is to scroll one line at a time.
                $widgets(listbox) yview scroll [expr {-($D/120)}] units
            }
        } 

	"<Any-KeyPress>" {
	    # if the widget is editable, clear the selection. 
	    # this makes it more obvious what will happen if the 
	    # user presses <Return> (and helps our code know what
	    # to do if the user presses return)
	    if {$options(-editable)} {
		$widgets(listbox) see 0
		$widgets(listbox) selection clear 0 end
		$widgets(listbox) selection anchor 0
		$widgets(listbox) activate 0
	    }
	}

	"<FocusIn>" {
	    set oldValue [$widgets(entry) get]
	}

	"<FocusOut>" {
	    if {![winfo ismapped $widgets(dropdown)]} {
		# did the value change?
		set newValue [$widgets(entry) get]
		if {$oldValue != $newValue} {
		    CallCommand $widgets(this) $newValue
		}
	    }
	}

	"<1>" {
	    set editable [::combobox::GetBoolean $options(-editable)]
	    if {!$editable} {
		if {[winfo ismapped $widgets(dropdown)]} {
		    $widgets(this) close
		    return -code break;

		} else {
		    if {$options(-state) != "disabled"} {
			$widgets(this) open
			return -code break;
		    }
		}
	    }
	}

	"<Double-1>" {
	    if {$options(-state) != "disabled"} {
		$widgets(this) toggle
		return -code break;
	    }
	}

	"<Tab>" {
	    if {[winfo ismapped $widgets(dropdown)]} {
		::combobox::Find $widgets(this) 0
		return -code break;
	    } else {
		::combobox::SetValue $widgets(this) [$widgets(this) get]
	    }
	}

	"<Escape>" {
#	    $widgets(entry) delete 0 end
#	    $widgets(entry) insert 0 $oldValue
	    if {[winfo ismapped $widgets(dropdown)]} {
		$widgets(this) close
		return -code break;
	    }
	}

	"<Return>" {
	    # did the value change?
	    set newValue [$widgets(entry) get]
	    if {$oldValue != $newValue} {
		CallCommand $widgets(this) $newValue
	    }

	    if {[winfo ismapped $widgets(dropdown)]} {
		::combobox::Select $widgets(this) \
			[$widgets(listbox) curselection]
		return -code break;
	    } 

	}

	"<Next>" {
	    $widgets(listbox) yview scroll 1 pages
	    set index [$widgets(listbox) index @0,0]
	    $widgets(listbox) see $index
	    $widgets(listbox) activate $index
	    $widgets(listbox) selection clear 0 end
	    $widgets(listbox) selection anchor $index
	    $widgets(listbox) selection set $index

	}

	"<Prior>" {
	    $widgets(listbox) yview scroll -1 pages
	    set index [$widgets(listbox) index @0,0]
	    $widgets(listbox) activate $index
	    $widgets(listbox) see $index
	    $widgets(listbox) selection clear 0 end
	    $widgets(listbox) selection anchor $index
	    $widgets(listbox) selection set $index
	}

	"<Down>" {
	    if {[winfo ismapped $widgets(dropdown)]} {
		::combobox::tkListboxUpDown $widgets(listbox) 1
		return -code break;

	    } else {
		if {$options(-state) != "disabled"} {
		    $widgets(this) open
		    return -code break;
		}
	    }
	}
	"<Up>" {
	    if {[winfo ismapped $widgets(dropdown)]} {
		::combobox::tkListboxUpDown $widgets(listbox) -1
		return -code break;

	    } else {
		if {$options(-state) != "disabled"} {
		    $widgets(this) open
		    return -code break;
		}
	    }
	}
    }

    return ""
}

# ::combobox::DestroyHandler {w} --
# 
#    Cleans up after a combobox widget is destroyed
#
# Arguments:
#
#    w    widget pathname
#
# Results:
#
#    The namespace that was created for the widget is deleted,
#    and the widget proc is removed.

proc ::combobox::DestroyHandler {w} {

    catch {
	# if the widget actually being destroyed is of class Combobox,
	# remove the namespace and associated proc.
	if {[string compare [winfo class $w] "Combobox"] == 0} {
	    # delete the namespace and the proc which represents
	    # our widget
	    namespace delete ::combobox::$w
	    rename $w {}
	}   
    }
    return ""
}

# ::combobox::Find
#
#    finds something in the listbox that matches the pattern in the
#    entry widget and selects it
#
#    N.B. I'm not convinced this is working the way it ought to. It
#    works, but is the behavior what is expected? I've also got a gut
#    feeling that there's a better way to do this, but I'm too lazy to
#    figure it out...
#
# Arguments:
#
#    w      widget pathname
#    exact  boolean; if true an exact match is desired
#
# Returns:
#
#    Empty string

proc ::combobox::Find {w {exact 0}} {
    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options

    ## *sigh* this logic is rather gross and convoluted. Surely
    ## there is a more simple, straight-forward way to implement
    ## all this. As the saying goes, I lack the time to make it
    ## shorter...

    # use what is already in the entry widget as a pattern
    set pattern [$widgets(entry) get]

    if {[string length $pattern] == 0} {
	# clear the current selection
	$widgets(listbox) see 0
	$widgets(listbox) selection clear 0 end
	$widgets(listbox) selection anchor 0
	$widgets(listbox) activate 0
	return
    }

    # we're going to be searching this list...
    set list [$widgets(listbox) get 0 end]

    # if we are doing an exact match, try to find,
    # well, an exact match
    set exactMatch -1
    if {$exact} {
	set exactMatch [lsearch -exact $list $pattern]
    }

    # search for it. We'll try to be clever and not only
    # search for a match for what they typed, but a match for
    # something close to what they typed. We'll keep removing one
    # character at a time from the pattern until we find a match
    # of some sort.
    set index -1
    while {$index == -1 && [string length $pattern]} {
	set index [lsearch -glob $list "$pattern*"]
	if {$index == -1} {
	    regsub {.$} $pattern {} pattern
	}
    }

    # this is the item that most closely matches...
    set thisItem [lindex $list $index]

    # did we find a match? If so, do some additional munging...
    if {$index != -1} {

	# we need to find the part of the first item that is 
	# unique WRT the second... I know there's probably a
	# simpler way to do this... 

	set nextIndex [expr {$index + 1}]
	set nextItem [lindex $list $nextIndex]

	# we don't really need to do much if the next
	# item doesn't match our pattern...
	if {[string match $pattern* $nextItem]} {
	    # ok, the next item matches our pattern, too
	    # now the trick is to find the first character
	    # where they *don't* match...
	    set marker [string length $pattern]
	    while {$marker <= [string length $pattern]} {
		set a [string index $thisItem $marker]
		set b [string index $nextItem $marker]
		if {[string compare $a $b] == 0} {
		    append pattern $a
		    incr marker
		} else {
		    break
		}
	    }
	} else {
	    set marker [string length $pattern]
	}
	
    } else {
	set marker end
	set index 0
    }

    # ok, we know the pattern and what part is unique;
    # update the entry widget and listbox appropriately
    if {$exact && $exactMatch == -1} {
	# this means we didn't find an exact match
	$widgets(listbox) selection clear 0 end
	$widgets(listbox) see $index

    } elseif {!$exact}  {
	# this means we found something, but it isn't an exact
	# match. If we find something that *is* an exact match we
	# don't need to do the following, since it would merely 
	# be replacing the data in the entry widget with itself
	set oldstate [$widgets(entry) cget -state]
	$widgets(entry) configure -state normal
	$widgets(entry) delete 0 end
	$widgets(entry) insert end $thisItem
	$widgets(entry) selection clear
	$widgets(entry) selection range $marker end
	$widgets(listbox) activate $index
	$widgets(listbox) selection clear 0 end
	$widgets(listbox) selection anchor $index
	$widgets(listbox) selection set $index
	$widgets(listbox) see $index
	$widgets(entry) configure -state $oldstate
    }
}

# ::combobox::Select --
#
#    selects an item from the list and sets the value of the combobox
#    to that value
#
# Arguments:
#
#    w      widget pathname
#    index  listbox index of item to be selected
#
# Returns:
#
#    empty string

proc ::combobox::Select {w index} {
    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options

    # the catch is because I'm sloppy -- presumably, the only time
    # an error will be caught is if there is no selection. 
    if {![catch {set data [$widgets(listbox) get [lindex $index 0]]}]} {
	::combobox::SetValue $widgets(this) $data

	$widgets(listbox) selection clear 0 end
	$widgets(listbox) selection anchor $index
	$widgets(listbox) selection set $index

    }
    $widgets(entry) selection range 0 end
    $widgets(entry) icursor end

    $widgets(this) close

    return ""
}

# ::combobox::HandleScrollbar --
# 
#    causes the scrollbar of the dropdown list to appear or disappear
#    based on the contents of the dropdown listbox
#
# Arguments:
#
#    w       widget pathname
#    action  the action to perform on the scrollbar
#
# Returns:
#
#    an empty string

proc ::combobox::HandleScrollbar {w {action "unknown"}} {
    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options

    if {$options(-height) == 0} {
	set hlimit $options(-maxheight)
    } else {
	set hlimit $options(-height)
    }		    

    switch $action {
	"grow" {
	    if {$hlimit > 0 && [$widgets(listbox) size] > $hlimit} {
		pack forget $widgets(listbox)
		pack $widgets(vsb) -side right -fill y -expand n
		pack $widgets(listbox) -side left -fill both -expand y
	    }
	}

	"shrink" {
	    if {$hlimit > 0 && [$widgets(listbox) size] <= $hlimit} {
		pack forget $widgets(vsb)
	    }
	}

	"crop" {
	    # this means the window was cropped and we definitely 
	    # need a scrollbar no matter what the user wants
	    pack forget $widgets(listbox)
	    pack $widgets(vsb) -side right -fill y -expand n
	    pack $widgets(listbox) -side left -fill both -expand y
	}

	default {
	    if {$hlimit > 0 && [$widgets(listbox) size] > $hlimit} {
		pack forget $widgets(listbox)
		pack $widgets(vsb) -side right -fill y -expand n
		pack $widgets(listbox) -side left -fill both -expand y
	    } else {
		pack forget $widgets(vsb)
	    }
	}
    }

    return ""
}

# ::combobox::ComputeGeometry --
#
#    computes the geometry of the dropdown list based on the size of the
#    combobox...
#
# Arguments:
#
#    w     widget pathname
#
# Returns:
#
#    the desired geometry of the listbox

proc ::combobox::ComputeGeometry {w} {
    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options
    
    if {$options(-height) == 0 && $options(-maxheight) != "0"} {
	# if this is the case, count the items and see if
	# it exceeds our maxheight. If so, set the listbox
	# size to maxheight...
	set nitems [$widgets(listbox) size]
	if {$nitems > $options(-maxheight)} {
	    # tweak the height of the listbox
	    $widgets(listbox) configure -height $options(-maxheight)
	} else {
	    # un-tweak the height of the listbox
	    $widgets(listbox) configure -height 0
	}
	update idletasks
    }

    # compute height and width of the dropdown list
    set bd [$widgets(dropdown) cget -borderwidth]
    set height [expr {[winfo reqheight $widgets(dropdown)] + $bd + $bd}]
    if {[string length $options(-dropdownwidth)] == 0 || 
        $options(-dropdownwidth) == 0} {
        set width [winfo width $widgets(this)]
    } else {
        set m [font measure [$widgets(listbox) cget -font] "m"]
        set width [expr {$options(-dropdownwidth) * $m}]
    }

    # figure out where to place it on the screen, trying to take into
    # account we may be running under some virtual window manager
    set screenWidth  [winfo screenwidth $widgets(this)]
    set screenHeight [winfo screenheight $widgets(this)]
    set rootx        [winfo rootx $widgets(this)]
    set rooty        [winfo rooty $widgets(this)]
    set vrootx       [winfo vrootx $widgets(this)]
    set vrooty       [winfo vrooty $widgets(this)]

    # the x coordinate is simply the rootx of our widget, adjusted for
    # the virtual window. We won't worry about whether the window will
    # be offscreen to the left or right -- we want the illusion that it
    # is part of the entry widget, so if part of the entry widget is off-
    # screen, so will the list. If you want to change the behavior,
    # simply change the if statement... (and be sure to update this
    # comment!)
    set x  [expr {$rootx + $vrootx}]
    if {0} { 
	set rightEdge [expr {$x + $width}]
	if {$rightEdge > $screenWidth} {
	    set x [expr {$screenWidth - $width}]
	}
	if {$x < 0} {set x 0}
    }

    # the y coordinate is the rooty plus vrooty offset plus 
    # the height of the static part of the widget plus 1 for a 
    # tiny bit of visual separation...
    set y [expr {$rooty + $vrooty + [winfo reqheight $widgets(this)] + 1}]
    set bottomEdge [expr {$y + $height}]

    if {$bottomEdge >= $screenHeight} {
	# ok. Fine. Pop it up above the entry widget isntead of
	# below.
	set y [expr {($rooty - $height - 1) + $vrooty}]

	if {$y < 0} {
	    # this means it extends beyond our screen. How annoying.
	    # Now we'll try to be real clever and either pop it up or
	    # down, depending on which way gives us the biggest list. 
	    # then, we'll trim the list to fit and force the use of
	    # a scrollbar

	    # (sadly, for windows users this measurement doesn't
	    # take into consideration the height of the taskbar,
	    # but don't blame me -- there isn't any way to detect
	    # it or figure out its dimensions. The same probably
	    # applies to any window manager with some magic windows
	    # glued to the top or bottom of the screen)

	    if {$rooty > [expr {$screenHeight / 2}]} {
		# we are in the lower half of the screen -- 
		# pop it up. Y is zero; that parts easy. The height
		# is simply the y coordinate of our widget, minus
		# a pixel for some visual separation. The y coordinate
		# will be the topof the screen.
		set y 1
		set height [expr {$rooty - 1 - $y}]

	    } else {
		# we are in the upper half of the screen --
		# pop it down
		set y [expr {$rooty + $vrooty + \
			[winfo reqheight $widgets(this)] + 1}]
		set height [expr {$screenHeight - $y}]

	    }

	    # force a scrollbar
	    HandleScrollbar $widgets(this) crop
	}	   
    }

    if {$y < 0} {
	# hmmm. Bummer.
	set y 0
	set height $screenheight
    }

    set geometry [format "=%dx%d+%d+%d" $width $height $x $y]

    return $geometry
}

# ::combobox::DoInternalWidgetCommand --
#
#    perform an internal widget command, then mung any error results
#    to look like it came from our megawidget. A lot of work just to
#    give the illusion that our megawidget is an atomic widget
#
# Arguments:
#
#    w           widget pathname
#    subwidget   pathname of the subwidget 
#    command     subwidget command to be executed
#    args        arguments to the command
#
# Returns:
#
#    The result of the subwidget command, or an error

proc ::combobox::DoInternalWidgetCommand {w subwidget command args} {
    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options

    set subcommand $command
    set command [concat $widgets($subwidget) $command $args]
    if {[catch $command result]} {
	# replace the subwidget name with the megawidget name
	regsub $widgets($subwidget) $result $widgets(this) result

	# replace specific instances of the subwidget command
	# with our megawidget command
	switch $subwidget,$subcommand {
	    listbox,index  {regsub "index"  $result "list index"  result}
	    listbox,insert {regsub "insert" $result "list insert" result}
	    listbox,delete {regsub "delete" $result "list delete" result}
	    listbox,get    {regsub "get"    $result "list get"    result}
	    listbox,size   {regsub "size"   $result "list size"   result}
	}
	error $result

    } else {
	return $result
    }
}


# ::combobox::WidgetProc --
#
#    This gets uses as the widgetproc for an combobox widget. 
#    Notice where the widget is created and you'll see that the
#    actual widget proc merely evals this proc with all of the
#    arguments intact.
#
#    Note that some widget commands are defined "inline" (ie:
#    within this proc), and some do most of their work in 
#    separate procs. This is merely because sometimes it was
#    easier to do it one way or the other.
#
# Arguments:
#
#    w         widget pathname
#    command   widget subcommand
#    args      additional arguments; varies with the subcommand
#
# Results:
#
#    Performs the requested widget command

proc ::combobox::WidgetProc {w command args} {
    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options
    upvar ::combobox::${w}::oldFocus oldFocus
    upvar ::combobox::${w}::oldFocus oldGrab

    set command [::combobox::Canonize $w command $command]

    # this is just shorthand notation...
    set doWidgetCommand \
	    [list ::combobox::DoInternalWidgetCommand $widgets(this)]

    if {$command == "list"} {
	# ok, the next argument is a list command; we'll 
	# rip it from args and append it to command to
	# create a unique internal command
	#
	# NB: because of the sloppy way we are doing this,
	# we'll also let the user enter our secret command
	# directly (eg: listinsert, listdelete), but we
	# won't document that fact
	set command "list-[lindex $args 0]"
	set args [lrange $args 1 end]
    }

    set result ""

    # many of these commands are just synonyms for specific
    # commands in one of the subwidgets. We'll get them out
    # of the way first, then do the custom commands.
    switch $command {
	bbox -
	delete -
	get -
	icursor -
	index -
	insert -
	scan -
	selection -
	xview {
	    set result [eval $doWidgetCommand entry $command $args]
	}
	list-get 	{set result [eval $doWidgetCommand listbox get $args]}
	list-index 	{set result [eval $doWidgetCommand listbox index $args]}
	list-size 	{set result [eval $doWidgetCommand listbox size $args]}

	select {
	    if {[llength $args] == 1} {
		set index [lindex $args 0]
		set result [Select $widgets(this) $index]
	    } else {
		error "usage: $w select index"
	    }
	}

	subwidget {
	    set knownWidgets [list button entry listbox dropdown vsb]
	    if {[llength $args] == 0} {
		return $knownWidgets
	    }

	    set name [lindex $args 0]
	    if {[lsearch $knownWidgets $name] != -1} {
		set result $widgets($name)
	    } else {
		error "unknown subwidget $name"
	    }
	}

	curselection {
	    set result [eval $doWidgetCommand listbox curselection]
	}

	list-insert {
	    eval $doWidgetCommand listbox insert $args
	    set result [HandleScrollbar $w "grow"]
	}

	list-delete {
	    eval $doWidgetCommand listbox delete $args
	    set result [HandleScrollbar $w "shrink"]
	}

	toggle {
	    # ignore this command if the widget is disabled...
	    if {$options(-state) == "disabled"} return

	    # pops down the list if it is not, hides it
	    # if it is...
	    if {[winfo ismapped $widgets(dropdown)]} {
		set result [$widgets(this) close]
	    } else {
		set result [$widgets(this) open]
	    }
	}

	open {

	    # if this is an editable combobox, the focus should
	    # be set to the entry widget
	    if {$options(-editable)} {
		focus $widgets(entry)
		$widgets(entry) select range 0 end
		$widgets(entry) icursor end
	    }

	    # if we are disabled, we won't allow this to happen
	    if {$options(-state) == "disabled"} {
		return 0
	    }

	    # if there is a -opencommand, execute it now
	    if {[string length $options(-opencommand)] > 0} {
		# hmmm... should I do a catch, or just let the normal
		# error handling handle any errors? For now, the latter...
		uplevel \#0 $options(-opencommand)
	    }

	    # compute the geometry of the window to pop up, and set
	    # it, and force the window manager to take notice
	    # (even if it is not presently visible).
	    #
	    # this isn't strictly necessary if the window is already
	    # mapped, but we'll go ahead and set the geometry here
	    # since its harmless and *may* actually reset the geometry
	    # to something better in some weird case.
	    set geometry [::combobox::ComputeGeometry $widgets(this)]
	    wm geometry $widgets(dropdown) $geometry
	    update idletasks

	    # if we are already open, there's nothing else to do
	    if {[winfo ismapped $widgets(dropdown)]} {
		return 0
	    }

	    # save the widget that currently has the focus; we'll restore
	    # the focus there when we're done
	    set oldFocus [focus]

	    # ok, tweak the visual appearance of things and 
	    # make the list pop up
	    $widgets(button) configure -relief sunken
	    wm deiconify $widgets(dropdown) 
	    update idletasks
	    raise $widgets(dropdown) 

	    # force focus to the entry widget so we can handle keypress
	    # events for traversal
	    focus -force $widgets(entry)

	    # select something by default, but only if its an
	    # exact match...
	    ::combobox::Find $widgets(this) 1

	    # save the current grab state for the display containing
	    # this widget. We'll restore it when we close the dropdown
	    # list
	    set status "none"
	    set grab [grab current $widgets(this)]
	    if {$grab != ""} {set status [grab status $grab]}
	    set oldGrab [list $grab $status]
	    unset grab status

	    # *gasp* do a global grab!!! Mom always told me not to
	    # do things like this, but sometimes a man's gotta do
	    # what a man's gotta do.
	    grab -global $widgets(this)

	    # fake the listbox into thinking it has focus. This is 
	    # necessary to get scanning initialized properly in the
	    # listbox.
	    event generate $widgets(listbox) <B1-Enter>

	    return 1
	}

	close {
	    # if we are already closed, don't do anything...
	    if {![winfo ismapped $widgets(dropdown)]} {
		return 0
	    }

	    # restore the focus and grab, but ignore any errors...
	    # we're going to be paranoid and release the grab before
	    # trying to set any other grab because we really really
	    # really want to make sure the grab is released.
	    catch {focus $oldFocus} result
	    catch {grab release $widgets(this)}
	    catch {
		set status [lindex $oldGrab 1]
		if {$status == "global"} {
		    grab -global [lindex $oldGrab 0]
		} elseif {$status == "local"} {
		    grab [lindex $oldGrab 0]
		}
		unset status
	    }

	    # hides the listbox
	    $widgets(button) configure -relief raised
	    wm withdraw $widgets(dropdown) 

	    # select the data in the entry widget. Not sure
	    # why, other than observation seems to suggest that's
	    # what windows widgets do.
	    set editable [::combobox::GetBoolean $options(-editable)]
	    if {$editable} {
		$widgets(entry) selection range 0 end
		$widgets(button) configure -relief raised
	    }


	    # magic tcl stuff (see tk.tcl in the distribution 
	    # lib directory)
	    ::combobox::tkCancelRepeat

	    return 1
	}

	cget {
	    if {[llength $args] != 1} {
		error "wrong # args: should be $w cget option"
	    }
	    set opt [::combobox::Canonize $w option [lindex $args 0]]

	    if {$opt == "-value"} {
		set result [$widgets(entry) get]
	    } else {
		set result $options($opt)
	    }
	}

	configure {
	    set result [eval ::combobox::Configure {$w} $args]
	}

	default {
	    error "bad option \"$command\""
	}
    }

    return $result
}

# ::combobox::Configure --
#
#    Implements the "configure" widget subcommand
#
# Arguments:
#
#    w      widget pathname
#    args   zero or more option/value pairs (or a single option)
#
# Results:
#    
#    Performs typcial "configure" type requests on the widget

proc ::combobox::Configure {w args} {
    variable widgetOptions
    variable defaultEntryCursor

    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options

    if {[llength $args] == 0} {
	# hmmm. User must be wanting all configuration information
	# note that if the value of an array element is of length
	# one it is an alias, which needs to be handled slightly
	# differently
	set results {}
	foreach opt [lsort [array names widgetOptions]] {
	    if {[llength $widgetOptions($opt)] == 1} {
		set alias $widgetOptions($opt)
		set optName $widgetOptions($alias)
		lappend results [list $opt $optName]
	    } else {
		set optName  [lindex $widgetOptions($opt) 0]
		set optClass [lindex $widgetOptions($opt) 1]
		set default [option get $w $optName $optClass]
		if {[info exists options($opt)]} {
		    lappend results [list $opt $optName $optClass \
			    $default $options($opt)]
		} else {
		    lappend results [list $opt $optName $optClass \
			    $default ""]
		}
	    }
	}

	return $results
    }
    
    # one argument means we are looking for configuration
    # information on a single option
    if {[llength $args] == 1} {
	set opt [::combobox::Canonize $w option [lindex $args 0]]

	set optName  [lindex $widgetOptions($opt) 0]
	set optClass [lindex $widgetOptions($opt) 1]
	set default [option get $w $optName $optClass]
	set results [list $opt $optName $optClass \
		$default $options($opt)]
	return $results
    }

    # if we have an odd number of values, bail. 
    if {[expr {[llength $args]%2}] == 1} {
	# hmmm. An odd number of elements in args
	error "value for \"[lindex $args end]\" missing"
    }
    
    # Great. An even number of options. Let's make sure they 
    # are all valid before we do anything. Note that Canonize
    # will generate an error if it finds a bogus option; otherwise
    # it returns the canonical option name
    foreach {name value} $args {
	set name [::combobox::Canonize $w option $name]
	set opts($name) $value
    }

    # process all of the configuration options
    # some (actually, most) options require us to
    # do something, like change the attributes of
    # a widget or two. Here's where we do that...
    #
    # note that the handling of disabledforeground and
    # disabledbackground is a little wonky. First, we have
    # to deal with backwards compatibility (ie: tk 8.3 and below
    # didn't have such options for the entry widget), and
    # we have to deal with the fact we might want to disable
    # the entry widget but use the normal foreground/background
    # for when the combobox is not disabled, but not editable either.

    set updateVisual 0
    foreach option [array names opts] {
	set newValue $opts($option)
	if {[info exists options($option)]} {
	    set oldValue $options($option)
	}

	switch -- $option {
	    -buttonbackground {
		$widgets(button) configure -background $newValue
	    }
	    -background {
		set updateVisual 1
		set options($option) $newValue
	    }

	    -borderwidth {
		$widgets(frame) configure -borderwidth $newValue
		set options($option) $newValue
	    }

	    -command {
		# nothing else to do...
		set options($option) $newValue
	    }

	    -commandstate {
		# do some value checking...
		if {$newValue != "normal" && $newValue != "disabled"} {
		    set options($option) $oldValue
		    set message "bad state value \"$newValue\";"
		    append message " must be normal or disabled"
		    error $message
		}
		set options($option) $newValue
	    }

	    -cursor {
		$widgets(frame) configure -cursor $newValue
		$widgets(entry) configure -cursor $newValue
		$widgets(listbox) configure -cursor $newValue
		set options($option) $newValue
	    }

	    -disabledforeground {
		set updateVisual 1
		set options($option) $newValue
	    }

	    -disabledbackground {
		set updateVisual 1
		set options($option) $newValue
	    }

            -dropdownwidth {
                set options($option) $newValue
            }

	    -editable {
		set updateVisual 1
 		if {$newValue} {
 		    # it's editable...
 		    $widgets(entry) configure \
 			    -state normal \
 			    -cursor $defaultEntryCursor
 		} else {
 		    $widgets(entry) configure \
 			    -state disabled \
 			    -cursor $options(-cursor)
 		}
		set options($option) $newValue
	    }

	    -elementborderwidth {
		$widgets(button) configure -borderwidth $newValue
		$widgets(vsb) configure -borderwidth $newValue
		$widgets(dropdown) configure -borderwidth $newValue
		set options($option) $newValue
	    }

	    -font {
		$widgets(entry) configure -font $newValue
		$widgets(listbox) configure -font $newValue
		set options($option) $newValue
	    }

	    -foreground {
		set updateVisual 1
		set options($option) $newValue
	    }

	    -height {
		$widgets(listbox) configure -height $newValue
		HandleScrollbar $w
		set options($option) $newValue
	    }

	    -highlightbackground {
		$widgets(frame) configure -highlightbackground $newValue
		set options($option) $newValue
	    }

	    -highlightcolor {
		$widgets(frame) configure -highlightcolor $newValue
		set options($option) $newValue
	    }

	    -highlightthickness {
		$widgets(frame) configure -highlightthickness $newValue
		set options($option) $newValue
	    }
	    
	    -image {
		if {[string length $newValue] > 0} {
		    puts "old button width: [$widgets(button) cget -width]"
		    $widgets(button) configure \
			-image $newValue \
			-width [expr {[image width $newValue] + 2}]
		    puts "new button width: [$widgets(button) cget -width]"
		    
		} else {
		    $widgets(button) configure -image ::combobox::bimage
		}
		set options($option) $newValue
	    }

	    -listvar {
		if {[catch {$widgets(listbox) cget -listvar}]} {
		    return -code error \
			"-listvar not supported with this version of tk"
		}
		$widgets(listbox) configure -listvar $newValue
		set options($option) $newValue
	    }

	    -maxheight {
		# ComputeGeometry may dork with the actual height
		# of the listbox, so let's undork it
		$widgets(listbox) configure -height $options(-height)
		HandleScrollbar $w
		set options($option) $newValue
	    }

	    -opencommand {
		# nothing else to do...
		set options($option) $newValue
	    }

	    -relief {
		$widgets(frame) configure -relief $newValue
		set options($option) $newValue
	    }

	    -selectbackground {
		$widgets(entry) configure -selectbackground $newValue
		$widgets(listbox) configure -selectbackground $newValue
		set options($option) $newValue
	    }

	    -selectborderwidth {
		$widgets(entry) configure -selectborderwidth $newValue
		$widgets(listbox) configure -selectborderwidth $newValue
		set options($option) $newValue
	    }

	    -selectforeground {
		$widgets(entry) configure -selectforeground $newValue
		$widgets(listbox) configure -selectforeground $newValue
		set options($option) $newValue
	    }

	    -state {
		if {$newValue == "normal"} {
		    set updateVisual 1
		    # it's enabled

		    set editable [::combobox::GetBoolean \
			    $options(-editable)]
		    if {$editable} {
			$widgets(entry) configure -state normal
			$widgets(entry) configure -takefocus 1
		    }

                    # note that $widgets(button) is actually a label,
                    # not a button. And being able to disable labels
                    # wasn't possible until tk 8.3. (makes me wonder
		    # why I chose to use a label, but that answer is
		    # lost to antiquity)
                    if {[info patchlevel] >= 8.3} {
                        $widgets(button) configure -state normal
                    }

		} elseif {$newValue == "disabled"}  {
		    set updateVisual 1
		    # it's disabled
		    $widgets(entry) configure -state disabled
		    $widgets(entry) configure -takefocus 0
                    # note that $widgets(button) is actually a label,
                    # not a button. And being able to disable labels
                    # wasn't possible until tk 8.3. (makes me wonder
		    # why I chose to use a label, but that answer is
		    # lost to antiquity)
                    if {$::tcl_version >= 8.3} {
                        $widgets(button) configure -state disabled 
                    }

		} else {
		    set options($option) $oldValue
		    set message "bad state value \"$newValue\";"
		    append message " must be normal or disabled"
		    error $message
		}

		set options($option) $newValue
	    }

	    -takefocus {
		$widgets(entry) configure -takefocus $newValue
		set options($option) $newValue
	    }

	    -textvariable {
		$widgets(entry) configure -textvariable $newValue
		set options($option) $newValue
	    }

	    -value {
		::combobox::SetValue $widgets(this) $newValue
		set options($option) $newValue
	    }

	    -width {
		$widgets(entry) configure -width $newValue
		$widgets(listbox) configure -width $newValue
		set options($option) $newValue
	    }

	    -xscrollcommand {
		$widgets(entry) configure -xscrollcommand $newValue
		set options($option) $newValue
	    }
	}	    

	if {$updateVisual} {UpdateVisualAttributes $w}
    }
}

# ::combobox::UpdateVisualAttributes --
#
# sets the visual attributes (foreground, background mostly) 
# based on the current state of the widget (normal/disabled, 
# editable/non-editable)
#
# why a proc for such a simple thing? Well, in addition to the
# various states of the widget, we also have to consider the 
# version of tk being used -- versions from 8.4 and beyond have
# the notion of disabled foreground/background options for various
# widgets. All of the permutations can get nasty, so we encapsulate
# it all in one spot.
#
# note also that we don't handle all visual attributes here; just
# the ones that depend on the state of the widget. The rest are 
# handled on a case by case basis
#
# Arguments:
#    w		widget pathname
#
# Returns:
#    empty string

proc ::combobox::UpdateVisualAttributes {w} {

    upvar ::combobox::${w}::widgets     widgets
    upvar ::combobox::${w}::options     options

    if {$options(-state) == "normal"} {

	set foreground $options(-foreground)
	set background $options(-background)
	
    } elseif {$options(-state) == "disabled"} {

	set foreground $options(-disabledforeground)
	set background $options(-disabledbackground)
    }

    $widgets(entry)   configure -foreground $foreground -background $background
    $widgets(listbox) configure -foreground $foreground -background $background
    $widgets(button)  configure -foreground $foreground 
# $widgets(vsb)     configure -background $background -troughcolor $background
    $widgets(frame)   configure -background $background

    # we need to set the disabled colors in case our widget is disabled. 
    # We could actually check for disabled-ness, but we also need to 
    # check whether we're enabled but not editable, in which case the 
    # entry widget is disabled but we still want the enabled colors. It's
    # easier just to set everything and be done with it.
    
    if {$::tcl_version >= 8.4} {
	$widgets(entry) configure \
	    -disabledforeground $foreground \
	    -disabledbackground $background
	$widgets(button)  configure -disabledforeground $foreground
	$widgets(listbox) configure -disabledforeground $foreground
    }
}

# ::combobox::SetValue --
#
#    sets the value of the combobox and calls the -command, 
#    if defined
#
# Arguments:
#
#    w          widget pathname
#    newValue   the new value of the combobox
#
# Returns
#
#    Empty string

proc ::combobox::SetValue {w newValue} {

    upvar ::combobox::${w}::widgets     widgets
    upvar ::combobox::${w}::options     options
    upvar ::combobox::${w}::ignoreTrace ignoreTrace
    upvar ::combobox::${w}::oldValue    oldValue

    if {[info exists options(-textvariable)] \
	    && [string length $options(-textvariable)] > 0} {
	set variable ::$options(-textvariable)
	set $variable $newValue
    } else {
	set oldstate [$widgets(entry) cget -state]
	$widgets(entry) configure -state normal
	$widgets(entry) delete 0 end
	$widgets(entry) insert 0 $newValue
	$widgets(entry) configure -state $oldstate
    }

    # set our internal textvariable; this will cause any public
    # textvariable (ie: defined by the user) to be updated as
    # well
#    set ::combobox::${w}::entryTextVariable $newValue

    # redefine our concept of the "old value". Do it before running
    # any associated command so we can be sure it happens even
    # if the command somehow fails.
    set oldValue $newValue

    # call the associated command. The proc will handle whether or 
    # not to actually call it, and with what args
    CallCommand $w $newValue

    return ""
}

# ::combobox::CallCommand --
#
#   calls the associated command, if any, appending the new
#   value to the command to be called.
#
# Arguments:
#
#    w         widget pathname
#    newValue  the new value of the combobox
#
# Returns
#
#    empty string

proc ::combobox::CallCommand {w newValue} {
    upvar ::combobox::${w}::widgets widgets
    upvar ::combobox::${w}::options options
    
    # call the associated command, if defined and -commandstate is
    # set to "normal"
    if {$options(-commandstate) == "normal" && \
	    [string length $options(-command)] > 0} {
	set args [list $widgets(this) $newValue]
	uplevel \#0 $options(-command) $args
    }
}


# ::combobox::GetBoolean --
#
#     returns the value of a (presumably) boolean string (ie: it should
#     do the right thing if the string is "yes", "no", "true", 1, etc
#
# Arguments:
#
#     value       value to be converted 
#     errorValue  a default value to be returned in case of an error
#
# Returns:
#
#     a 1 or zero, or the value of errorValue if the string isn't
#     a proper boolean value

proc ::combobox::GetBoolean {value {errorValue 1}} {
    if {[catch {expr {([string trim $value])?1:0}} res]} {
	return $errorValue
    } else {
	return $res
    }
}

# ::combobox::convert --
#
#     public routine to convert %x, %y and %W binding substitutions.
#     Given an x, y and or %W value relative to a given widget, this
#     routine will convert the values to be relative to the combobox
#     widget. For example, it could be used in a binding like this:
#
#     bind .combobox <blah> {doSomething [::combobox::convert %W -x %x]}
#
#     Note that this procedure is *not* exported, but is intended for
#     public use. It is not exported because the name could easily 
#     clash with existing commands. 
#
# Arguments:
#
#     w     a widget path; typically the actual result of a %W 
#           substitution in a binding. It should be either a
#           combobox widget or one of its subwidgets
#
#     args  should one or more of the following arguments or 
#           pairs of arguments:
#
#           -x <x>      will convert the value <x>; typically <x> will
#                       be the result of a %x substitution
#           -y <y>      will convert the value <y>; typically <y> will
#                       be the result of a %y substitution
#           -W (or -w)  will return the name of the combobox widget
#                       which is the parent of $w
#
# Returns:
#
#     a list of the requested values. For example, a single -w will
#     result in a list of one items, the name of the combobox widget.
#     Supplying "-x 10 -y 20 -W" (in any order) will return a list of
#     three values: the converted x and y values, and the name of 
#     the combobox widget.

proc ::combobox::convert {w args} {
    set result {}
    if {![winfo exists $w]} {
	error "window \"$w\" doesn't exist"
    }

    while {[llength $args] > 0} {
	set option [lindex $args 0]
	set args [lrange $args 1 end]

	switch -exact -- $option {
	    -x {
		set value [lindex $args 0]
		set args [lrange $args 1 end]
		set win $w
		while {[winfo class $win] != "Combobox"} {
		    incr value [winfo x $win]
		    set win [winfo parent $win]
		    if {$win == "."} break
		}
		lappend result $value
	    }

	    -y {
		set value [lindex $args 0]
		set args [lrange $args 1 end]
		set win $w
		while {[winfo class $win] != "Combobox"} {
		    incr value [winfo y $win]
		    set win [winfo parent $win]
		    if {$win == "."} break
		}
		lappend result $value
	    }

	    -w -
	    -W {
		set win $w
		while {[winfo class $win] != "Combobox"} {
		    set win [winfo parent $win]
		    if {$win == "."} break;
		}
		lappend result $win
	    }
	}
    }
    return $result
}

# ::combobox::Canonize --
#
#    takes a (possibly abbreviated) option or command name and either 
#    returns the canonical name or an error
#
# Arguments:
#
#    w        widget pathname
#    object   type of object to canonize; must be one of "command",
#             "option", "scan command" or "list command"
#    opt      the option (or command) to be canonized
#
# Returns:
#
#    Returns either the canonical form of an option or command,
#    or raises an error if the option or command is unknown or
#    ambiguous.

proc ::combobox::Canonize {w object opt} {
    variable widgetOptions
    variable columnOptions
    variable widgetCommands
    variable listCommands
    variable scanCommands

    switch $object {
	command {
	    if {[lsearch -exact $widgetCommands $opt] >= 0} {
		return $opt
	    }

	    # command names aren't stored in an array, and there
	    # isn't a way to get all the matches in a list, so
	    # we'll stuff the commands in a temporary array so
	    # we can use [array names]
	    set list $widgetCommands
	    foreach element $list {
		set tmp($element) ""
	    }
	    set matches [array names tmp ${opt}*]
	}

	{list command} {
	    if {[lsearch -exact $listCommands $opt] >= 0} {
		return $opt
	    }

	    # command names aren't stored in an array, and there
	    # isn't a way to get all the matches in a list, so
	    # we'll stuff the commands in a temporary array so
	    # we can use [array names]
	    set list $listCommands
	    foreach element $list {
		set tmp($element) ""
	    }
	    set matches [array names tmp ${opt}*]
	}

	{scan command} {
	    if {[lsearch -exact $scanCommands $opt] >= 0} {
		return $opt
	    }

	    # command names aren't stored in an array, and there
	    # isn't a way to get all the matches in a list, so
	    # we'll stuff the commands in a temporary array so
	    # we can use [array names]
	    set list $scanCommands
	    foreach element $list {
		set tmp($element) ""
	    }
	    set matches [array names tmp ${opt}*]
	}

	option {
	    if {[info exists widgetOptions($opt)] \
		    && [llength $widgetOptions($opt)] == 2} {
		return $opt
	    }
	    set list [array names widgetOptions]
	    set matches [array names widgetOptions ${opt}*]
	}

    }

    if {[llength $matches] == 0} {
	set choices [HumanizeList $list]
	error "unknown $object \"$opt\"; must be one of $choices"

    } elseif {[llength $matches] == 1} {
	set opt [lindex $matches 0]

	# deal with option aliases
	switch $object {
	    option {
		set opt [lindex $matches 0]
		if {[llength $widgetOptions($opt)] == 1} {
		    set opt $widgetOptions($opt)
		}
	    }
	}

	return $opt

    } else {
	set choices [HumanizeList $list]
	error "ambiguous $object \"$opt\"; must be one of $choices"
    }
}

# ::combobox::HumanizeList --
#
#    Returns a human-readable form of a list by separating items
#    by columns, but separating the last two elements with "or"
#    (eg: foo, bar or baz)
#
# Arguments:
#
#    list    a valid tcl list
#
# Results:
#
#    A string which as all of the elements joined with ", " or 
#    the word " or "

proc ::combobox::HumanizeList {list} {

    if {[llength $list] == 1} {
	return [lindex $list 0]
    } else {
	set list [lsort $list]
	set secondToLast [expr {[llength $list] -2}]
	set most [lrange $list 0 $secondToLast]
	set last [lindex $list end]

	return "[join $most {, }] or $last"
    }
}

# This is some backwards-compatibility code to handle TIP 44
# (http://purl.org/tcl/tip/44.html). For all private tk commands
# used by this widget, we'll make duplicates of the procs in the
# combobox namespace. 
#
# I'm not entirely convinced this is the right thing to do. I probably
# shouldn't even be using the private commands. Then again, maybe the
# private commands really should be public. Oh well; it works so it
# must be OK...
foreach command {TabToWindow CancelRepeat ListboxUpDown} {
    if {[llength [info commands ::combobox::tk$command]] == 1} break;

    set tmp [info commands tk$command]
    set proc ::combobox::tk$command
    if {[llength [info commands tk$command]] == 1} {
        set command [namespace which [lindex $tmp 0]]
        proc $proc {args} "uplevel $command \$args"
    } else {
        if {[llength [info commands ::tk::$command]] == 1} {
            proc $proc {args} "uplevel ::tk::$command \$args"
        }
    }
}


