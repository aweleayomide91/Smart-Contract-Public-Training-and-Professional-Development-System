;; Training Budget Allocation Contract
;; Distributes training funds fairly across departments and employees

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-INSUFFICIENT-BUDGET (err u301))
(define-constant ERR-DEPT-NOT-FOUND (err u302))
(define-constant ERR-INVALID-AMOUNT (err u303))
(define-constant ERR-BUDGET-ALREADY-SET (err u304))
(define-constant ERR-REQUEST-NOT-FOUND (err u305))
(define-constant ERR-INVALID-STATUS (err u306))

;; Data Variables
(define-data-var contract-admin principal CONTRACT-OWNER)
(define-data-var total-budget uint u0)
(define-data-var allocated-budget uint u0)
(define-data-var next-request-id uint u1)

;; Data Maps
(define-map department-budgets
  { department: (string-ascii 50) }
  {
    allocated-amount: uint,
    used-amount: uint,
    remaining-amount: uint,
    employee-count: uint,
    budget-per-employee: uint,
    last-updated: uint
  }
)

(define-map employee-budgets
  { employee: principal }
  {
    department: (string-ascii 50),
    allocated-amount: uint,
    used-amount: uint,
    remaining-amount: uint,
    last-updated: uint
  }
)

(define-map budget-requests
  { request-id: uint }
  {
    employee: principal,
    department: (string-ascii 50),
    amount: uint,
    purpose: (string-ascii 200),
    status: (string-ascii 20), ;; "pending", "approved", "rejected", "completed"
    requested-at: uint,
    approved-by: (optional principal),
    approved-at: (optional uint)
  }
)

(define-map annual-budget-history
  { year: uint }
  {
    total-budget: uint,
    allocated-budget: uint,
    used-budget: uint,
    remaining-budget: uint,
    departments-count: uint
  }
)

;; Read-only functions
(define-read-only (get-department-budget (department (string-ascii 50)))
  (map-get? department-budgets { department: department })
)

(define-read-only (get-employee-budget (employee principal))
  (map-get? employee-budgets { employee: employee })
)

(define-read-only (get-budget-request (request-id uint))
  (map-get? budget-requests { request-id: request-id })
)

(define-read-only (get-total-budget)
  (var-get total-budget)
)

(define-read-only (get-allocated-budget)
  (var-get allocated-budget)
)

(define-read-only (get-remaining-total-budget)
  (- (var-get total-budget) (var-get allocated-budget))
)

(define-read-only (calculate-department-allocation (department (string-ascii 50)) (employee-count uint))
  ;; Simple allocation based on employee count
  ;; In practice, this could be more sophisticated
  (let ((remaining-budget (get-remaining-total-budget)))
    (if (> employee-count u0)
      (/ remaining-budget employee-count)
      u0)
  )
)

;; Public functions
(define-public (set-total-budget (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-eq (var-get total-budget) u0) ERR-BUDGET-ALREADY-SET)

    (var-set total-budget amount)
    (ok true)
  )
)

(define-public (allocate-department-budget
  (department (string-ascii 50))
  (employee-count uint)
  (allocation-amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (> allocation-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (> employee-count u0) ERR-INVALID-AMOUNT)
    (asserts! (<= (+ (var-get allocated-budget) allocation-amount) (var-get total-budget)) ERR-INSUFFICIENT-BUDGET)

    (let ((budget-per-employee (/ allocation-amount employee-count)))
      (map-set department-budgets
        { department: department }
        {
          allocated-amount: allocation-amount,
          used-amount: u0,
          remaining-amount: allocation-amount,
          employee-count: employee-count,
          budget-per-employee: budget-per-employee,
          last-updated: block-height
        }
      )

      (var-set allocated-budget (+ (var-get allocated-budget) allocation-amount))
      (ok true)
    )
  )
)

(define-public (allocate-employee-budget (employee principal) (department (string-ascii 50)))
  (let ((dept-budget (unwrap! (get-department-budget department) ERR-DEPT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)

    (let ((employee-allocation (get budget-per-employee dept-budget)))
      (map-set employee-budgets
        { employee: employee }
        {
          department: department,
          allocated-amount: employee-allocation,
          used-amount: u0,
          remaining-amount: employee-allocation,
          last-updated: block-height
        }
      )

      (ok true)
    )
  )
)

(define-public (submit-budget-request
  (amount uint)
  (purpose (string-ascii 200)))
  (let ((request-id (var-get next-request-id))
        (employee-budget (unwrap! (get-employee-budget tx-sender) ERR-INSUFFICIENT-BUDGET)))
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (<= amount (get remaining-amount employee-budget)) ERR-INSUFFICIENT-BUDGET)
    (asserts! (> (len purpose) u0) ERR-INVALID-AMOUNT)

    (map-set budget-requests
      { request-id: request-id }
      {
        employee: tx-sender,
        department: (get department employee-budget),
        amount: amount,
        purpose: purpose,
        status: "pending",
        requested-at: block-height,
        approved-by: none,
        approved-at: none
      }
    )

    (var-set next-request-id (+ request-id u1))
    (ok request-id)
  )
)

(define-public (approve-budget-request (request-id uint))
  (let ((request (unwrap! (get-budget-request request-id) ERR-REQUEST-NOT-FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status request) "pending") ERR-INVALID-STATUS)

    (map-set budget-requests
      { request-id: request-id }
      (merge request {
        status: "approved",
        approved-by: (some tx-sender),
        approved-at: (some block-height)
      })
    )

    (ok true)
  )
)

(define-public (use-budget (request-id uint))
  (let ((request (unwrap! (get-budget-request request-id) ERR-REQUEST-NOT-FOUND))
        (employee-budget (unwrap! (get-employee-budget (get employee request)) ERR-INSUFFICIENT-BUDGET))
        (dept-budget (unwrap! (get-department-budget (get department request)) ERR-DEPT-NOT-FOUND)))
    (asserts! (is-eq (get status request) "approved") ERR-INVALID-STATUS)
    (asserts! (>= (get remaining-amount employee-budget) (get amount request)) ERR-INSUFFICIENT-BUDGET)

    ;; Update employee budget
    (map-set employee-budgets
      { employee: (get employee request) }
      (merge employee-budget {
        used-amount: (+ (get used-amount employee-budget) (get amount request)),
        remaining-amount: (- (get remaining-amount employee-budget) (get amount request)),
        last-updated: block-height
      })
    )

    ;; Update department budget
    (map-set department-budgets
      { department: (get department request) }
      (merge dept-budget {
        used-amount: (+ (get used-amount dept-budget) (get amount request)),
        remaining-amount: (- (get remaining-amount dept-budget) (get amount request)),
        last-updated: block-height
      })
    )

    ;; Mark request as completed
    (map-set budget-requests
      { request-id: request-id }
      (merge request { status: "completed" })
    )

    (ok true)
  )
)

(define-public (reject-budget-request (request-id uint))
  (let ((request (unwrap! (get-budget-request request-id) ERR-REQUEST-NOT-FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status request) "pending") ERR-INVALID-STATUS)

    (map-set budget-requests
      { request-id: request-id }
      (merge request { status: "rejected" })
    )

    (ok true)
  )
)

(define-public (reallocate-unused-budget (from-department (string-ascii 50)) (to-department (string-ascii 50)) (amount uint))
  (let ((from-budget (unwrap! (get-department-budget from-department) ERR-DEPT-NOT-FOUND))
        (to-budget (unwrap! (get-department-budget to-department) ERR-DEPT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (asserts! (>= (get remaining-amount from-budget) amount) ERR-INSUFFICIENT-BUDGET)

    ;; Reduce from-department budget
    (map-set department-budgets
      { department: from-department }
      (merge from-budget {
        allocated-amount: (- (get allocated-amount from-budget) amount),
        remaining-amount: (- (get remaining-amount from-budget) amount),
        last-updated: block-height
      })
    )

    ;; Increase to-department budget
    (map-set department-budgets
      { department: to-department }
      (merge to-budget {
        allocated-amount: (+ (get allocated-amount to-budget) amount),
        remaining-amount: (+ (get remaining-amount to-budget) amount),
        last-updated: block-height
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
