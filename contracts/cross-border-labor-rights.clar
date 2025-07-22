;; Cross-Border Labor Rights Contract
;; Protects migrant workers from exploitation and abuse

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-WORKER-NOT-FOUND (err u501))
(define-constant ERR-EMPLOYER-NOT-FOUND (err u502))
(define-constant ERR-INVALID-VISA-STATUS (err u503))
(define-constant ERR-DOCUMENT-CONFISCATED (err u504))
(define-constant ERR-INSUFFICIENT-FUNDS (err u505))
(define-constant ERR-VIOLATION-NOT-FOUND (err u506))
(define-constant ERR-ALREADY-REPORTED (err u507))
(define-constant ERR-INVALID-WAGE (err u508))

;; Data Variables
(define-data-var next-violation-id uint u1)
(define-data-var next-assistance-id uint u1)
(define-data-var repatriation-fund-balance uint u0)

;; Data Maps
(define-map migrant-workers principal {
    home-country: (string-ascii 50),
    work-country: (string-ascii 50),
    visa-status: (string-ascii 30),
    visa-expiry: uint,
    employer: (optional principal),
    documents-held-by-employer: bool,
    fair-wage-rate: uint,
    actual-wage-rate: uint,
    contract-terms: (string-ascii 500),
    protection-status: (string-ascii 20),
    registered-date: uint
})

(define-map cross-border-employers principal {
    company-name: (string-ascii 100),
    operating-countries: (list 10 (string-ascii 50)),
    migrant-workers-count: uint,
    compliance-score: uint,
    violations-count: uint,
    license-status: (string-ascii 20),
    bond-amount: uint,
    active: bool
})

(define-map labor-violations uint {
    reporter: principal,
    employer: principal,
    violation-type: (string-ascii 100),
    description: (string-ascii 1000),
    severity-level: uint, ;; 1-5 scale
    evidence-hash: (optional (string-ascii 64)),
    date-occurred: uint,
    date-reported: uint,
    status: (string-ascii 20),
    investigation-result: (optional (string-ascii 500))
})

(define-map repatriation-assistance uint {
    worker: principal,
    home-country: (string-ascii 50),
    assistance-type: (string-ascii 50),
    amount-requested: uint,
    amount-approved: uint,
    request-date: uint,
    approval-date: (optional uint),
    status: (string-ascii 20),
    emergency: bool
})

(define-map wage-protection-escrow {worker: principal, employer: principal} {
    escrowed-amount: uint,
    monthly-wage: uint,
    last-payment-date: uint,
    payments-missed: uint,
    protection-active: bool
})

(define-map document-custody-records principal {
    passport-held-by: (optional principal),
    work-permit-held-by: (optional principal),
    other-documents: (string-ascii 200),
    custody-authorized: bool,
    return-requested: bool,
    return-date: (optional uint)
})

;; Public Functions

;; Register migrant worker
(define-public (register-migrant-worker
    (home-country (string-ascii 50))
    (work-country (string-ascii 50))
    (visa-status (string-ascii 30))
    (visa-expiry uint)
    (fair-wage-rate uint)
    (contract-terms (string-ascii 500))
)
    (begin
        (asserts! (> fair-wage-rate u0) ERR-INVALID-WAGE)
        (asserts! (> visa-expiry block-height) ERR-INVALID-VISA-STATUS)

        (map-set migrant-workers tx-sender {
            home-country: home-country,
            work-country: work-country,
            visa-status: visa-status,
            visa-expiry: visa-expiry,
            employer: none,
            documents-held-by-employer: false,
            fair-wage-rate: fair-wage-rate,
            actual-wage-rate: u0,
            contract-terms: contract-terms,
            protection-status: "active",
            registered-date: block-height
        })

        ;; Initialize document custody record
        (map-set document-custody-records tx-sender {
            passport-held-by: none,
            work-permit-held-by: none,
            other-documents: "",
            custody-authorized: false,
            return-requested: false,
            return-date: none
        })

        (ok true)
    )
)

;; Register cross-border employer
(define-public (register-cross-border-employer
    (company-name (string-ascii 100))
    (operating-countries (list 10 (string-ascii 50)))
    (bond-amount uint)
)
    (begin
        (asserts! (> bond-amount u0) ERR-INVALID-WAGE)

        ;; Transfer bond to contract
        (try! (stx-transfer? bond-amount tx-sender (as-contract tx-sender)))

        (map-set cross-border-employers tx-sender {
            company-name: company-name,
            operating-countries: operating-countries,
            migrant-workers-count: u0,
            compliance-score: u100,
            violations-count: u0,
            license-status: "active",
            bond-amount: bond-amount,
            active: true
        })

        (ok true)
    )
)

;; Assign worker to employer
(define-public (assign-worker-to-employer (worker principal) (actual-wage-rate uint))
    (let (
        (worker-data (unwrap! (map-get? migrant-workers worker) ERR-WORKER-NOT-FOUND))
        (employer-data (unwrap! (map-get? cross-border-employers tx-sender) ERR-EMPLOYER-NOT-FOUND))
    )
        (begin
            (asserts! (>= actual-wage-rate (get fair-wage-rate worker-data)) ERR-INVALID-WAGE)

            ;; Update worker assignment
            (map-set migrant-workers worker (merge worker-data {
                employer: (some tx-sender),
                actual-wage-rate: actual-wage-rate
            }))

            ;; Update employer worker count
            (map-set cross-border-employers tx-sender (merge employer-data {
                migrant-workers-count: (+ (get migrant-workers-count employer-data) u1)
            }))

            ;; Initialize wage protection escrow
            (map-set wage-protection-escrow {worker: worker, employer: tx-sender} {
                escrowed-amount: u0,
                monthly-wage: actual-wage-rate,
                last-payment-date: block-height,
                payments-missed: u0,
                protection-active: true
            })

            (ok true)
        )
    )
)

;; Report document confiscation
(define-public (report-document-confiscation (document-type (string-ascii 50)) (held-by principal))
    (let (
        (worker-data (unwrap! (map-get? migrant-workers tx-sender) ERR-WORKER-NOT-FOUND))
        (custody-record (unwrap! (map-get? document-custody-records tx-sender) ERR-WORKER-NOT-FOUND))
    )
        (begin
            ;; Update document custody record
            (map-set document-custody-records tx-sender (merge custody-record {
                passport-held-by: (if (is-eq document-type "passport") (some held-by) (get passport-held-by custody-record)),
                work-permit-held-by: (if (is-eq document-type "work-permit") (some held-by) (get work-permit-held-by custody-record)),
                custody-authorized: false
            }))

            ;; Update worker status
            (map-set migrant-workers tx-sender (merge worker-data {
                documents-held-by-employer: true,
                protection-status: "at-risk"
            }))

            (ok true)
        )
    )
)

;; Request document return
(define-public (request-document-return)
    (let (
        (custody-record (unwrap! (map-get? document-custody-records tx-sender) ERR-WORKER-NOT-FOUND))
        (worker-data (unwrap! (map-get? migrant-workers tx-sender) ERR-WORKER-NOT-FOUND))
    )
        (begin
            (asserts! (get documents-held-by-employer worker-data) ERR-DOCUMENT-CONFISCATED)

            (map-set document-custody-records tx-sender (merge custody-record {
                return-requested: true
            }))

            (ok true)
        )
    )
)

;; Return documents (called by employer)
(define-public (return-worker-documents (worker principal))
    (let (
        (custody-record (unwrap! (map-get? document-custody-records worker) ERR-WORKER-NOT-FOUND))
        (worker-data (unwrap! (map-get? migrant-workers worker) ERR-WORKER-NOT-FOUND))
    )
        (begin
            (asserts! (is-eq tx-sender (unwrap! (get employer worker-data) ERR-NOT-AUTHORIZED)) ERR-NOT-AUTHORIZED)

            ;; Update custody record
            (map-set document-custody-records worker (merge custody-record {
                passport-held-by: none,
                work-permit-held-by: none,
                return-requested: false,
                return-date: (some block-height)
            }))

            ;; Update worker status
            (map-set migrant-workers worker (merge worker-data {
                documents-held-by-employer: false,
                protection-status: "protected"
            }))

            (ok true)
        )
    )
)

;; Report labor violation
(define-public (report-labor-violation
    (employer principal)
    (violation-type (string-ascii 100))
    (description (string-ascii 1000))
    (severity-level uint)
    (evidence-hash (optional (string-ascii 64)))
    (date-occurred uint)
)
    (let (
        (worker-data (unwrap! (map-get? migrant-workers tx-sender) ERR-WORKER-NOT-FOUND))
        (violation-id (var-get next-violation-id))
    )
        (begin
            (asserts! (and (>= severity-level u1) (<= severity-level u5)) ERR-INVALID-VISA-STATUS)

            ;; Create violation record
            (map-set labor-violations violation-id {
                reporter: tx-sender,
                employer: employer,
                violation-type: violation-type,
                description: description,
                severity-level: severity-level,
                evidence-hash: evidence-hash,
                date-occurred: date-occurred,
                date-reported: block-height,
                status: "reported",
                investigation-result: none
            })

            ;; Update employer violation count
            (let ((employer-data (unwrap! (map-get? cross-border-employers employer) ERR-EMPLOYER-NOT-FOUND)))
                (map-set cross-border-employers employer (merge employer-data {
                    violations-count: (+ (get violations-count employer-data) u1),
                    compliance-score: (if (> (get compliance-score employer-data) (* severity-level u5))
                                        (- (get compliance-score employer-data) (* severity-level u5))
                                        u0)
                }))
            )

            ;; Increment violation ID
            (var-set next-violation-id (+ violation-id u1))

            (ok violation-id)
        )
    )
)

;; Request repatriation assistance
(define-public (request-repatriation-assistance
    (assistance-type (string-ascii 50))
    (amount-requested uint)
    (emergency bool)
)
    (let (
        (worker-data (unwrap! (map-get? migrant-workers tx-sender) ERR-WORKER-NOT-FOUND))
        (assistance-id (var-get next-assistance-id))
        (fund-balance (var-get repatriation-fund-balance))
    )
        (begin
            (asserts! (> amount-requested u0) ERR-INVALID-WAGE)

            ;; Create assistance request
            (map-set repatriation-assistance assistance-id {
                worker: tx-sender,
                home-country: (get home-country worker-data),
                assistance-type: assistance-type,
                amount-requested: amount-requested,
                amount-approved: u0,
                request-date: block-height,
                approval-date: none,
                status: "pending",
                emergency: emergency
            })

            ;; Increment assistance ID
            (var-set next-assistance-id (+ assistance-id u1))

            (ok assistance-id)
        )
    )
)

;; Approve repatriation assistance
(define-public (approve-repatriation-assistance (assistance-id uint) (approved-amount uint))
    (let (
        (assistance-data (unwrap! (map-get? repatriation-assistance assistance-id) ERR-VIOLATION-NOT-FOUND))
        (fund-balance (var-get repatriation-fund-balance))
    )
        (begin
            (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
            (asserts! (>= fund-balance approved-amount) ERR-INSUFFICIENT-FUNDS)
            (asserts! (is-eq (get status assistance-data) "pending") ERR-ALREADY-REPORTED)

            ;; Transfer assistance funds
            (try! (as-contract (stx-transfer? approved-amount tx-sender (get worker assistance-data))))

            ;; Update assistance record
            (map-set repatriation-assistance assistance-id (merge assistance-data {
                amount-approved: approved-amount,
                approval-date: (some block-height),
                status: "approved"
            }))

            ;; Update fund balance
            (var-set repatriation-fund-balance (- fund-balance approved-amount))

            (ok true)
        )
    )
)

;; Contribute to repatriation fund
(define-public (contribute-to-repatriation-fund (amount uint))
    (begin
        (asserts! (> amount u0) ERR-INVALID-WAGE)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set repatriation-fund-balance (+ (var-get repatriation-fund-balance) amount))
        (ok true)
    )
)

;; Deposit wage protection escrow
(define-public (deposit-wage-protection (worker principal) (amount uint))
    (let (
        (escrow-key {worker: worker, employer: tx-sender})
        (escrow-data (unwrap! (map-get? wage-protection-escrow escrow-key) ERR-WORKER-NOT-FOUND))
    )
        (begin
            (asserts! (> amount u0) ERR-INVALID-WAGE)
            (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

            (map-set wage-protection-escrow escrow-key (merge escrow-data {
                escrowed-amount: (+ (get escrowed-amount escrow-data) amount)
            }))

            (ok true)
        )
    )
)

;; Process wage payment from escrow
(define-public (process-wage-payment-from-escrow (worker principal))
    (let (
        (escrow-key {worker: worker, employer: tx-sender})
        (escrow-data (unwrap! (map-get? wage-protection-escrow escrow-key) ERR-WORKER-NOT-FOUND))
        (monthly-wage (get monthly-wage escrow-data))
    )
        (begin
            (asserts! (>= (get escrowed-amount escrow-data) monthly-wage) ERR-INSUFFICIENT-FUNDS)

            ;; Transfer wage to worker
            (try! (as-contract (stx-transfer? monthly-wage tx-sender worker)))

            ;; Update escrow data
            (map-set wage-protection-escrow escrow-key (merge escrow-data {
                escrowed-amount: (- (get escrowed-amount escrow-data) monthly-wage),
                last-payment-date: block-height,
                payments-missed: u0
            }))

            (ok true)
        )
    )
)

;; Investigate labor violation
(define-public (investigate-labor-violation (violation-id uint) (result (string-ascii 500)) (status (string-ascii 20)))
    (let ((violation-data (unwrap! (map-get? labor-violations violation-id) ERR-VIOLATION-NOT-FOUND)))
        (begin
            (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

            (map-set labor-violations violation-id (merge violation-data {
                status: status,
                investigation-result: (some result)
            }))

            (ok true)
        )
    )
)

;; Read-only Functions

(define-read-only (get-migrant-worker-info (worker principal))
    (map-get? migrant-workers worker)
)

(define-read-only (get-cross-border-employer-info (employer principal))
    (map-get? cross-border-employers employer)
)

(define-read-only (get-labor-violation (violation-id uint))
    (map-get? labor-violations violation-id)
)

(define-read-only (get-repatriation-assistance (assistance-id uint))
    (map-get? repatriation-assistance assistance-id)
)

(define-read-only (get-wage-protection-escrow (worker principal) (employer principal))
    (map-get? wage-protection-escrow {worker: worker, employer: employer})
)

(define-read-only (get-document-custody-record (worker principal))
    (map-get? document-custody-records worker)
)

(define-read-only (get-repatriation-fund-balance)
    (ok (var-get repatriation-fund-balance))
)

(define-read-only (calculate-employer-risk-score (employer principal))
    (let ((employer-data (unwrap! (map-get? cross-border-employers employer) ERR-EMPLOYER-NOT-FOUND)))
        (ok (- u100 (+
            (* (get violations-count employer-data) u10)
            (if (< (get compliance-score employer-data) u70) u20 u0)
        )))
    )
)

(define-read-only (is-visa-expiring-soon (worker principal))
    (let ((worker-data (unwrap! (map-get? migrant-workers worker) ERR-WORKER-NOT-FOUND)))
        (ok (< (get visa-expiry worker-data) (+ block-height u4320))) ;; 30 days in blocks
    )
)

(define-read-only (calculate-wage-gap (worker principal))
    (let ((worker-data (unwrap! (map-get? migrant-workers worker) ERR-WORKER-NOT-FOUND)))
        (ok (if (> (get actual-wage-rate worker-data) u0)
                (- (get fair-wage-rate worker-data) (get actual-wage-rate worker-data))
                (get fair-wage-rate worker-data)
            ))
    )
)
