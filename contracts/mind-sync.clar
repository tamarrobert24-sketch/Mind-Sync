(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-sync-failed (err u105))
(define-constant err-insufficient-energy (err u106))

(define-data-var min-sync-energy uint u10)
(define-data-var max-connections uint u100)
(define-data-var sync-cost uint u5)

(define-map minds principal {
  energy: uint,
  last-sync: uint,
  connection-count: uint,
  status: (string-ascii 20),
  created-at: uint
})

(define-map connections {sender: principal, receiver: principal} {
  strength: uint,
  created-at: uint,
  last-interaction: uint,
  sync-count: uint,
  is-active: bool
})

(define-map thoughts uint {
  creator: principal,
  content-hash: (buff 32),
  energy-cost: uint,
  timestamp: uint,
  connection-id: (optional {sender: principal, receiver: principal}),
  is-synchronized: bool
})

(define-map sync-sessions uint {
  participants: (list 10 principal),
  session-hash: (buff 32),
  start-block: uint,
  end-block: (optional uint),
  energy-pool: uint,
  thought-count: uint,
  is-active: bool
})

(define-data-var next-thought-id uint u1)
(define-data-var next-session-id uint u1)
(define-data-var total-syncs uint u0)

(define-read-only (get-mind (user principal))
  (map-get? minds user))

(define-read-only (get-connection (sender principal) (receiver principal))
  (map-get? connections {sender: sender, receiver: receiver}))

(define-read-only (get-thought (thought-id uint))
  (map-get? thoughts thought-id))

(define-read-only (get-sync-session (session-id uint))
  (map-get? sync-sessions session-id))

(define-read-only (get-current-thought-id)
  (var-get next-thought-id))

(define-read-only (get-current-session-id)
  (var-get next-session-id))

(define-read-only (get-total-syncs)
  (var-get total-syncs))

(define-read-only (get-sync-cost)
  (var-get sync-cost))

(define-read-only (can-sync (user principal))
  (match (map-get? minds user)
    mind (>= (get energy mind) (var-get min-sync-energy))
    false))

(define-public (initialize-mind (initial-energy uint))
  (let ((current-block stacks-block-height))
    (asserts! (is-none (map-get? minds tx-sender)) err-already-exists)
    (asserts! (> initial-energy u0) err-invalid-input)
    (map-set minds tx-sender {
      energy: initial-energy,
      last-sync: current-block,
      connection-count: u0,
      status: "active",
      created-at: current-block
    })
    (ok true)))

(define-public (create-connection (receiver principal) (initial-strength uint))
  (let ((current-block stacks-block-height)
        (sender-mind (unwrap! (map-get? minds tx-sender) err-not-found))
        (receiver-mind (unwrap! (map-get? minds receiver) err-not-found)))
    (asserts! (not (is-eq tx-sender receiver)) err-invalid-input)
    (asserts! (is-none (map-get? connections {sender: tx-sender, receiver: receiver})) err-already-exists)
    (asserts! (< (get connection-count sender-mind) (var-get max-connections)) err-invalid-input)
    (asserts! (>= initial-strength u1) err-invalid-input)
    (asserts! (<= initial-strength u100) err-invalid-input)
    
    (map-set connections {sender: tx-sender, receiver: receiver} {
      strength: initial-strength,
      created-at: current-block,
      last-interaction: current-block,
      sync-count: u0,
      is-active: true
    })
    
    (map-set minds tx-sender (merge sender-mind {
      connection-count: (+ (get connection-count sender-mind) u1)
    }))
    
    (ok true)))

(define-public (create-thought (content-hash (buff 32)) (energy-cost uint) (connection-receiver (optional principal)))
  (let ((current-block stacks-block-height)
        (thought-id (var-get next-thought-id))
        (sender-mind (unwrap! (map-get? minds tx-sender) err-not-found)))
    
    (asserts! (>= (get energy sender-mind) energy-cost) err-insufficient-energy)
    (asserts! (> energy-cost u0) err-invalid-input)
    
    (let ((connection-id (match connection-receiver
          receiver (some {sender: tx-sender, receiver: receiver})
          none)))
      
      (map-set thoughts thought-id {
        creator: tx-sender,
        content-hash: content-hash,
        energy-cost: energy-cost,
        timestamp: current-block,
        connection-id: connection-id,
        is-synchronized: false
      })
      
      (map-set minds tx-sender (merge sender-mind {
        energy: (- (get energy sender-mind) energy-cost),
        last-sync: current-block
      }))
      
      (var-set next-thought-id (+ thought-id u1))
      (ok thought-id))))

(define-public (synchronize-thought (thought-id uint) (target-mind principal))
  (let ((thought (unwrap! (map-get? thoughts thought-id) err-not-found))
        (source-mind (unwrap! (map-get? minds (get creator thought)) err-not-found))
        (target-mind-data (unwrap! (map-get? minds target-mind) err-not-found))
        (connection (map-get? connections {sender: (get creator thought), receiver: target-mind}))
        (sync-cost-val (var-get sync-cost))
        (current-block stacks-block-height))
    
    (asserts! (is-eq tx-sender (get creator thought)) err-unauthorized)
    (asserts! (not (get is-synchronized thought)) err-already-exists)
    (asserts! (>= (get energy source-mind) sync-cost-val) err-insufficient-energy)
    (asserts! (>= (get energy target-mind-data) sync-cost-val) err-insufficient-energy)
    
    (map-set thoughts thought-id (merge thought {
      is-synchronized: true
    }))
    
    (map-set minds (get creator thought) (merge source-mind {
      energy: (- (get energy source-mind) sync-cost-val),
      last-sync: current-block
    }))
    
    (map-set minds target-mind (merge target-mind-data {
      energy: (- (get energy target-mind-data) sync-cost-val),
      last-sync: current-block
    }))
    
    (match connection
      conn (map-set connections {sender: (get creator thought), receiver: target-mind}
             (merge conn {
               last-interaction: current-block,
               sync-count: (+ (get sync-count conn) u1)
             }))
      true)
    
    (var-set total-syncs (+ (var-get total-syncs) u1))
    (ok true)))

(define-public (start-sync-session (participants (list 10 principal)) (session-hash (buff 32)))
  (let ((session-id (var-get next-session-id))
        (current-block stacks-block-height))
    
    (asserts! (> (len participants) u1) err-invalid-input)
    (asserts! (<= (len participants) u10) err-invalid-input)
    
    (map-set sync-sessions session-id {
      participants: participants,
      session-hash: session-hash,
      start-block: current-block,
      end-block: none,
      energy-pool: u0,
      thought-count: u0,
      is-active: true
    })
    
    (var-set next-session-id (+ session-id u1))
    (ok session-id)))

(define-public (contribute-to-session (session-id uint) (energy-amount uint))
  (let ((session (unwrap! (map-get? sync-sessions session-id) err-not-found))
        (contributor-mind (unwrap! (map-get? minds tx-sender) err-not-found)))
    
    (asserts! (get is-active session) err-sync-failed)
    (asserts! (>= (get energy contributor-mind) energy-amount) err-insufficient-energy)
    (asserts! (> energy-amount u0) err-invalid-input)
    
    (map-set sync-sessions session-id (merge session {
      energy-pool: (+ (get energy-pool session) energy-amount)
    }))
    
    (map-set minds tx-sender (merge contributor-mind {
      energy: (- (get energy contributor-mind) energy-amount)
    }))
    
    (ok true)))

(define-public (end-sync-session (session-id uint))
  (let ((session (unwrap! (map-get? sync-sessions session-id) err-not-found))
        (current-block stacks-block-height))
    
    (asserts! (get is-active session) err-sync-failed)
    
    (map-set sync-sessions session-id (merge session {
      end-block: (some current-block),
      is-active: false
    }))
    
    (ok true)))

(define-public (recharge-energy (amount uint))
  (let ((mind (unwrap! (map-get? minds tx-sender) err-not-found))
        (current-block stacks-block-height))
    
    (asserts! (> amount u0) err-invalid-input)
    (asserts! (<= amount u1000) err-invalid-input)
    
    (map-set minds tx-sender (merge mind {
      energy: (+ (get energy mind) amount),
      last-sync: current-block
    }))
    
    (ok true)))

(define-public (update-connection-strength (receiver principal) (new-strength uint))
  (let ((connection (unwrap! (map-get? connections {sender: tx-sender, receiver: receiver}) err-not-found))
        (current-block stacks-block-height))
    
    (asserts! (get is-active connection) err-sync-failed)
    (asserts! (>= new-strength u1) err-invalid-input)
    (asserts! (<= new-strength u100) err-invalid-input)
    
    (map-set connections {sender: tx-sender, receiver: receiver} (merge connection {
      strength: new-strength,
      last-interaction: current-block
    }))
    
    (ok true)))

(define-public (deactivate-connection (receiver principal))
  (let ((connection (unwrap! (map-get? connections {sender: tx-sender, receiver: receiver}) err-not-found))
        (sender-mind (unwrap! (map-get? minds tx-sender) err-not-found)))
    
    (map-set connections {sender: tx-sender, receiver: receiver} (merge connection {
      is-active: false
    }))
    
    (map-set minds tx-sender (merge sender-mind {
      connection-count: (- (get connection-count sender-mind) u1)
    }))
    
    (ok true)))

(define-public (set-mind-status (new-status (string-ascii 20)))
  (let ((mind (unwrap! (map-get? minds tx-sender) err-not-found)))
    
    (map-set minds tx-sender (merge mind {
      status: new-status
    }))
    
    (ok true)))

(define-public (set-sync-parameters (new-min-energy uint) (new-max-connections uint) (new-sync-cost uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-min-energy u0) err-invalid-input)
    (asserts! (> new-max-connections u0) err-invalid-input)
    (asserts! (> new-sync-cost u0) err-invalid-input)
    
    (var-set min-sync-energy new-min-energy)
    (var-set max-connections new-max-connections)
    (var-set sync-cost new-sync-cost)
    
    (ok true)))
