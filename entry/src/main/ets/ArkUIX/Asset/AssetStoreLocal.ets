import { asset } from '@kit.AssetStoreKit'
import { arrayToString, stringToArray } from '../../common/TextUtil'

export async function queryAssetLocal(key: string) {
  const query: asset.AssetMap = new Map()
  query.set(asset.Tag.ALIAS, stringToArray(key))
  query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL)
  try {
    const result = await asset.query(query)
    return result.map(v => arrayToString(v.get(asset.Tag.SECRET) as Uint8Array))
  } catch (error) {
    // no found
    return undefined
  }
}

export async function createOrUpdateAssetLocal(key: string, secret: string) {
  const query = await queryAssetLocal(key)
  const assetEntry: asset.AssetMap = new Map()
  assetEntry.set(asset.Tag.ALIAS, stringToArray(key))
  if (query && query.length > 0) {
    const newSecret: asset.AssetMap = new Map()
    newSecret.set(asset.Tag.SECRET, stringToArray(secret))
    asset.updateSync(assetEntry, newSecret)
  } else {
    assetEntry.set(asset.Tag.SECRET, stringToArray(secret))
    asset.addSync(assetEntry)
  }
}

export async function removeAssetLocal(key: string) {
  const query = await queryAssetLocal(key)
  if (query && query.length > 0) {
    const assetEntry: asset.AssetMap = new Map()
    assetEntry.set(asset.Tag.ALIAS, stringToArray(key))
    asset.remove(assetEntry)
  }
}