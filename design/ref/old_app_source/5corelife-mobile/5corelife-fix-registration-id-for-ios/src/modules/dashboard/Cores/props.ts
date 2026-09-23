export default interface props {
  navigation: {
    navigate: any
  },
  //route: {
  //  params: any
  //}
  onBoardingMode?: boolean
  isLastTab?: boolean
  isCoreStep?: boolean
  navigateToNextStep?: any
  launch?: boolean
  cockpit?: boolean
  checkInMorningForce?: boolean
  setAdviseActive?:any
}
