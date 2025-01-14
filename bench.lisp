;;(push #P"~/Development/MySources/sento/" asdf:*central-registry*)
(asdf:load-system "sento")

(log:config :warn)

(defparameter *starttime* 0)
(defparameter *endtime* 0)

(defparameter *withreply-p* nil)

(defparameter *system* nil)
(defparameter *actor* nil)
(defparameter *counter* 0)
(defparameter +threads+ 8)
(defparameter *per-thread* nil)

(defun max-loop () (* *per-thread* +threads+))

(defun runner-bt (&optional (withreply-p nil) (asyncask nil) (queue-size 0))
  (declare (ignore queue-size))
  ;; dispatchers used for the async-ask
  #+(or abcl clasp lispworks8 allegro)
  (setf *per-thread* 125000)
  #+sbcl
  (setf *per-thread* 75000)  
  #+ccl
  (setf *per-thread* (if asyncask 10000 125000))
  (setf *system* (asys:make-actor-system '(:dispatchers (:shared (:workers 8)))))
  (setf *actor* (ac:actor-of *system*
                             :receive (lambda (msg)
                                        (declare (ignore msg))
                                        (incf *counter*))
                             :dispatcher :pinned))
  (setf *withreply-p* withreply-p)
  (setf *counter* 0)
  (setf *starttime* (get-universal-time))
  (format t "Times: ~a~%" (max-loop))
  (time
   (progn
     (map nil #'bt:join-thread
          (mapcar (lambda (x)
                    (bt:make-thread
                     (lambda ()
                       (dotimes (n *per-thread*)
                         (if withreply-p
                             (if asyncask
                                 (act:ask *actor* :foo)
                                 (act:ask-s *actor* :foo))
                             (act:tell *actor* :foo))))
                     :name x))
                  (mapcar (lambda (n) (format nil "thread-~a" n))
                          (loop for n from 1 to +threads+ collect n))))
     (miscutils:assert-cond (lambda () (= *counter* (max-loop))) 20)))
  (setf *endtime* (get-universal-time))
  (format t "Counter: ~a~%" *counter*)
  (format t "Elapsed: ~a~%" (- *endtime* *starttime*))
  (print *system*)
  (ac:shutdown *system*))

(defun runner-dp (&optional (withreply-p nil) (asyncask nil) (queue-size 0))
  (declare (ignore queue-size))
  #+sbcl
  (setf *per-thread* (if (or withreply-p asyncask) 50000 125000))
  #+ccl
  (setf *per-thread* (if asyncask 10000 125000))
  #+(or abcl clasp allegro lispworks8)
  (setf *per-thread* 125000)
  (setf *system* (asys:make-actor-system '(:dispatchers (:shared (:workers 8)))))
  (setf *actor* (ac:actor-of *system*
                             :receive (lambda (msg)
                                        (declare (ignore msg))
                                        (incf *counter*))
                             :dispatcher :shared))
  ;;(print *actor*)
  (setf *withreply-p* withreply-p)
  (setf *counter* 0)
  (setf *starttime* (get-universal-time))
  (format t "Times: ~a~%" (max-loop))
  (time
   (progn
     (map nil #'bt:join-thread
          (mapcar (lambda (x)
                    (bt:make-thread
                     (lambda ()
                       (dotimes (n *per-thread*)
                         (if withreply-p
                             (if asyncask
                                 (act:ask *actor* :foo)
                                 (act:ask-s *actor* :foo))
                             (act:tell *actor* :foo))))
                     :name x))
                  (mapcar (lambda (n) (format nil "thread-~a" n))
                          (loop for n from 1 to +threads+ collect n))))
     (miscutils:assert-cond (lambda () (= *counter* (max-loop))) 120)))
  (setf *endtime* (get-universal-time))
  (format t "Counter: ~a~%" *counter*)
  (format t "Elapsed: ~a~%" (- *endtime* *starttime*))
  ;;(print *system*)
  (ac:shutdown *system*))


;; (defun runner-lp ()
;;   (setf *msgbox* (make-instance 'sento.messageb::message-box-lsr))
;;   (setf lparallel:*kernel* (lparallel:make-kernel +threads+))
;;   (setf *counter* 0)

;;   (unwind-protect
;;        (time
;;         (let ((chan (lparallel:make-channel)))
;;           (dotimes (n (max-loop))
;;             (lparallel:submit-task chan #'msg-submit))
;;           (dotimes (n (max-loop))
;;             (lparallel:receive-result chan))))
;;     (format t "Counter: ~a~%" *counter*)
;;     (lparallel:end-kernel)
;;     (sento.messageb::stop *msgbox*)))

;; (defun runner-lp2 ()
;;   (setf *msgbox* (make-instance 'sento.messageb::message-box-lsr))
;;   (setf lparallel:*kernel* (lparallel:make-kernel +threads+))
;;   (setf *counter* 0)

;;   (unwind-protect
;;        (time
;;         (progn 
;;           (map nil #'lparallel:force
;;                (mapcar (lambda (x)
;;                          (lparallel:future
;;                            (dotimes (n *per-thread*)
;;                              (msg-submit))))
;;                        (mapcar (lambda (n) (format nil "thread-~a" n))
;;                                (loop for n from 1 to +threads+ collect n))))
;;           (format t "Counter: ~a~%" *counter*)
;;           (assert-cond (lambda () (= *counter* (max-loop))) 5)))
;;     (format t "Counter: ~a~%" *counter*)
;;     (lparallel:end-kernel)
;;     (sento.messageb::stop *msgbox*)))

;; (defun runner-lp3 ()
;;   (setf *msgbox* (make-instance 'sento.messageb::message-box-lsr))
;;   (setf lparallel:*kernel* (lparallel:make-kernel +threads+))
;;   (setf *counter* 0)

;;   (unwind-protect
;;        (time
;;         (lparallel:pmap nil (lambda (per-thread)
;;                               (dotimes (n per-thread)
;;                                 (msg-submit)))
;;                         :parts 1
;;                         (loop repeat +threads+ collect *per-thread*)))
;;     (format t "Counter: ~a~%" *counter*)
;;     (lparallel:end-kernel)
;;     (sento.messageb::stop *msgbox*)))
