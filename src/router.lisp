(defpackage :cl-gserver.router
  (:use :cl)
  (:nicknames :router)
  (:import-from #:act
                #:tell
                #:ask
                #:async-ask)
  (:export #:router
           #:make-router
           #:add-routee
           #:stop
           #:routees
           #:strategy
           #:tell
           #:ask
           #:async-ask)
  )

(in-package :cl-gserver.router)

(defun random-strategy (len)
  "The default, built-in strategy: random."
  (random len))

(defparameter *built-in-strategies*
  (list :random #'random-strategy))

(defun get-strategy (strategy)
  (cond
    ((eq :random strategy) (getf *built-in-strategies* strategy))
    ((functionp strategy) strategy)
    (t (error "Unknown strategy!"))))

(defun make-router (&key (strategy :random) (routees nil))
  "Default constructor of router.
Built-in strategies: `:random'.
Specify your own strategy by providing a function that takes a `fixnum' as parameter and returns a `fixnum' that represents the index of the routee to choose.
Specify `routees' if you know them upfront."
  (let ((router (make-instance 'router
                               :strategy (get-strategy strategy))))
    (when routees
      (dolist (routee routees)
        (add-routee router routee)))
    router))

(defclass router ()
  ((routees :initform (make-array 2 :adjustable t :fill-pointer 0)
            :reader routees
            :documentation "The routees.")
   (strategy :initform (get-strategy :random)
             :initarg :strategy
             :reader strategy
             :documentation
             "The router strategy.
The `strategy' is a function with a `fixnum' as input and a `fixnum' as output.
The input represents the number of routees.
The output represents the index of the routee to choose."))
  (:documentation
   "A router combines a pool of actors and implements the actor-api protocol.
So a `tell', `ask' and `async-ask' is delegated to one of the routers routees.
While a router implements parts of the actor protocol it doesn't implement all.
I.e. a router cannot be `watch'ed.
A router `strategy' defines how one of the actors is determined as the forwarding target of the message."))

(defun add-routee (router routee)
  "Adds a routee/actor to the router."
  (vector-push-extend routee (routees router))
  routee)

(defun stop (router)
  "Stops all routees."
  (mapcar #'act-cell:stop (coerce (routees router) 'list)))

(defun get-strategy-index (router)
  (let* ((routees (routees router))
         (strategy (strategy router))
         (actor-index (funcall strategy (length routees))))
    (log:debug "Using index from strategy: ~a" actor-index)
    actor-index))

(defmethod tell ((self router) message &optional sender)
  (tell
   (elt (routees self) (get-strategy-index self))
   message
   sender))

(defmethod ask ((self router) message &key time-out)
  (ask
   (elt (routees self) (get-strategy-index self))
   message
   :time-out time-out))

(defmethod async-ask ((self router) message &key time-out)
  (async-ask
   (elt (routees self) (get-strategy-index self))
   message
   :time-out time-out))