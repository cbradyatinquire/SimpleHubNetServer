;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variable and Breed declarations ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals
[
  ;; variables related to the health of the turtles
  old-num-infected          ;; number of turtles that had infected? = true during the last pass through the go procedure
  clock        ;; keeps track of the number of times through the go procedure (if there is at least one turtle infected)
  run-number

  ;; variables used to assign unique color and shape to clients
  shape-names        ;; list that holds the names of the non-sick shapes a student's turtle can have
  colors             ;; list that holds the colors used for students' turtles
  color-names        ;; list that holds the names of the colors used for students' turtles
  used-shape-colors  ;; list that holds the shape-color pairs that are already being used
  max-possible-codes ;; total number of possible unique shape/color combinations

  ;; quick start instructions variables
  quick-start  ;; current quickstart instruction displayed in the quickstart monitor
  qs-item      ;; index of the current quickstart instruction
  qs-items     ;; list of quickstart instructions
]

turtles-own
[
  infected?    ;; if a turtle is sick, infected? is true, otherwise, it is false
  base-shape   ;; original shape of a turtle
  step-size    ;; the amount that a turtle will go forward in the current direction
]

breed [ androids android ]  ;; created by the CREATE ANDROIDS button; not controlled by anyone, but can become sick and spread sickness
breed [ students student ]  ;; created and controlled by the clients

students-own
[
  user-id  ;; unique id, input by the client when they log in, to identify each student turtle
]


;;;;;;;;;;;;;;;;;;;;;;
;; Setup Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;

to startup
  hubnet-set-client-interface "COMPUTER" []
  hubnet-reset
  setup-vars
  setup-plot
end

to setup
  ask androids [ die ]
  cure-all
  reset-ticks
end

;; heals all sick turtles,  clears and sets up the plot,
;; and clears the lists sent to the calculators
to cure-all
  set clock 0
  ask turtles
  [
    set infected? false
    if breed = students
    [ update-sick?-monitor ]
    set shape base-shape
  ]

  set old-num-infected 0
  set run-number run-number + 1
  setup-plot
end

;; initialize global variables
to setup-vars
  set clock 0
  set old-num-infected 0

  set shape-names ["box" "star" "wheel" "target" "cat" "dog"
                   "butterfly" "leaf" "car" "airplane"
                   "monster" "key" "cow skull" "ghost"
                   "cactus" "moon" "heart"]
  ;; these colors were chosen with the goal of having colors
  ;; that are readily distinguishable from each other, and that
  ;; have names that everyone knows (e.g. no "cyan"!), and that
  ;; contrast sufficiently with the red infection dots and the
  ;; gray androids
  set colors      (list white brown green yellow
                        (violet + 1) (sky + 1))
  set color-names ["white" "brown" "green" "yellow"
                   "purple" "blue"]
  set max-possible-codes (length colors * length shape-names)
  set used-shape-colors []
  set run-number 1
end

;; create a temporary plot pen for the current run
;; cycle through a few colors so it is easy to
;; differentiate the runs.
to setup-plot
  create-temporary-plot-pen word "run " run-number
  set-plot-pen-color item (run-number mod 5)
                          [blue red green orange violet]
end

;; creates turtles that wander at random
to make-androids
  create-androids number
  [
    move-to one-of patches
    face one-of neighbors4
    set color gray
    set infected? false
    set base-shape "android"
    set shape base-shape
    set step-size 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;
;; Runtime Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;;

to go
  ;; get commands and data from the clients
  listen-clients

  every 0.1
  [
    ;;allow the androids to wander around the view
    if wander?
    [ androids-wander ]

    ask turtles with [ infected? ]
    [ spread-disease ]

    ;; increment the clock if there are infected turtles and plot the data
    let current-infected count turtles with [infected?]
    if current-infected > 0 and current-infected > old-num-infected
    [
      ;; plot the new data
      plotxy clock current-infected
      set old-num-infected current-infected
    ]
    if current-infected > 0
    [ set clock clock + 1 ]
    tick
  ]
end

;; controls the motion of the androids
to androids-wander
  every android-delay
  [
    ask androids
    [
      face one-of neighbors4
      fd 1
    ]
  ]
end

;; additional check infect called when student moves to new patch
;; added to avoid rewarding movement
to student-move-check-infect
  if infected?
  [ spread-disease ]

  ask other turtles-here with [ infected? ]
  [ ask myself [ maybe-get-sick ] ]
end

;; spread disease to other turtles here
to spread-disease
  ask other turtles-here [ maybe-get-sick ]
end


;; turtle procedure -- roll the dice and maybe get sick
to maybe-get-sick
  if not infected? [
    if ((random 100) + 1) <= infection-chance
    [ get-sick ] ]
end

;; turtle procedure -- set the appropriate variables to make this turtle sick
to get-sick
  set infected? true
  set-sick-shape
  if breed = students
  [ update-sick?-monitor ]
end

;; turtle procedure -- change the shape of turtles to its sick shape
;; if show-sick? is true and change the shape to the base-shape if
;; show-sick? is false
to set-sick-shape
  ifelse show-sick?
  [
    ;; we want to check if the turtles shape is already a sick shape
    ;; to prevent flickering in the turtles
    if shape != word base-shape " sick"
    [ set shape word base-shape " sick" ]
  ]
  [
    ;; we want to check if the turtles shape is already a base-shape
    ;; to prevent flickering in the turtles
    if shape != base-shape
    [ set shape base-shape ]
  ]
end

;; causes the initial infection in the turtle population --
;; infects a random healthy turtle until the desired number of
;; turtles are infected
to infect-turtles
  let healthy-turtles turtles with [ not infected? ]

  ifelse count healthy-turtles < initial-number-sick
  [
    ask healthy-turtles
    [
      get-sick
      set-sick-shape
    ]
    user-message "There are no more healthy turtles to infect.  Infection stopped."
    stop
  ]
  [
    ask n-of initial-number-sick healthy-turtles
    [
      get-sick
      set-sick-shape
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;
;; HubNet Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;

;; determines which client sent a command, and what the command was
to listen-clients
  while [ hubnet-message-waiting? ]
  [
    hubnet-fetch-message
    ifelse hubnet-enter-message?
    [ create-new-student ]
    [
      ifelse hubnet-exit-message?
      [ remove-student ]
      [
        if ( listen? )
        [
          ask students with [ user-id = hubnet-message-source ]
          [ execute-command hubnet-message-tag ]
        ]
      ]
    ]
  ]

  ask students
    [ update-sick?-monitor ]
end

;; NetLogo knows what each student turtle is supposed to be
;; doing based on the tag sent by the node:
;; step-size - set the turtle's step-size
;; Up    - make the turtle move up by step-size
;; Down  - make the turtle move down by step-size
;; Right - make the turtle move right by step-size
;; Left  - make the turtle move left by step-size
;; Get a Different Turtle - change the turtle's shape and color
to execute-command [command]
  if command = "step-size"
  [
    set step-size hubnet-message
    stop
  ]
  if command = "Up"
  [ execute-move 0 stop ]
  if command = "Down"
  [ execute-move 180 stop ]
  if command = "Right"
  [ execute-move 90 stop ]
  if command = "Left"
  [ execute-move 270 stop ]
  if command = "Change Appearance"
  [ execute-change-turtle stop ]
end

;; Create a turtle, set its shape, color, and position
;; and tell the node what its turtle looks like and where it is
to create-new-student
  create-students 1
  [
    setup-student-vars
    send-info-to-clients
    ;; we want to make sure that the clients all have the same plot ranges,
    ;; so when somebody logs in, set the plot ranges to themselves so that
    ;; everybody will have the same size plots.
    set-plot-y-range plot-y-min plot-y-max
    set-plot-x-range plot-x-min plot-x-max
  ]
end

;; sets the turtle variables to appropriate initial values
to setup-student-vars  ;; turtle procedure
  set user-id hubnet-message-source
  set-unique-shape-and-color
  move-to one-of patches
  face one-of neighbors4
  set infected? false
  set step-size 1
end

;; pick a base-shape and color for the turtle
to set-unique-shape-and-color
  let code random max-possible-codes
  while [member? code used-shape-colors and count students < max-possible-codes]
  [
    set code random max-possible-codes
  ]
  set used-shape-colors (lput code used-shape-colors)
  set base-shape item (code mod length shape-names) shape-names
  set shape base-shape
  set color item (code / length shape-names) colors
end

;; report the string version of the turtle's color
to-report color-string [color-value]
  report item (position color-value colors) color-names
end

;; sends the appropriate monitor information back to the client
to send-info-to-clients
  hubnet-send user-id "You are a:" (word (color-string color) " " base-shape)
  hubnet-send user-id "Located at:" (word "(" pxcor "," pycor ")")
  update-sick?-monitor
end

to update-sick?-monitor
  ifelse show-sick-on-clients?
  [ hubnet-send user-id "Sick?" infected? ]
  [ hubnet-send user-id "Sick?" "N/A" ]
end

;; Kill the turtle, set its shape, color, and position
;; and tell the node what its turtle looks like and where it is
to remove-student
  ask students with [user-id = hubnet-message-source]
  [
    set used-shape-colors remove my-code used-shape-colors
    die
  ]
end

;; translates a student turtle's shape and color into a code
to-report my-code
  report (position base-shape shape-names) + (length shape-names) * (position color colors)
end

;; Cause the students to move forward step-size in new-heading's heading
to execute-move [new-heading]
  set heading new-heading
  fd step-size
  hubnet-send user-id "Located at:" (word "(" pxcor "," pycor ")")

  ;; maybe infect or get infected by turtles on the patch student moved to
  student-move-check-infect
end

to execute-change-turtle
  ask students with [user-id = hubnet-message-source]
  [
    set used-shape-colors remove my-code used-shape-colors
    show-turtle
    set-unique-shape-and-color
    hubnet-send user-id "You are a:" (word (color-string color) " " base-shape)
    if infected?
    [ set-sick-shape ]
  ]
end

;;; this procedure is handy for testing out additional shapes and colors;
;;; you can call it from the Command Center
to show-gamut
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  setup-vars
  create-ordered-turtles max-possible-codes [
    fd max-pxcor * 0.7
    if who mod 3 = 0
      [ fd max-pxcor * 0.3 ]
    if who mod 3 = 1
      [ fd max-pxcor * 0.15 ]
    set heading 0
    set-unique-shape-and-color
  ]
  ask patch 0 0 [
    ask patches in-radius 2 [
      sprout-androids 1 [
        set shape "android"
        set color gray
      ]
    ]
  ]
  user-message (word length shape-names
              " shapes * "
              length colors
              " colors = "
              max-possible-codes
              " combinations")
end

; Copyright 1999 Uri Wilensky and Walter Stroup. All rights reserved.
; The full copyright notice is in the Information tab.
@#$#@#$#@
GRAPHICS-WINDOW
273
94
744
586
10
10
21.9524
1
10
1
1
1
0
0
0
1
-10
10
-10
10
1
1
1
ticks
30.0

BUTTON
131
10
209
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
26
130
208
163
infection-chance
infection-chance
0
100
100
1
1
%
HORIZONTAL

BUTTON
131
58
208
91
infect
infect-turtles
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
9
192
122
225
create androids
make-androids
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
7
350
263
547
Number Sick
time
sick
0.0
25.0
0.0
6.0
true
false
"" ""
PENS
"num-sick1" 1.0 0 -2674135 true "" ""
"num-sick2" 1.0 0 -13345367 true "" ""
"num-sick3" 1.0 0 -5825686 true "" ""

SLIDER
123
226
270
259
android-delay
android-delay
0
10
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
123
192
270
225
number
number
1
200
5
1
1
androids
HORIZONTAL

SWITCH
616
55
742
88
show-sick?
show-sick?
0
1
-1000

SWITCH
10
226
122
259
wander?
wander?
0
1
-1000

MONITOR
33
270
123
343
Turtles
count turtles
0
1
18

MONITOR
124
270
264
343
Number Sick
count turtles with [infected?]
0
1
18

SLIDER
27
94
207
127
initial-number-sick
initial-number-sick
1
20
1
1
1
NIL
HORIZONTAL

BUTTON
26
10
103
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
274
57
444
90
show-sick-on-clients?
show-sick-on-clients?
0
1
-1000

BUTTON
169
554
262
587
clear-plot
clear-all-plots\nset run-number 0
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
26
58
103
91
NIL
cure-all
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
213
10
316
43
listen?
listen?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model simulates the spread of a disease through a population.  This population can consist of either students, which are turtles controlled by individual students via the HubNet Client, or turtles that are generated and controlled by NetLogo, called androids, or both androids and students.

Turtles move around, possibly catching an infection.  Healthy turtles on the same patch as sick turtles have a INFECTION-CHANCE chance of becoming ill.  A plot shows the number of sick turtles at each time tick, and if SHOW-ILL? is on, sick turtles have a red circle attached to their shape.

Initially, all turtles are healthy.  A number of turtles equal to INITIAL-NUMBER-SICK become ill when the INFECT button is depressed.

For further documentation, see the Participatory Simulations Guide found at http://ccl.northwestern.edu/ps/

## HOW TO USE IT

Quickstart Instructions:

Teacher: Follow these directions to run the HubNet activity.  
Optional: Zoom In (see Tools in the Menu Bar)  
Optional: Change any of the settings. If you want to add androids press the CREATE ANDROIDS button.  Press the GO button.  
Everyone: Open up a HubNet client on your machine and type your user name, select this activity and press ENTER.  
Teacher: Have the students move their turtles around to acquaint themselves with the interface. Press the INFECT button to start the simulation.  
Everyone: Watch the plot of the number infected.  
Teacher: To run the activity again with the same group, stop the model by pressing the NetLogo GO button, if it is on. Change any of the settings that you would like.  Press the CURE-ALL button to keep the androids, or SETUP to clear them  
Teacher: Restart the simulation by pressing the NetLogo GO button again. Infect some turtles and continue.  
Teacher: To start the simulation over with a new group, stop the model by pressing the GO button, if it is on, have all the students log out or press the RESET button in the Control Center, and start these instructions from the beginning

Buttons:

SETUP - returns the model to the starting state, all student turtles are cured and androids are killed.  The plot is advanced to start a new run but it is not cleared.  
CURE-ALL - cures all turtles, androids are kept.  The plot is advanced to start a new run but it is not cleared.  
GO - runs the simulation  
CREATE ANDROIDS - adds randomly moving turtles to the simulation  
INFECT - infects INITIAL-NUMBER-SICK turtles in the simulation  
NEXT >>> - shows the next quick start instruction  
<<< PREVIOUS - shows the previous quick start instruction  
RESET INSTRUCTIONS - shows the first quick start instruction

Sliders:

NUMBER - determines how many androids are created by the CREATE ANDROIDS button  
ANDROID-DELAY - the delay time, in seconds, for android movement - the higher the number, the slower the androids move  
INITIAL-NUMBER-SICK - the number of turtles that become infected spontaneously when the INFECT button is pressed  
INFECTION-CHANCE - sets the percentage chance that every tenth of a second a healthy turtle will become sick if it is on the same patch as an infected turtle

Switches:

WANDER? - when on, the androids wander randomly.  When off, they sit still  
SHOW-SICK? - when on, sick turtles add to their original shape a red circle.  When off, they can move through the populace unnoticed  
SHOW-SICK-ON-CLIENTS? - when on, the clients will be told if their turtle is sick or not.

Monitors:

TURTLES - the number of turtles in the simulation  
NUMBER SICK - the number of turtles that are infected

Plots:

NUMBER SICK - shows the number of sick turtles versus time

Client Information

After logging in, the client interface will appear for the students, and if GO is pressed in NetLogo they will be assigned a turtle which will be described in the YOU ARE A: monitor.  And their current location will be shown in the LOCATED AT: monitor.  If the student doesn't like their assigned shape and/or color they can hit the CHANGE APPEARANCE button at any time to change to another random appearance.

The SICK? monitor will show one of three values: "true" "false" or "N/A".  "N/A" will be shown if the NetLogo SHOW-ILL-ON-CLIENTS? switch is off, otherwise "true" will be shown if your turtle is infected, or "false" will be shown if your turtle is not infected.

The student controls the movement of their turtle with the UP, DOWN, LEFT, and RIGHT buttons and the STEP-SIZE slider.  Clicking any of the directional buttons will cause their turtle to move in the respective direction a distance of STEP-SIZE.

## THINGS TO NOTICE

No matter how you change the various parameters, the same basic plot shape emerges.  After using the model once with the students, ask them how they think the plot will change if you alter a parameter.  Altering the initial percentage sick and the infection chance will have different effects on the plot.

## THINGS TO TRY

Use the model with the entire class to serve as an introduction to the topic.  Then have students use the NetLogo model individually, in a computer lab, to explore the effects of the various parameters.  Discuss what they find, observe, and can conclude from this model.

## EXTENDING THE MODEL

Currently, the turtles remain sick once they're infected.  How would the shape of the plot change if turtles eventually healed?  If, after healing, they were immune to the disease, or could still spread the disease, how would the dynamics be altered?

## HOW TO CITE

If you mention this model in an academic publication, we ask that you include these citations for the model itself and for the NetLogo software:  
- Wilensky, U. and Stroup, W. (1999). NetLogo HubNet Disease model.  http://ccl.northwestern.edu/netlogo/models/HubNetDisease.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.  
- Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

In other publications, please use:  
- Copyright 1999 Uri Wilensky and Walter Stroup. All rights reserved. See http://ccl.northwestern.edu/netlogo/models/HubNetDisease for terms of use.

## COPYRIGHT NOTICE

Copyright 1999 Uri Wilensky and Walter Stroup. All rights reserved.

Permission to use, modify or redistribute this model is hereby granted, provided that both of the following requirements are followed:  
a) this copyright notice is included.  
b) this model will not be redistributed for profit without permission from the copyright holders. Contact the copyright holders for appropriate licenses for redistribution for profit.

This activity and associated models and materials were created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

airplane sick
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15
Circle -2674135 true false 150 165 90

android
false
0
Polygon -7500403 true true 210 90 240 195 210 210 165 90
Circle -7500403 true true 110 3 80
Polygon -7500403 true true 105 88 120 193 105 240 105 298 135 300 150 210 165 300 195 298 195 240 180 193 195 88
Rectangle -7500403 true true 127 81 172 96
Rectangle -16777216 true false 135 33 165 60
Polygon -7500403 true true 90 90 60 195 90 210 135 90

android sick
false
0
Polygon -7500403 true true 210 90 240 195 210 210 165 90
Circle -7500403 true true 110 3 80
Polygon -7500403 true true 105 88 120 193 105 240 105 298 135 300 150 210 165 300 195 298 195 240 180 193 195 88
Rectangle -7500403 true true 127 81 172 96
Rectangle -16777216 true false 135 33 165 60
Polygon -7500403 true true 90 90 60 195 90 210 135 90
Circle -2674135 true false 150 120 120

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

box sick
false
0
Polygon -7500403 true true 150 285 270 225 270 90 150 150
Polygon -7500403 true true 150 150 30 90 150 30 270 90
Polygon -7500403 true true 30 90 30 225 150 285 150 150
Line -16777216 false 150 285 150 150
Line -16777216 false 150 150 30 90
Line -16777216 false 150 150 270 90
Circle -2674135 true false 170 178 108

butterfly
false
0
Rectangle -7500403 true true 92 135 207 224
Circle -7500403 true true 158 53 134
Circle -7500403 true true 165 180 90
Circle -7500403 true true 45 180 90
Circle -7500403 true true 8 53 134
Line -16777216 false 43 189 253 189
Rectangle -7500403 true true 135 60 165 285
Circle -7500403 true true 165 15 30
Circle -7500403 true true 105 15 30
Line -7500403 true 120 30 135 60
Line -7500403 true 165 60 180 30
Line -16777216 false 135 60 135 285
Line -16777216 false 165 285 165 60

butterfly sick
false
0
Rectangle -7500403 true true 92 135 207 224
Circle -7500403 true true 158 53 134
Circle -7500403 true true 165 180 90
Circle -7500403 true true 45 180 90
Circle -7500403 true true 8 53 134
Line -16777216 false 43 189 253 189
Rectangle -7500403 true true 135 60 165 285
Circle -7500403 true true 165 15 30
Circle -7500403 true true 105 15 30
Line -7500403 true 120 30 135 60
Line -7500403 true 165 60 180 30
Line -16777216 false 135 60 135 285
Line -16777216 false 165 285 165 60
Circle -2674135 true false 156 171 108

cactus
false
0
Rectangle -7500403 true true 135 30 175 177
Rectangle -7500403 true true 67 105 100 214
Rectangle -7500403 true true 217 89 251 167
Rectangle -7500403 true true 157 151 220 185
Rectangle -7500403 true true 94 189 148 233
Rectangle -7500403 true true 135 162 184 297
Circle -7500403 true true 219 76 28
Circle -7500403 true true 138 7 34
Circle -7500403 true true 67 93 30
Circle -7500403 true true 201 145 40
Circle -7500403 true true 69 193 40

cactus sick
false
0
Rectangle -7500403 true true 135 30 175 177
Rectangle -7500403 true true 67 105 100 214
Rectangle -7500403 true true 217 89 251 167
Rectangle -7500403 true true 157 151 220 185
Rectangle -7500403 true true 94 189 148 233
Rectangle -7500403 true true 135 162 184 297
Circle -7500403 true true 219 76 28
Circle -7500403 true true 138 7 34
Circle -7500403 true true 67 93 30
Circle -7500403 true true 201 145 40
Circle -7500403 true true 69 193 40
Circle -2674135 true false 156 171 108

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

car sick
false
0
Polygon -7500403 true true 285 208 285 178 279 164 261 144 240 135 226 132 213 106 199 84 171 68 149 68 129 68 75 75 15 150 15 165 15 225 285 225 283 174 283 176
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 195 90 135 90 135 135 210 135 195 105 165 90
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58
Circle -2674135 true false 171 156 108

cat
false
0
Line -7500403 true 285 240 210 240
Line -7500403 true 195 300 165 255
Line -7500403 true 15 240 90 240
Line -7500403 true 285 285 195 240
Line -7500403 true 105 300 135 255
Line -16777216 false 150 270 150 285
Line -16777216 false 15 75 15 120
Polygon -7500403 true true 300 15 285 30 255 30 225 75 195 60 255 15
Polygon -7500403 true true 285 135 210 135 180 150 180 45 285 90
Polygon -7500403 true true 120 45 120 210 180 210 180 45
Polygon -7500403 true true 180 195 165 300 240 285 255 225 285 195
Polygon -7500403 true true 180 225 195 285 165 300 150 300 150 255 165 225
Polygon -7500403 true true 195 195 195 165 225 150 255 135 285 135 285 195
Polygon -7500403 true true 15 135 90 135 120 150 120 45 15 90
Polygon -7500403 true true 120 195 135 300 60 285 45 225 15 195
Polygon -7500403 true true 120 225 105 285 135 300 150 300 150 255 135 225
Polygon -7500403 true true 105 195 105 165 75 150 45 135 15 135 15 195
Polygon -7500403 true true 285 120 270 90 285 15 300 15
Line -7500403 true 15 285 105 240
Polygon -7500403 true true 15 120 30 90 15 15 0 15
Polygon -7500403 true true 0 15 15 30 45 30 75 75 105 60 45 15
Line -16777216 false 164 262 209 262
Line -16777216 false 223 231 208 261
Line -16777216 false 136 262 91 262
Line -16777216 false 77 231 92 261

cat sick
false
0
Line -7500403 true 285 240 210 240
Line -7500403 true 195 300 165 255
Line -7500403 true 15 240 90 240
Line -7500403 true 285 285 195 240
Line -7500403 true 105 300 135 255
Line -16777216 false 150 270 150 285
Line -16777216 false 15 75 15 120
Polygon -7500403 true true 300 15 285 30 255 30 225 75 195 60 255 15
Polygon -7500403 true true 285 135 210 135 180 150 180 45 285 90
Polygon -7500403 true true 120 45 120 210 180 210 180 45
Polygon -7500403 true true 180 195 165 300 240 285 255 225 285 195
Polygon -7500403 true true 180 225 195 285 165 300 150 300 150 255 165 225
Polygon -7500403 true true 195 195 195 165 225 150 255 135 285 135 285 195
Polygon -7500403 true true 15 135 90 135 120 150 120 45 15 90
Polygon -7500403 true true 120 195 135 300 60 285 45 225 15 195
Polygon -7500403 true true 120 225 105 285 135 300 150 300 150 255 135 225
Polygon -7500403 true true 105 195 105 165 75 150 45 135 15 135 15 195
Polygon -7500403 true true 285 120 270 90 285 15 300 15
Line -7500403 true 15 285 105 240
Polygon -7500403 true true 15 120 30 90 15 15 0 15
Polygon -7500403 true true 0 15 15 30 45 30 75 75 105 60 45 15
Line -16777216 false 164 262 209 262
Line -16777216 false 223 231 208 261
Line -16777216 false 136 262 91 262
Line -16777216 false 77 231 92 261
Circle -2674135 true false 186 186 108

cow skull
false
0
Polygon -7500403 true true 150 90 75 105 60 150 75 210 105 285 195 285 225 210 240 150 225 105
Polygon -16777216 true false 150 150 90 195 90 150
Polygon -16777216 true false 150 150 210 195 210 150
Polygon -16777216 true false 105 285 135 270 150 285 165 270 195 285
Polygon -7500403 true true 240 150 263 143 278 126 287 102 287 79 280 53 273 38 261 25 246 15 227 8 241 26 253 46 258 68 257 96 246 116 229 126
Polygon -7500403 true true 60 150 37 143 22 126 13 102 13 79 20 53 27 38 39 25 54 15 73 8 59 26 47 46 42 68 43 96 54 116 71 126

cow skull sick
false
0
Polygon -7500403 true true 150 90 75 105 60 150 75 210 105 285 195 285 225 210 240 150 225 105
Polygon -16777216 true false 150 150 90 195 90 150
Polygon -16777216 true false 150 150 210 195 210 150
Polygon -16777216 true false 105 285 135 270 150 285 165 270 195 285
Polygon -7500403 true true 240 150 263 143 278 126 287 102 287 79 280 53 273 38 261 25 246 15 227 8 241 26 253 46 258 68 257 96 246 116 229 126
Polygon -7500403 true true 60 150 37 143 22 126 13 102 13 79 20 53 27 38 39 25 54 15 73 8 59 26 47 46 42 68 43 96 54 116 71 126
Circle -2674135 true false 156 186 108

dog
false
0
Polygon -7500403 true true 300 165 300 195 270 210 183 204 180 240 165 270 165 300 120 300 0 240 45 165 75 90 75 45 105 15 135 45 165 45 180 15 225 15 255 30 225 30 210 60 225 90 225 105
Polygon -16777216 true false 0 240 120 300 165 300 165 285 120 285 10 221
Line -16777216 false 210 60 180 45
Line -16777216 false 90 45 90 90
Line -16777216 false 90 90 105 105
Line -16777216 false 105 105 135 60
Line -16777216 false 90 45 135 60
Line -16777216 false 135 60 135 45
Line -16777216 false 181 203 151 203
Line -16777216 false 150 201 105 171
Circle -16777216 true false 171 88 34
Circle -16777216 false false 261 162 30

dog sick
false
0
Polygon -7500403 true true 300 165 300 195 270 210 183 204 180 240 165 270 165 300 120 300 0 240 45 165 75 90 75 45 105 15 135 45 165 45 180 15 225 15 255 30 225 30 210 60 225 90 225 105
Polygon -16777216 true false 0 240 120 300 165 300 165 285 120 285 10 221
Line -16777216 false 210 60 180 45
Line -16777216 false 90 45 90 90
Line -16777216 false 90 90 105 105
Line -16777216 false 105 105 135 60
Line -16777216 false 90 45 135 60
Line -16777216 false 135 60 135 45
Line -16777216 false 181 203 151 203
Line -16777216 false 150 201 105 171
Circle -16777216 true false 171 88 34
Circle -16777216 false false 261 162 30
Circle -2674135 true false 126 186 108

ghost
false
0
Polygon -7500403 true true 30 165 13 164 -2 149 0 135 -2 119 0 105 15 75 30 75 58 104 43 119 43 134 58 134 73 134 88 104 73 44 78 14 103 -1 193 -1 223 29 208 89 208 119 238 134 253 119 240 105 238 89 240 75 255 60 270 60 283 74 300 90 298 104 298 119 300 135 285 135 285 150 268 164 238 179 208 164 208 194 238 209 253 224 268 239 268 269 238 299 178 299 148 284 103 269 58 284 43 299 58 269 103 254 148 254 193 254 163 239 118 209 88 179 73 179 58 164
Line -16777216 false 189 253 215 253
Circle -16777216 true false 102 30 30
Polygon -16777216 true false 165 105 135 105 120 120 105 105 135 75 165 75 195 105 180 120
Circle -16777216 true false 160 30 30

ghost sick
false
0
Polygon -7500403 true true 30 165 13 164 -2 149 0 135 -2 119 0 105 15 75 30 75 58 104 43 119 43 134 58 134 73 134 88 104 73 44 78 14 103 -1 193 -1 223 29 208 89 208 119 238 134 253 119 240 105 238 89 240 75 255 60 270 60 283 74 300 90 298 104 298 119 300 135 285 135 285 150 268 164 238 179 208 164 208 194 238 209 253 224 268 239 268 269 238 299 178 299 148 284 103 269 58 284 43 299 58 269 103 254 148 254 193 254 163 239 118 209 88 179 73 179 58 164
Line -16777216 false 189 253 215 253
Circle -16777216 true false 102 30 30
Polygon -16777216 true false 165 105 135 105 120 120 105 105 135 75 165 75 195 105 180 120
Circle -16777216 true false 160 30 30
Circle -2674135 true false 156 171 108

heart
false
0
Circle -7500403 true true 152 19 134
Polygon -7500403 true true 150 105 240 105 270 135 150 270
Polygon -7500403 true true 150 105 60 105 30 135 150 270
Line -7500403 true 150 270 150 135
Rectangle -7500403 true true 135 90 180 135
Circle -7500403 true true 14 19 134

heart sick
false
0
Circle -7500403 true true 152 19 134
Polygon -7500403 true true 150 105 240 105 270 135 150 270
Polygon -7500403 true true 150 105 60 105 30 135 150 270
Line -7500403 true 150 270 150 135
Rectangle -7500403 true true 135 90 180 135
Circle -7500403 true true 14 19 134
Circle -2674135 true false 171 156 108

key
false
0
Rectangle -7500403 true true 90 120 300 150
Rectangle -7500403 true true 270 135 300 195
Rectangle -7500403 true true 195 135 225 195
Circle -7500403 true true 0 60 150
Circle -16777216 true false 30 90 90

key sick
false
0
Rectangle -7500403 true true 90 120 300 150
Rectangle -7500403 true true 270 135 300 195
Rectangle -7500403 true true 195 135 225 195
Circle -7500403 true true 0 60 150
Circle -16777216 true false 30 90 90
Circle -2674135 true false 156 171 108

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

leaf sick
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195
Circle -2674135 true false 141 171 108

monster
false
0
Polygon -7500403 true true 75 150 90 195 210 195 225 150 255 120 255 45 180 0 120 0 45 45 45 120
Circle -16777216 true false 165 60 60
Circle -16777216 true false 75 60 60
Polygon -7500403 true true 225 150 285 195 285 285 255 300 255 210 180 165
Polygon -7500403 true true 75 150 15 195 15 285 45 300 45 210 120 165
Polygon -7500403 true true 210 210 225 285 195 285 165 165
Polygon -7500403 true true 90 210 75 285 105 285 135 165
Rectangle -7500403 true true 135 165 165 270

monster sick
false
0
Polygon -7500403 true true 75 150 90 195 210 195 225 150 255 120 255 45 180 0 120 0 45 45 45 120
Circle -16777216 true false 165 60 60
Circle -16777216 true false 75 60 60
Polygon -7500403 true true 225 150 285 195 285 285 255 300 255 210 180 165
Polygon -7500403 true true 75 150 15 195 15 285 45 300 45 210 120 165
Polygon -7500403 true true 210 210 225 285 195 285 165 165
Polygon -7500403 true true 90 210 75 285 105 285 135 165
Rectangle -7500403 true true 135 165 165 270
Circle -2674135 true false 141 141 108

moon
false
0
Polygon -7500403 true true 175 7 83 36 25 108 27 186 79 250 134 271 205 274 281 239 207 233 152 216 113 185 104 132 110 77 132 51

moon sick
false
0
Polygon -7500403 true true 160 7 68 36 10 108 12 186 64 250 119 271 190 274 266 239 192 233 137 216 98 185 89 132 95 77 117 51
Circle -2674135 true false 171 171 108

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

star sick
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108
Circle -2674135 true false 156 171 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

target sick
true
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60
Circle -2674135 true false 163 163 95

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wheel sick
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269
Circle -2674135 true false 156 156 108

@#$#@#$#@
NetLogo 5.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
252
10
672
430
0
0
0
1
1
1
1
1
0
1
1
1
-10
10
-10
10

BUTTON
96
256
158
289
Up
NIL
NIL
1
T
OBSERVER
NIL
I

BUTTON
96
322
158
355
Down
NIL
NIL
1
T
OBSERVER
NIL
K

BUTTON
158
289
220
322
Right
NIL
NIL
1
T
OBSERVER
NIL
L

BUTTON
34
288
96
321
Left
NIL
NIL
1
T
OBSERVER
NIL
J

SLIDER
36
381
220
414
step-size
step-size
1
5
1
1
1
NIL
HORIZONTAL

MONITOR
158
105
245
154
Located at:
NIL
3
1

MONITOR
5
105
155
154
You are a:
NIL
3
1

MONITOR
158
159
245
208
Sick?
NIL
3
1

BUTTON
4
158
154
208
Change Appearance
NIL
NIL
1
T
OBSERVER
NIL
NIL

MONITOR
157
15
247
64
Number Sick
NIL
0
1

MONITOR
97
15
154
64
Turtles
NIL
0
1

@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
