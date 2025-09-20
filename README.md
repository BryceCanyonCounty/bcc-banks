# BCC Banks

Modern, feature-rich banking for RedM (VORP). BCC Banks adds multi‑account banking, transfers, safety deposit boxes integrated with vorp_inventory, a gold exchange, a full loans system with admin approvals, and immersive world integration (NPC tellers, door locks, distance blips, prompts).

Works out of the box: tables are auto‑created on first run, UI is powered by feather-menu, and all actions are server‑validated to prevent client-side cheating.

## Features

- Accounts: multiple accounts per bank, close with zero balance, share access by level (Admin, Withdraw/Deposit, Deposit, Read‑only), server-side locking while viewing, full transaction history.
- Transfers: send between accounts (same or other banks) with configurable cross‑bank fee; logs both sides and the fee.
- Safety Deposit Boxes (SDB): create boxes in sizes (Small/Medium/Large), pay in cash or gold, per‑size weight limits and blacklist, shared custom inventories via vorp_inventory, grant/revoke access by character ID.
- Gold Exchange: buy/sell gold currency for cash at config rates; redeem inventory gold bars to gold with a configurable fee.
- Loans: apply with or without an account, per‑bank/per‑character interest rates, admin approve/reject, disburse to account or claim later, repayments, overdue/default tracking using in‑game days, freeze all owner accounts on default.
- Admin UI: `/bankadmin` to manage banks (create at your position), base bank rates, per‑character overrides, list accounts/loans/SDBs, approve/reject loans.
- World Integration: distance-spawned tellers (NPCs), distance blips with open/closed color, prompt key to open, initial door-lock states per bank.
- Localization: English and Romanian included; switch default language in config.

## Requirements

Ensure these resources are installed and started before `bcc-banks`:

- vorp_core
- vorp_inventory
- feather-menu
- bcc-utils
- oxmysql
- Optional: weathersync (used to track in‑game days for loan due/default logic)

Note: `fxmanifest.lua` only declares `oxmysql` as a formal dependency; the others are used via exports and must be started first in your server.cfg.

## Installation

1) Copy this folder to `[BCC]/bcc-banks`.

2) Add start order to your `server.cfg` (example):

```
ensure oxmysql
ensure vorp_core
ensure vorp_inventory
ensure feather-menu
ensure bcc-utils
ensure bcc-minigames
ensure bcc-banks
```
If you want to use this lockpick intstead of bcc-minigames 

Requires the lockpick system dependency: https://github.com/guf1ck/lockpick-system

3) Start the server. All required tables are created automatically (see “Database” below). Use `/bankadmin` to create your first bank at your position, or insert banks via SQL.

## Configuration

Main settings live in `BCC/bcc-banks/shared/config.lua`:

- Language: set `defaultlang` to `'en_lang'` or `'ro_lang'`.
- Notifications: `Notify = "feather-menu"` (recommended) or `vorp_core`.
- Busy Banker: `UseBankerBusy = true` limits teller UI to one person.
- Prompts: `PromptSettings.Distance` and `TellerKey` (default G).
- NPCs: `NPCSettings` model, spawn distance.
- Blips: show, color per state, distance spawn radius.
- Access Levels: numeric mapping for Admin/Withdraw+Deposit/Deposit/ReadOnly.
- Transfers: enable and set `CrossBankFeePercent` (applies to sender).
- Gold Exchange: enable and set buy/sell rates; set `GoldBarItemName`, conversion `GoldBarToGold`, and `GoldBarFeePercent` for redeeming inventory items to gold.
- Accounts: `MaxAccounts` per bank (0 = no limit).
- Safety Deposit Boxes: global max per player/bank and per‑size prices, weight, item blacklist and stack behavior.
- Doors: map door hashes to initial lock state per bank.

Tip: The admin permission check uses VORP character `group` and `job` against `Config.adminGroups` and `Config.AllowedJobs`. There is an optional ACE check in code you can enable if desired.

## Usage

- Approach a bank teller NPC and press the prompt key (default G) to open the bank UI.
- Accounts: create/manage, deposit/withdraw cash or gold, view transactions, share/revoke access, and transfer funds.
- Safety Deposit Boxes: create boxes (cash or gold), open inventory UI, manage access.
- Gold Exchange: buy/sell gold, redeem gold bars from inventory to gold.
- Loans: apply (auto‑creates an account if needed), claim funds to an account once approved, repay from cash, track status. Overdue/default marks freeze all owner accounts until resolved.
- Admin: `/bankadmin` to open the admin UI. Create banks, adjust rates, review lists, approve/reject loans.

## Commands & Keys

- `/bankadmin` — open the bank admin UI (requires admin per config).
- Prompt key: `Config.PromptSettings.TellerKey` (default G) at teller.
- A developer-only `banksReady` command exists to reinit banks in dev mode.

## Database

Tables are created automatically on server start in `server/services/database.lua`:

- `bcc_banks`, `bcc_accounts`, `bcc_accounts_access`
- `bcc_transactions`
- `bcc_loans`, `bcc_loans_payments`, `bcc_loan_interest_rates`, `bcc_bank_interest_rates`
- `bcc_safety_deposit_boxes`, `bcc_safety_deposit_boxes_access`

You can seed banks by using `/bankadmin` → Create Bank At Your Location, or insert rows into `bcc_banks`.

## Technical Notes

- Server‑side validation: all sensitive operations run through server RPCs and DB checks; accounts can be locked while viewing to prevent race conditions.
- Inventory: SDB inventories are registered dynamically using `vorp_inventory` exports. Older rows are backfilled on startup.
- Loan timing: if `weathersync` is present, the script tracks game days to progress loan due dates and mark defaults.
- Discord: code includes a `bcc-utils` Discord webhook setup; provide `Config.WebhookLink`, `WebhookTitle`, and `WebhookAvatar` if you wish to emit notifications.

## Credits

Author: BCC Scripts

Thanks to the VORP and RedM communities, and to the maintainers of `vorp_core`, `vorp_inventory`, `feather-menu`, `bcc-utils`, and `oxmysql`.
