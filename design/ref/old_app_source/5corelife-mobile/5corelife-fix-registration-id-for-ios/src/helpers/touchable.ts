import { vh, vw } from '../helpers/dimensions'

export const hitSlop = (
  top: number,
  left: number,
  bottom: number,
  right: number
) => {
  return { top: vh(top), left: vw(left), bottom: vh(bottom), right: vw(right) }
}
