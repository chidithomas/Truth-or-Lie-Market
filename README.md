Truth-or-Lie Market Smart Contract

A decentralized prediction-style contract where users submit claims and stake STX tokens on whether they believe the claim is true or false. Once resolved by the contract owner, participants can claim payouts proportional to their stake if they bet on the correct outcome.

🚀 Features

Submit Claims: Anyone can propose a new claim with a description.

Stake on Outcomes: Users can stake STX on either "true" or "false."

Fair Payouts: Winners receive their stake plus a share of the losing side’s total pool.

Resolution: Only the contract owner can finalize the truth status of a claim.

Payout Claiming: Once resolved, stakers can withdraw their winnings.

⚙️ Functions
🔍 Read-only Functions

get-claim (claim-id) → Returns details of a claim.

get-stake (claim-id, staker) → Returns stake details of a user.

get-next-claim-id → Returns the ID for the next claim.

calculate-payout (claim-id, staker) → Estimates payout for a staker after resolution.

📝 Public Functions

submit-claim (description) → Creates a new claim.

stake-true (claim-id, amount) → Stake STX on "true".

stake-false (claim-id, amount) → Stake STX on "false".

resolve-claim (claim-id, outcome) → Owner sets the outcome (true/false).

claim-payout (claim-id) → Allows stakers to withdraw their earnings after resolution.

🛡️ Error Codes

err-not-found (404) → Claim or stake not found.

err-already-resolved (400) → Claim already resolved or payout already claimed.

err-insufficient-funds (401) → Transfer failed due to lack of STX.

err-unauthorized (403) → Unauthorized action (only owner can resolve).

err-invalid-outcome (405) → Invalid outcome parameter.

📊 Payout Logic

Winning side gets their stake back + a proportional share of the losing side’s pool.

If no one staked on the winning side, payouts will be zero.

🏗️ Example Flow

Alice submits a claim: “Bitcoin will surpass $100k in 2025.”

Bob stakes 100 STX on true, Charlie stakes 50 STX on false.

Owner resolves the claim as true.

Bob can now claim his payout:

His 100 STX back + all of Charlie’s 50 STX (since he’s the only winner).

✅ Deployment Notes

Designed for the Stacks blockchain using Clarity.

Contract owner has exclusive resolution authority.

Stakes are transferred to the contract at time of staking.

🔒 Security Considerations

Centralized resolution authority (owner decides outcomes).

All funds are handled by secure stx-transfer? calls.

Prevents double claims with the claimed flag in stakes map.