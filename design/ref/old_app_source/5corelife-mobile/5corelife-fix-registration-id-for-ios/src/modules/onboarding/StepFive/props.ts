import { Core, CoreInfo } from "../../../typescript/main";

export default interface props {
  navigation: {
    navigate: any,
    replace:any
  }
  route: {
    params: {
      core: Core
      prevHabits: any[] | null
    }
  }
}
