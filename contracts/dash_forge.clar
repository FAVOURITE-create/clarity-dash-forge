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

;; [Previous code remains unchanged until rollback-related functions]

;; Helper function for version validation
(define-private (is-valid-version (dashboard-id uint) (target-version uint) (current-version uint))
    (and
        (> current-version target-version)
        (match (get-dashboard-version dashboard-id target-version)
            version-data true
            false
        )
    )
)

;; Rollback version with improved validation and version tracking
(define-public (rollback-version (dashboard-id uint) (target-version uint))
    (begin
        (asserts! (not (is-contract-paused)) ERR-NOT-AUTHORIZED)
        (let (
            (dashboard (unwrap! (get-dashboard dashboard-id) ERR-INVALID-DASHBOARD))
            (version-data (unwrap! (get-dashboard-version dashboard-id target-version) ERR-INVALID-VERSION))
        )
            (asserts! (not (get deleted dashboard)) ERR-DASHBOARD-DELETED)
            (asserts! (is-authorized-to-edit dashboard-id) ERR-NOT-AUTHORIZED)
            (asserts! (is-valid-version dashboard-id target-version (get version dashboard)) ERR-INVALID-VERSION)
            
            ;; Store the rolled back version as a new version
            (let ((new-version (+ (get version dashboard) u1)))
                (map-set dashboard-versions
                    { dashboard-id: dashboard-id, version: new-version }
                    { config: (get config version-data), updated-at: (get-block-height) }
                )
                
                (map-set dashboards
                    { dashboard-id: dashboard-id }
                    (merge dashboard {
                        config: (get config version-data),
                        updated-at: (get-block-height),
                        version: new-version
                    })
                )
                (try! (print-dashboard-event "version_rollback" dashboard-id))
                (ok true)
            )
        )
    )
)

[... remaining original functions ...]
