;;; cl-pdf copyright 2002-2005 Marc Battyani see license.txt for the details
;;; You can reach me at marc.battyani@fractalconcept.com or marc@battyani.net
;;; The homepage of cl-pdf is here: http://www.fractalconcept.com/asp/html/cl-pdf.html

(in-package pdf)

;;;text functions

(defmacro in-text-mode (&body body)
  `(unwind-protect
     (let ((*font* nil))
       (write-line "BT" *page-stream*)
       ,@body)
    (write-line "ET" *page-stream*)))

(defun set-font (font size)
  (setf *font* font)
  (setf *font-size* size)
  (format *page-stream* "~a ~,2f Tf~%" (name (add-font-to-page font)) size))

(defun set-gstate (&rest gstate)
  (format *page-stream* "~a gs~%" (name (apply #'add-gstate-to-page gstate))))

(defun write-cid-string (string)
  (write-char #\( *page-stream*)
  (if (and *font* (typep (font-metrics *font*) 'ttu-font-metrics))
      (loop for c across string do
	   (let* ((code (char-code c))
		  (hi (ldb (byte 8 8) code))
 		  (lo (ldb (byte 8 0) code)))
 	     (write-char (code-char hi) *page-stream*)
 	     (write-char (code-char lo) *page-stream*)))
      (princ string *page-stream*))
  (write-string ") " *page-stream*))

(defun write-cid-char (char)
  (write-char #\( *page-stream*)
  (if (and *font* (typep (font-metrics *font*) 'ttu-font-metrics))
      (let* ((code (char-code char))
             (hi (ldb (byte 8 8) code))
             (lo (ldb (byte 8 0) code)))
        (write-char (code-char hi) *page-stream*)
        (write-char (code-char lo) *page-stream*))
      (write-char char *page-stream*))
  (write-string ") " *page-stream*))

(defmacro def-pdf-op (name (&rest args) format)
  (if args
    `(defun ,name ,args (format *page-stream* ,format ,@args))
    `(defun ,name () (write-line ,format *page-stream*))))

(def-pdf-op move-text (dx dy) "~8f ~8f Td~%")

(defun show-text (string) 
  (write-cid-string string)
  (write-line "Tj" *page-stream*))

(defun draw-text (string) (show-text string))

(defun show-text-on-next-line (string)
  (write-cid-string string)
  (write-line "'" *page-stream*))

(def-pdf-op set-text-rendering-mode (mode) "~d Tr~%")

(def-pdf-op set-char-spacing (space) "~8f Tc~%")

(def-pdf-op set-text-x-scale (scale) "~8f Tz~%")

(def-pdf-op set-text-leading (space) "~8f TL~%")

(def-pdf-op set-text-rise (rise) "~8f Ts~%")

(def-pdf-op move-to-next-line () " T*")

(def-pdf-op set-text-matrix (a b c d e f) "~10f ~10f ~10f ~10f ~10f ~10f Tm~%")

(defun show-spaced-strings (strings)
  (write-string "[ " *page-stream*)
  (dolist (item strings)
    (if (numberp item)
       (format *page-stream* "~a " item)
       (write-cid-string item)))
  (write-line "] TJ" *page-stream*))

(defun show-char (char)
  (case char
    (#\( (write-string "(\\() Tj " *page-stream*))
    (#\) (write-string "(\\)) Tj " *page-stream*))
    (#\\ (write-string "(\\\\) Tj " *page-stream*))
    (t (write-cid-char char) (write-line "Tj" *page-stream*))))

;;; graphic functions
(defconstant +deg-to-rad+ #.(/ pi 180))

(defmacro with-saved-state (&body body)
  `(unwind-protect
     (progn (write-line "q" *page-stream*)
	    ,@body)
    (write-line "Q" *page-stream*)))

(def-pdf-op set-transform-matrix (a b c d e f) "~8f ~8f ~8f ~8f ~8f ~8f cm~%")

(def-pdf-op translate (dx dy) "1.0 0.0 0.0 1.0 ~8f ~8f cm~%")

(defun rotate (deg)
  (let* ((angle (* +deg-to-rad+ deg))
	 (s (sin angle))
	 (c (cos angle)))
    (format *page-stream* "~10f ~10f ~10f ~10f 0.0 0.0 cm~%" c s (- s) c)))

(defun rotate* (radians)
  (let* ((s (sin radians))
	 (c (cos radians)))
    (format *page-stream* "~10f ~10f ~10f ~10f 0.0 0.0 cm~%" c s (- s) c)))

(def-pdf-op scale (sx sy) " ~8f 0.0 0.0 ~8f 0.0 0.0 cm~%")

(defun skew (x-deg y-deg)
  (format *page-stream* " 1.0 ~10f ~10f 1.0 0.0 0.0 cm~%"
	  (tan (* +deg-to-rad+ x-deg))(tan (* +deg-to-rad+ y-deg))))

(defun skew* (x-radians y-radians)
  (set-transform-matrix 1.0 (tan x-radians) (tan y-radians) 1.0 0.0 0.0))

(def-pdf-op set-line-width (width) "~8f w~%")

(def-pdf-op set-line-cap (mode) "~d J~%")

(def-pdf-op set-line-join (mode) "~d j~%")

(def-pdf-op set-dash-pattern (dash-array phase) "[~{~d~^ ~}] ~d d~%")

(def-pdf-op set-miter-limit (limit) "~8f M~%")

(def-pdf-op move-to (x y) "~8f ~8f m~%")

(def-pdf-op line-to (x y) "~8f ~8f l~%")

(def-pdf-op bezier-to (x1 y1 x2 y2 x3 y3) "~8f ~8f ~8f ~8f ~8f ~8f c~%")

(def-pdf-op bezier2-to (x2 y2 x3 y3) "~8f ~8f ~8f ~8f v~%")

(def-pdf-op bezier3-to (x1 y1 x3 y3) "~8f ~8f ~8f ~8f y~%")

(def-pdf-op close-path () " h")

(def-pdf-op basic-rect (x y dx dy) "~8f ~8f ~8f ~8f re~%")

(defun paint-image (image)
  (format *page-stream* "~a Do~%" (name image)))

(def-pdf-op stroke () " S")

(def-pdf-op close-and-stroke () " s")

(def-pdf-op fill-path () " f")

(def-pdf-op close-and-fill () " h f")

(def-pdf-op even-odd-fill () " f*")

(def-pdf-op fill-and-stroke () " B")

(def-pdf-op even-odd-fill-and-stroke () " B*")

(def-pdf-op close-fill-and-stroke () " b")

(def-pdf-op close-even-odd-fill-and-stroke () " b*")

(def-pdf-op end-path-no-op  () " n")

(def-pdf-op clip-path () " W")

(def-pdf-op even-odd-clip-path () " W*")

(def-pdf-op set-gray-stroke (gray) "~5f G~%")

(def-pdf-op set-gray-fill (gray) "~5f g~%")

(def-pdf-op set-rgb-stroke (r g b) "~5f ~5f ~5f RG~%")

(defgeneric get-rgb (color)
 (:method ((color list))  
  (values (first color)(second color)(third color)))

 (:method ((color vector))
  #+lispworks
  (if (numberp (aref color 0))
      (values (aref color 0)(aref color 1)(aref color 2))
      (case (aref color 0)		; convert from (color:make-rgb ...) or other model
	(:RGB	(values (aref color 1)(aref color 2)(aref color 3)))
	(:GRAY	(values (aref color 1)(aref color 1)(aref color 1)))))
  #-lispworks
  (values (aref color 0)(aref color 1)(aref color 2)))

 (:method ((color string))	; takes a CSS color string like "#CCBBFF"
  (if (eql #\# (aref color 0))
      (values (/ (parse-integer color :start 1 :end 3 :radix 16) 255.0)
	      (/ (parse-integer color :start 3 :end 5 :radix 16) 255.0)
	      (/ (parse-integer color :start 5 :end 7 :radix 16) 255.0))
      (find-color-from-string color)))

 (:method ((color integer))	; a la CSS but specified as a Lisp number like #xCCBBFF
  (values (/ (ldb (byte 8 16) color) 255.0)
          (/ (ldb (byte 8 8) color) 255.0)
          (/ (ldb (byte 8 0) color) 255.0))) 

 (:method ((color symbol))	; :blue, :darkgreen, or win32:color_3dface
   (find-color-from-symbol color)))

(defun set-color-stroke (color)
  (multiple-value-call #'set-rgb-stroke (get-rgb color)))

(defun set-color-fill (color)
  (multiple-value-call #'set-rgb-fill (get-rgb color)))

(def-pdf-op set-rgb-fill (r g b) "~5f ~5f ~5f rg~%")

(def-pdf-op set-cymk-stroke (c y m k) "~5f ~5f ~5f ~5f K~%")

(def-pdf-op set-cymk-fill (c y m k) "~5f ~5f ~5f ~5f k~%")

(defun draw-image (image x y dx dy rotation &optional keep-aspect-ratio)
  (when keep-aspect-ratio
    (let ((r1 (/ dy dx))
	  (r2 (/ (height image)(width image))))
      (if (> r1 r2)
	(setf dy (* dx r2)))
	(when (< r1 r2)(setf dx (/ dy r2)))))
  (with-saved-state
      (translate x y)
      (rotate rotation)
      (scale dx dy)
      (paint-image image)))

(defun add-link (x y dx dy ref-name &key (border #(0 0 0)))
  (let ((annotation (make-instance 'annotation :rect (vector x y (+ x dx) (+ y dy))
				   :type "/Link" :border border)))
    (push (cons "/Dest" (get-named-reference ref-name)) (dict-values (content annotation)))
    annotation))

(defun add-URI-link (x y dx dy uri &key (border #(0 0 0)))
  (let ((annotation (make-instance 'annotation :rect (vector x y (+ x dx) (+ y dy))
				   :type "/Link" :border border ))
	(action (make-instance 'dictionary :dict-values '(("/S" . "/URI")))))
    (add-dict-value (content annotation) "/A" action)
    (add-dict-value action "/URI" (concatenate 'string "(" uri ")"))
    annotation))

(defun add-external-link (x y dx dy filename page-nb &key (border #(0 0 0)))
  (let ((annotation (make-instance 'annotation :rect (vector x y (+ x dx) (+ y dy))
				   :type "/Link" :border border ))
	(action (make-instance 'dictionary :dict-values '(("/S" . "/GoToR")))))
    (add-dict-value (content annotation) "/A" action)
    (add-dict-value action "/F" (concatenate 'string "(" filename ")"))
    (add-dict-value action "/D" (vector page-nb "/Fit"))
    annotation))

(defparameter +jpeg-color-spaces+ #("?" "/DeviceGray" "?" "/DeviceRGB" "/DeviceCMYK"))

(defclass bitmap-image ()
  ((width  :accessor width :initarg :width)
   (height :accessor height :initarg :height)
   (nb-components :accessor nb-components :initarg :nb-components)
   (data   :accessor data :initarg :data)))

(defclass jpeg-image (bitmap-image)
  ())

(defun %read-jpeg-file% (filename)
  (with-open-file (s filename :direction :input :element-type '(unsigned-byte 8))
    (loop with width and height and nb-components and data
	  for marker = (read-byte s)
	  if (= marker #xFF) do
	      (setf marker (read-byte s))
	      (cond
		((member marker '(#xC0 #xC1 #xC2));SOF markers
		 (read-byte s)(read-byte s) ;size
		 (when (/= (read-byte s) 8) (error "JPEG must have 8bits per component"))
		 (setf height (+ (ash (read-byte s) 8)(read-byte s)))
		 (setf width (+ (ash (read-byte s) 8)(read-byte s)))
		 (setf nb-components (read-byte s))
		 (file-position s :start)
		 (setf data (make-array (file-length s) :element-type '(unsigned-byte 8)))
		 (read-sequence data s)
		 (return (values nb-components width height data)))
		((member marker '(#xC3 #xC5 #xC6 #xC7 #xC8 #xC9 #xCA #xCB #xCD #xCE #xCF)) ;unsupported markers
		 (error "Unsupported JPEG format"))
		((not (member marker '(#xD0 #xD1 #xD2 #xD3 #xD4 #xD5 #xD6 #xD7 #xD8 #x01))) ;no param markers
		 (file-position s (+ (file-position s)(ash (read-byte s) 8)(read-byte s) -2)))))))

(defun read-jpeg-file (filename)
  (multiple-value-bind (nb-components width height data) (%read-jpeg-file% filename)
    (when nb-components
      (make-instance 'jpeg-image :nb-components nb-components
		     :width width :height height :data data))))

(defmethod make-jpeg-image (jpeg)
  (make-image jpeg))

(defmethod make-jpeg-image ((pathname pathname))
  (make-jpeg-image (read-jpeg-file pathname)))

(defmethod make-jpeg-image ((string string))
  (make-jpeg-image (read-jpeg-file string)))

(defgeneric make-image (object &key type &allow-other-keys)
 (:documentation "Returns more than just one pdf:image object when mask is supplied"))

(defmethod make-image ((object pathname) &rest args &key (type (pathname-type object)))
  (cond ((member type '("jpeg" "jpg") :test #'equalp)
         (apply 'make-image (read-jpeg-file object) args))
        ((equalp type "png")
         (apply 'make-image (read-png-file object) args))
        (t (error "Unsupported image file type ~s." type))))

(defmethod make-image ((object string) &rest args &key type)
  (apply #'make-image (merge-pathnames object (make-pathname :type type))
         args))

(defmethod make-image ((jpeg jpeg-image) &key type)
  (make-instance 'pdf:image
         :bits (data jpeg)
         :width (width jpeg) :height (height jpeg)
         :filter "/DCTDecode"
         :color-space (aref +jpeg-color-spaces+ (nb-components jpeg))
         :no-compression t))
