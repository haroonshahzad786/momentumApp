export default interface props {
  isDisabled?: boolean
  onClickOk: (...args: any[]) => void
  children: any
  detail?: String
}