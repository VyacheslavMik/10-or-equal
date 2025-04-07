(require 'android-defs)

(define-alias bitmap android.graphics.Bitmap)
(define-alias bitmap-factory android.graphics.BitmapFactory)
(define-alias gles20 android.opengl.GLES20)
(define-alias gl-utils android.opengl.GLUtils)

(define-alias gl-texture-0 android.opengl.GLES20:GL_TEXTURE0)
(define-alias gl-texture-2d android.opengl.GLES20:GL_TEXTURE_2D)

(define load-texture
  (lambda ((context ::android.content.Context) (resource-id ::int))
    (let ((texture-ids #!null) (options #!null) (bitmap #!null))
      (set! texture-ids (int[] length: 1))
      (gles20:glGenTextures 1 texture-ids 0)
      (if (not (= (texture-ids 0) 0))
	  (begin
	    (set! options (bitmap-factory:Options))
	    (set! options:inScaled #f)
	    (set! bitmap (bitmap-factory:decodeResource (context:getResources) resource-id options))

	    (if (= bitmap #!null)
		(begin
		  (gles20:glDeleteTextures 1 texture-ids 0)
		  0)
		(begin
		  (gles20:glActiveTexture gl-texture-0)
		  (gles20:glBindTexture gl-texture-2d (texture-ids 0))

		  (gles20:glTexParameteri gl-texture-2d gles20:GL_TEXTURE_MIN_FILTER gles20:GL_LINEAR)
		  (gles20:glTexParameteri gl-texture-2d gles20:GL_TEXTURE_MAG_FILTER gles20:GL_LINEAR)

		  (gl-utils:texImage2D gl-texture-2d 0 bitmap 0)

		  (bitmap:recycle)

		  (gles20:glBindTexture gl-texture-2d 0)
		  (texture-ids 0))))
	  0))))
