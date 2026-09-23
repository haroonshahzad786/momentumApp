import { Core, CoreInfo } from '../../../typescript/main'

export default interface props {
  navigation: {
    navigate: any
    goBack: any
    replace: any

  }
  onBoardingMode?:boolean
  isLastTab?:boolean
  navigateToNextStep?:any
  lastStep?:boolean
  route: {
    params: {
      habits: any[]
      core: CoreInfo
      score: null | number
    }
  }
}
