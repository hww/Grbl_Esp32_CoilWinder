#lang racket

(require srfi/48)

;; List of diameters. Starts with awg 14, ends with awg 50
(define awg_diam_mm '(1.70053 1.51765 1.35636 1.21412 1.08585 0.97028 0.86995 0.77724 0.69469 0.62484
                      0.56007 0.50038 0.44831 0.40386 0.36195 0.32512 0.29083 0.26162 0.23749 0.21209
                      0.18796 0.16764 0.15113 0.13589 0.12065 0.10541 0.09398 0.08509 0.0762 0.06731
                      0.06096 0.053213 0.048387 0.043815 0.038989 0.035179 0.032385))

;; Convert the AWG value to the wire's diameter
(define (awg2mm awg)
  (list-ref awg_diam_mm (- awg 14)))

;; Math constants
(define sin60 0.86602540378)

;; The size of crossover is 15 degrees, so there will be 24
;; possible positions.
(define num_crossover_sections 24)
(define max_crossover_section 23)
(define crossover_size_norm (/ 1 num_crossover_sections))
;; Get the position of cross over for given layer
;; The first layer starts from the last secrtion (23)
(define (get_crossover_section layer)
  (modulo (- num_crossover_sections layer) num_crossover_sections))
;; Get crosover normalized position
(define (get_crossover_norm layer)
  (/ (get_crossover_section layer) num_crossover_sections))

;; Build gcode from the wire diameter and make it "orthocyclic equal"
;; see the manual https://en.wikipedia.org/wiki/Coil_winding_technology
;; The orthocyclic equal has the same amout of turns at each layer
;; but each layer is shifted for half of wire diameter. See image below:
;;
;; |( )( )( )( )( ) |
;; | ( )( )( )( )( )|
;; |( )( )( )( )( ) |
;; |----------------|
(define (build_gcode_orthocyclic_equal length idiam turns rpm wdiam)
  (letrec ([wradius (/ wdiam 2)]
           ; make the maximum lenght smaller by one ire radius
           [layer_max_len (- length wradius)] 
           [turns_per_row (floor (/ layer_max_len wdiam))]
           [layers (ceiling (/ turns  turns_per_row))]
           [winding_width (+ wradius (* turns_per_row wdiam))]
           [winding_heiht (* wdiam (+ 1 (* sin60 (- layers 1))))]
           ;; Calculation of the winding height in the layer cross section area
           ;; just add 5% 
           [winding_heiht_cross (* winding_heiht 1.05)]
           [approx_layers  (/ turns turns_per_row)]
           [odiam (+ idiam (* 2 winding_heiht))]
           [odiam_cross (+ idiam (* 2 winding_heiht_cross))]
        )

    ;; Print the arguments
    (printf "(:Arguments:)~n")
    (printf "(Speed RPM      = ~a)~n" rpm)
    (printf "(Wire diameter  = ~a mm)~n" wdiam)
    (printf "(Wire turns     = ~a)~n" turns)
    (printf "(Coil length    = ~a mm)~n" length)
    (printf "(Coil int. diam = ~a mm)~n" idiam)
    ;; Computed parameters
    (printf "(:Computed:)~n")
    (printf "(Turns per row  = ~a)~n" turns_per_row)
    (printf "(Layers num     = ~a)~n" layers)
    (printf "(Winding width  = ~a mm)~n" winding_width)
    (printf "(Winding heiht  = ~a mm)~n" winding_heiht)
    (printf "(Coil out. diam = ~a)~n" odiam)
    (printf "(Calculation of the outer dimensions of the coil in the cross section area)~n")
    (printf "(Max Winding height = ~a mm)~n" winding_heiht_cross)
    (printf "(Max Coil out. diam = ~a mm)~n" odiam_cross)
    ;; Start the gcode
    (printf "(:GCode begin:)~n")
    (printf "G21 (metric ftw)~n")
    (printf "G90 (absolute mode)~n")
    (printf "G92 X0 Y0 (zero all axes)~n")
    
    (let ([direction 1] 
          [layer 1]
          [posx 0])
      ;; For every turn print out the gcode expression
      (for ([i (in-range 0 turns)])
        (letrec ([i1 (+ i 1)]
                 ;; crossover position should change every layer
                 [cross_section (get_crossover_section layer)]
                 [cross_starts (get_crossover_norm layer)]
                 [cross_ends (+ cross_starts crossover_size_norm)]
                 [posx_old posx])
          
          ;; Increment or decrement X pposition
          (if (= direction 1)
              (set! posx (+ posx wdiam))
              (set! posx (- posx wdiam)))

          (cond
            [(= cross_section 0)
             ;; crossover at the begin of turn
             (println (format "G1 X~6,6F Y~6,6F F~d" posx (+ i cross_starts) rpm))
             (println (format "G1 X~6,6F Y~6,6F F~d" posx i1 rpm))
             ]
            [(= cross_section max_crossover_section)
             ;; crossover at the end of turn
             (println (format "G1 X~6,6F Y~6,6F F~d" posx_old (+ i cross_starts) rpm))
             (println (format "G1 X~6,6F Y~6,6F F~d" posx i1 rpm))
             ]
            [else
             ;; crossover at the middle of turn
             (println (format "G1 X~6,6F Y~6,6F F~d" posx_old (+ i cross_starts) rpm))
             (println (format "G1 X~6,6F Y~6,6F F~d" posx (+ i cross_ends) rpm))
             (println (format "G1 X~6,6F Y~6,6F F~d" posx i1 rpm))
             ])
          
          ;; display current turn and layer on LCD
          (printf "(T: ~a L: ~a)~n" i1 layer)
          
          ;; the end of layer
          (cond [(= 0 (modulo i1 turns_per_row))
                 (begin
                   (set! direction (bitwise-xor direction 1))
                   (set! layer (+ layer 1)))])))

      (printf "M18 (drivers off)~n")
      (printf "M127~n")
      )))

;; ==============================================================

;; Build gcode from the wire diameter
(define (build_gcode length diam turns rpm wdiam)
  (printf "(generated by coilgen.rkt)~n")
  (build_gcode_orthocyclic_equal length diam turns rpm wdiam))

;; Build gcode from the American Wire Gauge AWG
(define (build_gcode_awg length diam turns rpm awg)
  (printf "(generated by coilgen.rkt)~n")
  (printf "(Wire gauge      = ~a AWG)~n" awg)
  (build_gcode_orthocyclic_equal length diam turns rpm (awg2mm awg)))

(build_gcode 10 20 100 500 1)

