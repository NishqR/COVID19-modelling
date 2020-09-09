extensions [ time ]
breed [houses house]
breed [persons person]
breed [workplaces workplace]
breed [shops shop]


globals[
  infected-persons
  currently-infected
  r-zero
  tick-counter

  positional-xcor-list
  positional-ycor-list
  cbd-xcor-list
  cbd-ycor-list
  int-cbd-xcor-list
  int-cbd-ycor-list
  house-xcor
  house-ycor
  shops-xcor
  shops-ycor

  cbd-min-x
  cbd-max-x
  cbd-min-y
  cbd-max-y


  shops-roll
  total-dead
  total-recovered
  num-days

  economy
]

persons-own [
  infected?    ;; has the person been infected with the disease?
  immune?

  persons-house
  persons-workplace
  persons-shop
  shops-or-work

  incubation-period
  total-days-with-covid
  infectious-days
  infectious-period

  am-i-going-to-die
  will-i-stay-at-home
  depart-wave
  leave-home-time
  leave-shops-time
  leave-work-time


]

patches-own [
  p-infected?  ;; in the environmental variant, has the patch been infected?
  infect-time  ;; how long until the end of the patch infection?
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all

  set int-cbd-xcor-list []
  set int-cbd-ycor-list []

  set tick-counter 1

  ;; set world size depending on input
  resize-world 0 max-xcor 0 max-ycor


  ;; lists of all values in range of max-xcor and max-ycor
  set positional-xcor-list n-values (max-xcor) [i -> i]
  set positional-ycor-list n-values (max-ycor) [i -> i]

  ;; set patch size depending on input
  set-patch-size patch-sizer

  setup-cbd
  make-workplaces
  make-houses
  make-shops
  make-persons

  ;;show item 0 n-of 1 house-xcor-list



  infect
  recolor

  if policy-intervention? = true [
    set economy count persons with [(depart-wave <= percentage-daily-travel)]
  ]
  if policy-intervention? = false [
    set economy num-people
  ]
  set num-days 0
  set total-dead 0
  set total-recovered 0
  reset-ticks
end

to setup-cbd

  set cbd-min-x ( (max-xcor / 2) - (cbd-size / 2) )
  set cbd-max-x ( (max-xcor / 2) + (cbd-size / 2) )
  set cbd-min-y ( (max-ycor / 2) - (cbd-size / 2) )
  set cbd-max-y ( (max-ycor / 2) + (cbd-size / 2) )


  set cbd-xcor-list (range cbd-min-x cbd-max-x)
  set cbd-ycor-list (range cbd-min-y cbd-max-y)

  ;; convert cbd-xcor-list and cbd-ycor-list into int values
  foreach cbd-xcor-list [x -> set int-cbd-xcor-list insert-item 0 int-cbd-xcor-list int x]
  foreach cbd-ycor-list [y -> set int-cbd-ycor-list insert-item 0 int-cbd-ycor-list int y]

  ;; set border patches of cbd to grey to visualize it
  ask patches with [pxcor = int (cbd-min-x - 2) and pycor >= int (cbd-min-y - 2) and pycor < int (cbd-max-y + 2)] [ set pcolor grey ]
  ask patches with [pxcor = int (cbd-max-x + 2) and pycor >= int (cbd-min-y - 2) and pycor < int (cbd-max-y + 2)] [ set pcolor grey ]
  ask patches with [pycor = int (cbd-min-y - 2) and pxcor >= int (cbd-min-x - 2) and pxcor < int (cbd-max-x + 2)] [ set pcolor grey ]
  ask patches with [pycor = int (cbd-max-y + 2) and pxcor >= int (cbd-min-x - 2) and pxcor < int (cbd-max-x + 3)] [ set pcolor grey ]


end


to make-houses

  create-houses num-houses [


    ;; take a random x and y value from the list of all possible positions
    set house-xcor item 0 n-of 1 positional-xcor-list
    set house-ycor item 0 n-of 1 positional-ycor-list


    ;; if even one of x and y values that we took above are in the cbd coordinate list, take new values,
    ;; keep doing this till we have x and y values outside the cbd
    while [ (member? house-xcor int-cbd-xcor-list) and (member? house-ycor int-cbd-ycor-list) ]
    [set house-xcor item 0 n-of 1 positional-xcor-list
    set house-ycor item 0 n-of 1 positional-ycor-list
    ]

    ;; padding to ensure the houses aren't on the cbd border
    if house-xcor > (max-xcor / 2)
    [ set house-xcor house-xcor + 4]
    if house-xcor <= (max-xcor / 2)
    [ set house-xcor house-xcor - 4]

    if house-ycor > (max-ycor / 2)
    [ set house-ycor house-ycor + 4]
    if house-ycor <= (max-ycor / 2)
    [ set house-ycor house-ycor - 4]

    ;; set shape, coordinates, size and color for each house
    set shape "house"
    setxy house-xcor house-ycor
    set size 2
    set color 35
  ]
end



to make-workplaces

  create-workplaces num-workplaces [
    set shape "factory"
    setxy item 0 n-of 1 int-cbd-xcor-list item 0 n-of 1 int-cbd-ycor-list
    set size 3
    set color blue
  ]
end

;; shops can be in the cbd or suburbs
to make-shops


  create-shops num-shops [

    ;; rolls a value between 0 and 1, if 0 we place the shop in the cbd, else we place it outside
    set shops-roll random 2

    (ifelse
    shops-roll = 0 [
      setxy item 0 n-of 1 cbd-xcor-list item 0 n-of 1 cbd-ycor-list
    ]
    ;; same code as that for houses
    shops-roll = 1 [
        set shops-xcor item 0 n-of 1 positional-xcor-list
        set shops-ycor item 0 n-of 1 positional-ycor-list

        while [ (member? shops-xcor int-cbd-xcor-list) and (member? shops-ycor int-cbd-ycor-list) ]
        [set shops-xcor item 0 n-of 1 positional-xcor-list
          set shops-ycor item 0 n-of 1 positional-ycor-list
        ]

        if shops-xcor > (max-xcor / 2)
        [ set shops-xcor shops-xcor + 4]
        if shops-xcor <= (max-xcor / 2)
        [ set shops-xcor shops-xcor - 4]

        if shops-ycor > (max-ycor / 2)
        [ set shops-ycor shops-ycor + 4]
        if shops-ycor <= (max-ycor / 2)
        [ set shops-ycor shops-ycor - 4]

        setxy shops-xcor shops-ycor
      ]
      )
    ;; set shape, size and color of each shop
    set shape "building store"
    set size 1.75
    set color 125

  ]
end


to make-persons

  set-default-shape persons "person"
  create-persons num-people [
    set infected? false
    set immune? false

    set infected-persons 0

    ;; assign a house to each person
    set persons-house one-of houses

    ;; set person's coordinates around the house
    setxy ([xcor] of persons-house + random 3) ([ycor] of persons-house - random 3)

    ;; assign a workplace to each person
    set persons-workplace one-of workplaces
    ;; assign a shop to each person
    set persons-shop one-of shops

    ;; set a random value to determine whether the person will go to the shops or work
    ;; 1/3rds of the time they go to the shops, 2/3rds of the time they go to work
    set shops-or-work random 3

    set depart-wave random 100

    ;;show item 0 n-of 1 (range 200 300)
    set leave-home-time random 100
    set leave-shops-time item 0 n-of 1 (range 100 400)
    set leave-work-time item 0 n-of 1 (range 400 1000)



  ]
end



to infect
  ask n-of num-infected persons [
    set infected? true

    set total-days-with-covid 0
    ;; incubation period falls in normal distribution with mean 7 and sd 2.3
    set incubation-period int random-normal 7 2.3

    ;; infectious days can start up to 3 days prior to end of incubation period
    set infectious-days 1 + random 3
    set infectious-period (incubation-period - infectious-days)

    ;; random number picked from 1 to 100
    set am-i-going-to-die random-float 100

    ;; random number picked from 0 to 100
    set will-i-stay-at-home random-float 100


  ]
end

to recolor
  ask persons [

    (ifelse

      ;; if a person is infected
      infected? = true [
        ;; and they are in the infectious period, set their color to red
        if (total-days-with-covid >= incubation-period) and (total-days-with-covid < (incubation-period - infectious-days) + 10)[
          set color red
        ]
        if (total-days-with-covid >= infectious-period) and (total-days-with-covid < incubation-period) [
          set color orange
        ]
        ;; else if they are infected but not infectious to others, set color to yellow
        if total-days-with-covid < infectious-period [
          set color yellow
        ]
      ]
      ;; otherwise set their color to grey
      infected? = false [
        if total-days-with-covid = 0 [
          set color gray
        ]
      ]
      )


  ]

end

;;;;;;;;;;;;;;;;;;;;;;;
;;; Main Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;

to go
  if all? persons [ immune? ] [ stop ]
  if count persons with [ infected? = true ] = 0 [ stop ]

  set num-people count persons
  calculate-r-zero

  spread-infection
  recover-or-die
  recolor
  if policy-intervention? = true [
    calculate-economy-with-intervention

    move-with-policy-intervention
  ]
  if policy-intervention? = false [
    calculate-economy
    move
  ]
  ;;
  tick
end

to calculate-economy-with-intervention
  (ifelse
    ticks = 1 []

    ;; if it's the end of the day, calculate the economy
    ticks = 1440 [

        set economy count persons with [ (depart-wave <= percentage-daily-travel) or immune? = true]

    ]
    )
end


to calculate-economy

  (ifelse
    ticks = 1 [
    ]

    ;; if it's the end of the day, calculate the economy
    ticks = 1440 [
      if staying-home-when-sick? = false [
        set economy num-people
      ]
      if staying-home-when-sick? = true [
        ;;show count persons with [infected? = true and (total-days-with-covid >= incubation-period) and (will-i-stay-at-home <= percentage-staying-home )]
        set economy num-people - count persons with [infected? = true and (total-days-with-covid >= incubation-period) and (will-i-stay-at-home <= percentage-staying-home )]
      ]
      show economy
    ]
    )

end



to calculate-r-zero

  (ifelse
  ;; new day
  tick-counter = 1 [
    ;;show "counter reset"
    set infected-persons 0
    set currently-infected count persons with [infected?]
  ]

  ;; end of day
  tick-counter = 1440 [

    if currently-infected > 0 [
        set r-zero infected-persons / currently-infected

      ]
    set tick-counter 0
  ])


  set tick-counter tick-counter + 1
end

to limit-travel
  ask persons with [infected? ] [

    if total-days-with-covid >= incubation-period [

    ]
  ]

end
to recover-or-die
  ask persons with [ infected? ] [

    ;; people can die at random after getting symptomatic
    if total-days-with-covid >= (incubation-period + (random 10) )[
      if am-i-going-to-die < mortality-rate and fatalities? = true [
        set total-dead total-dead + 1
        die
        ]
    ]
    ;; people can recover if they cross the symptomatic period
    if total-days-with-covid >= (incubation-period + 10) [

       if fatalities? = true [
        if am-i-going-to-die >= mortality-rate [
          set infected? false
          set immune? true
          set total-recovered total-recovered + 1
          set color green
        ]
      ]
      if fatalities? = false [
        set infected? false
        set immune? true
        set total-recovered total-recovered + 1
        set color green
      ]

    ]


  ]
end

to spread-infection

  ask persons with [ infected? ] [

    ;;if ( total-days-with-covid >= infectious-period ) and (total-days-with-covid < (incubation-period - infectious-days) + 10) and (random 100 = 0) [
    if ( count persons-here > 1 ) and ( total-days-with-covid >= infectious-period ) and (total-days-with-covid < (incubation-period - infectious-days) + 10)[;; and (random 250 = 0) [

      ask persons-here [
        if infected? = false and immune? = false[


          set infected? true
          set infected-persons infected-persons + 1

          set total-days-with-covid 0

          set incubation-period int random-normal 7 2.3
          ;; infectious days can start up to 3 days prior to end of incubation period
          set infectious-days 1 + random 3
          set infectious-period (incubation-period - infectious-days)

          set am-i-going-to-die random-float 100
          set will-i-stay-at-home random-float 100

        ]
    ]
    ]


    ]



end

;;;;;;;;;;;;;;
;;; Layout ;;;
;;;;;;;;;;;;;;
to move-with-policy-intervention
  ask persons with [(depart-wave <= percentage-daily-travel) or immune? = true] [
    if ticks < leave-home-time [
      move-home
    ]
      if ticks >= leave-home-time and ticks < leave-shops-time   [
      (
      ifelse staying-home-when-sick? = true [
         (ifelse
            infected? = true and (total-days-with-covid >= incubation-period) and (will-i-stay-at-home <= percentage-staying-home ) [
              move-home
            ]
            ;;else statement
            [ move-to-shops-or-work ]
          )
        ]
      [
          move-to-shops-or-work
      ]

      )

    ]


      if ticks >= leave-shops-time and ticks < leave-work-time [
      (
      ifelse staying-home-when-sick? = true [
         (ifelse
            infected? = true and (total-days-with-covid >= incubation-period) and (will-i-stay-at-home <= percentage-staying-home) [
              move-home
            ]
            ;;else statement
            [ move-to-work-or-home]
          )
        ]
      [
          move-to-work-or-home
      ]

      )
    ]


    if ticks >= leave-work-time and ticks < 1440 [

      move-home

    ]
  ]
  ask persons with [(depart-wave > percentage-daily-travel) and immune? = false ] [
    move-home
  ]

  if ticks >= 1440 [

    ask persons[
      ;;people may want to go to a different shop
      set persons-shop one-of shops

      ;;odds of going to shops or work on a given day
      set shops-or-work random 3
      set depart-wave random 100
      if infected? = true [
        set total-days-with-covid total-days-with-covid + 1
    ]

    ]
    set num-days num-days + 1
    reset-ticks

  ]
end

to move


    ask persons [
      if ticks < leave-home-time [
      move-home
    ]
      if ticks >= leave-home-time and ticks < leave-shops-time   [
      (
      ifelse staying-home-when-sick? = true [
         (ifelse
            infected? = true and (total-days-with-covid >= incubation-period) and (will-i-stay-at-home <= percentage-staying-home ) [
              move-home
            ]
            ;;else statement
            [ move-to-shops-or-work ]
          )
        ]
      [
          move-to-shops-or-work
      ]

      )

    ]


      if ticks >= leave-shops-time and ticks < leave-work-time [
      (
      ifelse staying-home-when-sick? = true [
         (ifelse
            infected? = true and (total-days-with-covid >= incubation-period) and (will-i-stay-at-home <= percentage-staying-home) [
              move-home
            ]
            ;;else statement
            [ move-to-work-or-home]
          )
        ]
      [
          move-to-work-or-home
      ]

      )
    ]


    if ticks >= leave-work-time and ticks < 1440 [

      move-home

    ]
  ]

  if ticks >= 1440 [

    ask persons[
      ;;people may want to go to a different shop
      set persons-shop one-of shops

      ;;odds of going to shops or work on a given day
      set shops-or-work random 3

      if infected? = true [
        set total-days-with-covid total-days-with-covid + 1
    ]

    ]
    set num-days num-days + 1
    reset-ticks

  ]

end

to move-home
  facexy [xcor] of persons-house [ycor] of persons-house
      fd random-float 3
end

to move-to-shops-or-work
  (ifelse shops-or-work = 0 [
        facexy [xcor] of persons-shop [ycor] of persons-shop
      fd random-float 3
        ]
        shops-or-work > 0 [
    facexy [xcor] of persons-workplace [ycor] of persons-workplace
      fd random-float 3
        ]
        )
end

to move-to-work-or-home
  (ifelse shops-or-work = 0 [
        facexy [xcor] of persons-house [ycor] of persons-house
      fd random-float 3
        ]
        shops-or-work > 0 [
    facexy [xcor] of persons-workplace [ycor] of persons-workplace
      fd random-float 3
        ]
        )
end


;; This procedure allows you to run the model multiple times
;; and measure how long it takes for the disease to spread to
;; all people in each run. For more complex experiments, you
;; would use the BehaviorSpace tool instead.
to my-experiment
  repeat 10 [
    set num-people 50
    setup
    while [ not all? persons [ infected? ] ] [ go ]
    print ticks
  ]
end


; Copyright 2008 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
790
10
1878
774
-1
-1
5.0
1
10
1
1
1
0
1
1
1
0
215
0
150
1
1
1
ticks
120.0

BUTTON
605
10
695
45
setup
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

BUTTON
605
60
695
95
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
10
10
180
43
num-people
num-people
2
1000
487.0
1
1
NIL
HORIZONTAL

BUTTON
705
60
785
95
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
10
55
180
88
num-infected
num-infected
0
100
10.0
1
1
NIL
HORIZONTAL

PLOT
15
330
560
570
Infection vs. Time
Days
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"non-infectious" 6.94E-4 0 -1184463 true "" "plot count persons with [ infected? and total-days-with-covid < infectious-period] ;;* 100 / count turtles\n"
"infectious" 6.94E-4 0 -2674135 true "" "plot count persons with [ infected? and (total-days-with-covid >= incubation-period) and (total-days-with-covid < (incubation-period - infectious-days) + 10)]"
"unexposed" 6.94E-4 0 -7500403 true "" "plot count persons with [ infected? = false ]"
"dead" 6.94E-4 0 -16777216 true "" "plot total-dead"
"recovered" 6.94E-4 0 -13840069 true "" "plot total-recovered"
"infectious but asymptomatic" 6.94E-4 0 -955883 true "" "plot count persons with [ infected? and (total-days-with-covid >= infectious-period) and (total-days-with-covid < incubation-period)]"

MONITOR
605
105
695
150
Infected
count persons with [ infected? ]
3
1
11

SLIDER
190
10
380
43
max-xcor
max-xcor
20
750
215.0
1
1
NIL
HORIZONTAL

SLIDER
190
55
380
88
max-ycor
max-ycor
20
600
150.0
1
1
NIL
HORIZONTAL

SLIDER
190
145
380
178
patch-sizer
patch-sizer
1
50
5.0
1
1
NIL
HORIZONTAL

PLOT
395
160
595
315
r-zero over days
Days
r-zero
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 6.94E-4 0 -16777216 true "" "plot r-zero"

SLIDER
190
190
380
223
num-houses
num-houses
0
1000
343.0
1
1
NIL
HORIZONTAL

SLIDER
190
235
380
268
num-workplaces
num-workplaces
0
100
39.0
1
1
NIL
HORIZONTAL

SLIDER
190
100
380
133
cbd-size
cbd-size
0
200
74.0
1
1
NIL
HORIZONTAL

SLIDER
190
280
380
313
num-shops
num-shops
0
100
35.0
1
1
NIL
HORIZONTAL

SLIDER
575
375
775
408
mortality-rate
mortality-rate
0
100
3.5
0.5
1
NIL
HORIZONTAL

MONITOR
605
160
695
205
NIL
total-dead
17
1
11

MONITOR
605
215
695
260
NIL
total-recovered
17
1
11

SWITCH
10
100
180
133
staying-home-when-sick?
staying-home-when-sick?
0
1
-1000

SLIDER
10
145
180
178
percentage-staying-home
percentage-staying-home
0
100
100.0
1
1
NIL
HORIZONTAL

PLOT
15
595
405
770
Symptomatic people staying home vs not
Days
Number of people
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"staying at home" 6.94E-4 0 -13791810 true "" "plot count persons with [will-i-stay-at-home <= percentage-staying-home and total-days-with-covid > incubation-period and infected? = true]"
"not staying at home" 6.94E-4 0 -2674135 true "" "plot count persons with [will-i-stay-at-home > percentage-staying-home and total-days-with-covid > incubation-period and infected? = true] "

PLOT
425
595
775
770
Daily trips by symptotic vs asymptotic
Days
Number of trips
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"asymptomatic" 6.94E-4 0 -4079321 true "" "plot count persons with [total-days-with-covid < incubation-period and infected? = true]"
"symptomatic" 6.94E-4 0 -2674135 true "" "if staying-home-when-sick? = true [ plot count persons with [will-i-stay-at-home > percentage-staying-home and total-days-with-covid > incubation-period and infected? = true] ]"
"total trips" 6.94E-4 0 -7500403 true "" "plot economy"
"symptomatic " 6.94E-4 0 -2674135 true "" "if staying-home-when-sick? = false [ plot count persons with [total-days-with-covid < incubation-period and infected? = true] ]"

SWITCH
575
330
775
363
fatalities?
fatalities?
0
1
-1000

PLOT
395
10
595
150
Economy over days
Days
Economy
0.0
10.0
0.0
1.25
true
false
"" ""
PENS
"default" 6.94E-4 0 -13840069 true "" "plot economy / num-people"

MONITOR
605
270
695
315
NIL
num-days
17
1
11

SWITCH
10
190
180
223
policy-intervention?
policy-intervention?
0
1
-1000

PLOT
575
420
775
570
fatalities
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 6.94E-4 0 -16777216 true "" "plot total-dead"

SLIDER
10
235
180
268
percentage-daily-travel
percentage-daily-travel
0
100
25.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## ACKNOWLEDGMENT

This model is from Chapter Six of the book "Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo", by Uri Wilensky & William Rand.

* Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, MA. MIT Press.

This model is in the IABM Textbook folder of the NetLogo Models Library. The model, as well as any updates to the model, can also be found on the textbook website: http://www.intro-to-abm.com/.

## WHAT IS IT?

This model explores the spread of disease in a number of different conditions and environments. In particular, it explores how making assumptions about the interactions of agents can drastically affect the results of the model.

## HOW IT WORKS

The SETUP procedure creates a population of agents. Depending on the value of the VARIANT chooser, these agents have different properties. In the NETWORK variant they are linked to each other through a social network. In the MOBILE and ENVIRONMENTAL variants they move around the landscape. At the start of the simulation, NUM-INFECTED of the agents are infected with a disease.

The GO procedure spreads the disease among the agents. In the case of the NETWORK variant this is along the social network links. In the case of the MOBILE or ENVIRONMENTAL variant, the disease is spread to nearby neighbors in the physical space. In the case of the ENVIRONMENTAL variant the disease is also spread via the environment. Finally, if the variant is either the MOBILE or ENVIRONMENTAL variant then the agents move.

## HOW TO USE IT

The NUM-PEOPLE slider controls the number of people in the world.

The VARIANT chooser controls how the infection spreads.

NUM-INFECTED controls how many individuals are initially infected with the disease.

The CONNECTIONS-PER-NODE slider controls how many connections to other nodes each node tries to make in the NETWORK variant.

The DISEASE-DECAY slider controls how quickly the disease leaves the current environment.

To use the model, set these parameters and then press SETUP.

Pressing the GO ONCE button spreads the disease for one tick. You can press the GO button to make the simulation run until all agents are infected.

The REDO LAYOUT button runs the layout-step procedure continuously to improve the layout of the network.

## THINGS TO NOTICE

How do the different variants affect the spread of the disease?

In particular, look at how the different parameters of the model influence the speed at which the disease spreads through the population. For example, in the "mobile" variant, the population (NUM-PEOPLE) clearly seem to be the main driving force for the speed of infection. Is that the case for the other two variants as well? Some suggestions of parameters to vary are given below under THINGS TO TRY.

Another thing that you may have noticed is that, in the "network" variant, there are cases where the disease will not spread to all people. This happens when the network has more than one [components](https://en.wikipedia.org/wiki/Connected_component_%28graph_theory%29) (isolated nodes, or groups of nodes that are not connected with the rest of the network) and that not all components get infected with the disease right from the start. NetLogo's [network extension](http://ccl.northwestern.edu/netlogo/docs/nw.html) has [a primitive](http://ccl.northwestern.edu/netlogo/docs/nw.html#weak-component-clusters) that can help you identify the components of a network.

## THINGS TO TRY

Set different values for the DISEASE-DECAY slider and run the ENVIRONMENTAL variant. How does the DISEASE-DECAY slider affect the results?

Similarly, set different values for the CONNECTIONS-PER-NODE slider and run the NETWORK variant. How does the CONNECTIONS-PER-NODE slider affect the results?

If you open the BehaviorSpace tool, you will see that we have a defined a few experiments that can be used to explore the behavior of the model more systematically. Try these out, and look at the data in the resulting CSV file. Are those results similar to what you obtained by manually playing with the model parameters? Can you confirm that using your favorite external analysis tool?

## EXTENDING THE MODEL

Can you think of additional variants and parameters that could affect the spread of a disease?

At the moment, in the environmental variant of the model, patches are either infected or not. DISEASE-DECAY allows you to set how long they stay infected, but they are fully contagious until they suddenly stop being infected. Do you think it would be more realistic to have their infection level decline gradually? The probability of a person catching the disease from a patch could become smaller as the infection level decreases on the patch. If you want to make the model look really nice, you could vary the color of the patch using the [`scale-color`](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#scale-color) primitive.

## RELATED MODELS

NetLogo is very good at simulating the spread of epidemics, so there are a few disease transmission model in the library:

- HIV
- Disease Solo
- Disease HubNet
- Disease Doctors HubNet
- epiDEM Basic
- epiDEM Travel and Control
- Virus on a Network

Some communication models are also very similar to disease transmission ones:

- Communication T-T Example
- Communication-T-T Network Example
- Language Change

## NETLOGO FEATURES

One particularity of this model is that it combines three different "variants" in the same model. The way this is accomplished in the code of the model is fairly simple: we have a few `if`-statements making the model behave slightly different, depending on the value of the VARIANT chooser.

A more interesting element is the **Infection vs. Time** plot. In the "mobile" and "network" variants, the plot is the same: we simply plot the number of infected persons. In the "environmental" variant, however, we want to plot an additional quantity: the number of infected patches. To achieve that, we use the "Plot update commands" field of our plot definition. Just like the "Pen update commands", these commands run every time a plot is updated (usually when calling [`tick`](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#tick)). In this case, we use the [`create-temporary-plot-pen`](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#create-temporary-plot-pen) primitive to make sure that we have a pen for the number of infected patches, and actually plot that number:

```
if variant = "environmental" [
  create-temporary-plot-pen "patches"
  plotxy ticks count patches with [ p-infected? ] / count patches
]
```

One nice thing about this NetLogo feature is that the temporary plot pen that we create is automatically added to the plot's legend (and removed from the legend when the plot is cleared, when calling [`clear-all`](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#clear-all)).

## HOW TO CITE

This model is part of the textbook, “Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo.”

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Rand, W., Wilensky, U. (2008).  NetLogo Spread of Disease model.  http://ccl.northwestern.edu/netlogo/models/SpreadofDisease.  Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the textbook as:

* Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, MA. MIT Press.

## COPYRIGHT AND LICENSE

Copyright 2008 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2008 Cite: Rand, W., Wilensky, U. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

food
false
0
Polygon -7500403 true true 30 105 45 255 105 255 120 105
Rectangle -7500403 true true 15 90 135 105
Polygon -7500403 true true 75 90 105 15 120 15 90 90
Polygon -7500403 true true 135 225 150 240 195 255 225 255 270 240 285 225 150 225
Polygon -7500403 true true 135 180 150 165 195 150 225 150 270 165 285 180 150 180
Rectangle -7500403 true true 135 195 285 210

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

house bungalow
false
0
Rectangle -7500403 true true 210 75 225 255
Rectangle -7500403 true true 90 135 210 255
Rectangle -16777216 true false 165 195 195 255
Line -16777216 false 210 135 210 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 150 75 150 150 75
Line -16777216 false 75 150 225 150
Line -16777216 false 195 120 225 150
Polygon -16777216 false false 165 195 150 195 180 165 210 195
Rectangle -16777216 true false 135 105 165 135

house colonial
false
0
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 45 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 60 195 105 240
Rectangle -16777216 true false 60 150 105 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Polygon -7500403 true true 30 135 285 135 240 90 75 90
Line -16777216 false 30 135 285 135
Line -16777216 false 255 105 285 135
Line -7500403 true 154 195 154 255
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 135 150 180 180

house efficiency
false
0
Rectangle -7500403 true true 180 90 195 195
Rectangle -7500403 true true 90 165 210 255
Rectangle -16777216 true false 165 195 195 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 165 75 165 150 90
Line -16777216 false 75 165 225 165

house ranch
false
0
Rectangle -7500403 true true 270 120 285 255
Rectangle -7500403 true true 15 180 270 255
Polygon -7500403 true true 0 180 300 180 240 135 60 135 0 180
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 45 195 105 240
Rectangle -16777216 true false 195 195 255 240
Line -7500403 true 75 195 75 240
Line -7500403 true 225 195 225 240
Line -16777216 false 270 180 270 255
Line -16777216 false 0 180 300 180

house two story
false
0
Polygon -7500403 true true 2 180 227 180 152 150 32 150
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 75 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 90 150 135 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Rectangle -7500403 true true 15 180 75 255
Polygon -7500403 true true 60 135 285 135 240 90 105 90
Line -16777216 false 75 135 75 180
Rectangle -16777216 true false 30 195 93 240
Line -16777216 false 60 135 285 135
Line -16777216 false 255 105 285 135
Line -16777216 false 0 180 75 180
Line -7500403 true 60 195 60 240
Line -7500403 true 154 195 154 255

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

person construction
false
0
Rectangle -7500403 true true 123 76 176 95
Polygon -1 true false 105 90 60 195 90 210 115 162 184 163 210 210 240 195 195 90
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Circle -7500403 true true 110 5 80
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -955883 true false 180 90 195 90 195 165 195 195 150 195 150 120 180 90
Polygon -955883 true false 120 90 105 90 105 165 105 195 150 195 150 120 120 90
Rectangle -16777216 true false 135 114 150 120
Rectangle -16777216 true false 135 144 150 150
Rectangle -16777216 true false 135 174 150 180
Polygon -955883 true false 105 42 111 16 128 2 149 0 178 6 190 18 192 28 220 29 216 34 201 39 167 35
Polygon -6459832 true false 54 253 54 238 219 73 227 78
Polygon -16777216 true false 15 285 15 255 30 225 45 225 75 255 75 270 45 285

person doctor
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -13345367 true false 135 90 150 105 135 135 150 150 165 135 150 105 165 90
Polygon -7500403 true true 105 90 60 195 90 210 135 105
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -1 true false 105 90 60 195 90 210 114 156 120 195 90 270 210 270 180 195 186 155 210 210 240 195 195 90 165 90 150 150 135 90
Line -16777216 false 150 148 150 270
Line -16777216 false 196 90 151 149
Line -16777216 false 104 90 149 149
Circle -1 true false 180 0 30
Line -16777216 false 180 15 120 15
Line -16777216 false 150 195 165 195
Line -16777216 false 150 240 165 240
Line -16777216 false 150 150 165 150

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

person graduate
false
0
Circle -16777216 false false 39 183 20
Polygon -1 true false 50 203 85 213 118 227 119 207 89 204 52 185
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -8630108 true false 90 19 150 37 210 19 195 4 105 4
Polygon -8630108 true false 120 90 105 90 60 195 90 210 120 165 90 285 105 300 195 300 210 285 180 165 210 210 240 195 195 90
Polygon -1184463 true false 135 90 120 90 150 135 180 90 165 90 150 105
Line -2674135 false 195 90 150 135
Line -2674135 false 105 90 150 135
Polygon -1 true false 135 90 150 105 165 90
Circle -1 true false 104 205 20
Circle -1 true false 41 184 20
Circle -16777216 false false 106 206 18
Line -2674135 false 208 22 208 57

person lumberjack
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -2674135 true false 60 196 90 211 114 155 120 196 180 196 187 158 210 211 240 196 195 91 165 91 150 106 150 135 135 91 105 91
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -6459832 true false 174 90 181 90 180 195 165 195
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -6459832 true false 126 90 119 90 120 195 135 195
Rectangle -6459832 true false 45 180 255 195
Polygon -16777216 true false 255 165 255 195 240 225 255 240 285 240 300 225 285 195 285 165
Line -16777216 false 135 165 165 165
Line -16777216 false 135 135 165 135
Line -16777216 false 90 135 120 135
Line -16777216 false 105 120 120 120
Line -16777216 false 180 120 195 120
Line -16777216 false 180 135 210 135
Line -16777216 false 90 150 105 165
Line -16777216 false 225 165 210 180
Line -16777216 false 75 165 90 180
Line -16777216 false 210 150 195 165
Line -16777216 false 180 105 210 180
Line -16777216 false 120 105 90 180
Line -16777216 false 150 135 150 165
Polygon -2674135 true false 100 30 104 44 189 24 185 10 173 10 166 1 138 -1 111 3 109 28

person police
false
0
Polygon -1 true false 124 91 150 165 178 91
Polygon -13345367 true false 134 91 149 106 134 181 149 196 164 181 149 106 164 91
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -13345367 true false 120 90 105 90 60 195 90 210 116 158 120 195 180 195 184 158 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Polygon -13345367 true false 150 26 110 41 97 29 137 -1 158 6 185 0 201 6 196 23 204 34 180 33
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Rectangle -16777216 true false 109 183 124 227
Rectangle -16777216 true false 176 183 195 205
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Polygon -1184463 true false 172 112 191 112 185 133 179 133
Polygon -1184463 true false 175 6 194 6 189 21 180 21
Line -1184463 false 149 24 197 24
Rectangle -16777216 true false 101 177 122 187
Rectangle -16777216 true false 179 164 183 186

person service
false
0
Polygon -7500403 true true 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -1 true false 120 90 105 90 60 195 90 210 120 150 120 195 180 195 180 150 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Polygon -1 true false 123 90 149 141 177 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -2674135 true false 180 90 195 90 183 160 180 195 150 195 150 135 180 90
Polygon -2674135 true false 120 90 105 90 114 161 120 195 150 195 150 135 120 90
Polygon -2674135 true false 155 91 128 77 128 101
Rectangle -16777216 true false 118 129 141 140
Polygon -2674135 true false 145 91 172 77 172 101

person soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

person student
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="population-density" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="variant">
      <value value="&quot;mobile&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="connections-per-node">
      <value value="4.1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-people" first="50" step="50" last="200"/>
    <enumeratedValueSet variable="num-infected">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-decay">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="degree" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles with [infected?]</metric>
    <enumeratedValueSet variable="num-people">
      <value value="200"/>
    </enumeratedValueSet>
    <steppedValueSet variable="connections-per-node" first="0.5" step="0.5" last="4"/>
    <enumeratedValueSet variable="disease-decay">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variant">
      <value value="&quot;network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-infected">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="environmental" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="num-people">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="connections-per-node">
      <value value="4"/>
    </enumeratedValueSet>
    <steppedValueSet variable="disease-decay" first="0" step="1" last="10"/>
    <enumeratedValueSet variable="variant">
      <value value="&quot;environmental&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-infected">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="density-and-decay" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="variant">
      <value value="&quot;environmental&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="disease-decay" first="0" step="1" last="10"/>
    <enumeratedValueSet variable="num-infected">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-people" first="50" step="50" last="200"/>
    <enumeratedValueSet variable="connections-per-node">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>r-zero</metric>
    <metric>num-days</metric>
    <metric>economy / num-people</metric>
    <enumeratedValueSet variable="num-houses">
      <value value="343"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-xcor">
      <value value="215"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workplaces">
      <value value="39"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="staying-home-when-sick?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cbd-size">
      <value value="74"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-shops">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-sizer">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-infected">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatalities?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ycor">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentage-staying-home">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
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
1
@#$#@#$#@
