;; DashForge Contract
(define-map dashboards
    { dashboard-id: uint }
    {
        owner: principal,
        title: (string-utf8 64),
        config: (string-utf8 4096),
        created-at: uint,
        updated-at: uint,
        version: uint
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

(define-data-var next-dashboard-id uint u1)

;; Error codes
(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-DASHBOARD (err u102))

;; Create new dashboard
(define-public (create-dashboard (title (string-utf8 64)) (config (string-utf8 4096)))
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
                version: u1
            }
        )
        (map-set dashboard-versions
            { dashboard-id: dashboard-id, version: u1 }
            { config: config, updated-at: block-height }
        )
        (var-set next-dashboard-id (+ dashboard-id u1))
        (ok dashboard-id)
    )
)

;; Update dashboard
(define-public (update-dashboard (dashboard-id uint) (title (string-utf8 64)) (config (string-utf8 4096)))
    (let (
        (dashboard (unwrap! (get-dashboard dashboard-id) ERR-INVALID-DASHBOARD))
        (current-version (get version dashboard))
        (block-height (get-block-height))
    )
        (asserts! (is-authorized-to-edit dashboard-id) ERR-NOT-AUTHORIZED)
        (map-set dashboards
            { dashboard-id: dashboard-id }
            (merge dashboard {
                title: title,
                config: config,
                updated-at: block-height,
                version: (+ current-version u1)
            })
        )
        (map-set dashboard-versions
            { dashboard-id: dashboard-id, version: (+ current-version u1) }
            { config: config, updated-at: block-height }
        )
        (ok true)
    )
)

;; Grant access
(define-public (grant-access (dashboard-id uint) (user principal) (can-view bool) (can-edit bool))
    (let (
        (dashboard (unwrap! (get-dashboard dashboard-id) ERR-INVALID-DASHBOARD))
    )
        (asserts! (is-eq tx-sender (get owner dashboard)) ERR-NOT-OWNER)
        (map-set dashboard-access
            { dashboard-id: dashboard-id, user: user }
            { can-view: can-view, can-edit: can-edit }
        )
        (ok true)
    )
)

;; Read functions
(define-read-only (get-dashboard (dashboard-id uint))
    (map-get? dashboards { dashboard-id: dashboard-id })
)

(define-read-only (get-dashboard-version (dashboard-id uint) (version uint))
    (map-get? dashboard-versions { dashboard-id: dashboard-id, version: version })
)

;; Helper functions
(define-private (is-authorized-to-edit (dashboard-id uint))
    (let (
        (dashboard (unwrap! (get-dashboard dashboard-id) false))
        (access-rights (map-get? dashboard-access { dashboard-id: dashboard-id, user: tx-sender }))
    )
        (or
            (is-eq tx-sender (get owner dashboard))
            (and
                (is-some access-rights)
                (get can-edit (unwrap! access-rights false))
            )
        )
    )
)