import { ApplicationConfig } from "../../config/v1/default";
import { PlatformInfo, PlatformTypeEnum } from "../PlatformInfo";
import { common, ConfigurationConstant } from "@kit.AbilityKit";
import { BridgeFunction, getBridgeInstance } from "../BridgeFunction";

export function SetNightMode(conf: ApplicationConfig, context: common.ApplicationContext) {
  // TODO: ApplicationContext.setColorMode since api 16
  if (PlatformInfo.getPlatform() == PlatformTypeEnum.HARMONYOS) {
    if (conf.dark_mode_follow_system) {
      context.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
    } else {
      context.setColorMode(conf.light_dark_mode_prefer)
    }
  }
}