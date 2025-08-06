;; Certification Tracking and Renewal Contract
;; Ensures employees maintain required professional certifications

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-CERT-NOT-FOUND (err u201))
(define-constant ERR-ALREADY-CERTIFIED (err u202))
(define-constant ERR-CERT-EXPIRED (err u203))
(define-constant ERR-INVALID-INPUT (err u204))
(define-constant ERR-RENEWAL-NOT-DUE (err u205))

;; Data Variables
(define-data-var next-cert-id uint u1)
(define-data-var contract-admin principal CONTRACT-OWNER)
(define-data-var renewal-reminder-blocks uint u1440) ;; ~10 days in blocks

;; Data Maps
(define-map certifications
  { cert-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    issuing-authority: (string-ascii 100),
    validity-period-blocks: uint,
    renewal-requirements: (string-ascii 500),
    is-mandatory: bool,
    created-by: principal,
    created-at: uint
  }
)

(define-map employee-certifications
  { employee: principal, cert-id: uint }
  {
    issued-at: uint,
    expires-at: uint,
    status: (string-ascii 20), ;; "active", "expired", "suspended", "renewed"
    renewal-count: uint,
    last-renewed: (optional uint)
  }
)

(define-map certification-requirements
  { role: (string-ascii 50) }
  {
    required-certs: (list 20 uint),
    updated-by: principal,
    updated-at: uint
  }
)

(define-map renewal-reminders
  { employee: principal, cert-id: uint }
  {
    reminder-sent-at: uint,
    reminder-count: uint,
    next-reminder-at: uint
  }
)

;; Read-only functions
(define-read-only (get-certification (cert-id uint))
  (map-get? certifications { cert-id: cert-id })
)

(define-read-only (get-employee-certification (employee principal) (cert-id uint))
  (map-get? employee-certifications { employee: employee, cert-id: cert-id })
)

(define-read-only (get-role-requirements (role (string-ascii 50)))
  (map-get? certification-requirements { role: role })
)

(define-read-only (is-certification-valid (employee principal) (cert-id uint))
  (match (get-employee-certification employee cert-id)
    emp-cert (and
               (is-eq (get status emp-cert) "active")
               (> (get expires-at emp-cert) block-height))
    false
  )
)

(define-read-only (get-expiring-certifications (employee principal))
  ;; This would return certifications expiring within reminder period
  ;; Simplified implementation - in practice would iterate through employee's certs
  (ok true)
)

(define-read-only (get-certification-compliance (employee principal) (role (string-ascii 50)))
  (match (get-role-requirements role)
    requirements
      (let ((required-certs (get required-certs requirements)))
        ;; Check if employee has all required certifications
        ;; Simplified - would iterate through required-certs list
        (ok true))
    (ok false)
  )
)

;; Public functions
(define-public (create-certification
  (name (string-ascii 100))
  (description (string-ascii 500))
  (issuing-authority (string-ascii 100))
  (validity-period-blocks uint)
  (renewal-requirements (string-ascii 500))
  (is-mandatory bool))
  (let ((cert-id (var-get next-cert-id)))
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> validity-period-blocks u0) ERR-INVALID-INPUT)

    (map-set certifications
      { cert-id: cert-id }
      {
        name: name,
        description: description,
        issuing-authority: issuing-authority,
        validity-period-blocks: validity-period-blocks,
        renewal-requirements: renewal-requirements,
        is-mandatory: is-mandatory,
        created-by: tx-sender,
        created-at: block-height
      }
    )

    (var-set next-cert-id (+ cert-id u1))
    (ok cert-id)
  )
)

(define-public (issue-certification (employee principal) (cert-id uint))
  (let ((cert (unwrap! (get-certification cert-id) ERR-CERT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (get-employee-certification employee cert-id)) ERR-ALREADY-CERTIFIED)

    (let ((expires-at (+ block-height (get validity-period-blocks cert))))
      (map-set employee-certifications
        { employee: employee, cert-id: cert-id }
        {
          issued-at: block-height,
          expires-at: expires-at,
          status: "active",
          renewal-count: u0,
          last-renewed: none
        }
      )

      ;; Set up renewal reminder
      (map-set renewal-reminders
        { employee: employee, cert-id: cert-id }
        {
          reminder-sent-at: u0,
          reminder-count: u0,
          next-reminder-at: (- expires-at (var-get renewal-reminder-blocks))
        }
      )

      (ok true)
    )
  )
)

(define-public (renew-certification (employee principal) (cert-id uint))
  (let ((emp-cert (unwrap! (get-employee-certification employee cert-id) ERR-CERT-NOT-FOUND))
        (cert (unwrap! (get-certification cert-id) ERR-CERT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)

    ;; Check if renewal is due (within reminder period)
    (asserts! (<= (get expires-at emp-cert) (+ block-height (var-get renewal-reminder-blocks))) ERR-RENEWAL-NOT-DUE)

    (let ((new-expires-at (+ block-height (get validity-period-blocks cert))))
      (map-set employee-certifications
        { employee: employee, cert-id: cert-id }
        (merge emp-cert {
          expires-at: new-expires-at,
          status: "active",
          renewal-count: (+ (get renewal-count emp-cert) u1),
          last-renewed: (some block-height)
        })
      )

      ;; Update renewal reminder
      (map-set renewal-reminders
        { employee: employee, cert-id: cert-id }
        {
          reminder-sent-at: u0,
          reminder-count: u0,
          next-reminder-at: (- new-expires-at (var-get renewal-reminder-blocks))
        }
      )

      (ok true)
    )
  )
)

(define-public (expire-certification (employee principal) (cert-id uint))
  (let ((emp-cert (unwrap! (get-employee-certification employee cert-id) ERR-CERT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (< (get expires-at emp-cert) block-height) ERR-INVALID-INPUT)

    (map-set employee-certifications
      { employee: employee, cert-id: cert-id }
      (merge emp-cert { status: "expired" })
    )

    (ok true)
  )
)

(define-public (set-role-requirements (role (string-ascii 50)) (required-certs (list 20 uint)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (> (len role) u0) ERR-INVALID-INPUT)

    (map-set certification-requirements
      { role: role }
      {
        required-certs: required-certs,
        updated-by: tx-sender,
        updated-at: block-height
      }
    )

    (ok true)
  )
)

(define-public (send-renewal-reminder (employee principal) (cert-id uint))
  (let ((reminder (default-to
                    { reminder-sent-at: u0, reminder-count: u0, next-reminder-at: u0 }
                    (map-get? renewal-reminders { employee: employee, cert-id: cert-id }))))
    (asserts! (>= block-height (get next-reminder-at reminder)) ERR-INVALID-INPUT)

    (map-set renewal-reminders
      { employee: employee, cert-id: cert-id }
      (merge reminder {
        reminder-sent-at: block-height,
        reminder-count: (+ (get reminder-count reminder) u1),
        next-reminder-at: (+ block-height u720) ;; Next reminder in ~5 days
      })
    )

    (ok true)
  )
)

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (var-set contract-admin new-admin)
    (ok true)
  )
)
