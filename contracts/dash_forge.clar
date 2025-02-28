;; DashForge Contract

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-DASHBOARD (err u102))
(define-constant ERR-INVALID-PRICE (err u103))
(define-constant ERR-PAYMENT-FAILED (err u104))
(define-constant ERR-DASHBOARD-DELETED (err u105))
(define-constant ERR-INVALID-VERSION (err u106))

;; Data Maps
(define-map dashboards
    { dashboard-id: uint }
    {
        owner: principal,
        title: (string-utf8 64),
        config: (string-utf8 4096),
        created-at: uint,
        updated-at: uint,
        version: uint,
        template: bool,
        price: uint,
        deleted: bool
    }
)

(define-map dashboard-access
    { dashboard-id: uint, user: principal }
    { can-view: bool, can-edit: bool }
)

(define-map dashboard-versions
    { dashboard-id: uint, version: uint }
    { config: (string-utf8 4096), updated-at: uint }
)

(define-map user-templates
    { user: principal }
    { template-ids: (list 100 uint) }
)

;; Variables
(define-data-var next-dashboard-id uint u1)
(define-data-var contract-paused bool false)

;; Events
(define-public (print-dashboard-event (event-type (string-utf8 24)) (dashboard-id uint))
    (ok (print { event-type: event-type, dashboard-id: dashboard-id, sender: tx-sender }))
)

;; Admin Functions
(define-public (set-contract-pause (paused bool))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-OWNER)
        (ok (var-set contract-paused paused))
    )
)

;; Helper Functions
(define-private (is-contract-paused)
    (var-get contract-paused)
)

(define-private (is-valid-dashboard (dashboard-id uint))
    (match (get-dashboard dashboard-id)
        dashboard (not (get deleted dashboard))
        false
    )
)

;; Create new dashboard
(define-public (create-dashboard (title (string-utf8 64)) (config (string-utf8 4096)))
    (begin
        (asserts! (not (is-contract-paused)) ERR-NOT-AUTHORIZED)
        (let
            (
                (dashboard-id (var-get next-dashboard-id))
                (block-height (get-block-height))
            )
            (map-set dashboards
                { dashboard-id: dashboard-id }
                {
                    owner: tx-sender,
                    title: title,
                    config: config,
                    created-at: block-height,
                    updated-at: block-height,
                    version: u1,
                    template: false,
                    price: u0,
                    deleted: false
                }
            )
            (map-set dashboard-versions
                { dashboard-id: dashboard-id, version: u1 }
                { config: config, updated-at: block-height }
            )
            (var-set next-dashboard-id (+ dashboard-id u1))
            (try! (print-dashboard-event "dashboard_created" dashboard-id))
            (ok dashboard-id)
        )
    )
)

;; Delete dashboard
(define-public (delete-dashboard (dashboard-id uint))
    (begin
        (asserts! (not (is-contract-paused)) ERR-NOT-AUTHORIZED)
        (let ((dashboard (unwrap! (get-dashboard dashboard-id) ERR-INVALID-DASHBOARD)))
            (asserts! (is-eq tx-sender (get owner dashboard)) ERR-NOT-OWNER)
            (map-set dashboards
                { dashboard-id: dashboard-id }
                (merge dashboard { deleted: true })
            )
            (try! (print-dashboard-event "dashboard_deleted" dashboard-id))
            (ok true)
        )
    )
)

;; Rollback version
(define-public (rollback-version (dashboard-id uint) (target-version uint))
    (begin
        (asserts! (not (is-contract-paused)) ERR-NOT-AUTHORIZED)
        (let (
            (dashboard (unwrap! (get-dashboard dashboard-id) ERR-INVALID-DASHBOARD))
            (version-data (unwrap! (get-dashboard-version dashboard-id target-version) ERR-INVALID-VERSION))
        )
            (asserts! (is-authorized-to-edit dashboard-id) ERR-NOT-AUTHORIZED)
            (asserts! (< target-version (get version dashboard)) ERR-INVALID-VERSION)
            
            (map-set dashboards
                { dashboard-id: dashboard-id }
                (merge dashboard {
                    config: (get config version-data),
                    updated-at: (get-block-height),
                    version: (+ (get version dashboard) u1)
                })
            )
            (try! (print-dashboard-event "version_rollback" dashboard-id))
            (ok true)
        )
    )
)

[... remaining original functions ...]
