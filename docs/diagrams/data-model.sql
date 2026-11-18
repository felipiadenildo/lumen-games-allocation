CREATE TABLE "ledger" (
  "line_id" varchar PRIMARY KEY,
  "month" varchar,
  "entity" varchar,
  "cost_center" int,
  "amount_usd" decimal,
  "account" int
);

CREATE TABLE "entities" (
  "entity" varchar PRIMARY KEY,
  "entity_name" varchar,
  "country" varchar,
  "entity_group" varchar
);

CREATE TABLE "accounts" (
  "account" int PRIMARY KEY,
  "account_name" varchar,
  "account_group" varchar
);

CREATE TABLE "cost_centers" (
  "cost_center" int PRIMARY KEY,
  "cost_center_name" varchar,
  "department" varchar,
  "game" varchar,
  "pool_id" varchar
);

CREATE TABLE "pools" (
  "pool_id" varchar,
  "game" varchar,
  PRIMARY KEY ("pool_id", "game")
);

CREATE TABLE "headcount_games" (
  "month" varchar,
  "game" varchar,
  "fte" decimal,
  PRIMARY KEY ("month", "game")
);

CREATE TABLE "headcount_employees" (
  "month" varchar,
  "employee_id" varchar,
  "entity" varchar,
  "category" varchar,
  PRIMARY KEY ("month", "employee_id")
);

CREATE TABLE "game_mapping" (
  "bearing_group" varchar,
  "category" varchar,
  "game_group" varchar,
  "side" varchar,
  "start_date" date,
  "end_date" date
);

CREATE INDEX ON "game_mapping" ("game_group", "bearing_group", "start_date");

COMMENT ON TABLE "ledger" IS 'one row per ledger line; scope = all except account_group Depreciation and zero amounts';

COMMENT ON COLUMN "ledger"."line_id" IS 'L00001';

COMMENT ON COLUMN "ledger"."month" IS 'yyyy-MM';

COMMENT ON COLUMN "ledger"."entity" IS 'entity that booked the cost';

COMMENT ON COLUMN "ledger"."amount_usd" IS 'positive = expense, negative = credit';

COMMENT ON COLUMN "entities"."entity" IS 'LGB, LGI, ...';

COMMENT ON COLUMN "entities"."entity_group" IS 'BR, US, FI or Others = booked group';

COMMENT ON COLUMN "accounts"."account_group" IS 'Depreciation is out of scope';

COMMENT ON COLUMN "cost_centers"."department" IS 'Live Games, New Games, ..., Operations';

COMMENT ON COLUMN "cost_centers"."game" IS 'filled when the team is a single game';

COMMENT ON COLUMN "cost_centers"."pool_id" IS 'filled when the team is shared by several games';

COMMENT ON TABLE "pools" IS 'pool x game: the games a shared team works for';

COMMENT ON TABLE "headcount_games" IS 'split weights for pool costs';

COMMENT ON TABLE "headcount_employees" IS 'split weights for indirect costs (buckets)';

COMMENT ON COLUMN "headcount_employees"."category" IS 'Live Games or New Games';

COMMENT ON TABLE "game_mapping" IS 'dated: one row per game or bucket x period';

COMMENT ON COLUMN "game_mapping"."bearing_group" IS 'filled only on bucket rows';

COMMENT ON COLUMN "game_mapping"."game_group" IS 'a game or a bucket';

COMMENT ON COLUMN "game_mapping"."side" IS 'BR Games, US Games or By entity';

COMMENT ON COLUMN "game_mapping"."end_date" IS '9999-12-31 = open';

ALTER TABLE "ledger" ADD FOREIGN KEY ("entity") REFERENCES "entities" ("entity") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "ledger" ADD FOREIGN KEY ("account") REFERENCES "accounts" ("account") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "ledger" ADD FOREIGN KEY ("cost_center") REFERENCES "cost_centers" ("cost_center") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "headcount_employees" ADD FOREIGN KEY ("entity") REFERENCES "entities" ("entity") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "cost_centers" ADD FOREIGN KEY ("pool_id") REFERENCES "pools" ("pool_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "cost_centers" ADD FOREIGN KEY ("game") REFERENCES "game_mapping" ("game_group") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "pools" ADD FOREIGN KEY ("game") REFERENCES "game_mapping" ("game_group") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "headcount_games" ADD FOREIGN KEY ("game") REFERENCES "game_mapping" ("game_group") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "headcount_employees" ADD FOREIGN KEY ("category") REFERENCES "game_mapping" ("category") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "game_mapping" ADD FOREIGN KEY ("bearing_group") REFERENCES "entities" ("entity_group") DEFERRABLE INITIALLY IMMEDIATE;
