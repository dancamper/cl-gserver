(defpackage :cl-gserver.actor-cell-test
  (:use :cl :trivia :fiveam :cl-gserver.actor-cell)
  (:export #:run!
           #:all-tests
           #:nil))

(in-package :cl-gserver.actor-cell-test)

(def-suite actor-cell-tests
  :description "actor-cell tests"
  :in cl-gserver.tests:test-suite)

(in-suite actor-cell-tests)

(log:config :warn)

(def-fixture cell-fixture (call-fun cast-fun before-start-fun after-stop-fun state)
  (defclass test-cell (actor-cell) ())
  (defmethod handle-call ((cell test-cell) message current-state)
    (funcall call-fun cell message current-state))
  (defmethod handle-cast ((cell test-cell) message current-state)
    (funcall cast-fun cell message current-state))
  (defmethod before-start ((cell test-cell) state)
    (when before-start-fun
      (funcall before-start-fun cell state)))
  (defmethod after-stop ((cell test-cell))
    (when after-stop-fun
      (funcall after-stop-fun cell)))
  
  (let ((cut (make-instance 'test-cell
                            :state state)))
    (setf (msgbox cut) (make-instance 'mesgb:message-box-bt))
    (unwind-protect
         (&body)
      (call cut :stop))))

(test get-cell-name
  "Just retrieves the name of the cell"

  (with-fixture cell-fixture (nil nil nil nil nil)
    (print (name cut))
    (is (= 0 (search "actor-" (name cut))))))

(test run-before-start-fun
  "Tests the execution of `before-start'"
  
  (with-fixture cell-fixture ((lambda (self message current-state)
                                (declare (ignore self message))
                                (cons current-state current-state))
                              nil
                              (lambda (self state)
                                (declare (ignore state))
                                (with-slots (act-cell:state) self
                                  (setf act-cell:state "before-start-fun-executed")))
                              nil
                              0)
    (is (string= "before-start-fun-executed" (call cut :foo)))))

(defparameter *after-stop-val* nil)
(test run-after-stop-fun
  "Tests the execution of `after-stop'"
  
  (with-fixture cell-fixture ((lambda (self message current-state)
                                (declare (ignore self message))
                                (cons current-state current-state))
                              nil
                              nil
                              (lambda (self)
                                (declare (ignore self))
                                (setf *after-stop-val* "after-stop-fun-executed"))
                              0)
    (call cut :stop)
    (is (string= "after-stop-fun-executed" *after-stop-val*))))

(test no-message-box
  "Test responds with :no-message-handling when no msgbox is configured."

  (defclass no-msg-server (actor-cell) ())
  (defmethod handle-call ((cell no-msg-server) message current-state)
    (cons message current-state))

  (let ((cut (make-instance 'stopping-cell)))
    (is (eq :no-message-handling (call cut :foo)))))

(test handle-call
  "Simple cell handle-call test."

  (with-fixture cell-fixture ((lambda (cell message current-state)
                                (declare (ignore cell))
                                (match message
                                  ((list :add n)
                                   (let ((new-state (+ current-state n)))
                                     (cons new-state new-state)))
                                  ((list :sub n)
                                   (let ((new-state (- current-state n)))
                                     (cons new-state new-state)))))
                              nil
                              nil
                              nil
                              0)
    (is (= 1000 (call cut '(:add 1000))))
    (is (= 500 (call cut '(:sub 500))))
    (is (eq :unhandled (call cut "Foo")))))

(test error-in-handler
  "testing error handling"
  
  (with-fixture cell-fixture ((lambda (cell message current-state)
                                (declare (ignore cell current-state))
                                (log:info "Raising error condition...")
                                (match message
                                  ((list :err) (error "Foo Error"))))
                              nil
                              nil
                              nil
                              nil)
    (let ((msg (call cut '(:err))))
      (format t "Got msg : ~a~%" msg)
      (is (not (null (cdr msg))))
      (is (eq (car msg) :handler-error))
      (is (string= "Foo Error" (format nil "~a" (cdr msg)))))))


(test stack-cell
  "a actor-cell as stack."

  (with-fixture cell-fixture ((lambda (cell message current-state)
                                (declare (ignore cell))
                                (format t "current-state: ~a~%" current-state)
                                (match message
                                  (:pop
                                   (cons
                                    (car current-state)
                                    (cdr current-state)))
                                  (:get
                                   (cons current-state current-state))))
                              (lambda (cell message current-state)
                                (declare (ignore cell))
                                (format t "current-state: ~a~%" current-state)
                                (match message
                                  ((cons :push value)
                                   (let ((new-state (append current-state (list value))))
                                     (cons new-state new-state)))))
                              nil
                              nil
                              '(5))
    (is (equalp '(5) (call cut :get)))
    (cast cut (cons :push 4))
    (sleep 0.01)
    (cast cut (cons :push 3))
    (sleep 0.01)
    (cast cut (cons :push 2))
    (sleep 0.01)
    (cast cut (cons :push 1))
    (sleep 0.3)
    (is (equalp '(5 4 3 2 1) (call cut :get)))
    (is (= 5 (call cut :pop)))
    (is (= 4 (call cut :pop)))
    (is (= 3 (call cut :pop)))
    (is (= 2 (call cut :pop)))
    (is (= 1 (call cut :pop)))
    (is (null (call cut :pop)))))


(test stopping-cell
  "Stopping a cell stops the message handling and frees resources."

  (defclass stopping-cell (actor-cell) ())
  (defmethod handle-call ((cell stopping-cell) message current-state)
    (cons message current-state))

  (let ((cut (make-instance 'stopping-cell)))
    (setf (msgbox cut) (make-instance 'mesgb:message-box-bt))
    (is (eq :stopped (call cut :stop)))))


(defun run-tests ()
  (run! 'get-cell-name)
  (run! 'no-message-box)
  (run! 'handle-call)
  (run! 'error-in-handler)
  (run! 'stack-cell)
  (run! 'stopping-cell))
