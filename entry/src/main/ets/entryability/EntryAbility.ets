import { AbilityConstant, UIAbility, Want } from "@kit.AbilityKit";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { window } from "@kit.ArkUI";

const LOG_DOMAIN: number = 0x0000;
const LOG_TAG: string = "HarmonyCalendar";

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, "EntryAbility created");
  }

  onDestroy(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, "EntryAbility destroyed");
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent("pages/Index", (err) => {
      if (err.code) {
        hilog.error(LOG_DOMAIN, LOG_TAG, "Failed to load content: %{public}s", JSON.stringify(err));
        return;
      }

      hilog.info(LOG_DOMAIN, LOG_TAG, "Content loaded");
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, "Window stage destroyed");
  }

  onForeground(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, "EntryAbility foreground");
  }

  onBackground(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, "EntryAbility background");
  }
}
