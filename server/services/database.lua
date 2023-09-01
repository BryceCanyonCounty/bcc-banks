local tables = {
  {
    name = 'banks',
    query = [[
      CREATE TABLE IF NOT EXISTS `banks` (
      `id` bigint UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
      `name` VARCHAR(255) NOT NULL,
      `x` decimal(15, 2) NOT NULL,
      `y` decimal(15, 2) NOT NULL,
      `z` decimal(15, 2) NOT NULL,
      `h` decimal(15, 2) NOT NULL,
      `blip` bigint DEFAULT -2128054417,
      `open_hour` int UNSIGNED NULL,
      `close_hour` int UNSIGNED NULL
      )ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
  },
  {
    name = 'accounts',
    query = [[
      CREATE TABLE IF NOT EXISTS `accounts` (
      `id` bigint UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
      `name` VARCHAR(255) NOT NULL,
      `bank_id` bigint UNSIGNED NOT NULL,
      `owner_id` bigint UNSIGNED NOT NULL,
      `cash` double (15,2) default 0.0,
      `gold` double (15, 2) default 0.0,
      CONSTRAINT `FK_Bank` FOREIGN KEY (`bank_id`) REFERENCES `banks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
      CONSTRAINT `FK_Owner` FOREIGN KEY (`owner_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE ON UPDATE CASCADE)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
  },
  {
    name = 'accounts_access',
    query = [[
      CREATE TABLE IF NOT EXISTS `accounts_access` (
      `account_id` bigint UNSIGNED NOT NULL,
      `character_id` bigint UNSIGNED NOT NULL,
      `level` int UNSIGNED default 2,
      PRIMARY KEY (`account_id`, `character_id`),
      CONSTRAINT `FK_ba_character` FOREIGN KEY (`character_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
      CONSTRAINT `FK_ba_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    )ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
  },
  {
    name = 'loans',
    query = [[
      CREATE TABLE IF NOT EXISTS `loans` (
      `id` bigint UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
      `account_id` bigint UNSIGNED NOT NULL,
      `character_id` bigint UNSIGNED NOT NULL,
      `amount` double (15, 2) NOT NULL,
      `interest` double (15, 2) NOT NULL,
      `duration` int UNSIGNED NOT NULL,
      `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      CONSTRAINT `FK_l_character` FOREIGN KEY (`character_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
      CONSTRAINT `FK_l_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
      )ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
      ]]
  },
  {
    name = 'loans_payments',
    query = [[
      CREATE TABLE IF NOT EXISTS `loans_payments` (
      `id` bigint UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
      `loan_id` bigint UNSIGNED NOT NULL,
      `amount` double (15, 2) NOT NULL,
      `date_due` datetime NOT NULL,
      `is_paid` boolean NOT NULL DEFAULT false,
      `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      CONSTRAINT `FK_lp_loan` FOREIGN KEY (`loan_id`) REFERENCES `loans` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
      )ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
      ]]
  },
  {
    name = 'transactions',
    query = [[
      CREATE TABLE IF NOT EXISTS `transactions` (
      `uuid` uuid DEFAULT UUID() NOT NULL PRIMARY KEY,
      `account_id` bigint UNSIGNED,
      `loan_id` bigint UNSIGNED,
      `character_id` bigint UNSIGNED NOT NULL,
      `amount` double (15, 2) NOT NULL,
      `type` VARCHAR(255) NOT NULL,
      `description` VARCHAR(255) NOT NULL,
      `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT `FK_t_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
      CONSTRAINT `FK_t_character` FOREIGN KEY (`character_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
      )ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
      ]]
  },
  {
    name = 'safety_deposit_boxes',
    query = [[
      CREATE TABLE IF NOT EXISTS `safety_deposit_boxes` (
      `id` bigint UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
      `name` VARCHAR(255) NOT NULL,
      `bank_id` bigint UNSIGNED NOT NULL,
      `owner_id` bigint UNSIGNED NOT NULL,
      `size` VARCHAR(255) NOT NULL,
      `inventory_id` UUID NULL,
      CONSTRAINT `FK_sdb_Bank` FOREIGN KEY (`bank_id`) REFERENCES `banks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
      CONSTRAINT `FK_sdb_Owner` FOREIGN KEY (`owner_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    )ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
  },
  {
    name = 'safety_deposit_boxes_access',
    query = [[
      CREATE TABLE IF NOT EXISTS `safety_deposit_boxes_access` (
      `safety_deposit_box_id` bigint UNSIGNED NOT NULL,
      `character_id` bigint UNSIGNED NOT NULL,
      `level` int UNSIGNED default 2,
      PRIMARY KEY (`safety_deposit_box_id`, `character_id`),
      CONSTRAINT `FK_sdba_character` FOREIGN KEY (`character_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
      CONSTRAINT `FK_sdba_safety_deposit_box` FOREIGN KEY (`safety_deposit_box_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    )ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
  }
}

local data = {
  {
    name = 'Valentine',
    query = [[
      INSERT INTO `banks` (`Name`, `X`, `Y`, `Z`, `H`, Blip) VALUES ('Valentine', -308.16, 773.77, 118.70, 1.31, -2128054417);
      ]]
  },
  -- {
  --   name = 'Blackwater',
  --   query = [[
  --     INSERT INTO `banks` (`Name`, `X`, `Y`, `Z`, `H`, Blip) VALUES ('Blackwater', -308.16, 773.77, 118.70, 1.31, -2128054417);
  --     ]]
  -- },
  -- {
  --   name = 'Saint Denis',
  --   query = [[
  --     INSERT INTO `banks` (`Name`, `X`, `Y`, `Z`, `H`, Blip) VALUES ('Saint Denis', -308.16, 773.77, 118.70, 1.31, -2128054417);
  --     ]]
  -- },
  -- {
  --   name = 'Rhodes',
  --   query = [[
  --     INSERT INTO `banks` (`Name`, `X`, `Y`, `Z`, `H`, Blip) VALUES ('Rhodes', -308.16, 773.77, 118.70, 1.31, -2128054417);
  --     ]]
  -- },
}

function LoadDatabase()
  for i, v in ipairs(tables) do
    MySQL.query.await(v.query)
  end

  for i, v in ipairs(data) do
    MySQL.query.await(v.query)
  end
end
