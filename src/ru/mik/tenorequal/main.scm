(require 'android-defs)
(require ru.mik.tenorequal.renderer)

(define-alias activity-manager android.app.ActivityManager)
;; (define-alias context android.content.Context)
(define-alias configuration-info android.content.pm.ConfigurationInfo)
(define-alias gl-surface-view android.opengl.GLSurfaceView)
(define-alias bundle android.os.Bundle)
(define-alias toast android.widget.Toast)

(define-simple-class game-gl-surface-view (gl-surface-view)
  (m-renderer ::open-gl-renderer)
  (m-prev-y   ::float)
  (m-prev-action)
  
  ((*init* (ctx ::context))
   (invoke-special android.opengl.GLSurfaceView (this) '*init* ctx))

  ((onPause)
   (m-renderer:save-settings))

  ((onResume)
   (m-renderer:restore-settings))

  ((onTouchEvent (event ::android.view.MotionEvent)) ::boolean
   (unless (eq? event #!null)
	   (let ((x (event:getX)) (y (event:getY)) (action (event:getAction)))
	     (cond
	      ((or (and (eq? action android.view.MotionEvent:ACTION_UP)
			(eq? m-prev-action android.view.MotionEvent:ACTION_DOWN))
		   (and (eq? action android.view.MotionEvent:ACTION_UP)
			(eq? m-prev-action android.view.MotionEvent:ACTION_MOVE)
			(< (abs (- m-prev-y y)) 5)))
	       (m-renderer:touch-down x y))

	      ((eq? action android.view.MotionEvent:ACTION_MOVE)
	       (m-renderer:move (- m-prev-y y))))

	     (set! m-prev-y y)
	     (set! m-prev-action action)))
   ;; (invoke-special android.view.View (this) 'onTouchEvent event)
   #t)

  ((set-renderer (renderer ::open-gl-renderer)) ::void
   (set! m-renderer renderer)
   (invoke-special android.opengl.GLSurfaceView (this) 'setRenderer renderer)))

(define support-es2
  (lambda (activity :: android.app.Activity)
    (let* ((activity-manager :: activity-manager (activity:getSystemService context:ACTIVITY_SERVICE))
	   (configuration-info :: configuration-info (activity-manager:getDeviceConfigurationInfo)))
      (>= configuration-info:reqGlEsVersion #x20000))))
      

(activity main
	  (gl-surface ::game-gl-surface-view)

	  (on-create
	   (if (not (support-es2 (this)))
	       ((toast:makeText (this) "OpenGL ES 2.0 is not supported" toast:LENGTH_LONG):show)
	       (begin
		 (set! gl-surface (game-gl-surface-view (this)))
		 (gl-surface:setEGLContextClientVersion 2)
		 (gl-surface:set-renderer (open-gl-renderer (this)))
		 (setContentView gl-surface))))

	  ((onPause) ::void
	   (invoke-special <android.app.Activity> (this) 'onPause)
	   (gl-surface:onPause))

	  ((onResume) :: void
	   (invoke-special <android.app.Activity> (this) 'onResume)
	   (gl-surface:onResume)))
