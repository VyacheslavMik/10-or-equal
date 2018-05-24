(require 'android-defs)
(require ru.mik.tenorequal.shader-utils)
(require 'list-lib)
(import (only (ru mik tenorequal texture-utils) load-texture)
	(rnrs hashtables)
	(only (ru mik tenorequal numbers) number number-val number-state
	      make-number-array row-count col-count)
	(srfi 95)
	(class android.preference PreferenceManager)
	(class android.app AlertDialog)
	(class java.lang Runnable)
	(class android.content DialogInterface Intent))

(define-alias byte-buffer java.nio.ByteBuffer)
(define-alias byte-order java.nio.ByteOrder)
(define-alias float-buffer java.nio.FloatBuffer)
(define-alias buffer java.nio.Buffer)

(define-alias egl-config javax.microedition.khronos.egl.EGLConfig)
(define-alias gl10 javax.microedition.khronos.opengles.GL10)

(define-alias gles20 android.opengl.GLES20)
(define-alias gl-color-buffer-bit gles20:GL_COLOR_BUFFER_BIT)
(define-alias gl-float gles20:GL_FLOAT)
(define-alias gl-fragment-shader gles20:GL_FRAGMENT_SHADER)
(define-alias gl-triangles gles20:GL_TRIANGLES)
(define-alias gl-triangle-strip gles20:GL_TRIANGLE_STRIP)
(define-alias gl-triangle-fan gles20:GL_TRIANGLE_FAN)
(define-alias gl-lines gles20:GL_LINES)
(define-alias gl-line-strip gles20:GL_LINE_STRIP)
(define-alias gl-line-loop gles20:GL_LINE_LOOP)
(define-alias gl-points gles20:GL_POINTS)
(define-alias gl-depth-test gles20:GL_DEPTH_TEST)
(define-alias gl-depth-buffer-bit gles20:GL_DEPTH_BUFFER_BIT)
(define-alias gl-vertex-shader gles20:GL_VERTEX_SHADER)
(define-alias gl-texture-0 android.opengl.GLES20:GL_TEXTURE0)
(define-alias gl-texture-2d android.opengl.GLES20:GL_TEXTURE_2D)

(define log
  (lambda (fmt . values)
    (android.util.Log:d "TEST" (apply format (cons #f (cons fmt values))))))

(define gl-clear
  (lambda ((mask :: int))
    (invoke-static gles20 'glClear mask)))
  
(define gl-clear-color
  (lambda ((a :: float) (r :: float) (g :: float) (b :: float))
    (invoke-static gles20 'glClearColor a r g b)))

(define gl-draw-arrays
  (lambda ((mode :: int) (first :: int) (count :: int))
    (invoke-static gles20 'glDrawArrays mode first count)))

(define gl-enable
  (lambda ((cap :: int))
    (invoke-static gles20 'glEnable cap)))

(define gl-enable-vertex-attrib-array
  (lambda ((index :: int))
    (invoke-static gles20 'glEnableVertexAttribArray index)))

(define gl-get-attrib-location
  (lambda ((program :: int) (name :: string))
    (invoke-static gles20 'glGetAttribLocation program name)))

(define gl-get-uniform-location
  (lambda ((program :: int) (name :: string))
    (invoke-static gles20 'glGetUniformLocation program name)))

(define gl-line-width
  (lambda ((width :: float))
    (invoke-static gles20 'glLineWidth width)))

(define gl-uniform-4f
  (lambda ((location :: int) (x :: float) (y :: float) (z :: float) (w :: float))
    (invoke-static gles20 'glUniform4f location x y z w)))

(define gl-uniform-matrix-4fv
  (lambda ((location :: int) (count :: int) (transpose :: boolean) (value :: float[]) (offset :: int))
    (invoke-static gles20 'glUniformMatrix4fv location count transpose value offset)))

(define gl-use-program
  (lambda ((program :: int))
    (invoke-static gles20 'glUseProgram program)))

(define gl-vertex-attrib-pointer
  (lambda ((indx :: int) (size :: int) (type :: int) (normalized :: boolean) (stride :: int) (ptr :: buffer))
    (invoke-static gles20 'glVertexAttribPointer indx size type normalized stride ptr)))

(define gl-viewport
  (lambda ((x :: int) (y :: int) (width :: int) (height :: int))
    (invoke-static gles20 'glViewport x y width height)))

(define-alias context android.content.Context)
(define-alias renderer android.opengl.GLSurfaceView$Renderer)

(define side-size 1/9)
(define text-side-size (* 9/16 1/20))
(define numbers-setting-name "numbers")
(define top-scores-setting-name "top-scores")

;; (defmacro get-vertices lists
;;   (let ((res '()))
;;     (for-each (lambda (ls)
;; 		(let* ((r (cadr ls)) (c (caddr ls)) (ss 1/9) (iss 256) (tss 1024)
;; 		       (pix (/ 1 tss)))
;; 		  (set! res (append res (list 0  ss  (* (* c iss) pix)               (* (* r iss) pix)
;; 					      0  0   (* (* c iss) pix)               (- (* (* (+ r 1) iss) pix) pix)
;; 					      ss ss  (- (* (* (+ c 1) iss) pix) pix) (* (* r iss) pix)
;; 					      ss 0   (- (* (* (+ c 1) iss) pix) pix) (- (* (* (+ r 1) iss) pix) pix))))))
;; 	      lists)
;;     `(float[] ,@res)))

(defmacro get-vertices (numbers digits)
  (define get-values
    (lambda (lists x y iss tss height)
      (let ((res '()))
	(for-each (lambda (ls)
		    (let* ((r (cadr ls)) (c (caddr ls)) (pix (/ 1 tss)))
		      (set! res (append res (list 0  y  (* (* c iss) pix)       (* (* r iss) pix)
						  0  0  (* (* c iss) pix)       (if height height (* (* (+ r 1) iss) pix))
						  x  y  (* (* (+ c 1) iss) pix) (* (* r iss) pix)
						  x  0  (* (* (+ c 1) iss) pix) (if height height (* (* (+ r 1) iss) pix)))))))
		  lists)
	res)))
  
  (define get-texture-coordinates
    (lambda (x y tx1 ty1 tx2 ty2)
      (list 0 y tx1 ty1
	    0 0 tx1 ty2
	    x y tx2 ty1
	    x 0 tx2 ty2)))

  (define get-scores-text
    (lambda ()
      (get-texture-coordinates (* 54/16 1/20) 1/20 0 0 54/800 16/224)))
  (define get-targets-text
    (lambda ()
      (get-texture-coordinates (* 60/16 1/20) 1/20 0 16/224 60/800 32/224)))
  (define get-you-lose-text
    (lambda ()
      (get-texture-coordinates (* 146/32 1/10) 1/10 0 32/224 146/800 64/224)))
  (define get-you-win-text
    (lambda ()
      (get-texture-coordinates (* 139/32 1/10) 1/10 0 64/224 146/800 96/224)))
  (define get-new-game-text
    (lambda ()
      (get-texture-coordinates (* 178/32 1/10) 1/10 0 96/224 178/800 128/224)))
  (define get-continue-text
    (lambda ()
      (get-texture-coordinates (* 157/32 1/10) 1/10 0 128/224 157/800 160/224)))
  (define get-top-scores-text
    (lambda ()
      (get-texture-coordinates (* 182/32 1/10) 1/10 0 160/224 182/800 192/224)))
  (define get-rules-text
    (lambda ()
      (get-texture-coordinates (* 93/32 1/10) 1/10 0 192/224 93/800 224/224)))

  (let ((res '()))
    (set! res (append res (get-values numbers 1/9 1/9 32 128 #f)))
    (set! res (append res (get-values digits (* 9/16 1/20) 1/20 9 120 1.0)))
    (set! res (append res (get-scores-text)))
    (set! res (append res (get-targets-text)))
    (set! res (append res (get-you-lose-text)))
    (set! res (append res (get-you-win-text)))
    (set! res (append res (get-new-game-text)))
    (set! res (append res (get-continue-text)))
    (set! res (append res (get-top-scores-text)))
    (set! res (append res (get-rules-text)))
    `(float[] ,@res)))

(defmacro defdraw (name position)
  (let ((proc-name (string->symbol (format #f "draw-~a" name))))
    `(define ,proc-name
       (lambda (texture-sheet)
	 (invoke-static 'android.opengl.GLES20 'glBindTexture gl-texture-2d texture-sheet)
	 (gl-draw-arrays gl-triangle-strip ,(* position 4) 4)))))

(define time 10000)
(define position-count 2)
(define texture-count 2)
(define stride (* (+ position-count texture-count) 4))

(defdraw one 0)
(defdraw two 1)
(defdraw three 2)
(defdraw four 3)
(defdraw five 4)
(defdraw six 5)
(defdraw seven 6)
(defdraw eight 7)
(defdraw nine 8)
(defdraw background 9)
(defdraw selected 10)
(defdraw adjacent 11)
(defdraw disabled 12)

(defdraw text-one 13)
(defdraw text-two 14)
(defdraw text-three 15)
(defdraw text-four 16)
(defdraw text-five 17)
(defdraw text-six 18)
(defdraw text-seven 19)
(defdraw text-eight 20)
(defdraw text-nine 21)
(defdraw text-zero 22)

(defdraw scores 23)
(defdraw targets 24)
(defdraw you-lose 25)
(defdraw you-win 26)
(defdraw new-game 27)
(defdraw continue 28)
(defdraw top-scores 29)
(defdraw rules 30)

(define draw-number
  (lambda (number texture-sheet)
    (case (number-state number)
      ('normal (draw-background texture-sheet))
      ('selected (draw-selected texture-sheet))
      ('adjacent (draw-adjacent texture-sheet))
      ('disabled (draw-disabled texture-sheet))
      (else (raise (format #f "Unknown state ~a" (number-state number)))))

    (case (number-val number)
      ((1) (draw-one texture-sheet))
      ((2) (draw-two texture-sheet))
      ((3) (draw-three texture-sheet))
      ((4) (draw-four texture-sheet))
      ((5) (draw-five texture-sheet))
      ((6) (draw-six texture-sheet))
      ((7) (draw-seven texture-sheet))
      ((8) (draw-eight texture-sheet))
      ((9) (draw-nine texture-sheet))
      (else (raise (format #f "Unknown number ~a" (number-val number)))))))

(define copy-number
  (lambda (n)
    (number (number-val n) (number-state n))))

(define make-next-number
  (lambda (numbers)
    (let* ((row 0) (col -1)
	   (next-number (lambda ()
			  (set! col (+ col 1))
			  (when (>= col col-count)
				(set! col 0)
				(set! row (+ row 1)))
			  (if (>= row row-count)
			      (cons #f (cons row col))
			      (cons (numbers get-number: row col) (cons row col))))))
      next-number)))

(define-simple-class open-gl-renderer (renderer)
  (ctx ::context)

  (vertex-data ::float-buffer)

  (a-position-location     ::int)
  (a-texture-location      ::int)
  (u-texture-unit-location ::int)
  (u-matrix-location       ::int)
  
  (program-id ::int)

  (m-projection-matrix ::float[] init: (float[] length: 16))
  (m-view-matrix       ::float[] init: (float[] length: 16))
  (m-model-matrix      ::float[] init: (float[] length: 16))
  (m-matrix            ::float[] init: (float[] length: 16))
  
  (texture-sheet ::int)
  (digits        ::int)
  (texts         ::int)

  (game-state init: 'main-menu)
  (top-scores init: '())

  (numbers   init: (make-number-array))

  ((*init* (arg1 ::context))
   (set! ctx arg1)
   (init-numbers))

  ((onSurfaceCreated (arg0 ::gl10) (arg1 ::egl-config)) ::void
   (gl-clear-color 0.0 0.0 0.0 1.0)
   (gles20:glBlendFunc gles20:GL_SRC_ALPHA gles20:GL_ONE_MINUS_SRC_ALPHA)
   (gl-enable gles20:GL_BLEND)

   (create-and-use-program)
   (get-locations)
   (prepare-data)
   (bind-data)
   (create-view-matrix))

  ((save-setting name value)
   (let ((editor ((PreferenceManager:getDefaultSharedPreferences ctx):edit)))
     (editor:putString name value)
     (editor:commit)))

  ((get-setting name)
   (let* ((sp (PreferenceManager:getDefaultSharedPreferences ctx))
	  (value (sp:getString name "")))
     (if (eqv? value "")
	 #f
	 value)))

  (m-width  ::int)
  (m-height ::int)
  (end-game-time 0)
  (last-second 0)

  ((onSurfaceChanged (arg0 ::gl10) (width ::int) (height ::int)) ::void
   (set! m-width width)
   (set! m-height height)
   (gl-viewport 0 0 width height)
   (create-projection-matrix width height)
   (set! side-size (/ right col-count))
   (set! max-position (- (* row-count side-size height) (* 1/20 height)))
   (bind-matrix))

  ((init-numbers)
   (add-number (number 1 'normal))
   (add-number (number 2 'normal))
   (add-number (number 3 'normal))
   (add-number (number 4 'normal))
   (add-number (number 5 'normal))
   (add-number (number 6 'normal))
   (add-number (number 7 'normal))
   (add-number (number 8 'normal))
   (add-number (number 9 'normal))
   (add-number (number 1 'normal))
   (add-number (number 1 'normal))
   (add-number (number 1 'normal))
   (add-number (number 2 'normal))

   (set-targets))

  ((add-number number)
   (numbers add-number: number))

  ((save-settings)
   (save-top-scores-setting)
   (case game-state
     ('playing (save-numbers-setting))))

  ((save-numbers-setting)
   (let ((next-number (make-next-number numbers))
	 (p (open-output-string)))
     (write game-scores p)
     (do ((number (car (next-number)) (car (next-number))))
	 ((not number))
       (write number p))
     (save-setting numbers-setting-name (get-output-string p))))

  ((save-top-scores-setting)
   (save-setting top-scores-setting-name (top-scores-to-string)))

  ((top-scores-to-string)
   (let ((p (open-output-string)))
     (for-each (lambda (score)
		 (write score p))
	       top-scores)
     (get-output-string p)))

  ((restore-settings)
   (restore-top-scores-setting)
   (restore-numbers-setting))

  ((restore-numbers-setting)
   (let ((numbers-setting (get-setting numbers-setting-name)))
     (when numbers-setting
	   (let ((p (open-input-string numbers-setting)))
	     (if (eof-object? (peek-char p))
		 (set! numbers-setting #f)
		 (begin
		   (set! game-scores (read p))
		   (set! numbers (make-number-array))
		   (do ((num (read p) (read p)))
		       ((eof-object? num))
		     (numbers add-number: (number (number-val num) (number-state num))))
		   (set-targets)))))
     numbers-setting))

  ((restore-top-scores-setting)
   (set! top-scores '())
   (let ((top-scores-setting (get-setting top-scores-setting-name)))
     (when top-scores-setting
	   (let ((p (open-input-string top-scores-setting)))
	     (do ((score (read p) (read p)))
		 ((eof-object? score))
	       (set! top-scores (cons score top-scores)))))))

  ((prepare-data)
   (let* ((vertices (get-vertices ((one      0 0) (two        0 1) (three    0 2) (four     0 3)
				   (five     1 0) (six        1 1) (seven    1 2) (eight    1 3)
				   (nine     2 0) (background 2 1) (selected 2 2) (adjacent 2 3)
				   (disabled 3 0))
				  ((one 0 0) (two 0 1) (three 0 2) (four 0 3) (five 0 4) (six 0 5) (seven 0 6) (eight 0 7) (nine 0 8) (zero 0 9))))
	  (byte-buffer (byte-buffer:allocateDirect (* (length vertices) 4)))
	  (ordered (byte-buffer:order (byte-order:native-order))))
     (set! vertex-data (ordered:asFloatBuffer))
     (vertex-data:put vertices)
     
     (set! texture-sheet (load-texture ctx R$drawable:texture_sheet_min))
     (set! digits (load-texture ctx R$drawable:digits_test))
     (set! texts (load-texture ctx R$drawable:texts))))

  ((create-and-use-program)
   (let ((vertex-shader-id (create-shader ctx gl-vertex-shader R$raw:vertex_shader))
	 (fragment-shader-id (create-shader ctx gl-fragment-shader R$raw:fragment_shader)))
     (set! program-id (create-program vertex-shader-id fragment-shader-id))
     (gl-use-program program-id)))

  ((get-locations)
   (set! a-position-location (gl-get-attrib-location program-id "a_Position"))
   (set! a-texture-location (gl-get-attrib-location program-id "a_Texture"))
   (set! u-texture-unit-location (gl-get-uniform-location program-id "u_TextureUnit"))
   (set! u-matrix-location (gl-get-uniform-location program-id "u_Matrix")))

  ((bind-data)
   (vertex-data:position 0)
   (gl-vertex-attrib-pointer a-position-location position-count gl-float #f stride vertex-data)
   (gl-enable-vertex-attrib-array a-position-location)

   (vertex-data:position position-count)
   (gl-vertex-attrib-pointer a-texture-location texture-count gl-float #f stride vertex-data)
   (gl-enable-vertex-attrib-array a-texture-location)

   (gles20:glActiveTexture gl-texture-0)
   (gles20:glBindTexture gl-texture-2d texture-sheet)

   (gles20:glUniform1i u-texture-unit-location 0))

  (left   ::float init: 0.0)
  (right  ::float init: 1.0)
  (bottom ::float init: 0.0)
  (top    ::float init: 1.0)

  ((create-projection-matrix (width ::int) (height ::int))
   (let* ((ratio (if (> width height)
		     (/ width height)
		     (/ height width)))
	  (near 0.0) (far 2.0))
     (set! left 0)
     (set! right 1)
     (set! bottom 0)
     (set! top 1)

     (if (> width height)
	 (begin
	   (set! left (* left ratio))
	   (set! right (* right ratio)))
	 (begin
	   (set! bottom (* bottom ratio))
	   (set! top (* top ratio))))
     (android.opengl.Matrix:orthoM m-projection-matrix 0 left right bottom top near far)))

  ((create-view-matrix)
   (let* ((center-x 0) (center-y 0) (center-z 0)
	  (up-x 0) (up-y 1) (up-z 0)
	  (eye-x 0) (eye-y 0) (eye-z 1))
     (android.opengl.Matrix:setLookAtM m-view-matrix 0
				       eye-x eye-y eye-z
				       center-x center-y center-z
				       up-x up-y up-z)))

  ((bind-matrix)
   (android.opengl.Matrix:multiplyMM m-matrix 0 m-view-matrix 0 m-model-matrix 0)
   (android.opengl.Matrix:multiplyMM m-matrix 0 m-projection-matrix 0 m-matrix 0)
   (gl-uniform-matrix-4fv u-matrix-location 1 #f m-matrix 0))

  (cursor-position 0)
  (max-position 0)
  (top-row 0)

  ((move (y ::float))
   (set! cursor-position (+ cursor-position y))
   (when (< cursor-position 0)
	 (set! cursor-position 0))
   (when (> cursor-position max-position)
	 (set! cursor-position max-position))
   (set! top-row (quotient cursor-position (* side-size m-height))))

  (selected-number #f)
  (adjacent-numbers '())

  ((touch-down (x ::float) (y ::float))
   (case game-state

     ('main-menu
      (let ((menu-item (get-touched-menu-item x y)))
	(case menu-item
	  ('new-game-menu-item
	   (set! game-scores 0)
	   (set! numbers (make-number-array))
	   (init-numbers)
	   (set! game-state 'playing))

	  ('continue-menu-item
	   (if (restore-numbers-setting)
	       (set! game-state 'playing)
	       (begin
		 (set! numbers (make-number-array))
		 (init-numbers)
		 (set! game-state 'playing))))

	  ('top-scores-menu-item
	   (let ((intent (Intent ctx ru.mik.tenorequal.topScores:class)))
	     (intent:putExtra "top-scores" (as string (top-scores-to-string)))
	     ((as android.app.Activity ctx):startActivity intent)))

	  ('rules-menu-item
	   (let ((intent (Intent ctx ru.mik.tenorequal.rules:class)))
	     ((as android.app.Activity ctx):startActivity intent))))))

     ('playing (playing-touch-down x y))))

  ((playing-touch-down (x ::float) (y ::float))
   (let* ((col (integer (floor (/ (/ x m-width) (/ side-size right)))))
	  (row (integer (+ top-row (floor (/ (/ (- y (* m-height 1/20)) m-height) (/ side-size top))))))
	  (prev-selected-number selected-number)
	  (curr-selected-number (if (or (>= col col-count)
					(>= row row-count))
				    #f
				    (numbers get-number: row col)))
	  (prev-adjacent-numbers adjacent-numbers))
     (when selected-number
	   (set! (number-state (car selected-number)) 'normal))
     (unless (null? adjacent-numbers)
	     (for-each (lambda (number)
			 (when (eq? (number-state (car number)) 'adjacent)
			       (set! (number-state (car number)) 'normal)))
		       adjacent-numbers)
	     (set! adjacent-numbers '()))

     (when (and prev-selected-number curr-selected-number
		(memq curr-selected-number (map car prev-adjacent-numbers))
		(goal? (car prev-selected-number) curr-selected-number))
	   (set! selected-number #f)
	   (numbers disable-numbers: (cdr prev-selected-number) (cons row col))
	   (set! game-scores (+ game-scores 10))
	   (set-targets)

	   (do ()
	       ((or (not (= game-targets 0))
		    (numbers 'full?:)
		    (numbers 'empty?:)))
	     (fill-numbers)
	     (set-targets)))

     (cond
      ((numbers 'empty?:)
       (set! end-game-time 0)
       (set! game-state 'win))
      ((numbers 'full?:)
       (set! end-game-time 0)
       (set! game-state 'lose)))

     (when (and curr-selected-number (not (eq? (number-state curr-selected-number) 'disabled)))
	   (set! (number-state curr-selected-number) 'selected)
	   (set! selected-number (cons curr-selected-number (cons row col)))
	   (set! adjacent-numbers (get-adjacent-numbers row col))
	   (for-each (lambda (number) (set! (number-state (car number)) 'adjacent)) adjacent-numbers))))

  ((get-touched-menu-item x y)
   (let* ((ix (- right (/ x m-width)))
	  (iy (abs (- (* (/ y m-height) top) top)))
	  (get-touched-item
	   (lambda (width y menu-item)
	     (and (< (- (/ right 2) (/ (* (/ width 32) 1/10) 2)) ix (+ (/ right 2) (/ (* (/ width 32) 1/10) 2)))
		  (< (- top (* (/ y 10) top)) iy (- top (* (/ (- y 1) 10) top)) ) menu-item))))
     (or (get-touched-item 178 4 'new-game-menu-item)
	 (get-touched-item 157 5 'continue-menu-item)
	 (get-touched-item 182 6 'top-scores-menu-item)
	 (get-touched-item 93  7 'rules-menu-item))))

  ((fill-numbers)
   (let ((next-number (make-next-number numbers))
	 (numbers-to-fill '()))
     (do ((number (car (next-number)) (car (next-number))))
	 ((not number))
       (when (not (eq? (number-state number) 'disabled))
	     (set! numbers-to-fill (cons number numbers-to-fill))))

     (call/cc
      (lambda (exit)
	(for-each (lambda (number)
		    (unless (numbers add-number: (copy-number number))
			    (exit)))
		  (reverse numbers-to-fill))))))
  
  ((set-targets)
   (set! game-targets 0)
   (let ((next-number (make-next-number numbers))
	 (ht (make-eq-hashtable))
	 (res #f))
     (do ((number (next-number) (next-number))
	  (exit #f))
	 ((or exit (not (car number))))
       (when (and (car number)
		  (not (eq? (number-state (car number)) 'disabled))
		  (goal-in-adjacents? (car number) (get-adjacent-numbers (cadr number) (cddr number))))
	     (let ((adjacents (get-adjacent-numbers (cadr number) (cddr number))))
	       (for-each (lambda (adjacent)
			   (when (goal? (car adjacent) (car number))
				 (set! game-targets (+ game-targets 1))))
			 adjacents))))
     (set! game-targets (/ game-targets 2))))

  ((goal? n1 n2)
   (or (= (number-val n1) (number-val n2))
       (= (+ (number-val n1) (number-val n2)) 10)))

  ((goal-in-adjacents? number adjacent-numbers)
   (let goal-in-list? ((adjacents adjacent-numbers))
     (if (null? adjacents)
	 #f
	 (if (goal? number (car (car adjacents)))
	     #t
	     (goal-in-list? (cdr adjacents))))))

  ((get-adjacent-numbers row col)
   (let ((next-pos (lambda (place op pos)
		     (set! (place pos) (op (place pos) 1))
		     (when (>= (cdr pos) col-count)
			   (set! (car pos) (+ (car pos) 1))
			   (set! (cdr pos) 0))
		     (when (< (cdr pos) 0)
			   (set! (car pos) (- (car pos) 1))
			   (set! (cdr pos) (- col-count 1)))
		     pos))
	 (res '()))
     (letrec ((adjacent-number (lambda (place op pos)
				 (set! pos (next-pos place op pos))
				 (if (or (< (car pos) 0) (>= (car pos) row-count))
				     #f
				     (begin
				       (let ((number (numbers get-number: (car pos) (cdr pos))))
					 (cond
					  ((not number) #f)
					  ((eq? (number-state number) 'disabled)
					   (adjacent-number place op pos))
					  (else (cons number (cons (car pos) (cdr pos)))))))))))
       (let ((top (adjacent-number car - (cons row col)))
	     (bottom (adjacent-number car + (cons row col)))
	     (left (adjacent-number cdr - (cons row col)))
	     (right (adjacent-number cdr + (cons row col))))
	 (when top
	       (set! res (cons top res)))
	 (when bottom
	       (set! res (cons bottom res)))
	 (when left
	       (set! res (cons left res)))
	 (when right
	       (set! res (cons right res)))))
     res))

  ((onDrawFrame (arg0 ::gl10)) ::void
   (let ((elapsed (- (current-second) last-second)))
     (set! last-second (current-second))
     (gl-clear gl-color-buffer-bit)
     (gl-clear-color 0.98 1.0 0.89 1.0)

     (case game-state
       ('playing

	(android.opengl.Matrix:setIdentityM m-model-matrix 0)
	(android.opengl.Matrix:translateM m-model-matrix 0 0 (- top side-size 1/20) 0)
	(bind-matrix)

	(let* ((row-start top-row) (row-end (+ row-start (/ top side-size)))
	       (next-row (lambda () (android.opengl.Matrix:translateM m-model-matrix 0 (- (* 8 side-size)) (- side-size) 0))))
	  (when (> row-end row-count)
		(set! row-end row-count))
	  (do ((row row-start)
	       (col 0 (if (>= col (- col-count 1))
			  (begin
			    (set! row (+ row 1))
			    (next-row)
			    0)
			  (+ col 1))))
	      ((>= row row-end))
	    (let ((number (numbers get-number: row col)))
	      (bind-matrix)
	      (if number
		  (draw-number number texture-sheet)
		  (draw-background texture-sheet))
	      (unless (>= col (- col-count 1))
		      (android.opengl.Matrix:translateM m-model-matrix 0 side-size 0 0)))))

	(draw-game-scores)
	(draw-game-targets))

       ('main-menu
	(draw-main-menu))

       ('win
	(set! end-game-time (+ end-game-time elapsed))
	(save-setting numbers-setting-name "")
	(when (> end-game-time 3)
	      (add-top-score game-scores)
	      (set! game-scores 0)
	      (set! game-state 'main-menu))
	(draw-text-you-win))

       ('lose
	(set! end-game-time (+ end-game-time elapsed))
	(set! game-scores 0)
	(save-setting numbers-setting-name "")
	(when (> end-game-time 5)
	      (set! game-state 'main-menu))
	(draw-text-you-lose)))))

  ((top-score? score)
   (or (< (length top-scores) 10)
       (> score (apply min (map cdr top-scores)))))

  ((get-name)
   (let* ((res #f)
	  (exit #f)
	  (get-name-runnable (runnable (lambda ()
					 (current-activity ctx)
					 (let* ((alert-dialog (AlertDialog:Builder ctx))
						(input (EditText id: 101))
						(lp (LinearLayout:LayoutParams LinearLayout:LayoutParams:MATCH_PARENT
									       LinearLayout:LayoutParams:MATCH_PARENT)))
					   (alert-dialog:setTitle "Winner name")
					   (alert-dialog:setMessage "Enter your name:")
					   (input:setLayoutParams lp)
					   (alert-dialog:setView input)
					   (alert-dialog:setPositiveButton "YES"
									   (object (DialogInterface:OnClickListener)
										   ((onClick (dialog ::DialogInterface) (which ::int))
										    (set! res ((input:getText):toString))
										    (set! exit #t))))
					   (alert-dialog:setNegativeButton "NO"
									   (object (DialogInterface:OnClickListener)
										   ((onClick (dialog ::DialogInterface) (which ::int))
										    (set! exit #t))))
					   (alert-dialog:show))))))
     ((as android.app.Activity ctx):runOnUiThread get-name-runnable)
     (do ()
	 (exit)
       (sleep 0.01))
     res))

  ((add-top-score score)
   (when (top-score? score)
	 (let ((name (get-name)))
	   (when name
		 (if (< (length top-scores) 10)
		     (set! top-scores (cons (cons name score) top-scores))
		     (set! top-scores (take (sort (cons (cons name score) top-scores)
						  (lambda (l r)
						    (if (= (cdr l) (cdr r))
							(string<? (car l) (car r))
							(> (cdr l) (cdr r))))) 10)))))))

  (game-scores  init: 0)
  (game-targets init: 0)

  ((draw-game-scores)
   (android.opengl.Matrix:setIdentityM m-model-matrix 0)
   (android.opengl.Matrix:translateM m-model-matrix 0 0 (- top 1/20) 0)
   (bind-matrix)
   (draw-scores texts)
   (android.opengl.Matrix:translateM m-model-matrix 0 0.16875 0 0)
   (bind-matrix)
   (draw-text-number game-scores))

  ((draw-game-targets)
   (android.opengl.Matrix:translateM m-model-matrix 0 1/20 0 0)
   (bind-matrix)
   (draw-targets texts)
   (android.opengl.Matrix:translateM m-model-matrix 0 0.1875 0 0)
   (bind-matrix)
   (draw-text-number game-targets))

  ((draw-text-number number)
   (for-each (lambda (c)
	       (case c
		 ((#\1) (draw-text-one digits))
		 ((#\2) (draw-text-two digits))
		 ((#\3) (draw-text-three digits))
		 ((#\4) (draw-text-four digits))
		 ((#\5) (draw-text-five digits))
		 ((#\6) (draw-text-six digits))
		 ((#\7) (draw-text-seven digits))
		 ((#\8) (draw-text-eight digits))
		 ((#\9) (draw-text-nine digits))
		 ((#\0) (draw-text-zero digits)))
	       (android.opengl.Matrix:translateM m-model-matrix 0 text-side-size 0 0)
	       (bind-matrix))
	     (string->list (number->string number))))

  ((draw-text-you-lose)
   (android.opengl.Matrix:setIdentityM m-model-matrix 0)
   (android.opengl.Matrix:translateM m-model-matrix 0 (- (/ right 2) 0.228125) (- (/ top 2) 1/20) 0)
   (bind-matrix)
   (draw-you-lose texts))

  ((draw-text-you-win)
   (android.opengl.Matrix:setIdentityM m-model-matrix 0)
   (android.opengl.Matrix:translateM m-model-matrix 0 (- (/ right 2) 0.2171875) (- (/ top 2) 1/20) 0)
   (bind-matrix)
   (draw-you-win texts))

  ((draw-main-menu)
   (draw-text-new-game)
   (draw-text-continue)
   (draw-text-top-scores)
   (draw-text-rules))

  ((draw-text-new-game)
   (android.opengl.Matrix:setIdentityM m-model-matrix 0)
   (android.opengl.Matrix:translateM m-model-matrix 0 (- (/ right 2) (/ (* 178/32 1/10) 2)) (- top (* 4/10 top)) 0)
   (bind-matrix)
   (draw-new-game texts))

  ((draw-text-continue)
   (android.opengl.Matrix:setIdentityM m-model-matrix 0)
   (android.opengl.Matrix:translateM m-model-matrix 0 (- (/ right 2) (/ (* 157/32 1/10) 2)) (- top (* 5/10 top)) 0)
   (bind-matrix)
   (draw-continue texts))

  ((draw-text-top-scores)
   (android.opengl.Matrix:setIdentityM m-model-matrix 0)
   (android.opengl.Matrix:translateM m-model-matrix 0 (- (/ right 2) (/ (* 182/32 1/10) 2)) (- top (* 6/10 top)) 0)
   (bind-matrix)
   (draw-top-scores texts))

  ((draw-text-rules)
   (android.opengl.Matrix:setIdentityM m-model-matrix 0)
   (android.opengl.Matrix:translateM m-model-matrix 0 (- (/ right 2) (/ (* 93/32 1/10) 2)) (- top (* 7/10 top)) 0)
   (bind-matrix)
   (draw-rules texts)))
