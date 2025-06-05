;; inventory-tracking.clar
;; Contract to track retail inventory

(define-data-var admin principal tx-sender)

;; Define product struct
(define-map products uint
  {
    name: (string-utf8 100),
    sku: (string-utf8 50),
    category: (string-utf8 50),
    created-by: principal
  }
)

;; Map to track inventory levels
(define-map inventory (tuple (retailer principal) (product-id uint))
  {
    quantity: uint,
    last-updated: uint
  }
)

;; Counter for product IDs
(define-data-var next-product-id uint u1)

;; Function to register a new product
(define-public (register-product (name (string-utf8 100)) (sku (string-utf8 50)) (category (string-utf8 50)))
  (let ((product-id (var-get next-product-id)))
    (map-set products product-id
      {
        name: name,
        sku: sku,
        category: category,
        created-by: tx-sender
      }
    )
    (var-set next-product-id (+ product-id u1))
    (ok product-id)
  )
)

;; Function to update inventory
(define-public (update-inventory (product-id uint) (quantity uint))
  (begin
    (asserts! (is-some (map-get? products product-id)) (err u101))
    (map-set inventory {retailer: tx-sender, product-id: product-id}
      {
        quantity: quantity,
        last-updated: block-height
      }
    )
    (ok true)
  )
)

;; Function to get inventory level
(define-read-only (get-inventory (retailer principal) (product-id uint))
  (default-to
    {quantity: u0, last-updated: u0}
    (map-get? inventory {retailer: retailer, product-id: product-id})
  )
)

;; Function to get product details
(define-read-only (get-product (product-id uint))
  (map-get? products product-id)
)

;; Function to transfer product ownership
(define-public (transfer-product (product-id uint) (new-owner principal))
  (let ((product (map-get? products product-id)))
    (asserts! (is-some product) (err u101))
    (asserts! (is-eq tx-sender (get created-by (unwrap-panic product))) (err u102))
    (map-set products product-id
      (merge (unwrap-panic product) {created-by: new-owner})
    )
    (ok true)
  )
)
