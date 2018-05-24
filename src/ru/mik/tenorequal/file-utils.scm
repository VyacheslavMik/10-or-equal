(require 'android-defs)

(define-alias context android.content.Context)
(define-alias resources android.content.res.Resources)
 
(define-alias buffered-reader java.io.BufferedReader)
(define-alias io-exception java.io.IOException)
(define-alias input-stream java.io.InputStream)
(define-alias input-stream-reader java.io.InputStreamReader)

(define-alias string-builder java.lang.StringBuilder)

(define open-raw-resource
  (lambda ((context :: context) (resource-id :: int))
    ((context:getResources):openRawResource resource-id)))

(define read-line
  (lambda ((buffered-reader :: buffered-reader))
    (buffered-reader:readLine)))

(define read-text-from-raw
  (lambda (context resource-id)
    (let* ((string-builder (string-builder))
	   (input-stream (open-raw-resource context resource-id))
	   (buffered-reader (buffered-reader (input-stream-reader input-stream))))
      (let read ((buffered-reader buffered-reader) (line #!null))
	(set! line (read-line buffered-reader))
	(if (eq? line #!null)
	    (string-builder:toString)
	    (begin
	      (string-builder:append line)
	      (string-builder:append "\r\n")
	      (read buffered-reader line)))))))
