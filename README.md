# BitBudget – Decentralized Personal Finance Manager

**BitBudget** is a Bitcoin-native personal finance management protocol built on the [Stacks blockchain](https://stacks.co/).
It empowers users to take full control of their money by enabling **on-chain budgeting, transparent expense tracking, and goal-based savings** with **STX-backed rewards** for financial discipline.

The protocol reimagines traditional finance management by making it **trustless, transparent, and gamified**, all while aligning with Bitcoin’s principles of sovereignty and accountability.

---

## ✨ Features

* **Blockchain-verified Budgets**
  Users can define monthly spending plans with granular category allocations.
* **Immutable Expense Tracking**
  Every expense is permanently recorded on-chain for full transparency.
* **Savings Goals with Incentives**
  Create and contribute to savings targets with a deadline; meeting goals earns STX rewards.
* **Gamification & Rewards**
  Achievements, streaks, and bonus incentives encourage consistent financial discipline.
* **Reward Pool Mechanism**
  Administrators can fund a global reward pool to distribute STX bonuses to users who complete goals.

---

## ⚙️ System Overview

BitBudget is composed of **three core modules**:

1. **Budget Management**

   * Create monthly budgets with category allocations (Food, Transport, Entertainment, etc.).
   * Track expenses and enforce budget limits.

2. **Savings Goals**

   * Define financial goals with target amounts and deadlines.
   * Contribute gradually from deposits.
   * Claim rewards upon successful completion.

3. **Reward & Achievement Tracking**

   * STX bonus distribution from the community reward pool.
   * On-chain user statistics: goals achieved, total saved, streaks maintained.

---

## 📐 Contract Architecture

The protocol is implemented in **Clarity** with modular storage maps and helper functions for safe, predictable state transitions.

### State Variables

* **Counters:** Budget, Expense, and Goal counters for unique IDs.
* **Reward Pool:** STX pool used for incentives.
* **User Balances:** Tracks deposits available for budgeting and goals.

### Core Data Maps

* **`budgets`** – Stores monthly budgets per user.
* **`expenses`** – Immutable expense records tied to budgets.
* **`savings-goals`** – Individual goal definitions with contribution tracking.
* **`user-balances`** – On-chain ledger of deposits/withdrawals.
* **`user-stats`** – Aggregated statistics for achievements and gamification.

### Constants

* `BLOCKS-PER-MONTH`: Defines ~30-day cycles.
* `MIN-BUDGET-AMOUNT`, `MIN-GOAL-AMOUNT`: Enforce discipline and prevent spam entries.
* `ACHIEVEMENT-BONUS`: Fixed STX reward per completed goal.

---

## 🔄 Data Flow

1. **User deposits STX** → credited to `user-balances`.
2. **Budget creation** → allocates STX across categories with spending limits.
3. **Expense logging** → reduces available budget, enforces category limits.
4. **Goal creation & contributions** → user funds locked toward specific savings goals.
5. **Goal completion** → updates user stats; reward claim pulls from reward pool.
6. **Withdrawal** → users can withdraw unallocated balances at any time.

---

## 📜 Error Codes

| Code   | Description        |
| ------ | ------------------ |
| `u100` | Unauthorized       |
| `u101` | Not Found          |
| `u102` | Invalid Input      |
| `u103` | Insufficient Funds |
| `u104` | Budget Exceeded    |
| `u105` | Goal Not Met       |
| `u106` | Already Exists     |
| `u107` | Goal Expired       |

---

## 🚀 Deployment & Usage

### Deploy

1. Compile and deploy the `bitbudget.clar` contract to your Stacks environment.
2. Set contract-owner (for reward pool funding).

### Typical Workflow

1. **Fund account**: `deposit(amount)`
2. **Create monthly budget**: `create-budget(total-budget …categories)`
3. **Add expense**: `add-expense(amount category description)`
4. **Create savings goal**: `create-goal(title target-amount deadline-months)`
5. **Contribute to goal**: `contribute-to-goal(goal-id amount)`
6. **Claim reward (if eligible)**: `claim-goal-reward(goal-id)`

---

## 🔐 Security Considerations

* **Immutable records:** Expenses and goals cannot be deleted, ensuring transparency.
* **Strict assertions:** Validations prevent budget overspending or unauthorized claims.
* **Reward pool isolation:** Only the contract-owner can fund the pool; claims require verifiable achievements.

---

## 📊 Future Enhancements

* **Multi-user shared budgets** (family/teams).
* **NFT-based achievement badges.**
* **Integration with sBTC for yield-backed savings.**
* **Mobile wallet integration for real-time budget alerts.**

---

## 🛠️ Tech Stack

* **Blockchain:** [Stacks](https://stacks.co/)
* **Smart Contracts:** Clarity
* **Settlement:** Secured by Bitcoin via Proof of Transfer (PoX)

---

## 🤝 Contributing

1. Fork this repository.
2. Create a feature branch.
3. Submit a pull request with detailed commit messages.

---

## 📄 License

MIT License – open for community use, modification, and contributions.
