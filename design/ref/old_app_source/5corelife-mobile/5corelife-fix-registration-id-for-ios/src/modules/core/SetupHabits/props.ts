import { Core } from '../../../typescript/main'

export default interface props {
  navigation: {
    goBack: any
    navigate: any
    replace: any
  }
  route: {
    params: {
      core: Core
    }
  }
}
