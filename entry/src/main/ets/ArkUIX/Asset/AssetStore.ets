import { PlatformInfo, PlatformTypeEnum } from '../PlatformInfo'
import lazy { AssetDbInit, createOrUpdateAssetArkUIX, queryAssetArkUIX, removeAssetArkUIX } from './AssetStoreArkUIX'
import lazy { createOrUpdateAssetLocal, queryAssetLocal, removeAssetLocal } from './AssetStoreLocal'

export async function queryAsset(key: string): Promise<string[] | undefined> {
  if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {
    return queryAssetLocal(key)
  } else {
    return [await queryAssetArkUIX(key)]
  }
}

export async function createOrUpdateAsset(key: string, secret: string){
  if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {
    createOrUpdateAssetLocal(key, secret)
  } else {
    createOrUpdateAssetArkUIX(key, secret)
  }
}

export async function removeAsset(key: string) {
  if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {
    removeAssetLocal(key)
  } else {
    removeAssetArkUIX(key)
  }
}

export async function AssetStoreInit(context: Context) {
  if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {

  } else {
    AssetDbInit(context)
  }
}