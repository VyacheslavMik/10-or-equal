(require 'android-defs)
(require ru.mik.tenorequal.file-utils)

(define-alias gl-compile-status android.opengl.GLES20:GL_COMPILE_STATUS)
(define-alias gl-link-status android.opengl.GLES20:GL_LINK_STATUS)

(define gl-attach-shader
  (lambda ((program :: int) (shader :: int))
    (android.opengl.GLES20:glAttachShader program shader)))

(define gl-compile-shader
  (lambda ((shader :: int))
    (android.opengl.GLES20:glCompileShader shader)))

(define gl-create-program
  (lambda ()
    (android.opengl.GLES20:glCreateProgram)))

(define gl-create-shader
  (lambda ((type :: int))
    (android.opengl.GLES20:glCreateShader type)))

(define gl-delete-program
  (lambda ((program :: int))
    (android.opengl.GLES20:glDeleteProgram program)))

(define gl-delete-shader
  (lambda ((shader :: int))
    (android.opengl.GLES20:glDeleteShader shader)))

(define gl-get-programiv
  (lambda ((program :: int) (pname :: int) (params :: int[]) (offset :: int))
    (android.opengl.GLES20:glGetProgramiv program pname params offset)))

(define gl-get-shaderiv
  (lambda ((shader :: int) (pname :: int) (params :: int[]) (offset :: int))
    (android.opengl.GLES20:glGetShaderiv shader pname params offset)))

(define gl-link-program
  (lambda ((program :: int))
    (android.opengl.GLES20:glLinkProgram program)))

(define gl-shader-source
  (lambda ((shader :: int) (string :: string))
    (android.opengl.GLES20:glShaderSource shader string)))


(define create-program
  (lambda (vertext-shader-id fragment-shader-id)
    (let ((program-id (gl-create-program)))
      (if (= program-id 0)
	  0
	  (begin
	    (gl-attach-shader program-id vertext-shader-id)
	    (gl-attach-shader program-id fragment-shader-id)
	    (gl-link-program program-id)
	    (let ((link-status (int[] length: 1)))
	      (gl-get-programiv program-id gl-link-status link-status 0)
	      (if (= (link-status 0) 0)
		  (begin
		    (gl-delete-program program-id)
		    0)
		  program-id)))))))
		  
(define create-shader
  (case-lambda
   ((context type shader-raw-id)
    (create-shader type (read-text-from-raw context shader-raw-id)))
   ((type shader-text)
    (let ((shader-id (gl-create-shader type)))
      (if (= shader-id 0)
	  0
	  (begin
	    (gl-shader-source shader-id shader-text)
	    (gl-compile-shader shader-id)
	    (let ((compile-status (int[] 1)))
	      (gl-get-shaderiv shader-id gl-compile-status compile-status 0)
	      (if (= (compile-status 0) 0)
		  (begin
		    (gl-delete-shader shader-id)
		    0)
		  shader-id))))))))
