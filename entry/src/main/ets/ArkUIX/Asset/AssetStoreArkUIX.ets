import { relationalStore } from '@kit.ArkData';

const ASSET_DB_FILE = 'Asset.db';
const ASSET_STORE_CONFIG: relationalStore.StoreConfig = {
  name: ASSET_DB_FILE,
  securityLevel: relationalStore.SecurityLevel.S2
};

const TABLE_NAME = 'AssetStore';

enum COLUMN {
  key = 'key',
  value = 'value'
}

let assetDb: relationalStore.RdbStore | undefined = undefined;

let dbInitFinished: () => void = () => {};
let dbInitPromise: Promise<void> = new Promise(resolve => dbInitFinished = resolve);

function createTableSQL() {
  return `
    CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
      ${COLUMN.key} TEXT PRIMARY KEY,
      ${COLUMN.value} TEXT
    ) WITHOUT ROWID`;
}

export function AssetDbInit(context: Context) {
  if (!assetDb) {
    relationalStore.getRdbStore(context, ASSET_STORE_CONFIG, async (err, store) => {
      if (err) {
        console.error(`Failed to init asset DB. Code:${err.code}, message:${err.message}`);
        return;
      }
      try {
        await store.executeSql(createTableSQL());
      } catch (e) {
        console.error('Create asset table failed:', e);
      }
      assetDb = store;
      dbInitFinished();
    });
  }
}

export async function createOrUpdateAssetArkUIX(key: string, value: string) {
  await dbInitPromise;

  const row: relationalStore.ValuesBucket = {
    [COLUMN.key]: key,
    [COLUMN.value]: value
  };

  assetDb?.beginTransaction();
  assetDb?.insert(TABLE_NAME, row,
    relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  assetDb?.commit();
}

export async function queryAssetArkUIX(key: string): Promise<string> {
  await dbInitPromise;

  const predicates = new relationalStore.RdbPredicates(TABLE_NAME)
    .equalTo(COLUMN.key, key);

  const result = await assetDb!.query(predicates, [COLUMN.value]);
  if (result.rowCount === 0) {
    return Promise.reject();
  }

  result.goToFirstRow();
  const value = result.getString(result.getColumnIndex(COLUMN.value));
  result.close();
  return value;
}

export async function removeAssetArkUIX(key: string): Promise<number> {
  await dbInitPromise;

  const predicates = new relationalStore.RdbPredicates(TABLE_NAME)
    .equalTo(COLUMN.key, key);

  return await assetDb!.delete(predicates);
}