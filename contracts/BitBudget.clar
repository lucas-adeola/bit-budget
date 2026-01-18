;; Title: BitBudget - Decentralized Personal Finance Manager
;;
;; Summary: A Bitcoin-native financial planning platform built on Stacks that empowers users
;; to take control of their spending through blockchain-verified budgets, transparent expense
;; tracking, and incentivized savings goals with cryptocurrency rewards.
;;
;; Description: BitBudget revolutionizes personal finance management by bringing budgeting and
;; savings to the Bitcoin ecosystem. Users can create monthly spending plans, track expenses
;; across multiple categories, and set long-term financial goals-all secured by blockchain
;; immutability. The platform features a unique reward mechanism that incentivizes financial
;; discipline: users who meet their savings goals receive STX token bonuses from a community
;; reward pool. With transparent on-chain records, achievement tracking, and streak-based
;; gamification, BitBudget transforms mundane money management into an engaging, trustless
;; experience that aligns with Bitcoin's principles of financial sovereignty and transparency.

;; ERROR CODES

(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-INVALID-INPUT (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-BUDGET-EXCEEDED (err u104))
(define-constant ERR-GOAL-NOT-MET (err u105))
(define-constant ERR-ALREADY-EXISTS (err u106))
(define-constant ERR-GOAL-EXPIRED (err u107))

;; CONTRACT STATE

(define-data-var contract-owner principal tx-sender)
(define-data-var budget-counter uint u0)
(define-data-var expense-counter uint u0)
(define-data-var goal-counter uint u0)
(define-data-var reward-pool uint u0)

;; CONSTANTS

(define-constant BLOCKS-PER-MONTH u4320) ;; Approximately 30 days
(define-constant MIN-BUDGET-AMOUNT u1000)
(define-constant MIN-GOAL-AMOUNT u5000)
(define-constant ACHIEVEMENT-BONUS u500)

;; Expense Categories
(define-constant CATEGORY-FOOD u1)
(define-constant CATEGORY-TRANSPORT u2)
(define-constant CATEGORY-ENTERTAINMENT u3)
(define-constant CATEGORY-UTILITIES u4)
(define-constant CATEGORY-HEALTHCARE u5)
(define-constant CATEGORY-SHOPPING u6)
(define-constant CATEGORY-OTHER u7)

;; DATA MAPS

;; Monthly Budget Storage
(define-map budgets
  { user: principal, month: uint, year: uint }
  {
    total-budget: uint,
    total-spent: uint,
    categories: {
      food: uint,
      transport: uint,
      entertainment: uint,
      utilities: uint,
      healthcare: uint,
      shopping: uint,
      other: uint
    },
    category-spent: {
      food: uint,
      transport: uint,
      entertainment: uint,
      utilities: uint,
      healthcare: uint,
      shopping: uint,
      other: uint
    },
    created-at: uint,
    is-active: bool
  }
)

;; Individual Expense Records
(define-map expenses
  uint
  {
    user: principal,
    amount: uint,
    category: uint,
    description: (string-ascii 100),
    timestamp: uint,
    month: uint,
    year: uint
  }
)

;; Savings Goal Tracker
(define-map savings-goals
  uint
  {
    user: principal,
    title: (string-ascii 50),
    target-amount: uint,
    current-amount: uint,
    deadline: uint,
    created-at: uint,
    is-completed: bool,
    reward-claimed: bool
  }
)

;; User Token Balances
(define-map user-balances principal uint)

;; User Achievement Statistics
(define-map user-stats
  principal
  {
    budgets-met: uint,
    goals-achieved: uint,
    total-saved: uint,
    streak-months: uint,
    last-activity: uint
  }
)

;; PRIVATE HELPER FUNCTIONS

(define-private (is-valid-category (category uint))
  (and (>= category CATEGORY-FOOD) (<= category CATEGORY-OTHER))
)

(define-private (is-valid-description (desc (string-ascii 100)))
  (and (> (len desc) u0) (<= (len desc) u100))
)

(define-private (is-valid-title (title (string-ascii 50)))
  (and (> (len title) u0) (<= (len title) u50))
)

(define-private (get-current-month)
  (mod (/ stacks-block-height BLOCKS-PER-MONTH) u12)
)

(define-private (get-current-year)
  (+ u2024 (/ stacks-block-height (* BLOCKS-PER-MONTH u12)))
)

(define-private (update-category-spent 
  (current-spent { food: uint, transport: uint, entertainment: uint, utilities: uint, healthcare: uint, shopping: uint, other: uint }) 
  (category uint) 
  (amount uint))
  (if (is-eq category CATEGORY-FOOD)
    (merge current-spent { food: (+ (get food current-spent) amount) })
    (if (is-eq category CATEGORY-TRANSPORT)
      (merge current-spent { transport: (+ (get transport current-spent) amount) })
      (if (is-eq category CATEGORY-ENTERTAINMENT)
        (merge current-spent { entertainment: (+ (get entertainment current-spent) amount) })
        (if (is-eq category CATEGORY-UTILITIES)
          (merge current-spent { utilities: (+ (get utilities current-spent) amount) })
          (if (is-eq category CATEGORY-HEALTHCARE)
            (merge current-spent { healthcare: (+ (get healthcare current-spent) amount) })
            (if (is-eq category CATEGORY-SHOPPING)
              (merge current-spent { shopping: (+ (get shopping current-spent) amount) })
              (merge current-spent { other: (+ (get other current-spent) amount) })))))))
)

(define-private (update-user-activity (user principal))
  (let (
    (current-stats (default-to { budgets-met: u0, goals-achieved: u0, total-saved: u0, 
                                 streak-months: u0, last-activity: u0 } 
                               (map-get? user-stats user)))
  )
    (map-set user-stats user (merge current-stats { last-activity: stacks-block-height }))
  )
)

(define-private (update-goal-achievement (user principal) (amount uint))
  (let (
    (current-stats (default-to { budgets-met: u0, goals-achieved: u0, total-saved: u0, 
                                 streak-months: u0, last-activity: u0 } 
                               (map-get? user-stats user)))
  )
    (map-set user-stats user (merge current-stats {
      goals-achieved: (+ (get goals-achieved current-stats) u1),
      total-saved: (+ (get total-saved current-stats) amount),
      last-activity: stacks-block-height
    }))
  )
)

;; PUBLIC FUNCTIONS - BALANCE MANAGEMENT

(define-public (deposit (amount uint))
  (begin
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set user-balances tx-sender (+ (get-balance tx-sender) amount))
    (ok true)
  )
)

(define-public (withdraw (amount uint))
  (let (
    (user-balance (get-balance tx-sender))
  )
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    (asserts! (>= user-balance amount) ERR-INSUFFICIENT-FUNDS)
    (map-set user-balances tx-sender (- user-balance amount))
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (ok true)
  )
)

;; PUBLIC FUNCTIONS - BUDGET MANAGEMENT

(define-public (create-budget
    (total-budget uint)
    (food uint) (transport uint) (entertainment uint)
    (utilities uint) (healthcare uint) (shopping uint) (other uint))
  (let (
    (current-month (get-current-month))
    (current-year (get-current-year))
    (category-sum (+ (+ (+ food transport) (+ entertainment utilities))
                     (+ (+ healthcare shopping) other)))
  )
    (asserts! (>= total-budget MIN-BUDGET-AMOUNT) ERR-INVALID-INPUT)
    (asserts! (is-eq total-budget category-sum) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? budgets { user: tx-sender, month: current-month, year: current-year })) ERR-ALREADY-EXISTS)
    
    (map-set budgets { user: tx-sender, month: current-month, year: current-year } {
      total-budget: total-budget,
      total-spent: u0,
      categories: {
        food: food,
        transport: transport,
        entertainment: entertainment,
        utilities: utilities,
        healthcare: healthcare,
        shopping: shopping,
        other: other
      },
      category-spent: {
        food: u0,
        transport: u0,
        entertainment: u0,
        utilities: u0,
        healthcare: u0,
        shopping: u0,
        other: u0
      },
      created-at: stacks-block-height,
      is-active: true
    })
    
    (var-set budget-counter (+ (var-get budget-counter) u1))
    (ok true)
  )
)

(define-public (add-expense (amount uint) (category uint) (description (string-ascii 100)))
  (let (
    (expense-id (+ (var-get expense-counter) u1))
    (current-month (get-current-month))
    (current-year (get-current-year))
    (budget-key { user: tx-sender, month: current-month, year: current-year })
    (budget (map-get? budgets budget-key))
  )
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    (asserts! (is-valid-category category) ERR-INVALID-INPUT)
    (asserts! (is-valid-description description) ERR-INVALID-INPUT)
    
    (map-set expenses expense-id {
      user: tx-sender,
      amount: amount,
      category: category,
      description: description,
      timestamp: stacks-block-height,
      month: current-month,
      year: current-year
    })
    
    (match budget
      budget-data (let (
        (new-total-spent (+ (get total-spent budget-data) amount))
        (updated-category-spent (update-category-spent (get category-spent budget-data) category amount))
      )
        (asserts! (<= new-total-spent (get total-budget budget-data)) ERR-BUDGET-EXCEEDED)
        (map-set budgets budget-key (merge budget-data {
          total-spent: new-total-spent,
          category-spent: updated-category-spent
        }))
      )
      true
    )
    
    (update-user-activity tx-sender)
    (var-set expense-counter expense-id)
    (ok expense-id)
  )
)

;; PUBLIC FUNCTIONS - SAVINGS GOALS

(define-public (create-goal (title (string-ascii 50)) (target-amount uint) (deadline-months uint))
  (let (
    (goal-id (+ (var-get goal-counter) u1))
    (deadline (+ stacks-block-height (* deadline-months BLOCKS-PER-MONTH)))
  )
    (asserts! (is-valid-title title) ERR-INVALID-INPUT)
    (asserts! (>= target-amount MIN-GOAL-AMOUNT) ERR-INVALID-INPUT)
    (asserts! (and (> deadline-months u0) (<= deadline-months u60)) ERR-INVALID-INPUT)
    
    (map-set savings-goals goal-id {
      user: tx-sender,
      title: title,
      target-amount: target-amount,
      current-amount: u0,
      deadline: deadline,
      created-at: stacks-block-height,
      is-completed: false,
      reward-claimed: false
    })
    
    (var-set goal-counter goal-id)
    (ok goal-id)
  )
)

(define-public (contribute-to-goal (goal-id uint) (amount uint))
  (let (
    (goal (unwrap! (map-get? savings-goals goal-id) ERR-NOT-FOUND))
    (user-balance (get-balance tx-sender))
  )
    (asserts! (is-eq tx-sender (get user goal)) ERR-UNAUTHORIZED)
    (asserts! (not (get is-completed goal)) ERR-ALREADY-EXISTS)
    (asserts! (<= stacks-block-height (get deadline goal)) ERR-GOAL-EXPIRED)
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    (asserts! (>= user-balance amount) ERR-INSUFFICIENT-FUNDS)
    
    (let (
      (new-current-amount (+ (get current-amount goal) amount))
      (is-now-completed (>= new-current-amount (get target-amount goal)))
    )
      (map-set user-balances tx-sender (- user-balance amount))
      
      (map-set savings-goals goal-id (merge goal {
        current-amount: new-current-amount,
        is-completed: is-now-completed
      }))
      
      (if is-now-completed
        (update-goal-achievement tx-sender (get target-amount goal))
        true
      )
      
      (ok is-now-completed)
    )
  )
)

(define-public (claim-goal-reward (goal-id uint))
  (let (
    (goal (unwrap! (map-get? savings-goals goal-id) ERR-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender (get user goal)) ERR-UNAUTHORIZED)
    (asserts! (get is-completed goal) ERR-GOAL-NOT-MET)
    (asserts! (not (get reward-claimed goal)) ERR-ALREADY-EXISTS)
    (asserts! (>= (var-get reward-pool) ACHIEVEMENT-BONUS) ERR-INSUFFICIENT-FUNDS)
    
    (map-set user-balances tx-sender (+ (get-balance tx-sender) ACHIEVEMENT-BONUS))
    (var-set reward-pool (- (var-get reward-pool) ACHIEVEMENT-BONUS))
    (map-set savings-goals goal-id (merge goal { reward-claimed: true }))
    
    (ok ACHIEVEMENT-BONUS)
  )
)

;; PUBLIC FUNCTIONS - ADMIN

(define-public (fund-reward-pool (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-UNAUTHORIZED)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set reward-pool (+ (var-get reward-pool) amount))
    (ok true)
  )
)

;; READ-ONLY FUNCTIONS

(define-read-only (get-balance (user principal))
  (default-to u0 (map-get? user-balances user))
)

(define-read-only (get-budget (user principal) (month uint) (year uint))
  (map-get? budgets { user: user, month: month, year: year })
)

(define-read-only (get-expense (expense-id uint))
  (map-get? expenses expense-id)
)

(define-read-only (get-savings-goal (goal-id uint))
  (map-get? savings-goals goal-id)
)

(define-read-only (get-user-stats (user principal))
  (map-get? user-stats user)
)

(define-read-only (get-current-budget (user principal))
  (map-get? budgets { user: user, month: (get-current-month), year: (get-current-year) })
)

(define-read-only (calculate-budget-remaining (user principal))
  (match (get-current-budget user)
    budget (- (get total-budget budget) (get total-spent budget))
    u0)
)

(define-read-only (get-expense-count)
  (var-get expense-counter)
)

(define-read-only (get-goal-count)
  (var-get goal-counter)
)

(define-read-only (get-reward-pool-balance)
  (var-get reward-pool)
)