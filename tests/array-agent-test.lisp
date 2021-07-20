(defpackage :cl-gserver.agent.array-test
  (:use :cl :fiveam :cl-gserver.agent.array)
  (:export #:run!
           #:all-tests
           #:nil))
(in-package :cl-gserver.agent.array-test)

(def-suite agent.array-tests
  :description "Tests for array agent"
  :in cl-gserver.tests:test-suite)

(in-suite agent.array-tests)

(def-fixture asys-fixture ()
  (let ((asys (asys:make-actor-system '(:dispatchers (:shared (:workers 1))))))
    (unwind-protect
         (&body)
      (ac:shutdown asys))))

(def-fixture agt (arr)
  (let ((cut (make-array-agent nil :initial-array arr)))
    (unwind-protect
         (&body)
      (agt:agent-stop cut))))

(test create
  "Tests creating a array agent."
  (let ((cut (make-array-agent nil :initial-array #())))
    (is-true cut)
    (agt:agent-stop cut)))

(test create--in-system
  "Tests creating a array agent with providing an actor-context."
  (with-fixture asys-fixture ()
    (let ((cut (make-array-agent asys :initial-array #())))
      (is-true cut))))

(test elt
  "Tests retrieve element."
  (with-fixture agt (#(10 20))
    (is (= 10 (agent-elt 0 cut)))
    (is (= 20 (agent-elt 1 cut)))
    ))

(test push-value
  "Tests pushing new value."
  (with-fixture agt ((make-array 0 :adjustable t :fill-pointer t))
    (is-true (agent-push 1 cut))))
