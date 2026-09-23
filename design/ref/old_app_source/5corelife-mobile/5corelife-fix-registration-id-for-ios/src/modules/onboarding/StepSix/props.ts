import { CoreInfo } from "../../../typescript/main";

export default interface props {
  navigation: {
    navigate: any
    replace: any
  }
  route: {
    params: {
      habits: any[]
      core: CoreInfo
      score: null | number
    }
  }
}
