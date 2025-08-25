;; QuestBoard Smart Contract - Commit 3: NFT Badge System and Player Statistics
;; A community board for game developers to post quests and reward players with NFT badges

;; Define SIP-009 NFT trait locally
(define-trait sip009-nft-trait
  (
    ;; Last token ID, limited to uint range
    (get-last-token-id () (response uint uint))

    ;; URI for metadata associated with the token  
    (get-token-uri (uint) (response (optional (string-ascii 256)) uint))

    ;; Owner of a given token identifier
    (get-owner (uint) (response (optional principal) uint))

    ;; Transfer from the sender to a new principal
    (transfer (uint principal principal) (response bool uint))
  )
)

;; token definitions
(define-non-fungible-token quest-badge uint)

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-QUEST-NOT-FOUND (err u101))
(define-constant ERR-QUEST-INACTIVE (err u102))
(define-constant ERR-QUEST-EXPIRED (err u103))
(define-constant ERR-ALREADY-COMPLETED (err u104))
(define-constant ERR-INVALID-INPUT (err u105))

;; data vars
(define-data-var quest-counter uint u0)
(define-data-var badge-counter uint u0)
(define-data-var contract-uri (string-ascii 256) "https://questboard.stacks.co/metadata/")

;; data maps
(define-map quests 
  uint 
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    reward-amount: uint,
    max-participants: uint,
    current-participants: uint,
    expiry-block: uint,
    is-active: bool,
    created-at: uint
  }
)

(define-map quest-participants 
  {quest-id: uint, player: principal}
  {completed: bool, completion-block: uint}
)

(define-map player-badges
  principal
  {total-badges: uint, last-badge-id: uint}
)

;; public functions
(define-public (create-quest 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (reward-amount uint)
  (max-participants uint)
  (duration-blocks uint)
)
  (let 
    (
      (quest-id (+ (var-get quest-counter) u1))
      (expiry-block (+ burn-block-height duration-blocks))
    )
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)
    (asserts! (> max-participants u0) ERR-INVALID-INPUT)
    (asserts! (> duration-blocks u0) ERR-INVALID-INPUT)
    
    (map-set quests quest-id {
      creator: tx-sender,
      title: title,
      description: description,
      reward-amount: reward-amount,
      max-participants: max-participants,
      current-participants: u0,
      expiry-block: expiry-block,
      is-active: true,
      created-at: burn-block-height
    })
    
    (var-set quest-counter quest-id)
    (ok quest-id)
  )
)

(define-public (join-quest (quest-id uint))
  (let 
    (
      (quest (unwrap! (map-get? quests quest-id) ERR-QUEST-NOT-FOUND))
      (participant-key {quest-id: quest-id, player: tx-sender})
    )
    (asserts! (get is-active quest) ERR-QUEST-INACTIVE)
    (asserts! (< burn-block-height (get expiry-block quest)) ERR-QUEST-EXPIRED)
    (asserts! (< (get current-participants quest) (get max-participants quest)) ERR-QUEST-INACTIVE)
    (asserts! (is-none (map-get? quest-participants participant-key)) ERR-ALREADY-COMPLETED)
    
    (map-set quest-participants participant-key {
      completed: false,
      completion-block: u0
    })
    
    (map-set quests quest-id (merge quest {
      current-participants: (+ (get current-participants quest) u1)
    }))
    
    (ok true)
  )
)

(define-public (complete-quest (quest-id uint) (player principal))
  (let 
    (
      (quest (unwrap! (map-get? quests quest-id) ERR-QUEST-NOT-FOUND))
      (participant-key {quest-id: quest-id, player: player})
      (participant (unwrap! (map-get? quest-participants participant-key) ERR-QUEST-NOT-FOUND))
      (badge-id (+ (var-get badge-counter) u1))
      (player-stats (default-to {total-badges: u0, last-badge-id: u0} (map-get? player-badges player)))
    )
    (asserts! (or (is-eq tx-sender (get creator quest)) (is-eq tx-sender CONTRACT-OWNER)) ERR-UNAUTHORIZED)
    (asserts! (get is-active quest) ERR-QUEST-INACTIVE)
    (asserts! (< burn-block-height (get expiry-block quest)) ERR-QUEST-EXPIRED)
    (asserts! (not (get completed participant)) ERR-ALREADY-COMPLETED)
    
    ;; Mark quest as completed for player
    (map-set quest-participants participant-key {
      completed: true,
      completion-block: burn-block-height
    })
    
    ;; Mint NFT badge to player
    (try! (nft-mint? quest-badge badge-id player))
    
    ;; Update player badge count  
    (map-set player-badges player {
      total-badges: (+ (get total-badges player-stats) u1),
      last-badge-id: badge-id
    })
    
    ;; Update badge counter
    (var-set badge-counter badge-id)
    
    (ok badge-id)
  )
)

;; read-only functions
(define-read-only (get-quest (quest-id uint))
  (map-get? quests quest-id)
)

(define-read-only (get-quest-counter)
  (var-get quest-counter)
)

(define-read-only (get-quest-participant (quest-id uint) (player principal))
  (map-get? quest-participants {quest-id: quest-id, player: player})
)

(define-read-only (is-quest-active (quest-id uint))
  (match (map-get? quests quest-id)
    quest (and (get is-active quest) (< burn-block-height (get expiry-block quest)))
    false
  )
)

(define-read-only (get-player-badges (player principal))
  (default-to {total-badges: u0, last-badge-id: u0} (map-get? player-badges player))
)

(define-read-only (get-badge-counter)
  (var-get badge-counter)
)
