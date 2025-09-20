CreateThread(function()
    -- bcc_banks
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_banks` (
            `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(255) NOT NULL UNIQUE,
            `x` DECIMAL(15,2) NOT NULL,
            `y` DECIMAL(15,2) NOT NULL,
            `z` DECIMAL(15,2) NOT NULL,
            `h` DECIMAL(15,2) NOT NULL,
            `blip` BIGINT DEFAULT -2128054417,
            `hours_active` BOOLEAN NOT NULL DEFAULT FALSE,
            `open_hour` INT UNSIGNED NULL,
            `close_hour` INT UNSIGNED NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Ensure column exists for existing installations (add if missing)
    local col = MySQL.query.await([[ 
        SELECT COUNT(*) AS cnt
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'bcc_banks'
          AND COLUMN_NAME = 'hours_active'
    ]])
    local hasCol = col and col[1] and tonumber(col[1].cnt or 0) or 0
    if hasCol == 0 then
        -- Add missing column with default false
        MySQL.query.await([[ALTER TABLE `bcc_banks` ADD COLUMN `hours_active` BOOLEAN NOT NULL DEFAULT FALSE AFTER `blip`]])
    end

    -- bcc_accounts (no FK to characters)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_accounts` (
            `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            `account_number` CHAR(36) NOT NULL,
            `name` VARCHAR(255) NOT NULL,
            `bank_id` BIGINT UNSIGNED NOT NULL,
            `owner_id` BIGINT UNSIGNED NOT NULL,
            `cash` DOUBLE(15,2) DEFAULT 0.0,
            `gold` DOUBLE(15,2) DEFAULT 0.0,
            `is_frozen` BOOLEAN NOT NULL DEFAULT FALSE,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_account_number` (`account_number`),
            KEY `idx_accounts_bank` (`bank_id`),
            KEY `idx_accounts_owner` (`owner_id`),
            CONSTRAINT `FK_accounts_bank`
              FOREIGN KEY (`bank_id`) REFERENCES `bcc_banks` (`id`)
              ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- bcc_accounts_access
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_accounts_access` (
            `account_id` BIGINT UNSIGNED NOT NULL,
            `character_id` BIGINT UNSIGNED NOT NULL,
            `level` INT UNSIGNED DEFAULT 2,
            PRIMARY KEY (`account_id`, `character_id`),
            KEY `idx_baa_account` (`account_id`),
            KEY `idx_baa_character` (`character_id`),
            CONSTRAINT `FK_baa_account`
              FOREIGN KEY (`account_id`) REFERENCES `bcc_accounts` (`id`)
              ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- bcc_loans (no FK to characters)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_loans` (
            `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            `account_id` BIGINT UNSIGNED NULL,
            `bank_id` BIGINT UNSIGNED NULL,
            `character_id` BIGINT UNSIGNED NOT NULL,
            `amount` DOUBLE(15,2) NOT NULL,
            `interest` DOUBLE(15,2) NOT NULL,
            `duration` INT UNSIGNED NOT NULL,
            `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
            `approved_by` BIGINT UNSIGNED NULL,
            `approved_at` DATETIME NULL,
            `disbursed_account_id` BIGINT UNSIGNED NULL,
            `disbursed_at` DATETIME NULL,
            `last_game_day` INT NULL,
            `game_days_elapsed` INT UNSIGNED NOT NULL DEFAULT 0,
            `due_game_days` INT UNSIGNED NULL,
            `is_defaulted` BOOLEAN NOT NULL DEFAULT FALSE,
            `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_loans_account` (`account_id`),
            KEY `idx_loans_bank` (`bank_id`),
            CONSTRAINT `FK_loans_account`
              FOREIGN KEY (`account_id`) REFERENCES `bcc_accounts` (`id`)
              ON DELETE CASCADE ON UPDATE CASCADE,
            CONSTRAINT `FK_loans_bank`
              FOREIGN KEY (`bank_id`) REFERENCES `bcc_banks` (`id`)
              ON DELETE SET NULL ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- bcc_loans_payments
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_loans_payments` (
            `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            `loan_id` BIGINT UNSIGNED NOT NULL,
            `amount` DOUBLE(15,2) NOT NULL,
            `date_due` DATETIME NOT NULL,
            `is_paid` BOOLEAN NOT NULL DEFAULT FALSE,
            `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_lp_loan` (`loan_id`),
            CONSTRAINT `FK_lp_loan`
              FOREIGN KEY (`loan_id`) REFERENCES `bcc_loans` (`id`)
              ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- bcc_loan_interest_rates (no FKs)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_loan_interest_rates` (
            `character_id` BIGINT UNSIGNED NOT NULL,
            `bank_id` BIGINT UNSIGNED NOT NULL,
            `interest` DOUBLE(15,2) NOT NULL,
            PRIMARY KEY (`character_id`, `bank_id`),
            KEY `idx_lir_bank` (`bank_id`),
            KEY `idx_lir_character` (`character_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- bcc_bank_interest_rates (per-bank base rate used by admin UI)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_bank_interest_rates` (
            `bank_id` BIGINT UNSIGNED NOT NULL,
            `interest` DOUBLE(15,2) NOT NULL,
            PRIMARY KEY (`bank_id`),
            KEY `idx_bir_bank` (`bank_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- bcc_transactions (no FK to characters)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_transactions` (
            `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            `account_id` BIGINT UNSIGNED,
            `loan_id` BIGINT UNSIGNED,
            `character_id` BIGINT UNSIGNED NOT NULL,
            `amount` DOUBLE(15,2) NOT NULL,
            `type` VARCHAR(255) NOT NULL,
            `description` VARCHAR(255) NOT NULL,
            `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_t_account` (`account_id`),
            KEY `idx_t_loan` (`loan_id`),
            CONSTRAINT `FK_t_account`
              FOREIGN KEY (`account_id`) REFERENCES `bcc_accounts` (`id`)
              ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- bcc_safety_deposit_boxes (no FK to characters)
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_safety_deposit_boxes` (
            `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(255) NOT NULL,
            `bank_id` BIGINT UNSIGNED NOT NULL,
            `owner_id` BIGINT UNSIGNED NOT NULL,
            `size` VARCHAR(255) NOT NULL,
            `inventory_id` CHAR(36) NULL,
            PRIMARY KEY (`id`),
            KEY `idx_sdb_bank` (`bank_id`),
            KEY `idx_sdb_owner` (`owner_id`),
            CONSTRAINT `FK_sdb_bank`
              FOREIGN KEY (`bank_id`) REFERENCES `bcc_banks` (`id`)
              ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- bcc_safety_deposit_boxes_access
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bcc_safety_deposit_boxes_access` (
            `safety_deposit_box_id` BIGINT UNSIGNED NOT NULL,
            `character_id` BIGINT UNSIGNED NOT NULL,
            `level` INT UNSIGNED DEFAULT 2,
            PRIMARY KEY (`safety_deposit_box_id`, `character_id`),
            KEY `idx_sdba_sdb` (`safety_deposit_box_id`),
            KEY `idx_sdba_character` (`character_id`),
            CONSTRAINT `FK_sdba_sdb`
              FOREIGN KEY (`safety_deposit_box_id`)
              REFERENCES `bcc_safety_deposit_boxes` (`id`)
              ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Optional seed
    MySQL.query.await([[
        INSERT IGNORE INTO `bcc_banks` (`name`, `x`, `y`, `z`, `h`, `blip`, `hours_active`, `open_hour`, `close_hour`)
        VALUES 
        ('Valentine', -307.82, 773.96, 118.70, 2.88, -2128054417, 0, 7, 21),
        ('BlackWater', -810.51, -1275.37, 43.64, 189.16, -2128054417, 0, 7, 21),
        ('Rhodes', 1291.25, -1303.30, 77.04, 322.24, -2128054417, 0, 7, 21),
        ('SaintDenis', 2644.15, -1296.16, 52.25, 111.40, -2128054417, 0, 7, 21);
    ]])

    devPrint("Database tables for *bcc-banks* created successfully.")
end)
