export default interface props {
  navigation: {
    navigate: any
    goBack: any
  }
  route: {
    params?: any
  }
  tutorial?: boolean
  navigateToNextStep?: any
  goNextStep?: any
  nextStep?:number
}
