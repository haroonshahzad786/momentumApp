import { Core } from '../../../typescript/main'

export default interface props {
  navigation: {
    pop: any
    navigate: any
    replace: any
  }
  route: {
    params: {
      core: Core
    }
  }
}
