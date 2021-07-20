(defpackage :cl-gserver.agent.array
  (:use :cl)
  (:nicknames :agtarray)
  (:export #:make-array-agent
           #:agent-elt
           #:agent-push)
  )

(in-package :cl-gserver.agent.array)


(defun make-array-agent (context &key
                                   initial-array
                                   (dispatcher-id :shared))
  "Creates an agent that wraps a CL array/vector.  
`context`: something implementing `ac:actor-context` protocol like `asys:actor-system`. Specifying `nil` here creates an agent outside of an actor system. The user has to take care of that himself.  
`initial-array`: specify an initial array/vector.  
`dispatcher-id`: a dispatcher. defaults to `:shared`."
  (check-type initial-array array)
  (agt:make-agent (lambda () initial-array)
                  context dispatcher-id))

(defun agent-elt (index array-agent)
  (agt:agent-get array-agent
                 (lambda (array)
                   (elt array index))))

(defun agent-push (item array-agent)
  (agt:agent-update array-agent
                    (lambda (array)
                      (vector-push-extend item array)
                      array)))
